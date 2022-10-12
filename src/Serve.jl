module Serve
import ..Stipple, ..Genie, ..ModelInit, ..UI, ..MAX_NUM_TEAMS
export serve_presentation

function add_js(file::AbstractString; basedir = @__DIR__, subfolder = "", prefix = "", kwargs...)
    file = replace(file, ".js" => "")
    Genie.Router.route(Genie.Assets.asset_path(file; ext = ".js", package = "InteractiveSlides.jl", type = "", prefix, kwargs...)) do
    Genie.Renderer.WebRenderable(
        Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; prefix, type = subfolder, ext = ".js", file)),
    :javascript) |> Genie.Renderer.respond
    end
    filename = splitpath(file)[end]
    Stipple.DEPS[Symbol(filename)] = () -> [Stipple.script(src = "/interactiveslides.jl/$filename.js")]
end

function getAssets()
    out = []
    for (root, dirs, files) in walkdir("public")
        for file in files
            fileandfolder = joinpath(push!(splitpath(root)[2:end], file))
            if endswith(fileandfolder, ".css") && !endswith(fileandfolder, "theme.css") 
                #theme.css is loaded differently, in serve(), as otherwise theme.css would be loaded before inline styles
                push!(out, Stipple.stylesheet(fileandfolder))
            elseif endswith(fileandfolder, ".vue.js")
                add_js(file, basedir = root)
            elseif endswith(fileandfolder, ".js")
                push!(out, Stipple.script(src = fileandfolder))
            end
        end
    end
    return out
end

"""
    serve_presentation(PresModel::DataType, gen_content::Function; 
    num_teams_default::Int = 1, max_num_teams = MAX_NUM_TEAMS::Int, use_Stipple_theme::Bool = false, kwargs...)


High-level function which takes a reactive model definition and a function which generates content (both defined by the presentation creator) 
and uses them to generate the presentation (and set up a route to it).
It also sets up routes for the landing page, the settings page, as well as css files and vue.js files in the /public folder.
The content-generating function needs to take two arguments, "pmodel" and "params" (which should be named as such for macros such as @slide to work),
and should return a list of slides as well as an HTML element defining "auxilliary" UI elements such as header, footer, and drawer.
### Example
```julia
julia> @presentation! struct PresentationModel <: ReactiveModel
       end
julia> function gen_content(pmodel::PresentationModel, params::Dict)
            slides = [Slide("",Dict(:class => "slide"), p("content"), 1)]
            auxUI = ""
            return slides, auxUI
       end
julia> serve_presentation(PresentationModel, gen_content; num_teams_default = 2, max_num_teams = 4)
```
"""
function serve_presentation(PresModel::DataType, gen_content::Function; 
                            num_teams_default::Int = 1, max_num_teams = MAX_NUM_TEAMS::Int, use_Stipple_theme::Bool = false, kwargs...)
    pmodel = ModelInit.get_or_create_pmodel(PresModel; num_teams_default, max_num_teams)

    !use_Stipple_theme && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    push!(Stipple.Layout.THEMES, () -> [Stipple.stylesheet("css/theme.css"), ""])

    add_js("timer", subfolder = "js")
    add_js("hotkeys", subfolder = "js")

    Genie.route("/") do
        UI.ui_landing(pmodel) |> Stipple.html
    end

    Genie.route("/:team_id::Int/") do
        println("Time to build HTML:")
        @time UI.ui(pmodel, gen_content, Genie.params(), getAssets(); kwargs...) |> Stipple.html 
    end

    Genie.route("/settings") do
        UI.ui_setting(pmodel) |> Stipple.html
    end
end

end