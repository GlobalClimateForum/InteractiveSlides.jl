module InteractiveSlides
using Reexport
@reexport using Stipple, StippleUI
# Genie.Assets.assets_config!([Genie, Stipple, StippleUI], host = "https://cdn.statically.io/gh/GenieFramework")

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
