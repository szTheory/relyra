# brandbook/notes/contrast.exs
#
# WCAG 2.2 relative-luminance + contrast-ratio calculator for the Relyra brand palette.
#
# Pure Elixir stdlib (:math, String, Enum). No Mix.install, no external deps.
# Run with:   elixir brandbook/notes/contrast.exs
#
# What it does:
#   * Computes a WCAG 2.2 contrast ratio + pass/fail verdict for every realistic
#     foreground/background brand pair in BOTH light and dark mode.
#   * Prints a Markdown table (pair | mode | use | ratio | required | verdict | remediation)
#     to stdout. accessibility-checks.md is generated verbatim from this output.
#   * Exits 1 if any pair flagged must_pass is below its required ratio; exits 0 otherwise.
#     The committed pair list uses the remediated hexes (#9A6B1C gold, #64748B dark border)
#     so this script exits 0. The unremediated FAIL rows (#C08A2B gold, #334155 dark
#     border) are retained as must_pass=false witnesses that reproduce the research ratios.
#
# WCAG sources:
#   1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
#   1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
#
# Thresholds: normal text 4.5:1, large text 3:1, non-text/UI 3:1.
# Linearization threshold constant: 0.04045 (W3C updated 0.03928 -> 0.04045 in May 2021,
#   "with no practical effect"; no verdict flips for this palette).
# No-rounding rule: the verdict compares the UNROUNDED ratio; display rounds to 2dp
#   (per W3C note: "2.999:1 would not meet the 3:1 threshold").

defmodule WCAG do
  @doc "Linearize one 0-255 sRGB channel using the 0.04045 threshold."
  def srgb_to_lin(c) do
    cs = c / 255.0
    if cs <= 0.04045, do: cs / 12.92, else: :math.pow((cs + 0.055) / 1.055, 2.4)
  end

  @doc "Relative luminance of a hex color. Accepts \"#RRGGBB\" or \"RRGGBB\"."
  def luminance("#" <> h), do: luminance(h)

  def luminance(h) do
    <<r::binary-2, g::binary-2, b::binary-2>> = h
    {r, g, b} = {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
    0.2126 * srgb_to_lin(r) + 0.7152 * srgb_to_lin(g) + 0.0722 * srgb_to_lin(b)
  end

  @doc """
  Returns {display_ratio, passes?}.
  display_ratio is rounded to 2dp for presentation; passes? is computed against the
  UNROUNDED ratio per the WCAG no-rounding rule.
  """
  def check(fg, bg, required) do
    l1 = luminance(fg)
    l2 = luminance(bg)
    {hi, lo} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
    raw = (hi + 0.05) / (lo + 0.05)
    {Float.round(raw, 2), raw >= required}
  end
end

# Each tuple: {fg, bg, mode, use, required, must_pass, remediation_note}
#   must_pass  -> drives the exit code (true means this pair must meet `required`)
#   remediation_note -> short note shown in the last table column ("-" when none)
pairs = [
  # ---- LIGHT MODE: body + secondary text on the two light surfaces ----
  {"#101827", "#FCFBF7", "light", "Body text (Ink on Paper)", 4.5, true, "-"},
  {"#263245", "#FCFBF7", "light", "Secondary text (Graphite on Paper)", 4.5, true, "-"},
  {"#101827", "#EEF2F6", "light", "Body text on Mist panel", 4.5, true, "-"},

  # ---- LIGHT MODE: links / primary action ----
  {"#3454D1", "#FCFBF7", "light", "Link / primary action text (Relay Blue on Paper)", 4.5, true, "-"},
  {"#FCFBF7", "#3454D1", "light", "Primary button text (Paper on Relay Blue)", 4.5, true, "-"},
  {"#FCFBF7", "#1D2E82", "light", "Hero / emphasis text (Paper on Deep Relay)", 4.5, true, "-"},

  # ---- LIGHT MODE: semantic colors on Paper ----
  {"#027A48", "#FCFBF7", "light", "Success text (on Paper)", 4.5, true, "-"},
  {"#B45309", "#FCFBF7", "light", "Warning text (on Paper)", 4.5, true, "thin margin (4.85)"},
  {"#B42318", "#FCFBF7", "light", "Error text (on Paper)", 4.5, true, "-"},
  {"#3454D1", "#FCFBF7", "light", "Info text (on Paper) — byte-identical to Relay Blue", 4.5, true, "Info==Relay Blue collision (D-04)"},
  {"#147D77", "#FCFBF7", "light", "Verified / Proof Teal text (on Paper)", 4.5, true, "thin margin (4.80)"},

  # ---- LIGHT MODE: focus ring, interactive border, divider, disabled ----
  {"#6D5DF2", "#FCFBF7", "light", "Focus ring (Keyline Violet on Paper, non-text)", 3.0, true, "thin margin (4.51)"},
  {"#7E8A9A", "#FCFBF7", "light", "Interactive border (Accessible Border on Paper, non-text)", 3.0, true, "-"},
  {"#7E8A9A", "#EEF2F6", "light", "Interactive border (Accessible Border on Mist, non-text)", 3.0, true, "thin margin (3.12)"},
  {"#263245", "#EEF2F6", "light", "Disabled text (Graphite on Mist surface)", 4.5, true, "-"},
  {"#D8E0EA", "#FCFBF7", "light", "Soft Line divider on Paper (decorative-only, exempt)", 3.0, false, "structural: decorative-only; route controls to #7E8A9A (D-03)"},

  # ---- LIGHT MODE: the load-bearing FAILURE + its remediation ----
  {"#C08A2B", "#FCFBF7", "light", "Certificate Gold accent on Paper (non-text) — UNREMEDIATED", 3.0, false, "FAIL 2.93 < 3:1 -> remediate to #9A6B1C (D-01)"},
  {"#9A6B1C", "#FCFBF7", "light", "Certificate Gold REMEDIATED on Paper (text-capable)", 4.5, true, "remediated from #C08A2B"},

  # ---- DARK MODE: text on the two dark surfaces ----
  {"#F8FAFC", "#0B1020", "dark", "Body text (Dark Text on Dark Background)", 4.5, true, "-"},
  {"#F8FAFC", "#111827", "dark", "Body text (Dark Text on Dark Surface)", 4.5, true, "-"},
  {"#CBD5E1", "#0B1020", "dark", "Secondary text (Dark Muted on Dark Background)", 4.5, true, "-"},
  {"#CBD5E1", "#111827", "dark", "Secondary text (Dark Muted on Dark Surface)", 4.5, true, "-"},

  # ---- DARK MODE: links / actions / accents ----
  {"#8CA2FF", "#0B1020", "dark", "Link / action (Dark Blue on Dark Background)", 4.5, true, "-"},
  {"#8CA2FF", "#111827", "dark", "Link / action (Dark Blue on Dark Surface)", 4.5, true, "-"},
  {"#61D6C8", "#0B1020", "dark", "Verified accent (Dark Teal on Dark Background)", 4.5, true, "-"},
  {"#FBBF24", "#0B1020", "dark", "Warning (Dark Amber on Dark Background)", 4.5, true, "-"},
  {"#FDA29B", "#0B1020", "dark", "Error (Dark Red on Dark Background)", 4.5, true, "-"},
  {"#86EFAC", "#0B1020", "dark", "Success (Dark Green on Dark Background)", 4.5, true, "-"},

  # ---- DARK MODE: focus ring ----
  {"#A99BFF", "#0B1020", "dark", "Focus ring (Dark Violet on Dark Background, non-text)", 3.0, true, "-"},
  {"#A99BFF", "#111827", "dark", "Focus ring (Dark Violet on Dark Surface, non-text)", 3.0, true, "-"},

  # ---- DARK MODE: the dark-border contradiction + contrast failure, fixed together ----
  {"#334155", "#0B1020", "dark", "Dark Border on Dark Background (non-text) — UNREMEDIATED (palette table)", 3.0, false, "FAIL 1.83 < 3:1; contradicts CSS --relyra-border:#64748B -> adopt #64748B (D-02)"},
  {"#334155", "#111827", "dark", "Dark Border on Dark Surface (non-text) — UNREMEDIATED (palette table)", 3.0, false, "FAIL 1.71 < 3:1 -> adopt #64748B (D-02)"},
  {"#64748B", "#0B1020", "dark", "Dark Border REMEDIATED on Dark Background (non-text)", 3.0, true, "from book CSS --relyra-border:#64748B"},
  {"#64748B", "#111827", "dark", "Dark Border REMEDIATED on Dark Surface (non-text)", 3.0, true, "from book CSS --relyra-border:#64748B"}
]

header = """
| Pair (fg on bg) | Mode | Use | Ratio | Required | Verdict | Remediation / note |
| --- | --- | --- | ---: | ---: | --- | --- |\
"""

IO.puts(header)

{rows, any_failure} =
  Enum.reduce(pairs, {[], false}, fn {fg, bg, mode, use, required, must_pass, note},
                                     {acc, failed?} ->
    {ratio, passes?} = WCAG.check(fg, bg, required)
    verdict = if passes?, do: "PASS", else: "FAIL"

    ratio_str = :erlang.float_to_binary(ratio, decimals: 2)
    req_str = :erlang.float_to_binary(required / 1.0, decimals: 2)

    row =
      "| #{fg} on #{bg} | #{mode} | #{use} | #{ratio_str} | #{req_str} | #{verdict} | #{note} |"

    now_failed = failed? or (must_pass and not passes?)
    {[row | acc], now_failed}
  end)

rows
|> Enum.reverse()
|> Enum.each(&IO.puts/1)

IO.puts("")

if any_failure do
  IO.puts("RESULT: at least one must-pass pair is below its required ratio. (exit 1)")
  System.halt(1)
else
  IO.puts("RESULT: all must-pass pairs meet their required ratio. (exit 0)")
  System.halt(0)
end
