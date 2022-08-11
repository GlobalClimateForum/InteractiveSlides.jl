module Serve
import ..Stipple, ..Genie, ..StippleUI, ..ModelInit, ..UI
export serve_presentation

# from https://github.com/GenieFramework/StippleDemos/blob/master/AdvancedExamples/DraggableTree/DraggableTree.jl 
function add_fileroute(assets_config::Genie.Assets.AssetsConfig, filename::AbstractString; 
    basedir = @__DIR__, content_type::Union{Nothing, Symbol} = nothing, type::Union{Nothing, String} = nothing, ext::Union{Nothing, String} = nothing, kwargs...)

    file, ex = splitext(filename)
    ext = isnothing(ext) ? ex : ext
    type = isnothing(type) ? ex[2:end] : type
    
    content_type = isnothing(content_type) ? if type == "js"
        :javascript
    elseif type == "css"
        :css
    elseif type in ["jpg", "jpeg", "svg", "mov", "avi", "png", "gif", "tif", "tiff"]
        imagetype = replace(type, Dict("jpg" => "jpeg", "mpg" => "mpeg", "tif" => "tiff")...)
        Symbol("image/$imagetype")
    else
        Symbol("*.*")
    end : content_type

    Genie.Router.route(Genie.Assets.asset_path(assets_config, type; file, ext, kwargs...)) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; type, file)),
        content_type) |> Genie.Renderer.respond
    end
end

function build_presentation(PresModel::DataType, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    if get(request_params, :modelreset, "0") != "0"
        pmodel = ModelInit.get_or_create_pmodel(PresModel; force_create = true)
    else
        pmodel = ModelInit.get_or_create_pmodel(PresModel)
    end

    add_fileroute(StippleUI.assets_config, "hotkey.js")
    Stipple.DEPS[:hotkey] = () -> [Stipple.script(src = "/stippleui.jl/master/assets/js/hotkey.js")]

    !get(settings, :use_Stipple_theme, false) && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    length(Stipple.Layout.THEMES) < 2 && push!(Stipple.Layout.THEMES, () -> [Stipple.link(href = "$(settings[:folder])/theme.css", rel = "stylesheet"), ""])
    
    println("Time to build UI:")
    @time UI.ui(pmodel, gen_content, settings, request_params) |> Stipple.html 
end

function serve_presentation(PresModel::DataType, gen_content::Function, settings::Dict)
    Genie.route("/") do
        build_presentation(PresModel, gen_content, settings, Genie.params())
    end

    Genie.route("/:team_id::Int/") do
        build_presentation(PresModel, gen_content, settings, Genie.params())
    end
end

end