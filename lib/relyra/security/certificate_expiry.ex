if Code.ensure_loaded?(Ecto.Query) do
  defmodule Relyra.Security.CertificateExpiry do
    @moduledoc """
    Batch traversal function to check for expiring SAML certificates.

    Provides a pure function `check_all/2` that adopters can hook into
    their own schedulers. Queries active/next certificates on enabled
    connections that are approaching their `not_after` threshold.
    """

    import Ecto.Query, only: [from: 2]

    alias Relyra.Ecto.Certificate
    alias Relyra.Ecto.Connection
    alias Relyra.Error

    @doc """
    Checks for expiring certificates and emits standard `:telemetry` events.

    `opts`:
      - `:days_to_expiry` — default `30`. Certificates expiring within this many days are flagged.

    Returns `{:ok, %{certificate_id => :ok}}` for matching certificates.
    """
    @spec check_all(module(), keyword()) ::
            {:ok, %{optional(binary()) => :ok}} | {:error, Error.t()}
    def check_all(repo, opts \\ []) when is_atom(repo) and is_list(opts) do
      days_to_expiry = Keyword.get(opts, :days_to_expiry, 30)
      now = DateTime.utc_now()
      threshold_date = DateTime.add(now, days_to_expiry, :day)

      certs = fetch_expiring_certificates(repo, threshold_date)

      case certs do
        [] ->
          {:ok, %{}}

        certs ->
          results =
            certs
            |> Enum.map(fn {cert, conn} ->
              days_until_expiry = DateTime.diff(cert.not_after, now, :day)

              Relyra.Telemetry.execute(
                [:certificate, :expiring],
                %{days_until_expiry: days_until_expiry},
                %{
                  connection_id: conn.connection_id,
                  certificate_id: cert.id,
                  fingerprint_sha256: cert.fingerprint_sha256,
                  not_after: cert.not_after
                }
              )

              {cert.id, :ok}
            end)
            |> Map.new()

          {:ok, results}
      end
    end

    defp fetch_expiring_certificates(repo, threshold_date) do
      repo.all(
        from(cert in Certificate,
          join: conn in Connection,
          on: conn.id == cert.connection_record_id,
          where: conn.status == :enabled,
          where: cert.lifecycle_state in [:active, :next],
          where: cert.not_after <= ^threshold_date,
          select: {cert, conn}
        )
      )
    end
  end
else
  defmodule Relyra.Security.CertificateExpiry do
    @moduledoc """
    Ecto-absent compile lane. Calling `check_all/2` returns a typed
    optional-dep error.
    """

    alias Relyra.Error

    @spec check_all(module(), keyword()) :: {:error, Error.t()}
    def check_all(_repo, _opts \\ []) do
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Ecto is required for certificate expiry checks; add `{:ecto, \"~> 3.13\"}` and `{:ecto_sql, \"~> 3.13\"}` to deps",
         %{operation: :check_all, missing_dependency: :ecto}
       )}
    end
  end
end
