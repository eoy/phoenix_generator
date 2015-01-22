defmodule Mix.Tasks.Phoenix.Gen.Ectomodel do
  use Mix.Task
  import Phoenix.Gen.Utils
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate an Ecto Model for a Phoenix Application"

  @moduledoc """
  Generates an Ecto Model

      mix phoenix.gen.ectomodel model\_name field\_name:field\_type

    ## Command line options

      * `--timestamps` - adds created_at:datetime and updated_at:datetime fields

    ## Examples

      mix phoenix.gen.ectomodel user first_name:string age:integer --timestamps
  """

  def run(opts) do
    {switches, [model_name | fields], _files} = OptionParser.parse opts
    model_name_camel = camelize model_name
    app_name_camel = camelize Atom.to_string(Mix.Project.config()[:app])

    if Keyword.get switches, :timestamps do
      fields = fields ++ ["created_at:datetime", "updated_at:datetime"]
    end

    fields = for field <- fields do
      case String.split(field, ":") do
        [name]             -> [name, "string"]
        [name, "datetime"] -> [name, "datetime, default: Ecto.DateTime.utc"]
        [name, "date"]     -> [name, "date, default: Ecto.Date.utc"]
        [name, "time"]     -> [name, "time, default: Ecto.Time.utc"]
        [name, type]       -> [name, type]
      end
    end

    bindings = [
      app_name: app_name_camel,
      model_name_camel: model_name_camel,
      model_name_under: model_name,
      fields: fields
    ]

    # generate the model file
    gen_file(
      ["ectomodel.ex.eex"],
      ["models", "#{model_name}.ex"],
      bindings)

    # generate the migration
    import Mix.Shell.IO, only: [info: 1]
    import Inflex, only: [pluralize: 1]
    migration_text = "\"CREATE TABLE #{pluralize model_name}( \\\n"
    migration_text = migration_text <> "  id serial primary key \\\n"
    migration_text = migration_text <> for [name, type] <- fields, into: "" do
      #TODO binary, uuid, array, decimal
      "  #{name} " <> case type do
        "integer"       -> "bigint"
        "float"         -> "float8"
        "boolean"       -> "boolean"
        "string"        -> "text"
        "datetime" <> _ -> "timestamptz"
        "date" <> _     -> "date"
        "time" <> _     -> "timetz"
        other           -> other
      end <> ", \\\n"
    end
    migration_text = migration_text <> ")\""

    info "Generate a migration with:"
    info "    mix ecto.gen.migration *your_repo_name* create_#{pluralize model_name}_table"
    info "UP:"
    info migration_text
    info ""
    info "DOWN:"
    info "\"DROP TABLE #{model_name};\""
  end
end
