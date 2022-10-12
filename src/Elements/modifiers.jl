export iftitleslide, @v__bind, @state_controlled_class, @appear_on, @hide_on, @show_from_to

function iftitleslide(slides::Vector{Slide}, params::Dict)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(slide_id$(params[:URLid]))")
end

macro v__bind(expr, type)
    :( "v-bind:$($(esc(type)))='$($(esc(expr)))'" )
end

####################### Macros which allow to modify HTML elements based on slide state ####################

macro state_controlled_class(class1, class2, class3, state1, state2)
    esc(:(@v__bind("[{  $($class1): slide_state$(params[:URLid]) < $($state1),
                        $($class2): slide_state$(params[:URLid]) >= $($state1) && slide_state$(params[:URLid]) <= $($state2),
                        $($class3): slide_state$(params[:URLid]) > $($state2) }]", :class)))
end

macro state_controlled_class(class, state1, state2)
    esc(:(@v__bind("[{ $($class): slide_state$(params[:URLid]) >= $($state1) && slide_state$(params[:URLid]) <= $($state2) }]", :class)))
end

macro appear_on(state, take_space_before)
    esc(:(@state_controlled_class($take_space_before ? "invisible" : "hidden", "abcde", "abcde", $state, 99))) #abcde has no function, it's only there because an empty string doesn't work here
end

macro hide_on(state, take_space_after)
    esc(:(@state_controlled_class($take_space_after ? "invisible" : "hidden", "abcde", "abcde", 1, $state)))
end

macro show_from_to(state_from, state_to, take_space_before, take_space_after)
    esc(:(@state_controlled_class($take_space_before ? "invisible" : "hidden", "abcde", $take_space_after ? "invisible" : "hidden", $state_from, $state_to)))
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