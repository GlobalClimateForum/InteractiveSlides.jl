module Serve
import ..Stipple, ..Genie, ..StippleUI, ..StipplePlotly, ..ModelInit, ..ModelManager, ..Build, ..Assets, ..MAX_NUM_TEAMS, ..AS_EXECUTABLE
export serve_presentation

function prep_pmodel_and_params!(pmodel, params)
    params[:show_whole_slide] = params[:URLid] == 99 || haskey(params, :shift) || get(params, :show_whole_slide_for_groups, true) && params[:URLid] > 0
    params[:team_id] = params[:URLid] ∈ (0,99) ? 1 : params[:URLid] #the presentor (URLid = 0) and the controller (URLid = 99) basically "play" for team 1
    params[:num_teams] = pmodel.num_teams[] #useful to decrease number of needed arguments for some functions
    slidefield = ModelManager.getslidefield(pmodel, params[:URLid])
    slidefield[] = max(1, slidefield[]) # necessary because the model is initialized with slide_idx = 0
    Stipple.notify(slidefield)          # (otherwise slide 1 would be shown briefly upon loading, no matter the actual slide one is at)
    pmodel.is_fully_loaded[] = true # at first, the model in the frontend has the value defined in ModelInit (in this case 'false'). 
                                    # If this 'true' doesn't 'arrive', something went wrong, and the frontend will change pmodel.push (see Assets.jl)
    if get(params, :reset, "0") != "0" || pmodel.reset_required[]
        params[:init] = true
        ModelManager.delete_listeners()
        pmodel.reset_required[] = false
        pmodel.timer_isactive[] = false
    else
        params[:init] = false
    end
    params[:drawerstr] = haskey(params, :shift) ? "drawer_shift$(params[:URLid])" : "drawer$(params[:URLid])"
    params[:shift] = try parse(Int, get(params, :shift, "0")); catch; return "Shift parameter needs to be an integer."; end
end

"""
    serve_presentation(PresModel::DataType, gen_content::Function; 
    num_teams_default::Int = 1, max_num_teams = MAX_NUM_TEAMS::Int, use_Stipple_theme::Bool = false, kwargs...)


High-level function which takes a reactive model definition and a function which generates content (both defined by the presentation creator) 
and uses them to generate the presentation (and set up a route to it).
It also sets up routes for the landing page, the settings page, as well as css files and javascript files in the /public folder.
The content-generating function needs to take two arguments, "pmodel" and "params" (which should be named as such for macros such as @slide to work),
and should return a list of slides as well as an HTML element defining "auxilliary" UI elements such as header, footer, and drawer.

Any kwargs you pass to serve_presentation will be available in the params dict. Also, they will be passed on to the Build functions 
which are called on every page load. Currently, one use of this is that you can pass a kwarg named "qview" (see Build.jl).

### Example
```julia
julia> @presentation! struct PresentationModel <: ReactiveModel
       end
julia> function gen_content(pmodel::PresentationModel, params::Dict)
            slides = [Slide("",Dict(:class => "slide"), p("content"), 1)]
            auxUI = ""
            return slides, auxUI
       end
julia> serve_presentation(PresentationModel, gen_content; num_teams_default = 2, max_num_teams = 4, qview = "lHh lpR lFf")
```
"""
function serve_presentation(PresModel::DataType, gen_content::Function; as_executable = false, local_pkg_assets = as_executable, custom_landing = false, custom_settings = false,
                            num_teams_default::Int = 1, max_num_teams::Int = MAX_NUM_TEAMS, use_Stipple_theme::Bool = false, isdev = false, qview = "hHh lpR fFf", 
                            keep_alive_frequency = 15000, connection_attempts = 20, kwargs...)
    
    Assets.standard_assets(max_num_teams, use_Stipple_theme; local_pkg_assets)
    AS_EXECUTABLE[] = as_executable
    Genie.config.webchannels_keepalive_frequency = keep_alive_frequency
    Genie.config.webchannels_subscription_trails = connection_attempts
    Genie.config.webchannels_connection_attempts = connection_attempts

    pmodel = ModelInit.get_or_create_pmodel(PresModel; num_teams_default, max_num_teams)

    if !custom_landing
        Genie.route("/") do
            Build.landing(pmodel) |> Stipple.html
        end
    end

    if !custom_settings
        Genie.route("/settings") do
            Build.settings(pmodel) |> Stipple.html
        end
    end

    Genie.route("/:URLid::Int/") do
        params = merge!(Dict{Symbol, Any}(kwargs), Genie.params())
        prep_pmodel_and_params!(pmodel, params)
        @info "Time to build HTML:"
        @time Build.presentation(pmodel, gen_content, params, Assets.get_assets(); isdev, qview, use_Stipple_theme) |> Stipple.html 
    end
end

function __init__()
    Genie.Configuration.config!(path_build = joinpath(pwd(), "tmp", "build"))
end

end