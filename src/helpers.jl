import CSV
export save_on, @save_on

function save_field(field_ref, dir, filename, dateformat)
    try mkdir(dir) catch end
    suffix = Dates.format(Dates.now(), dateformat)
    if typeof(field_ref[]) <: DataTable
        open(joinpath(dir, "$filename $suffix.csv"), "w") do io
            CSV.write(io, field_ref[].data)
        end
    else
        open(joinpath(dir, "$filename $suffix.html"), "w") do io
            write(io, field_ref[])
        end
    end
end

"""
    save_on(pmodel, params, field, filename = string(typeof(value)); dir = "out", dateformat = "yy-mm-dd at HH:MM", on = (val) -> val == pmodel.num_slides[])

Function which adds a listener to the given field, which then saves the contents of that field in a file (in dir) if the given condition is true.
Default is to save the field once any team reaches the last slide.
"""
function save_on(pmodel, params, field_ref, filename = string(typeof(value)); 
    dir = "out", dateformat = "yy-mm-dd at HH:MM", on = (val) -> val == pmodel.num_slides[])
    for t_id in 1:params[:num_teams]
        @new_listener(@getslidefield(t_id)) do val
            if on(val)
                save_field(field_ref, dir, filename, dateformat)
            end
        end
    end
end

function save_on(pmodel, params, field::ModelManager.ManagedField, filename = field.str; kwargs...)
    save_on(pmodel, params, field.ref, filename; kwargs...)
end

"""
    @save_on(field, exprs...)

Convenience macro which calls `save_on` (see `?save_on`). See ?@slide for more info on convenience macros.
"""
macro save_on(field, exprs...)
    esc(:(save_on(pmodel, params, $field, $(eqtokw!(exprs)...))))
end
