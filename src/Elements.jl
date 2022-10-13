module Elements
using ..Stipple, ..StippleUI
import ..eqtokw!
import ..Genie.Renderer.Html: normal_element, register_normal_element

include("./Elements/slide.jl")
include("./Elements/modifiers.jl")
include("./Elements/UI.jl")

end