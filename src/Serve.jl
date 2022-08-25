module Serve
import ..Stipple, ..Genie, ..StippleUI, ..ModelInit, ..UI
export serve_presentation

function build_presentation(PresModel::DataType, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    if get(request_params, :modelreset, "0") != "0"
        pmodel = ModelInit.get_or_create_pmodel(PresModel; force_create = true)
    else
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
    end

    Genie.Assets.add_fileroute(StippleUI.assets_config, "hotkey.js"; basedir = @__DIR__)
    Stipple.DEPS[:hotkey] = () -> [Stipple.script(src = "/stippleui.jl/master/assets/js/hotkey.js")]

    !get(settings, :use_Stipple_theme, false) && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    folder = get(settings, :folder, "")
    length(Stipple.Layout.THEMES) < 2 && push!(Stipple.Layout.THEMES, () -> [Stipple.link(href = "$folder/theme.css", rel = "stylesheet"), ""])
    
    println("Time to build UI:")
    @time UI.ui(pmodel, gen_content, settings, request_params) |> Stipple.html 
end

function serve_presentation(PresModel::DataType, gen_content::Function, settings::Dict)
    pmodel = ModelInit.get_or_create_pmodel(PresModel)
    pmodel.num_teams[] = settings[:num_teams_default]

    Genie.route("/") do
        build_presentation(PresModel, gen_content, settings, Genie.params())
    end

    Genie.route("/:team_id::Int/") do
        build_presentation(PresModel, gen_content, settings, Genie.params())
    end

    Genie.route("/settings") do
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
        UI.ui_setting(pmodel) |> Stipple.html
    end
end

end