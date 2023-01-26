import CSV
export save_on, @save_on, save_on_slide, @save_on_slide

function save_field(field_ref, filename; dir = "out", dateformat = "yy-mm-dd at HH:MM")
    @info "Saving field with filename $filename"
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

function save_on(pmodel, params, field_ref::Reactive, triggering_field::Union{Reactive, ModelManager.ManagedField}, 
    value, filename::String; kwargs...)  
    new_listener(triggering_field, params) do val
        if val == value
            save_field(field_ref, filename, kwargs...)
        end
    end
    @info "Save listener set up (saves on value $value, filename: $filename)."
end

function save_on(pmodel, params, field::ModelManager.ManagedField, triggering_field::Union{Reactive, ModelManager.ManagedField}, 
    value, filename = field.str; kwargs...)
    save_on(pmodel, params, field.ref, triggering_field, value, filename, kwargs...)
end

function save_on_slide(pmodel, params, field_ref::Reactive, filename::String;
    slide_id = -1, kwargs...)
    for t_id in 1:params[:num_teams]
        new_listener(getslidefield(pmodel, t_id), params) do current_id
            if current_id == slide_id || (slide_id == -1 && current_id == pmodel.num_slides[] && current_id > 0)
                save_field(field_ref, filename, kwargs...)
            end
        end
    end
end

"""
    save_on_slide(pmodel, params, field, filename = field.str; 
    dir = "out", dateformat = "yy-mm-dd at HH:MM")

Function which saves the contents of a given field once a team reaches slide_id.
Default is the last slide. 
"""
function save_on_slide(pmodel, params, field::ModelManager.ManagedField, 
    filename = field.str; kwargs...)
    save_on_slide(pmodel, params, field.ref, filename, kwargs...)
end

"""
    @save_on_slide(field, exprs...)

Convenience macro which calls `save_on_slide` (see `?save_on_slide`). See ?@slide for more info on convenience macros.
"""
macro save_on_slide(field, exprs...)
    esc(:(save_on_slide(pmodel, params, $field, $(eqtokw!(exprs)...))))
end

macro save_on(field, triggering_field, value, exprs...)
    esc(:(save_on(pmodel, params, $field, $triggering_field, $value, $(eqtokw!(exprs)...))))
end