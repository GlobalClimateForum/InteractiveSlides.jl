module Serve
import ..Stipple, ..ModelInit, ..ModelManager, ..UI
export serve_presentation

function build_presentation(PresModel::DataType, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    hardreset = get(request_params, :hardreset, "0") != "0"
    if hardreset
        pmodel = ModelInit.get_or_create_pmodel(PresModel; force_create = true)
    else
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
    end
    println("Time to build UI:")
    if hardreset || get(request_params, :reset, "0") != "0"
        empty!(pmodel.counters)
        ModelManager.reset_handlers()
    end
    if !get(settings, :use_Stipple_theme, false)
        Stipple.Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    end
    push!(Stipple.Layout.THEMES, () -> [Stipple.link(href = "$(settings[:folder])/theme.css", rel = "stylesheet"), ""])
    @time UI.ui(pmodel, gen_content, settings, request_params) |> Stipple.html 
end

function serve_presentation(PresModel::DataType, gen_content::Function, settings::Dict)
    Stipple.route("/") do
        build_presentation(PresModel, gen_content, settings, Stipple.params())
    end

    Stipple.route("/:monitor_id::Int/") do
        build_presentation(PresModel, gen_content, settings, Stipple.params())
    end
end

end