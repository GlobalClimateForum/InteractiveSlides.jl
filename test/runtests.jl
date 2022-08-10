using InteractiveSlides
using Test

module TestBasics
    using ..InteractiveSlides
    @presentation! struct PresentationModel <: ReactiveModel
    end

    const settings = Dict{Symbol, Any}(:folder => "test", :num_monitors => 2)

    function gen_content(monitor_id::Int, pmodel::PresentationModel, init::Bool)
    end

    serve_presentation(PresentationModel, gen_content, settings)

    Genie.up()
end

@testset "Basics" begin
    using .TestBasics
    @show Genie.routes()
end
