export slide_id, navcontrols, menu_slides, spacer, autocell, simplelist

function navcontrols(params::Dict; icon_menu = "menu", icon_toLeft = "chevron_left", icon_toRight = "navigate_next")
    URLid = params[:URLid]
    drawerstr = get(params, :drawerstr, "drawer$URLid")
    [btn("",icon=icon_menu, @click("$drawerstr = ! $drawerstr"))
    btn("",icon=icon_toLeft, @click("slide_state$URLid == 1 ? slide_id$URLid > 1 ? (slide_id$URLid--, slide_state$URLid = num_states[slide_id$URLid-1]) : null : slide_state$URLid--"))
    btn("",icon=icon_toRight, @click("slide_state$URLid == num_states[slide_id$URLid-1] ? slide_id$URLid < num_slides ? (slide_id$URLid++, slide_state$URLid = 1) : null : slide_state$URLid++"))]
    # see hotkeys.js for similar js logic (anyone has any idea for how to reduce that redundancy?)
end

function menu_slides(slides::Vector{Slide}, params::Dict, item_fun; side = "left")
    URLid = params[:URLid]
    classes = [slide.HTMLattr[:class] for slide in slides]
    drawerstr = get(params, :drawerstr, "drawer$URLid")
    drawer_js = get(params, :persist_drawer, false) ? "" : "; $drawerstr = ! $drawerstr"
    listHTML = list([item(item_section(item_fun(id, title)), class = join([" menu_" * class for class in split(classes[id])]),
    :clickable, @click("slide_state$URLid = 1; slide_id$URLid = $id" * drawer_js), @v__bind("[{menu_current: slide_id$URLid == $id }]", :class)) 
    for (id, title) in enumerate(getproperty.(slides, :title))])
    drawer(v__model = drawerstr, listHTML; side)
end

slide_id(params::Dict) = span("", @text("slide_id$(params[:URLid]) + $(get(params, :shift, 0))"), class = "slide_id")

spacer(padstr) = Html.div(style = "padding:$padstr")

autocell(args...; sizestr = "sm", kwargs...) = Html.div(args...; class = "col-$sizestr-auto")

function simplelist(args...; ordered = false, cellfun = autocell, size = 0, kwargs...)
    if ordered listfun = ol else listfun = ul end
    cellfun(listfun(
        [contains(x, "<") ? x : li(x) for x in args]; kwargs...); size)
end