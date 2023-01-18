module ModelInit
import Mixers, ..Stipple, ..to_fieldname, ..MAX_NUM_TEAMS
export @presentation!, @addfields, get_or_create_pmodel

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
    reset_required::R{Bool} = true
    timer::R{Int} = 0
    timer_isactive::R{Bool} = false
    num_teams::R{Int} = 1
    max_num_teams::R{Int} = 1
    num_slides::R{Int} = 0
    num_states::R{Vector{Int}} = []
    slide_id0::R{Int} = 1
    slide_state0::R{Int} = 1
    drawer0::R{Bool} = false
    @addfields("slide_id", ::Int, 0)
    @addfields("slide_state", ::Int, 1)
    @addfields("drawer", ::Bool, false)
    @addfields("drawer_shift", ::Bool, false)
    push::R{Int} = 0
    is_fully_loaded::R{Bool} = false
end

function create_pmodel(PresentationModel)
    @info "Time to initialize model:"
    @time pmodel = Stipple.init(PresentationModel, vue_app_name = "pmodel")
    Stipple.on(pmodel.isready) do ready
        ready || return
        push!(pmodel)        
    end

    Stipple.on(pmodel.push) do _
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
    function get_or_create_pmodel(PresentationModel; num_teams_default = 1::Int, max_num_teams = MAX_NUM_TEAMS::Int)
        if !isassigned(pmodel_ref)
            pmodel_ref[] = create_pmodel(PresentationModel)
            pmodel_ref[].num_teams[] = num_teams_default
            if max_num_teams <= MAX_NUM_TEAMS; 
                pmodel_ref[].max_num_teams[] = max_num_teams 
            else
                error("Currently no more than $MAX_NUM_TEAMS teams are supported by InteractiveSlides.jl. 
                       Please change keyword argument 'max_num_teams' accordingly.")
            end
        end
        pmodel_ref[]
    end
end

end