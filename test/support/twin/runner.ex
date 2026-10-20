defmodule Relyra.Twin.Runner do
  @moduledoc """
  Phase 82 adversarial twin — turns a `Relyra.Twin.Generators` plan into a
  concrete `%Relyra.Twin.Mint.Doc{}` by minting a genuinely signed base and
  applying the plan's strategy:

    * `:mutate_after` — sign, then splice the op list into the final bytes
      (the adversarial case: signed content is fixed; anything accepted must
      still carry the signed truth).
    * `:resign` — splice only equivalence ops into the unsigned template, then
      sign it (legitimacy fuzzing with the real IdP key: a weirdly-shaped but
      genuinely signed document must still verify to the same truth).

  `truth` is never recomputed from Relyra's parse — it is exactly what `Mint`
  signed, which is the whole point of the oracle.
  """

  alias Relyra.Twin.Mint
  alias Relyra.Twin.Mint.Doc
  alias Relyra.Twin.Mutations

  @spec realize(map()) :: Doc.t()
  def realize(%{kind: kind, base_opts: base_opts, strategy: strategy, ops: ops}) do
    base = Mint.mint(kind, base_opts)
    apply_strategy(base, strategy, ops)
  end

  # The redirect query IS the signed artifact; there is no tree to re-sign, so
  # both strategies act on the query bytes.
  defp apply_strategy(%Doc{kind: :logout_redirect} = base, _strategy, ops) do
    %Doc{base | payload: Mutations.apply_ops(base.payload, :logout_redirect, ops)}
  end

  defp apply_strategy(%Doc{} = base, :mutate_after, ops) do
    %Doc{base | payload: Mutations.apply_ops(base.payload, base.kind, ops)}
  end

  defp apply_strategy(%Doc{template: template, resign: resign} = base, :resign, ops)
       when is_binary(template) and is_function(resign, 1) do
    eq_ops = Enum.filter(ops, &Mutations.equivalence_op?/1)
    mutated_template = Mutations.apply_ops(template, base.kind, eq_ops)

    payload =
      try do
        resign.(mutated_template)
      rescue
        _ -> base.payload
      catch
        _, _ -> base.payload
      end

    %Doc{base | payload: payload}
  end

  defp apply_strategy(%Doc{} = base, _strategy, _ops), do: base
end
