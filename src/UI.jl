module UI
using ..Stipple, ..Reexport, ..ModelManager
import ..eqtokw!
@reexport using StippleUI
export Slide, ui, slide, titleslide, iftitleslide, slide_id, navcontrols, menu_slides
export HTMLdiv, spacer, autocell, simplelist, simpleslide, @slide, @titleslide, @simpleslide #convenience functions

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
end

function slide(slides::Vector{Slide}, monitor_id::Int, HTMLelem...; prepend_class = ""::String, title = ""::String, HTMLattr...)
    HTMLattr = Dict(HTMLattr)
    if isempty(HTMLattr)
        HTMLattr = Dict{Symbol, Any}() 
    end #"text-center flex-center q-gutter-sm q-col-gutter-sm slide"
    HTMLattr[:class] = prepend_class * " " * get(HTMLattr, :class, "slide")
    slide_id = length(slides) + 1
    body = [x for x in HTMLelem]
    if isempty(title) 
        try
            title = strip(match(r"(?<=\<h[1-2]\>).+(?=<)", String(body[1])).match)
        catch
            title = "Untitled"; println("Warning: Untitled slide")
        end
    end
    body = quasar(:page, body, @iif("$slide_id == current_id$monitor_id"); HTMLattr...)
    push!(slides, Slide(title, HTMLattr, body))
    return slides
end

function titleslide(args...; prepend_class = "text-center flex-center"::String, title = ""::String, HTMLattr...)
    HTMLattr = Dict(HTMLattr)
    if isempty(HTMLattr)
        HTMLattr = Dict{Symbol, Any}() 
    end
    HTMLattr[:class] = "titleslide"
    if !isempty(prepend_class)
        slide(args...; prepend_class, title, HTMLattr...)
    else
        slide(args...; title, HTMLattr...)
    end
end

function navcontrols(m_id::Int)
    [btn("",icon="menu", @click("drawer$m_id = ! drawer$m_id"))
    btn("",icon="chevron_left", @click("current_id$m_id > 1 ? current_id$m_id-- : null"))
    btn("",icon="navigate_next", @click("current_id$m_id < num_slides ? current_id$m_id++ : null"))]
end

function iftitleslide(slides::Vector{Slide}, m_id::Int)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(current_id$m_id)")
end

function slide_id(m_id::Int) span("", @text(Symbol("current_id$m_id")), class = "slide_id") end

function menu_slides(slides::Vector{Slide}, m_id::Int, item_fun; side = "left")
drawer(v__model = "drawer$m_id", [
    list([
        item(item_section(item_fun(id, title)), :clickable, @click("current_id$m_id = $(id); drawer$m_id = ! drawer$m_id")) 
        for 
        (id, title) in enumerate(getproperty.(slides, :title))
        ])
    ]; side)
end

function ui(pmodel::ReactiveModel, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    m_id = get(request_params, :monitor_id, 1)::Int
    m_id > settings[:num_monitors] && return "Only $(settings[:num_monitors]) monitors are active."
    if get(request_params, :reset, "0") != "0" || get(request_params, :hardreset, "0") != "0"
        init = true
        ModelManager.reset_handlers()
    else
        init = isempty(pmodel.counters) ? true : false #only initialize fields/handlers if they have not already been initialized
    end
    empty!(pmodel.counters)
    slides, auxUI = gen_content(m_id, pmodel, init)
    pmodel.num_slides[] = length(slides)
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            auxUI,
            p(v__hotkey = "$m_id"),
            quasar(:page__container, 
                getproperty.(slides, :body)
            )
        ])
    ])
end

####################### CONVENIENCE FUNCTIONS ####################
HTMLdiv(args...; kwargs...) = Genie.Renderer.Html.div(args...; kwargs...)

spacer(padstr) = HTMLdiv(style = "padding:$padstr")

autocell(args...; sizestr = "sm", kwargs...) = HTMLdiv(args...; class = "col-$sizestr-auto")

function simplelist(args...; ordered = false, cellfun = autocell, size = 0, kwargs...)
    if ordered listfun = ol else listfun = ul end
    cellfun(listfun(
        [contains(x, "<") ? x : li(x) for x in args]; kwargs...); size)
end

function simpleslide(heading, content, args...; row_class = "flex-center", kwargs...)
    slide(args..., heading, row(content, class = row_class); kwargs...)
end

macro slide(exprs...)
    esc(:(slides = slide(slides, monitor_id, $(eqtokw!(exprs)...))))
end

macro titleslide(exprs...)
    esc(:(slides = titleslide(slides, monitor_id, $(eqtokw!(exprs)...))))
end

macro simpleslide(exprs...)
    esc(:(slides = simpleslide(slides, monitor_id, $(eqtokw!(exprs)...))))
end

end