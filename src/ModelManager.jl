module ModelManager
using ..Stipple
import ..to_fieldname
export new_field!, new_multi_field!, new_handler

mutable struct ManagedField
    str::String
    sym::Symbol
    ref::Reactive
end

function new_field!(pmodel::ReactiveModel, type::String; value = Nothing)
    name = to_fieldname(type, get!(pmodel.counters, type, 1))
    name_sym = Symbol(name)
    if value != Nothing
        getfield(pmodel, name_sym).o.val = value
    end
    pmodel.counters[type] += 1
    return ManagedField(name, name_sym, getfield(pmodel, name_sym))::ManagedField
end

function new_multi_field!(pmodel::ReactiveModel, type::String, num_monitors::Int; value = Nothing)
    [new_field!(pmodel, type; value) for i in 1:num_monitors]
end

function Base.getindex(field::Vector{ManagedField}, sym::Symbol)
    return Symbol(field[1].sym, "<f_id")
end

let handlers = Observables.ObserverFunction[] #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global new_handler
    global reset_handlers

    function new_handler(fun::Function, field::Reactive)
        handler = on(field, weak = true) do val
            fun(val)
        end
        notify(field)
        push!(handlers, handler)
    end

    function reset_handlers()
        off.(handlers)
        empty!(handlers)
    end
end

function new_handler(fun::Function, field::ManagedField)
    new_handler(fun, field.ref)
end

end