import CSV
export save, @save

function save(pmodel, params, value, filename = string(typeof(value)); dirname = "out", dateformat = "yy-mm-dd at HH:MM")
    for t_id in 1:params[:num_teams]
        @new_listener(@getslidefield(t_id)) do id
            if id == pmodel.num_slides[]
                try mkdir(dirname) catch end
                suffix = Dates.format(Dates.now(), dateformat)
                if typeof(value) <: DataTable
                    CSV.write(joinpath(dirname, "$filename $suffix.csv"), value.data)
                else
                    open(joinpath(dirname, "$filename $suffix.html"), "w") do io
                        write(io, value)
                    end
                end
            end
        end
    end
end

function save(pmodel, params, field::ModelManager.ManagedField, filename = field.str; kwargs...)
    save(pmodel, params, field.ref[], filename; kwargs...)
end

"""
    @save(value/field, exprs...)

Convenience macro which calls `save` (see `?save`). See ?@slide for more info on convenience macros.
"""
macro save(value, exprs...)
    esc(:(save(pmodel, params, $value, $(eqtokw!(exprs)...))))
end
