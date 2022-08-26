module Serve
import ..Stipple, ..Genie, ..StippleUI, ..ModelInit, ..UI
export serve_presentation

function build_presentation(PresModel::DataType, gen_content::Function, request_params::Dict{Symbol, Any}; kwargs...)
    if get(request_params, :modelreset, "0") != "0"
        pmodel = ModelInit.get_or_create_pmodel(PresModel; force_create = true)
    else
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
    end
    
    println("Time to build UI:")
    @time UI.ui(pmodel, gen_content, request_params; kwargs...) |> Stipple.html 
end

function serve_presentation(PresModel::DataType, gen_content::Function; num_teams_default::Int = 1, use_Stipple_theme::Bool = false, kwargs...)
    pmodel = ModelInit.get_or_create_pmodel(PresModel)
    pmodel.num_teams[] = num_teams_default

    !use_Stipple_theme && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    push!(Stipple.Layout.THEMES, () -> [Stipple.link(href = "theme.css", rel = "stylesheet"), ""])

    Genie.Assets.add_fileroute(StippleUI.assets_config, "hotkey.js"; basedir = @__DIR__)
    Stipple.DEPS[:hotkey] = () -> [Stipple.script(src = "/stippleui.jl/master/assets/js/hotkey.js")]

    Genie.route("/") do
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
        UI.ui_landing(pmodel) |> Stipple.html
    end

    Genie.route("/:team_id::Int/") do
        build_presentation(PresModel, gen_content, Genie.params(); kwargs...)
    end

    Genie.route("/settings") do
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
        UI.ui_setting(pmodel) |> Stipple.html
    end
end

end