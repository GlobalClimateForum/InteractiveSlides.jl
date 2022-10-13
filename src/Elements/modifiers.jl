export hide_on_titleslide, @hide_on_titleslide, @v__bind, linktoslide, @linktoslide
export @state_controlled_class, @appear_on, @hide_on, @show_from_to

"""
    hide_on_titleslide(slides::Vector{Slide}, params::Dict; class = "titleslide")

The html element this is added to will only be visible on slides which are not title slides (useful for header and footer).
Other kinds of slides are also possible by passing a corresponding "class" kwarg.
"""
function hide_on_titleslide(slides::Vector{Slide}, params::Dict; class = "titleslide")
    slide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], class))
    isempty(slide_ids) ? "" : @showif("!$slide_ids.includes(slide_id$(params[:URLid]))")
end

macro hide_on_titleslide(exprs...)
    esc(:(hide_on_titleslide(slides, params, $(eqtokw!(exprs)...))))
end

macro v__bind(expr, type)
    :( "v-bind:$($(esc(type)))='$($(esc(expr)))'" )
end

"""
    linktoslide(params::Dict, linktext::AbstractString, operator::AbstractString, kwargs...)

Returns a link to a slide. 'Operator' is a string and can either be absolute
(e.g. "=5" for link to slide 5) or relative (e.g. "-=1" for link to the previous slide).

### Example
```julia
julia> @linktoslide(Dict(:URLid => 0), "Link to slide 1", "=1")
"<a onclick=\"PresentationModel.slide_id0 =1\" href=\"javascript:void(0);\">Link to slide 1</a>"
```
"""
function linktoslide(params::Dict, linktext::AbstractString, operator::AbstractString, kwargs...)
    a(linktext, onclick = "PresentationModel.slide_id$(params[:URLid]) $operator", href = "javascript:void(0);", kwargs...)
end

macro linktoslide(exprs...)
    esc(:(linktoslide(params, $(eqtokw!(exprs)...))))
end

####################### Macros which allow to modify HTML elements based on slide state ####################

macro state_controlled_class(class1, class2, class3, state1, state2)
    esc(:(@v__bind("[{  $($class1): slide_state$(params[:URLid]) < $($state1),
                        $($class2): slide_state$(params[:URLid]) >= $($state1) && slide_state$(params[:URLid]) <= $($state2),
                        $($class3): slide_state$(params[:URLid]) > $($state2) }]", :class)))
end

macro state_controlled_class(class1, class2, state1, state2)
    esc(:(@v__bind("[{  $($class1): slide_state$(params[:URLid]) < $($state1) || slide_state$(params[:URLid]) > $($state2),
                        $($class2): slide_state$(params[:URLid]) >= $($state1) && slide_state$(params[:URLid]) <= $($state2) }]", :class)))
end

macro state_controlled_class(class, state1, state2)
    esc(:(@v__bind("[{ $($class): slide_state$(params[:URLid]) >= $($state1) && slide_state$(params[:URLid]) <= $($state2) }]", :class)))
end

macro show_from_to(state_from, state_to, take_space_before, take_space_after)
    class1 = take_space_before ? "invisible" : "hidden"
    class2 = take_space_after ? "invisible" : "hidden"
    if take_space_before != take_space_after
        esc(:(@state_controlled_class($class1, "visible", $class2, $state_from, $state_to)))
    else
        esc(:(@state_controlled_class($class1, "visible", $state_from, $state_to)))
    end
end

macro appear_on(state, take_space_before)
    esc(:(@show_from_to($state, 99, $take_space_before, false)))
end

macro hide_on(state, take_space_after)
    state = state - 1
    esc(:(@show_from_to(1, $state, false, $take_space_after)))
end

macro appear_on(state)
    esc(:(@appear_on($state, false)))
end

macro hide_on(state)
    esc(:(@hide_on($state, false)))
end

macro show_from_to(state_from, state_to)
    esc(:(@show_from_to($state_from, $state_to, false, false)))
end