module UI
using ..Stipple, ..Reexport, ..ModelManager
import ..eqtokw!
@reexport using StippleUI
export Slide, ui, slide, titleslide, iftitleslide, slide_id, navcontrols, menu_slides
export spacer, autocell, simplelist, simpleslide, @slide, @titleslide, @simpleslide #convenience functions

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
end

function slide(slides::Vector{Slide}, team_id::Int, HTMLelem...; prepend_class = ""::String, title = ""::String, HTMLattr...)
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
    body = quasar(:page, body, @iif("$slide_id == current_id$team_id"); HTMLattr...)
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

function navcontrols(t_id::Int)
    [btn("",icon="menu", @click("drawer$t_id = ! drawer$t_id"))
    btn("",icon="chevron_left", @click("current_id$t_id > 1 ? current_id$t_id-- : null"))
    btn("",icon="navigate_next", @click("current_id$t_id < num_slides ? current_id$t_id++ : null"))]
end

function iftitleslide(slides::Vector{Slide}, t_id::Int)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(current_id$t_id)")
end

function slide_id(t_id::Int) span("", @text(Symbol("current_id$t_id")), class = "slide_id") end

function menu_slides(slides::Vector{Slide}, t_id::Int, item_fun; side = "left")
drawer(v__model = "drawer$t_id", [
    list([
        item(item_section(item_fun(id, title)), :clickable, @click("current_id$t_id = $(id); drawer$t_id = ! drawer$t_id")) 
        for 
        (id, title) in enumerate(getproperty.(slides, :title))
        ])
    ]; side)
end

function ui(pmodel::ReactiveModel, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    t_id = get(request_params, :team_id, 1)::Int
    t_id > settings[:num_teams] && return "Only $(settings[:num_teams]) teams can participate as per current settings."
    if get(request_params, :reset, "0") != "0" || get(request_params, :hardreset, "0") != "0"
        init = true
        ModelManager.reset_handlers()
    else
        init = isempty(pmodel.counters) ? true : false #only initialize fields/handlers if they have not already been initialized
    end
    empty!(pmodel.counters)
    slides, auxUI = gen_content(t_id, pmodel, init)
    pmodel.num_slides[] = length(slides)
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            auxUI,
            Html.div(v__hotkey = "$t_id"),
            quasar(:page__container, 
                getproperty.(slides, :body)
            )
        ])
    ])
end

####################### CONVENIENCE FUNCTIONS ####################
spacer(padstr) = Html.div(style = "padding:$padstr")

autocell(args...; sizestr = "sm", kwargs...) = Html.div(args...; class = "col-$sizestr-auto")

function simplelist(args...; ordered = false, cellfun = autocell, size = 0, kwargs...)
    if ordered listfun = ol else listfun = ul end
    cellfun(listfun(
        [contains(x, "<") ? x : li(x) for x in args]; kwargs...); size)
end

function simpleslide(slides, team_id, heading, content, args...; row_class = "flex-center", kwargs...)
    slide(slides, team_id, args..., heading, row(content, class = row_class); kwargs...)
end

macro slide(exprs...)
    esc(:(slides = slide(slides, team_id, $(eqtokw!(exprs)...))))
end

macro titleslide(exprs...)
    esc(:(slides = titleslide(slides, team_id, $(eqtokw!(exprs)...))))
end

macro simpleslide(exprs...)
    esc(:(slides = simpleslide(slides, team_id, $(eqtokw!(exprs)...))))
end

end