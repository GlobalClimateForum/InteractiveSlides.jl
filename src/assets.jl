#Genie assets

get_module_path(m) = dirname(dirname(Base.functionloc(m.eval, Tuple{Nothing})[1]))
genie_path = get_module_path(Genie)
cwd_genie() = AS_EXECUTABLE[] ? pwd() : genie_path

function Genie.Assets.channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String
    AS_EXECUTABLE[] && println("Stipple and Genie assets need to be in " * joinpath(cwd_genie(), "assets"))
    string(Genie.Assets.js_settings(channel), Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), type = "js", file = "channels")))
end

function Genie.Assets.webthreads(channel::String = Genie.config.webthreads_default_route) :: String
    string(Genie.Assets.js_settings(channel),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="pollymer.js")),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="webthreads.js")))
end
