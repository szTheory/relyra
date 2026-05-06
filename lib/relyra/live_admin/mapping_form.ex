defmodule Relyra.LiveAdmin.AttributeMappingForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :source_attribute, :string
    field :target_field, Ecto.Enum, values: [:email, :first_name, :last_name, :display_name, :name_id]
    field :multivalue_strategy, Ecto.Enum, values: [:first, :all], default: :first
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:source_attribute, :target_field, :multivalue_strategy])
    |> validate_required([:source_attribute, :target_field, :multivalue_strategy])
  end
end

defmodule Relyra.LiveAdmin.AttributeMappingsForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many :mappings, Relyra.LiveAdmin.AttributeMappingForm
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [])
    |> cast_embed(:mappings,
      with: &Relyra.LiveAdmin.AttributeMappingForm.changeset/2,
      sort_param: :mappings_sort,
      drop_param: :mappings_drop
    )
  end
end

defmodule Relyra.LiveAdmin.GroupMappingForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :source_attribute, :string
    field :source_value, :string
    field :role_target, Ecto.Enum, values: [:role], default: :role
    field :role_value, :string
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:source_attribute, :source_value, :role_target, :role_value])
    |> validate_required([:source_attribute, :source_value, :role_target, :role_value])
  end
end

defmodule Relyra.LiveAdmin.GroupMappingsForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many :mappings, Relyra.LiveAdmin.GroupMappingForm
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [])
    |> cast_embed(:mappings,
      with: &Relyra.LiveAdmin.GroupMappingForm.changeset/2,
      sort_param: :mappings_sort,
      drop_param: :mappings_drop
    )
  end
end
