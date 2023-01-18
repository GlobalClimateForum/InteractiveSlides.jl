export slide_id, @slide_id, navcontrols, @navcontrols, menu_slides, spacer, autocell, simplelist, two_columns
export linktoslide, @linktoslide, active_img

"""
    navcontrols(params::Dict; icon_menu = "menu", icon_toLeft = "navigate_before", icon_toRight = "navigate_next")

Returns a list of three buttons that link to the menu, to the previous slide, and to the next slide respectively.
"""
function navcontrols(params::Dict; icon_menu = "menu", icon_toLeft = "navigate_before", icon_toRight = "navigate_next")
    URLid = params[:URLid]
    drawerstr = get(params, :drawerstr, "drawer$URLid")
    [btn("",icon=icon_menu, @click("$drawerstr = ! $drawerstr")),
    btn("",icon=icon_toLeft, @click("previous($URLid)")),
    btn("",icon=icon_toRight, @click("next($URLid)"))]
end

macro navcontrols(exprs...)
    esc(:(navcontrols(params, $(eqtokw!(exprs)...))))
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

slide_id(params::Dict; offset = 0, kwargs...) = span("", @text("slide_id$(params[:URLid]) + $(get(params, :shift, 0)+offset)"), class = "slide_id"; kwargs...)

macro slide_id(exprs...)
    esc(:(slide_id(params, $(eqtokw!(exprs)...))))
end

spacer(padstr) = Html.div(style = "padding:$padstr")

autocell(args...; sizestr = "sm", kwargs...) = Html.div(args...; class = "col-$sizestr-auto", kwargs...)

function simplelist(args...; ordered = false, cellfun = autocell, size = 0, kwargs...)
    if ordered listfun = ol else listfun = ul end
    cellfun(listfun(
        [startswith(x, "<div") || startswith(x, "<br") ? x : li(x) for x in args]; kwargs...); size)
end

"""
    linktoslide(params::Dict, linktext::AbstractString, operator::AbstractString, kwargs...)

Returns a link to a slide. 'Operator' is a string and can either be absolute
(e.g. "=5" for link to slide 5) or relative (e.g. "-=1" for link to the previous slide).

### Example
```julia
julia> @linktoslide(Dict(:URLid => 0), "Link to slide 1", "=1")
"<a onclick=\"pmodel.slide_id0 =1\" href=\"javascript:void(0);\">Link to slide 1</a>"
```
"""
function linktoslide(params::Dict, linktext::AbstractString, operator::AbstractString, args...; kwargs...)
    a(linktext, onclick = "pmodel.slide_id$(params[:URLid]) $operator", href = "javascript:void(0);", args...; kwargs...)
end

macro linktoslide(linktext, operator, exprs...)
    esc(:(linktoslide(params, $linktext, $operator, $(eqtokw!(exprs)...))))
end

register_normal_element("q__header", context = @__MODULE__)

register_normal_element("q__footer", context = @__MODULE__)

column(args...; class = "", kwargs...) = Html.div(args...; class = class * " column", kwargs...)

function two_columns(lcontent, rcontent; sizes = [6,6], lclass = "flex-center column", rclass = lclass, lstyle = "", rstyle = "", kwargs...)
    row([   cell(lcontent, class = lclass, style = lstyle, size = sizes[1])
            cell(rcontent, class = rclass, style = rstyle, size = sizes[2])
    ]; kwargs...)
end

function active_img(team, field, options, filenameprefix; path = "img", ext = "png", kwargs...)
    [img(src = "$path/$filenameprefix$id.$ext", @showif("""$(field[team].str) == "$name" """); kwargs...) for (id, name) in enumerate(options)]
end

function active_img(team, field1, options1, field2, options2, filenameprefix; path = "img", ext = "png", kwargs...)
    imgs = []
    for (id2, name2) in enumerate(options2)
        append!(imgs, [img(src = "$path/$filenameprefix$id1$id2.$ext", 
        @showif("""$(field1[team].str) == "$name1" && $(field2[team].str) == "$name2" """); kwargs...) for (id1, name1) in enumerate(options1)])
    end
    return imgs
end