module ModelInit
import Mixers, ..Stipple, ..to_fieldname
export @presentation!, @addfields, get_or_create_pmodel, PresentationModel, reset_counters

Mixers.@mix Stipple.@with_kw struct presentation!
    Stipple.@reactors #This line is from the definition of reactive! (Stipple.jl)
    counters::Dict{String, Int8} = Dict()
    num_slides::R{Int8} = 0
    current_id0::R{Int8} = 1
    current_id1::R{Int8} = 1
    current_id2::R{Int8} = 1
    current_id3::R{Int8} = 1
    current_id4::R{Int8} = 1
    drawer0::R{Bool} = false
    drawer1::R{Bool} = false
    drawer2::R{Bool} = false
    drawer3::R{Bool} = false
    drawer4::R{Bool} = false
    drawer_controller0::R{Bool} = false
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