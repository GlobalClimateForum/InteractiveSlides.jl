module ModelInit
import Mixers, ..Stipple, ..to_fieldname
export @presentation!, @addfields, get_or_create_pmodel, PresentationModel, reset_counters

Mixers.@mix Stipple.@with_kw struct presentation!
    Stipple.@reactors #This line is from the definition of reactive! (Stipple.jl)
    counters::Dict{String, Int8} = Dict()
    reset_required::R{Bool} = false
    num_teams::R{Int8} = 1
    num_slides::R{Int8} = 0
    current_id1::R{Int8} = 1
    current_id2::R{Int8} = 1
    current_id3::R{Int8} = 1
    current_id4::R{Int8} = 1
    num_states::R{Vector{Int8}} = []
    slide_state1::R{Int8} = 1
    slide_state2::R{Int8} = 1
    slide_state3::R{Int8} = 1
    slide_state4::R{Int8} = 1
    drawer1::R{Bool} = false
    drawer2::R{Bool} = false
    drawer3::R{Bool} = false
    drawer4::R{Bool} = false
    drawer_controller1::R{Bool} = false
    drawer_controller2::R{Bool} = false
    drawer_controller3::R{Bool} = false
    drawer_controller4::R{Bool} = false
end


macro addfields(num, type, init)
    exprs = [esc(Expr(:(=), 
                            Expr(:(::), Symbol(to_fieldname(type.args[1], i)), Meta.parse("R{$(type.args[1])}")),
                 init)) for i = 1:num]
    return Expr(:block, exprs...)
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

    # for t_id = 1:4
    #     state_field = getfield(pmodel, Symbol("slide_state$t_id"))
    #     current_id_field = getfield(pmodel, Symbol("current_id$t_id"))
    #     Stipple.on(state_field) do new_state
    #         current_id = current_id_field[]
    #         if new_state == 0 && current_id > 1
    #             current_id_field[] = current_id - 1
    #         end
    #         if new_state == 0
    #             state_field[] = 1
    #         end
    #         if new_state > pmodel.num_states[current_id] 
    #             if current_id < pmodel.num_slides[]
    #                 current_id_field[] = current_id + 1
    #                 state_field[] = 1
    #             else
    #                 state_field[] = pmodel.num_states[current_id]
    #             end
    #         end
    #     end
    # end

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