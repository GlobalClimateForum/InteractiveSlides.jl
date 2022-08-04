module Serve
using ..Stipple, ..ModelInit, ..UI
export serve_presentation

function build_presentation(PresModel::DataType, gen_content::Function, gen_auxUI::Function, settings::Dict, request_params::Dict{Symbol, Any})
    hardreset = get(request_params, :hardreset, "0") != "0"
    if hardreset
        pmodel = get_or_create_pmodel(PresModel; force_create = true)
    else
        pmodel = get_or_create_pmodel(PresModel)
    end
    println("Time to build UI:")
    if hardreset || get(request_params, :reset, "0") != "0"
        empty!(pmodel.counters)
        reset_handlers()
        pop!(Stipple.Layout.THEMES)
    end
    @time ui(pmodel, gen_content, gen_auxUI, settings, request_params) |> html 
end

function serve_presentation(PresModel::DataType, gen_content::Function, gen_auxUI::Function, settings::Dict)
    Genie.route("/") do
        build_presentation(PresModel, gen_content, gen_auxUI, settings, params())
    end

    Genie.route("/:monitor_id::Int/") do
        build_presentation(PresModel, gen_content, gen_auxUI, settings, params())
    end
end

end