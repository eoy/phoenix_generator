defmodule Mix.Tasks.Phoenix.Gen.Template do
  use Mix.Task
  import Mix.Generator
  import Phoenix.Gen.Utils

  @shortdoc "Generate a template for a Phoenix Application"
  @moduledoc """
  Generates a Template

      mix phoenix.gen.template controller_name action

    ## Command line options

    ## Examples

      mix phoenix.gen.template user recent
  """

  def run(opts) do
    {switches, [controller_name | template_name], _files} = OptionParser.parse opts

    template_path = Path.join(
        [templates_path, controller_name, "#{template_name}.html.eex"])

    bindings = [
      controller: controller_name,
      template: template_name,
      template_path: template_path
    ]

    unless switches[:crud] do
      create_file template_path, action_template(bindings)
    else
      create_file template_path, File.read!(Path.join([Mix.Project.deps_path,
        "phoenix_generator","templates", "#{template_name}_crud.html.eex"]))
    end
  end

  embed_template :action, """
  <div class="well">
    I am an empty template for
    <strong><%= @controller %>.<%= @template %></strong><br>
    Find me at: <strong><%= @template_path %></strong>
  </div>
  """

end
