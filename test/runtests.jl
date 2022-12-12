using InteractiveSlides
using Test

module TestBasics
    using ..InteractiveSlides
    @presentation! struct PresentationModel <: ReactiveModel
    end

    function gen_content(pmodel::PresentationModel, params::Dict)
        return [], []
    end

    serve_presentation(PresentationModel, gen_content)

    Genie.up()
end

@testset "Basics" begin
    using .TestBasics
    @show Genie.routes()
end
