module Serve
import ..Stipple, ..Genie, ..ModelInit, ..ModelManager, ..Build, ..MAX_NUM_TEAMS
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

function get_assets()
    out = []
    for (root, dirs, files) in walkdir("public")
        for file in files
            fileandfolder = joinpath(push!(splitpath(root)[2:end], file))
            if endswith(fileandfolder, ".css") && !endswith(fileandfolder, "theme.css") 
                #theme.css is loaded differently, in standard_assets(), as otherwise theme.css would be loaded before inline styles
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

function standard_assets(use_Stipple_theme::Bool)
    !use_Stipple_theme && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    push!(Stipple.Layout.THEMES, () -> [Stipple.stylesheet("css/theme.css"), ""])

    add_js("timer", subfolder = "js")
    add_js("hotkeys", subfolder = "js")
end

function prep_pmodel_and_params!(pmodel, params)
    params[:team_id] > pmodel.num_teams[] && return "Only $(pmodel.num_teams[]) teams can participate as per current settings."
    if get(params, :reset, "0") != "0" || pmodel.reset_required[]
        params[:init] = true
        ModelManager.delete_listeners()
        pmodel.reset_required[] = false
        pmodel.timer_isactive[] = false
    else
        params[:init] = isempty(pmodel.counters) ? true : false #only initialize fields/listeners if they have not already been initialized
    end
    params[:shift] = try parse(Int, get(params, :shift, "0")); catch; return "Shift parameter needs to be an integer."; end
    params[:is_controller] = params[:shift] != 0 || get(params, :ctrl, "0") == "1"
    params[:persist_drawer] = params[:is_controller] #persist the drawer for controllers
    empty!(pmodel.counters)
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
    
    standard_assets(use_Stipple_theme)

    pmodel = ModelInit.get_or_create_pmodel(PresModel; num_teams_default, max_num_teams)

    Genie.route("/") do
        Build.landing(pmodel) |> Stipple.html
    end

    Genie.route("/:team_id::Int/") do
        params = merge!(Dict{Symbol, Any}(kwargs), Genie.params())
        prep_pmodel_and_params!(pmodel, params)
        println("Time to build HTML:")
        @time Build.presentation(pmodel, gen_content, params, get_assets()) |> Stipple.html 
    end

    Genie.route("/settings") do
        Build.settings(pmodel) |> Stipple.html
    end
end

end