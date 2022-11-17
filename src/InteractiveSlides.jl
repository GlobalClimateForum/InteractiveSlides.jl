module InteractiveSlides
using Reexport
@reexport using Stipple, StippleUI
# Genie.Assets.assets_config!([Genie, Stipple, StippleUI], host = "https://cdn.statically.io/gh/GenieFramework")

function Genie.Assets.channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String
    string(Genie.Assets.js_settings(channel), Genie.Assets.embedded(Genie.Assets.asset_file(cwd=pwd(), prefix = "SenatsDT_public", type = "js", file = "channels")))
end

function Genie.Assets.webthreads(channel::String = Genie.config.webthreads_default_route) :: String
    string(Genie.Assets.js_settings(channel),
        Genie.Assets.embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), file="pollymer.js")),
        Genie.Assets.embedded(Genie.Assets.asset_file(cwd=normpath(joinpath(@__DIR__, "..")), file="webthreads.js")))
end
  

include("shared.jl")

include("ModelInit.jl")
@reexport using .ModelInit

include("ModelManager.jl")
@reexport using .ModelManager

include("Build.jl")
@reexport using .Build

include("Serve.jl")
@reexport using .Serve

include("Elements.jl")
@reexport using .Elements

end
