module ModelInit
import Mixers, ..Stipple, ..to_fieldname, ..MAX_NUM_TEAMS
export @presentation!, @addfields, get_or_create_pmodel, PresentationModel, reset_counters

function addfields(name::String, num::Int, type, init)
    [esc(Expr(:(=), 
         Expr(:(::), Symbol(name, i), Meta.parse("R{$(type.args[1])}")),
         init)) for i = 1:num]
end

macro addfields(name::String, type, init)
    exprs = addfields(name, MAX_NUM_TEAMS, type, init)
    return Expr(:block, exprs...)
end

macro addfields(num::Int, type, init)
    exprs = addfields(to_fieldname(type.args[1]), num, type, init)
    return Expr(:block, exprs...)
end

Mixers.@mix Stipple.@with_kw struct presentation!
    Stipple.@reactors #This line is from the definition of reactive! (Stipple.jl)
    counters::Dict{String, Int} = Dict()
    reset_required::R{Bool} = false
    timer::R{Int} = 0
    num_teams::R{Int} = 1
    num_slides::R{Int} = 0
    num_states::R{Vector{Int}} = []
    @addfields("slide_id", ::Int, 1)
    @addfields("slide_state", ::Int, 1)
    @addfields("drawer", ::Bool, false)
    @addfields("drawer_controller", ::Bool, false)
end

function create_pmodel(PresentationModel)
    println("Time to initialize model:")
    @time pmodel = Stipple.init(PresentationModel)
    Stipple.on(pmodel.isready) do ready
        ready || return
        push!(pmodel)        
    end

    Stipple.on(pmodel.num_teams) do _
        pmodel.reset_required[] = 1
    end

    return pmodel
end

let pmodel_ref = Ref{Stipple.ReactiveModel}() 
    #https://discourse.julialang.org/t/how-to-correctly-define-and-use-global-variables-in-the-module-in-julia/65720/6?u=jochen2
    #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global get_or_create_pmodel
    function get_or_create_pmodel(PresentationModel; force_create = false::Bool)
        if !isassigned(pmodel_ref) || force_create
            pmodel_ref[] = create_pmodel(PresentationModel)
        end
        pmodel_ref[]
    end
end

end