module Serve
import ..Stipple, ..Genie, ..ModelInit, ..UI
export serve_presentation, add_js

function add_js(file::AbstractString; basedir = @__DIR__, subfolder = "", prefix = "", kwargs...)
    Genie.Router.route(Genie.Assets.asset_path(file; ext = ".js", package = "InteractiveSlides.jl", type = "", prefix, kwargs...)) do
    Genie.Renderer.WebRenderable(
        Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; prefix, type = subfolder, ext = ".js", file)),
    :javascript) |> Genie.Renderer.respond
    end
    filename = splitpath(file)[end]
    Stipple.DEPS[Symbol(filename)] = () -> [Stipple.script(src = "/interactiveslides.jl/$filename.js")]
end

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

    add_js("timer", subfolder = "js")
    add_js("hotkeys", subfolder = "js")

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