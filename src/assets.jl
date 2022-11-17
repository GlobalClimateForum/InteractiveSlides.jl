#Genie assets

get_module_path(m) = dirname(dirname(Base.functionloc(m.eval, Tuple{Nothing})[1]))

genie_path = get_module_path(Genie)
stipple_path = get_module_path(Stipple)

cwd_genie() = AS_EXECUTABLE[] ? pwd() : genie_path
cwd_stipple() = AS_EXECUTABLE[] ? pwd() : stipple_path

function Genie.Assets.channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String
    AS_EXECUTABLE[] && println("Stipple and Genie assets need to be in " * joinpath(cwd_genie(), "assets"))
    string(Genie.Assets.js_settings(channel), Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), type = "js", file = "channels")))
end

function Genie.Assets.webthreads(channel::String = Genie.config.webthreads_default_route) :: String
    string(Genie.Assets.js_settings(channel),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="pollymer.js")),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="webthreads.js")))
end


#Stipple assets

function Stipple.deps_routes(channel::String = Stipple.channel_js_name; core_theme::Bool = true) :: Nothing
    if ! Genie.Assets.external_assets(assets_config)

        Genie.Router.route(Genie.Assets.asset_route(Stipple.assets_config, :css, file="stipplecore")) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="css", file="stipplecore")),
            :css) |> Genie.Renderer.respond
        end

        if is_channels_webtransport()
        Genie.Assets.channels_route(Genie.Assets.jsliteral(channel))
        else
        Genie.Assets.webthreads_route(Genie.Assets.jsliteral(channel))
        end

        Genie.Router.route(
        Genie.Assets.asset_route(assets_config, :js, file="underscore-min"), named = :get_underscorejs) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file="underscore-min")), :javascript) |> Genie.Renderer.respond
        end

        VUEJS = Genie.Configuration.isprod() ? "vue.min" : "vue"
        Genie.Router.route(
        Genie.Assets.asset_route(assets_config, :js, file=VUEJS), named = :get_vuejs) do
            Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file=VUEJS)), :javascript) |> Genie.Renderer.respond
        end

        if core_theme
        Genie.Router.route(Genie.Assets.asset_route(assets_config, :js, file="stipplecore"), named = :get_stipplecorejs) do
            Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file="stipplecore")), :javascript) |> Genie.Renderer.respond
        end
        end

        Genie.Router.route(
        Genie.Assets.asset_route(assets_config, :js, file="vue_filters"), named = :get_vuefiltersjs) do
            Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file="vue_filters")), :javascript) |> Genie.Renderer.respond
        end

        Genie.Router.route(Genie.Assets.asset_route(assets_config, :js, file="watchers"), named = :get_watchersjs) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file="watchers")), :javascript) |> Genie.Renderer.respond
        end

        Genie.Router.route(Genie.Assets.asset_route(assets_config, :img, file="genie-logo"), named = :get_genielogosvg) do
        Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="svg", file="genie-logo")), :svg) |> Genie.Renderer.respond
        end

        if Genie.config.webchannels_keepalive_frequency > 0 && is_channels_webtransport()
        Genie.Router.route(Genie.Assets.asset_route(assets_config, :js, file="keepalive"), named = :get_keepalivejs) do
            Genie.Renderer.WebRenderable(
            Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_stipple(), type="js", file="keepalive")), :javascript) |> Genie.Renderer.respond
        end
        end

    end

    nothing
end