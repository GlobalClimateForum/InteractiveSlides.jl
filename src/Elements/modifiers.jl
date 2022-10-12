export iftitleslide, @v__bind, @linktoslide, @state_controlled_class, @appear_on, @hide_on, @show_from_to

function iftitleslide(slides::Vector{Slide}, params::Dict)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(slide_id$(params[:URLid]))")
end

macro v__bind(expr, type)
    :( "v-bind:$($(esc(type)))='$($(esc(expr)))'" )
end

macro linktoslide(linktext, operator::String, kwargs...)
    esc(:(a($linktext, onclick = "PresentationModel.slide_id$(params[:URLid]) $($operator)", 
    href = "javascript:void(0);", $(eqtokw!(kwargs)...))))
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
        esc(:(@state_controlled_class($class1, "abcde", $class2, $state_from, $state_to)))
    else
        #abcde has no function, it's only there because an empty string doesn't work here
        esc(:(@state_controlled_class($class1, "abcde", $state_from, $state_to)))
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