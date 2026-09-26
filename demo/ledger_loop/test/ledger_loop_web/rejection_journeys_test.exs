defmodule LedgerLoopWeb.RejectionJourneysTest do
  use LedgerLoopWeb.ConnCase, async: false

  import Ecto.Query

  alias LedgerLoop.Accounts.LoginReceipt
  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.FakeIdP.Signer
  alias LedgerLoop.Repo
  alias LedgerLoop.TestSupport.LifecycleFlow
  alias Relyra.Ecto.{AuditEvent, Connection}

  @connection_id Fixtures.relyra_enabled_scenario_id()
  @issuer "https://idp.northstar.example.com"
  @subject "sarah@northstar.example.com"

  setup do
    Reset.reset!()
    :ok
  end

  test "the ACS returns typed, sessionless rejections for each representative invalid response" do
    cases = [
      {"digest", :digest_mismatch, &Signer.tamper/1},
      {"signature", :invalid_signature, &invalidate_signature/1},
      {"issuer", :issuer_mismatch, [issuer: "https://attacker.example.com"]},
      {"audience", :invalid_audience, [audience: "https://attacker.example.com/sp"]},
      {"destination", :destination_mismatch, [destination: "https://attacker.example.com/acs"]},
      {"time", :assertion_expired,
       [
         not_on_or_after: "2000-01-01T00:00:00Z",
         subject_confirmation_not_on_or_after: "2000-01-01T00:00:00Z"
       ]},
      {"request correlation", :in_response_to_mismatch,
       [in_response_to: "request-from-another-login"]}
    ]

    for {label, expected_error, mutation} <- cases do
      flow =
        LifecycleFlow.start_login(@connection_id, @issuer, @subject, signer_options(mutation))

      saml_response = response_for(flow.saml_response, mutation)

      assert_rejected_without_host_session(flow, saml_response, label, expected_error)
    end
  end

  test "the same configured ACS still accepts a valid signed response" do
    flow = LifecycleFlow.start_login(@connection_id, @issuer, @subject)

    accepted = LifecycleFlow.post_acs(flow)

    assert accepted.status == 302
    assert get_resp_header(accepted, "location") == ["/"]
    assert Repo.aggregate(LoginReceipt, :count, :id) == 1
  end

  defp signer_options(fun) when is_function(fun, 1), do: []
  defp signer_options(options) when is_list(options), do: options

  defp response_for(response, mutation) when is_function(mutation, 1), do: mutation.(response)
  defp response_for(response, _options), do: response

  defp assert_rejected_without_host_session(flow, saml_response, label, expected_error) do
    receipts_before = Repo.aggregate(LoginReceipt, :count, :id)
    rejected = LifecycleFlow.post_acs(flow, saml_response)

    assert rejected.status == 400, "#{label} response was not rejected by the ACS"

    refute get_resp_header(rejected, "location") == ["/"],
           "#{label} response redirected as a login"

    assert get_resp_header(rejected, "set-cookie") == [],
           "#{label} response created a browser session cookie"

    assert Repo.aggregate(LoginReceipt, :count, :id) == receipts_before,
           "#{label} response created an adopter-owned receipt"

    connection = Repo.get_by!(Connection, connection_id: @connection_id)

    assert Enum.any?(
             Repo.all(
               from event in AuditEvent,
                 where: event.connection_record_id == ^connection.id and event.domain == :login
             ),
             fn event ->
               event.action == :failed and
                 event_error_codes(event) |> Enum.member?(Atom.to_string(expected_error))
             end
           ),
           "#{label} response did not retain its exact typed error in the owning login trace"
  end

  defp event_error_codes(event) do
    event.after_summary
    |> Map.get("steps", %{})
    |> Map.values()
    |> Enum.map(&Map.get(&1, "error_code"))
    |> Enum.reject(&is_nil/1)
  end

  defp invalidate_signature(response) do
    xml = Base.decode64!(response)

    tampered =
      Regex.replace(
        ~r/(<SignatureValue>)([^<]+)(<\/SignatureValue>)/,
        xml,
        fn _, open, signature, close ->
          replacement = "B" <> binary_part(signature, 1, byte_size(signature) - 1)
          open <> replacement <> close
        end,
        global: false
      )

    assert tampered != xml
    Base.encode64(tampered)
  end
end
