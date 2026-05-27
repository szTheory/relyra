defmodule Relyra.Security.XML.AttributeEscape do
  @moduledoc """
  Escapes a string for use in an XML attribute value per Exclusive C14N rules.

  Mirrors the replacements in `Relyra.Security.XML.C14n` private `escape_attr/1`
  without coupling callers to C14n internals.
  """

  @spec escape_attribute(term()) :: binary()
  def escape_attribute(value) when is_binary(value) do
    value
    |> :binary.replace("&", "&amp;", [:global])
    |> :binary.replace("<", "&lt;", [:global])
    |> :binary.replace("\"", "&quot;", [:global])
    |> :binary.replace("\t", "&#x9;", [:global])
    |> :binary.replace("\n", "&#xA;", [:global])
    |> :binary.replace("\r", "&#xD;", [:global])
  end

  def escape_attribute(_), do: ""
end
