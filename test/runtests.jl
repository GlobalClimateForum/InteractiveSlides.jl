using InteractiveSlides
using Test

module TestBasics
    using ..InteractiveSlides
    @presentation! struct PresentationModel <: ReactiveModel
    end

    const settings = Dict{Symbol, Any}(:folder => "test", :num_teams => 2)

    function gen_content(team_id::Int, pmodel::PresentationModel, init::Bool)
    end

    serve_presentation(PresentationModel, gen_content, settings)

    Genie.up()
end

@testset "Basics" begin
    using .TestBasics
    @show Genie.routes()
end
