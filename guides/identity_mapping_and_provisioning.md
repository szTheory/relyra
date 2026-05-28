# Identity Mapping And Provisioning

This guide is the operator-facing reference for the moment after SAML validation
has already succeeded. Use it to decide which verified identity field becomes
your local account anchor, whether login-time JIT is appropriate, and where
Relyra's responsibility ends.

## Overview

Relyra verifies the SAML response, normalizes the successful login into a
verified payload, and then stops at a host-owned seam. It does not decide
whether a local user should be looked up, linked, created, updated, suspended,
or authorized for application-specific roles.

In the Phoenix ACS path, that seam is `Relyra.UserMapper.map_attributes/3`.
The controller passes the verified login result plus the resolved connection
into the mapper, and the host application returns the user-shaped map that its
session layer needs next.

Treat this guide as a local identity policy document, not as a SAML theory
overview. The question is not "what can the IdP emit?" The question is "which
verified value should our app trust as the durable local anchor?"

## `UserMapper` behaviour

`Relyra.UserMapper.map_attributes/3` is the host-owned seam between verified
SAML identity and your application's account policy.

On the Phoenix ACS success path, Relyra calls the mapper like this:

```elixir
{:ok, login_result} = Relyra.consume_response(response_xml, consume_opts)
{:ok, mapped_user} = Relyra.UserMapper.map_attributes(login_result, login_result.connection, opts)
```

That means the adapter receives the verified `%Relyra.LoginResult{}` plus the
resolved connection. In the ACS path, read identity data from
`login_result.principal`, not from invented top-level fields:

```elixir
%Relyra.LoginResult{
  principal: %Relyra.Principal{
    name_id: name_id,
    name_id_format: name_id_format,
    attributes: attributes
  },
  connection: connection
}
```

Keep one contract explicit in host code and operator docs:

- Relyra verifies the response, the signature, the replay constraints, and the
  normalized identity payload.
- Your mapper decides how to interpret those verified facts for local account
  lookup, linking, creation, update, and authorization policy.
- Relyra does not ship a user database, background provisioning engine, or SCIM
  lifecycle controller.

The examples below are intentionally host-owned. They show real adapter modules
that read from `%Relyra.LoginResult{principal: %Relyra.Principal{...}}` and
then call application code to enforce local identity rules.

## Relyra owns / Host owns

## Relyra owns

- Response validation, signature verification, replay checks, and the verified
  login payload.
- The normalized identity facts exposed through `Relyra.LoginResult` and
  `Relyra.Principal`, such as `name_id`, `name_id_format`, and released
  attributes.
- The mapper and session seams where the host application takes over.

## Host owns

- Choosing the local account anchor.
- Looking up an existing account, deciding whether a new account may be created,
  and deciding which fields are safe to update on login.
- Authorization, tenant membership, offboarding, manual account linking, and
  every lifecycle action outside the successful login event.
- Any SCIM workflow or adjacent lifecycle sync system.

The practical boundary is simple: Relyra proves "this IdP asserted these facts
and the trust path verified." Your application decides what those facts mean for
an account in your domain.

## Choose your identity anchor first

Choose the anchor before you write mapping code or enable JIT. This is the
decision that determines whether future IdP cleanup is harmless or becomes an
account migration.

Anchor-quality rules:

- Best: a stable opaque identifier that the IdP treats as durable for the life
  of the user.
- Acceptable with care: email or another human-readable attribute when your app
  already treats that field as the canonical identity and your org can tolerate
  renames, aliases, and reuse risk.
- Poor choice: `transient` identifiers or any field the IdP explicitly treats
  as session-scoped or presentation-only.

Anchor-stability warning:

- If the IdP changes the NameID source or NameID format after users already
  exist, your app may see a different local identifier for the same human.
- If the anchor is email-based, mailbox rename, domain migration, and recycled
  addresses can split or relink accounts unexpectedly.
- If you anchor on a convenient attribute now and later move to a different
  source, plan that as an account-migration project, not as a docs cleanup.

Before enabling any automatic create-or-update flow, capture the chosen anchor
in operator docs the same way you would capture an ACS URL or signing
certificate. Anchor drift is a trust-boundary change, not a cosmetic IdP edit.

Keep this aligned with the [generic SAML runbook](recipes/generic_saml.md),
which already treats NameID choice as a trust-boundary decision rather than an
admin-console default.

## Pattern 1: NameID as local identifier

Use this pattern when the IdP can emit a NameID that is already the durable
identifier your application wants to anchor on.

This is usually the safest pattern when:

- The IdP can emit a stable `persistent` NameID.
- Your host app does not need a separate internal identity key for the same
  user.
- You want the smallest gap between the validated SAML identity and the local
  lookup key.

What the host app should do:

- Read the verified NameID from the login payload.
- Look up the local account by that anchor.
- Fail closed if the account must already exist and no match is found.

What breaks this pattern:

- The IdP emits `transient` NameID.
- The IdP emits `unspecified` NameID but the actual source changes between
  environments or later admin edits.
- The org treats email-style NameID as durable even though addresses can change.

If you pick NameID, make the exact source and format part of the deployment
contract. "Whatever the IdP currently sends" is not a stable policy.

## Example: NameID as local identifier

Use this pattern when `principal.name_id` is already the durable account anchor
your host app wants to trust.

```elixir
defmodule MyApp.Relyra.NameIdUserMapper do
  @behaviour Relyra.UserMapper

  alias MyApp.Accounts
  alias Relyra.Error
  alias Relyra.LoginResult
  alias Relyra.Principal

  @transient_name_id "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"

  @impl true
  def map_attributes(
        %LoginResult{
          principal: %Principal{
            name_id: name_id,
            name_id_format: name_id_format,
            attributes: attributes
          }
        },
        connection,
        _opts
      ) do
    cond do
      is_nil(name_id) or name_id == "" ->
        {:error, Error.new(:invalid_identity_anchor, "NameID is required for this connection")}

      name_id_format == @transient_name_id ->
        {:error, Error.new(:invalid_identity_anchor, "Transient NameID cannot anchor local users")}

      user = Accounts.get_user_by_saml_subject(connection.connection_id, name_id) ->
        {:ok,
         %{
           user_id: user.id,
           identity_anchor: %{type: :name_id, value: name_id, format: name_id_format},
           email: first_attribute(attributes, ["email", "mail", "EmailAddress"]),
           roles: normalize_list(attributes["groups"] || attributes[:groups])
         }}

      true ->
        {:error, Error.new(:user_not_found, "No local account is linked to this NameID")}
    end
  end

  defp first_attribute(attributes, keys) do
    Enum.find_value(keys, fn key -> attributes[key] || attributes[String.to_atom(key)] end)
  end

  defp normalize_list(nil), do: []
  defp normalize_list(values) when is_list(values), do: values
  defp normalize_list(value), do: [value]
end
```

This stays inside the real seam: Relyra already proved the SAML identity, and
the host app decides whether that verified NameID is allowed to resolve a local
account.

## Pattern 2: Attribute as local identifier

Use this pattern when NameID is not the right durable anchor for your app, but
another verified attribute is.

Common examples:

- The app anchors on employee number, HR identifier, or another stable directory
  key.
- The IdP uses NameID for presentation or federation convenience, but the app
  already has a different canonical local identifier.
- The app intentionally uses email as the lookup key and accepts the rename
  policy and migration burden that comes with it.

This pattern needs more discipline than Pattern 1 because you are choosing a
field that may look stable in one directory but be mutable in another. Ask:

- Who owns this attribute?
- Can it change on rename, domain move, or tenant merge?
- Can the value be recycled for a different person later?
- Does every environment release it consistently?

If the answer is "sometimes," document the migration and relinking plan now.
Attribute anchors are viable, but they are only safe when the host application
owns the consequences of churn.

## Example: Attribute as local identifier

Use this pattern when your host app anchors on a verified attribute such as an
employee number or another durable directory key instead of NameID.

```elixir
defmodule MyApp.Relyra.EmployeeNumberUserMapper do
  @behaviour Relyra.UserMapper

  alias MyApp.Accounts
  alias Relyra.Error
  alias Relyra.LoginResult
  alias Relyra.Principal

  @employee_number_keys ["employeeNumber", "employee_id", "EmployeeNumber"]

  @impl true
  def map_attributes(
        %LoginResult{
          principal: %Principal{
            name_id: name_id,
            name_id_format: name_id_format,
            attributes: attributes
          }
        },
        connection,
        _opts
      ) do
    with {:ok, employee_number} <- required_attribute(attributes, @employee_number_keys),
         %{} = user <- Accounts.get_user_by_employee_number(connection.connection_id, employee_number) do
      {:ok,
       %{
         user_id: user.id,
         identity_anchor: %{type: :employee_number, value: employee_number},
         saml_subject: %{name_id: name_id, name_id_format: name_id_format},
         email: first_attribute(attributes, ["email", "mail", "EmailAddress"]),
         display_name: first_attribute(attributes, ["display_name", "DisplayName", "cn"])
       }}
    else
      {:error, :missing_attribute} ->
        {:error, Error.new(:invalid_identity_anchor, "Required employee number attribute is missing")}

      nil ->
        {:error, Error.new(:user_not_found, "No local account is linked to this employee number")}
    end
  end

  defp required_attribute(attributes, keys) do
    case first_attribute(attributes, keys) do
      nil -> {:error, :missing_attribute}
      value -> {:ok, value}
    end
  end

  defp first_attribute(attributes, keys) do
    Enum.find_value(keys, fn key -> attributes[key] || attributes[String.to_atom(key)] end)
  end
end
```

This is still host-owned policy. Relyra does not decide that employee number is
the right local anchor. Your app makes that decision and owns the migration plan
if the IdP ever changes the released field.

## Pattern 3: JIT create or update

JIT means your host application decides, during a successful login, whether to
create a new local account or update a subset of fields on an existing one.
Relyra does not provision the user for you. It gives you verified identity input
and a mapper seam.

In the Phoenix path, that input arrives as the verified login result passed into
`Relyra.UserMapper.map_attributes/3`. The host app can read stable identity data
from `login_result.principal` and then decide whether local account creation or
update is allowed.

Use JIT only after you are confident about the anchor decision. Otherwise you
will automate duplicate-account creation at login speed.

JIT is usually reasonable when:

- The app allows first-login account creation for the target population.
- The anchor is stable enough that repeated logins resolve to the same account.
- The fields you plan to update on login are low-risk profile projections, not
  broader authorization or lifecycle controls.

JIT is risky when:

- The app has approval gates or entitlement rules that should not be bypassed by
  successful authentication alone.
- Several directories or tenants can release overlapping identifiers.
- Another lifecycle system already creates and links accounts independently.

Keep the output of `Relyra.UserMapper.map_attributes/3` narrow and
host-shaped. The mapper should return the identity data your app needs for local
lookup or create-or-update decisions, not pretend to be a full provisioning
engine.

## Example: JIT create or update

Use this pattern when the host application allows login-time account creation or
limited profile projection after a successful lookup decision.

```elixir
defmodule MyApp.Relyra.JitUserMapper do
  @behaviour Relyra.UserMapper

  alias MyApp.Accounts
  alias Relyra.Error
  alias Relyra.LoginResult
  alias Relyra.Principal

  @impl true
  def map_attributes(
        %LoginResult{
          principal: %Principal{
            name_id: name_id,
            name_id_format: name_id_format,
            attributes: attributes
          }
        },
        connection,
        _opts
      ) do
    with {:ok, email} <- required_attribute(attributes, ["email", "mail", "EmailAddress"]),
         {:ok, anchor} <- stable_anchor(name_id, name_id_format, email) do
      projected_user = %{
        saml_subject: %{name_id: name_id, name_id_format: name_id_format},
        email: email,
        first_name: first_attribute(attributes, ["given_name", "givenname", "FirstName"]),
        last_name: first_attribute(attributes, ["family_name", "sn", "LastName"]),
        roles: normalize_list(attributes["groups"] || attributes[:groups])
      }

      case Accounts.find_user_for_saml_login(connection.connection_id, anchor) do
        nil ->
          create_user_if_allowed(connection, anchor, projected_user)

        user ->
          update_allowed_fields(user, projected_user)
      end
    end
  end

  defp create_user_if_allowed(connection, anchor, projected_user) do
    if Accounts.jit_enabled_for_connection?(connection.connection_id) do
      Accounts.create_saml_user(connection.connection_id, anchor, projected_user)
    else
      {:error, Error.new(:user_not_found, "JIT is disabled for this connection")}
    end
  end

  defp update_allowed_fields(user, projected_user) do
    Accounts.update_user_from_saml(user, Map.take(projected_user, [:email, :first_name, :last_name]))
  end

  defp stable_anchor(name_id, _name_id_format, _email) when is_binary(name_id) and name_id != "" do
    {:ok, {:name_id, name_id}}
  end

  defp stable_anchor(_name_id, _name_id_format, email) when is_binary(email) and email != "" do
    {:ok, {:email, email}}
  end

  defp stable_anchor(_name_id, _name_id_format, _email) do
    {:error, Error.new(:invalid_identity_anchor, "JIT requires a documented stable anchor")}
  end

  defp required_attribute(attributes, keys) do
    case first_attribute(attributes, keys) do
      nil -> {:error, Error.new(:invalid_identity_anchor, "Required email attribute is missing")}
      value -> {:ok, value}
    end
  end

  defp first_attribute(attributes, keys) do
    Enum.find_value(keys, fn key -> attributes[key] || attributes[String.to_atom(key)] end)
  end

  defp normalize_list(nil), do: []
  defp normalize_list(values) when is_list(values), do: values
  defp normalize_list(value), do: [value]
end
```

This is still not Relyra-owned provisioning. The host app chooses whether JIT is
enabled, which fields may change on login, and whether some other lifecycle
system is the real source of truth.

## JIT decision tree

Use this decision tree before enabling login-time create or update:

1. Is the local identity anchor stable across rename, tenant, and format
   changes?
   If no, do not enable JIT yet.
2. Is the anchor released consistently in every environment this connection will
   serve?
   If no, fix the IdP release contract first.
3. Does your app allow successful login to create a local account without a
   separate approval step?
   If no, use lookup-only mapping and reject unknown users.
4. If the account already exists, which fields are safe to update on login?
   Limit this to profile projection, not lifecycle authority.
5. Is another system already creating, linking, or deprovisioning these
   accounts?
   If yes, choose one source of truth before enabling JIT.

Recommended outcomes:

- Stable anchor + no other lifecycle source: JIT create or update can be
  reasonable.
- Stable anchor + external lifecycle owner: prefer lookup and limited projection.
- Unstable anchor: fix the anchor first, then reconsider JIT.

## SCIM is a non-goal

SCIM lifecycle ownership is outside Relyra's scope. Relyra covers login-time
assertion validation and the host-owned mapping seam that follows. It does not
ship a user directory, background lifecycle sync, or deprovisioning authority.

If your organization uses SCIM, keep the responsibility split explicit:

- SCIM or an adjacent lifecycle system owns long-lived account creation,
  disablement, and reconciliation.
- Relyra owns the verified login event.
- Your host app decides how those two systems meet.

Safety warning:

- Running JIT create-or-update and SCIM at the same time without one clear
  source of truth can create duplicate accounts, broken links, or account drift.
- The risk is highest when JIT uses one anchor and SCIM uses another, or when
  one system updates fields the other treats as authoritative.
- A safe mixed model needs one written owner for account existence, one written
  anchor for linking, and one explicit rule for which fields may change at login.

If you need both, define the authoritative anchor and lifecycle owner first.
Without that decision, simultaneous JIT and SCIM is not additive resilience. It
is two competing account writers.

## Related docs

- [Getting Started](getting_started.md)
- [Generic SAML runbook](recipes/generic_saml.md)
- [Troubleshooting](troubleshooting.md)
- [Incident playbook — evidence surfaces](operations/incident_playbook.md#evidence-surfaces)
- [Documentation overview](overview.md)
