module ModelManager
using ..Stipple
import ..to_fieldname, ..eqtokw!
export use_field!, use_fields!, new_listener, getslidefield, table_listener, getstatefield
export @use_field!, @use_fields!, @new_listener, @getslidefield, @table_listener, @getstatefield

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
function use_field!(pmodel::ReactiveModel, params::Dict, counters::Dict, type::String; init_val = Nothing)
    name = to_fieldname(type; id = get!(counters, type, 1))
    name_sym = Symbol(name)
    if init_val != Nothing && params[:init]
        getfield(pmodel, name_sym).o.val = init_val
    end
    counters[type] += 1
    return ManagedField(name, name_sym, getfield(pmodel, name_sym))::ManagedField
end

"""
    use_fields!(pmodel::ReactiveModel, params::Dict, type::String; init_val = Nothing)

ONLY USEFUL IF YOU ARE PRESENTING TO MORE THAN ONE TEAM (otherwise you can safely ignore this functionality).
"Manages" multiple ManagedField (returns a list of ManagedField, one ManageField per team)
"""
function use_fields!(pmodel::ReactiveModel, params::Dict, counters::Dict, type::String; init_val = Nothing)
    [use_field!(pmodel, params, counters, type; init_val) for _ in 1:pmodel.num_teams[]]
end

let listeners = Observables.ObserverFunction[] #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global new_listener
    global delete_listeners

    function new_listener(fun::Function, field::Reactive, params::Dict)
        if params[:init]
            listener = on(field, weak = true) do val
                fun(val)
            end
            notify(field) #to immediately initialize the value
            push!(listeners, listener)
        end
    end

    function delete_listeners()
        off.(listeners)
        empty!(listeners)
    end
end

"""
    getslidefield(pmodel::ReactiveModel, team_id::Int)

Simply returns the field which stores the current slide id for the given team.
"""
function getslidefield(pmodel::ReactiveModel, team_id::Int)
    getfield(pmodel, Symbol("slide_id", team_id))
end

function getstatefield(pmodel::ReactiveModel, team_id::Int)
    getfield(pmodel, Symbol("slide_state", team_id))
end

"""
    new_listener(fun::Function, field::ManagedField, params::Dict)

Takes a function and a field (either a ManagedField or a direct reference to a field). 
Sets up a listener accordingly (see https://genieframework.com/docs/stipple/v0.25/API/stipple.html#Observables.on).
In order to be able to delete that listener in case when resetting the presentation (via delete_listeners), 
`new_listener` also stores a reference to the listener in a list.
"""
function new_listener(fun::Function, field::ManagedField, params::Dict)
    new_listener(fun, field.ref, params)
end

"""
    table_listener(num_teams, table, rows, field; dict = Dict(false => "", true => "✓"), column = 2)

This function simplifies setting up table rows whose data is dynamically updated depending on the choices of each team.
Depending what's in the dict, the table's cells (given the desired rows/column) will show outputs depending on what is the field's value 
(e.g., if the field has the value true, the standard is to show a checkmark ✓). If a value isn't found in the dict, the stringified field value is shown.
This function also works for fields which are vectors (in which case you'll need to provide several rows according to the length of the vector).

For StippleUI tables see here: https://www.genieframework.com/docs/stippleui/api/tables.html

### Example
```julia
julia> row_names = OrderedDict(:RowNames => ["I1", "I2", "I3", "I4"], :Vals => ["I1", "I2", "I3", "I4"])
julia> df = DataFrame(;merge(row_names,OrderedDict((Symbol("Team \$t_id")=>["", "", "", "", ""] for t_id = team_ids)...))...)
julia> choices_table = @use_field!("DataTable", init_val = DataTable(df))
julia> investment_choices = @use_fields!("Vector", init_val = [false, false, false, false])
julia> table_listener(params, choices_table, 1:4, investment_choices)
```
"""
function table_listener(params::Dict, table, rows, field; dict = Dict(false => "", true => "✓"), column = 2, team_ids = 1:params[:num_teams])
    for (id, t_id) in enumerate(team_ids)
        new_listener(field[t_id], params) do choice
            if typeof(choice) <: Vector
                output = [get(dict, c, string(c)) for c in choice]
                table.ref.data[!, id+column-1][rows] .= output
                notify(table.ref)
            else
                output = get(dict, choice, string(choice))
                table.ref.data[!, id+column-1][rows] = output
                notify(table.ref)
            end
        end
    end
end

"""
    table_listener(num_teams, table, rows, field, available_choices; notchosen = "", chosen = "✓", column = 2)

This method is useful in case your field value is a vector of values which is a subset of a given set of available choices 
(which might e.g. be the case if you are using the StippleUI select element).

### Example
```julia
julia> choices_table = see other method
julia> available_invest_choices = ["A", "B", "C", "D"]
julia> investment_choices = @use_fields!("Vector", init_val = [])
julia> table_listener(params, choices_table, 1:4, investment_choices, available_invest_choices)
```
"""
function table_listener(params::Dict, table, rows, field, available_choices; notchosen = "", chosen = "✓", column = 2, team_ids = 1:params[:num_teams])
    for (id, t_id) in enumerate(team_ids)
        new_listener(field[t_id], params) do choices
            choices_bool = falses(length(available_choices))
            for choice in choices
                choices_bool = choices_bool .|| contains.(available_choices, choice)
            end
            table.ref.data[!, id+column-1][rows] = [choice ? chosen : notchosen for choice in choices_bool]
            notify(table.ref)
        end
    end
end

####################### CONVENIENCE MACROS ####################

"""
    @use_field!(exprs...)

Convenience macro which calls `use_field!` (see `?use_field!`). See ?@slide for more info on convenience macros.
"""
macro use_field!(exprs...)
    esc(
        quote 
            !@isdefined(counters) && (counters = Dict{String, Int}())
            use_field!(pmodel, params, counters, $(eqtokw!(exprs)...))
        end
        )
end

macro use_fields!(exprs...)
    esc(
        quote 
            !@isdefined(counters) && (counters = Dict{String, Int}())
            use_fields!(pmodel, params, counters, $(eqtokw!(exprs)...))
        end
        )
end

"""
    @new_listener(fct, field)

Convenience macro which calls `new_listener` (see `?new_listener`). See ?@slide for more info on convenience macros.
"""
macro new_listener(fct, field)
    esc(:(new_listener($fct, $field, params)))
end

"""
    @table_listener(exprs...)

Convenience macro which calls `table_listener` (see `?table_listener`). See ?@slide for more info on convenience macros.
"""
macro table_listener(exprs...)
    esc(:(table_listener(params, $(eqtokw!(exprs)...))))
end

macro getslidefield(team_id)
    esc(:(getslidefield(pmodel, $team_id)))
end

macro getstatefield(team_id)
    esc(:(getstatefield(pmodel, $team_id)))
end

end