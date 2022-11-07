module Elements
using ..Stipple, ..StippleUI
import ..eqtokw!
import ..Genie.Renderer.Html: normal_element, register_normal_element

include(joinpath("Elements", "slide.jl"))
include(joinpath("Elements", "modifiers.jl"))
include(joinpath("Elements", "UI.jl"))

end