defmodule Relyra.Twin.Generators do
  @moduledoc """
  Phase 82 adversarial twin — StreamData generators.

  Produces a shrinkable **plan**:

      %{kind: atom, base_opts: keyword, strategy: :mutate_after | :resign, ops: [op]}

  Shrinking acts on the plan's structure — the op list shrinks toward `[]` and
  each op's integer components shrink toward `0` — never on raw document bytes,
  because the bytes are a deterministic function of the plan (mint + mutate).
  `Relyra.Twin.Runner` turns a plan into a `%Doc{}` and the oracle judges it.

  Every mutation family in `Relyra.Twin.Mutations.families/0` is reachable from
  these generators; `generator_coverage_test` asserts it.
  """

  import StreamData

  alias Relyra.Twin.Mint
  alias Relyra.Twin.Mutations

  @doc "A plan over all kinds — the deep-run / broad property generator."
  @spec plan() :: StreamData.t()
  def plan do
    bind(member_of(Mint.kinds()), &plan_for/1)
  end

  @doc "A plan fixed to one kind."
  @spec plan_for(atom()) :: StreamData.t()
  def plan_for(kind) do
    fixed_map(%{
      kind: constant(kind),
      base_opts: base_opts(kind),
      strategy: member_of([:mutate_after, :resign]),
      ops: list_of(op(kind), max_length: 6)
    })
  end

  # ---------------------------------------------------------------------------
  # Base-mint parameters (realizes the :time_boundary family for login)
  # ---------------------------------------------------------------------------

  defp base_opts(:login) do
    one_of([
      constant([]),
      bind(member_of(time_edges()), fn noa -> constant(not_on_or_after: noa) end),
      bind(member_of(time_edges()), fn nb -> constant(not_before: nb) end)
    ])
  end

  defp base_opts(_kind), do: constant([])

  # ±1s around Mint.now/0 (2026-04-24T16:00:00Z) plus the default far bounds.
  defp time_edges do
    [
      "2026-04-24T15:59:59Z",
      "2026-04-24T16:00:00Z",
      "2026-04-24T16:00:01Z",
      "2000-01-01T00:00:00Z",
      "2099-01-01T00:00:00Z"
    ]
  end

  # ---------------------------------------------------------------------------
  # Op generators
  # ---------------------------------------------------------------------------

  defp op(:logout_redirect) do
    one_of([
      tuple({constant(:dup_param), small_int()}),
      tuple({constant(:append_param), small_int()}),
      tuple({constant(:flip_byte), small_int()}),
      tuple({constant(:truncate), integer(1..99)})
    ])
  end

  # Metadata's `Parser.parse/2` is a structural extractor, not a signature
  # verifier (that is `Signature.verify_metadata_root`, whose crypto core the
  # logout_post twin fuzzes). Its trust property is authoritative-node
  # selection: an UNSIGNED outer wrapper carrying rival fields must never
  # override the inner SIGNED descriptor. So metadata mutations only wrap the
  # signed node or add out-of-band noise — never inject inside it (in-node
  # injection is the signature layer's concern, and would break a real sig).
  defp op(:metadata) do
    one_of([
      tuple({constant(:wrap_signed), small_int()}),
      tuple({constant(:comment), member_of([:before_signed, :after_signed, :root_end])}),
      tuple({constant(:pi), member_of([:before_signed, :after_signed])}),
      tuple({constant(:whitespace), member_of([:before_signed, :after_signed])}),
      constant(:duplicate_id),
      tuple({constant(:rebind_ns), small_int()}),
      tuple({constant(:truncate), integer(1..99)}),
      tuple({constant(:pad), integer(0..64)})
    ])
  end

  defp op(_xml_kind) do
    one_of([
      tuple({constant(:inject), position(), small_int()}),
      tuple({constant(:wrap_signed), small_int()}),
      constant(:duplicate_signed),
      constant(:move_signature),
      tuple({constant(:comment), position()}),
      tuple({constant(:pi), position()}),
      tuple({constant(:cdata), position()}),
      tuple({constant(:whitespace), position()}),
      tuple({constant(:entity_encode), small_int()}),
      constant(:duplicate_id),
      tuple({constant(:id_variant), small_int()}),
      tuple({constant(:rebind_ns), small_int()}),
      tuple({constant(:truncate), integer(1..99)}),
      tuple({constant(:pad), integer(0..64)})
    ])
  end

  defp position, do: member_of(Mutations.positions())
  defp small_int, do: integer(0..10)
end
