module ModelManager
using ..Stipple
import ..to_fieldname, ..eqtokw!
export use_field!, use_fields!, new_listener, table_listener, @table_listener
export @use_field!, @use_fields!, getslidefield, @getslidefield, getstatefield, @getstatefield #convenience functionss

mutable struct ManagedField
    str::String
    sym::Symbol
    ref::Reactive
end

"""
    use_field!(pmodel::ReactiveModel, params::Dict, type::String; init_val = Nothing)

If params[:init], this function populates a field of pmodel with init_val, and increases a counter such that on the next call it uses a different field.
Then, it returns a reference to that field as well as the corresponding symbol in the shape of a ManagedField.

If not params[:init] (i.e., if the presentation has already been initialized), 
the function simply looks up the counter, returns the corresponding ManagedField (without modyfing anything), and increases the counter.
"""
function use_field!(pmodel::ReactiveModel, params::Dict, type::String; init_val = Nothing)
    name = to_fieldname(type; id = get!(pmodel.counters, type, 1))
    name_sym = Symbol(name)
    if init_val != Nothing && params[:init]
        getfield(pmodel, name_sym).o.val = init_val
    end
    pmodel.counters[type] += 1
    return ManagedField(name, name_sym, getfield(pmodel, name_sym))::ManagedField
end

"""
    use_fields!(pmodel::ReactiveModel, params::Dict, type::String; init_val = Nothing)

ONLY USEFUL IF YOU ARE PRESENTING TO MORE THAN ONE TEAM (otherwise you can safely ignore this functionality).
"Manages" multiple ManagedField (returns a list of ManagedField, one ManageField per team)
"""
function use_fields!(pmodel::ReactiveModel, params::Dict, type::String; init_val = Nothing)
    [use_field!(pmodel, params, type; init_val) for _ in 1:pmodel.num_teams[]]
end

let listeners = Observables.ObserverFunction[] #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global new_listener
    global delete_listeners

    function new_listener(fun::Function, field::Reactive)
        listener = on(field, weak = true) do val
            fun(val)
        end
        notify(field) #to immediately initialize the value
        push!(listeners, listener)
    end

    function delete_listeners()
        off.(listeners)
        empty!(listeners)
    end
end

function table_listener(num_teams, table, rows, fields; dict = Dict(false => "", true => "✓"))
    typeof(rows) != Vector && (rows = [rows])
    typeof(fields) != Vector && (fields = [fields])
    for t_id in 1:num_teams
        for (id, field) in enumerate(fields)
            new_listener(field[t_id]) do choice
                output = get(dict, choice, string(choice))
                table.ref.data[!, t_id+1][rows[id]] = output
                notify(table.ref)
            end
        end
    end
end

function table_listener(num_teams, table, rows, field, available_choices; notchosen = "", chosen = "✓")
    for t_id in 1:num_teams
        new_listener(field[t_id]) do choices
            choices_bool = falses(length(available_choices))
            for choice in choices
                choices_bool = choices_bool .|| contains.(available_choices, choice)
            end
            table.ref.data[!, t_id+1][rows] = [choice ? chosen : notchosen for choice in choices_bool]
            notify(table.ref)
        end
    end
end

"""
    new_listener

Takes a function and a field (either a ManagedField or a direct reference to a field). 
Sets up a listener accordingly (see https://genieframework.com/docs/stipple/v0.25/API/stipple.html#Observables.on).
In order to be able to delete that listener in case when resetting the presentation (via delete_listeners), 
`new_listener` also stores a reference to the listener in a list.
"""
function new_listener(fun::Function, field::ManagedField)
    new_listener(fun, field.ref)
end

####################### CONVENIENCE FUNCTIONS ####################

"""
    @use_field!(exprs...)

Convenience macro which calls `use_field!` (see `?use_field!`). See ?@slide for more info on convenience macros.
"""
macro use_field!(exprs...)
    esc(:(use_field!(pmodel, params, $(eqtokw!(exprs)...))))
end

macro use_fields!(exprs...)
    esc(:(use_fields!(pmodel, params, $(eqtokw!(exprs)...))))
end

macro table_listener(exprs...)
    esc(:(table_listener(pmodel.num_teams[], $(eqtokw!(exprs)...))))
end

function getslidefield(pmodel::ReactiveModel, team_id::Int)
    getfield(pmodel, Symbol("slide_id", team_id))
end

function getstatefield(pmodel::ReactiveModel, team_id::Int)
    getfield(pmodel, Symbol("slide_state", team_id))
end

macro getslidefield(team_id)
    esc(:(getslidefield(pmodel, $team_id)))
end

macro getstatefield(team_id)
    esc(:(getstatefield(pmodel, $team_id)))
end

end