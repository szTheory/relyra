defmodule LedgerLoop.Relyra.SessionAdapter do
  @moduledoc """
  LedgerLoop-owned implementation of the Relyra.SessionAdapter behaviour.
  Establishes a host session/receipt proof after Relyra verifies the SAML trust.
  """
  @behaviour Relyra.SessionAdapter

  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.LoginReceipt

  @impl Relyra.SessionAdapter
  def establish_session(subject, context, _opts) do
    connection_id =
      Map.get(context, :connection_id) ||
        context
        |> Map.get(:principal, %{})
        |> Map.get(:connection_id) || "unknown"

    # context is a %Relyra.LoginResult{} struct — use Map.get, not Access ([]),
    # since LoginResult does not implement the Access behaviour. The verified
    # connection identifier is carried by its Principal.
    scenario_key =
      "session_#{connection_id}_#{System.unique_integer([:positive])}"

    changeset =
      LoginReceipt.changeset(%LoginReceipt{}, %{
        user_id: subject.id,
        scenario_key: scenario_key
      })

    case Repo.insert(changeset) do
      {:ok, receipt} ->
        receipt_proof = %{
          receipt_id: receipt.id,
          user_id: subject.id,
          scenario_key: receipt.scenario_key,
          principal_verified_by: "Relyra",
          mapping_owner: "LedgerLoop",
          session_owner: "LedgerLoop",
          authorization_owner: "LedgerLoop"
        }

        {:ok, receipt_proof}

      {:error, _changeset} ->
        {:error, Relyra.Error.new(:session_establishment_failed, "Failed to insert LoginReceipt")}
    end
  end

  @impl Relyra.SessionAdapter
  def revoke_session(_subject, _session_index, _context, _opts) do
    {:ok, :revoked}
  end

  @impl Relyra.SessionAdapter
  def index_session(_session_index, _issuer, _context, _opts) do
    {:ok, :indexed}
  end

  @impl Relyra.SessionAdapter
  def terminate_by_session_index(_session_index, _issuer, _context, _opts) do
    {:ok, :terminated}
  end
end
