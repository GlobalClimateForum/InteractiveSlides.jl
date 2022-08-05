using InteractiveSlides
using Test

module TestBasics
    using ..InteractiveSlides
    @presentation! struct PresentationModel <: ReactiveModel
    end

    const settings = Dict{Symbol, Any}(:folder => "test", :num_monitors => 2)

    function gen_auxUI(m_id::Int)
    end

    function gen_content(pmodel::PresentationModel)
    end

    serve_presentation(PresentationModel, gen_content, gen_auxUI, settings)

    Genie.up()
end

@testset "Basics" begin
    using .TestBasics
    @show Genie.routes()
end
