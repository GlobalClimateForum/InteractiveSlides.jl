module Serve
using ..Stipple, ..ModelInit, ..UI
export serve_slideshow

function serve_slideshow(PresentationModel::DataType, create_slideshow::Function, create_auxUI::Function, settings::Dict, request_params::Dict{Symbol, Any})
    hardreset = get(request_params, :hardreset, "0") != "0"
    if hardreset
        pmodel = get_or_create_pmodel(PresentationModel; force_create = true)
    else
        pmodel = get_or_create_pmodel(PresentationModel)
    end
    println("Time to build UI:")
    if hardreset || get(request_params, :reset, "0") != "0"
        empty!(pmodel.counters)
        reset_handlers()
        pop!(Stipple.Layout.THEMES)
    end
    @time ui(pmodel, create_slideshow, create_auxUI, settings, request_params) |> html 
end

end