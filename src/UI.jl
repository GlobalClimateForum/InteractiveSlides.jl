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

function slide(slides::Vector{Slide}, params::Dict, HTMLelem...; prepend_class = ""::String, title = ""::String, HTMLattr...)
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
    body = quasar(:page, body, @iif("$slide_id == current_id$(params[:team_id]) + $(params[:shift])"); HTMLattr...)
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

function navcontrols(params::Dict)
    t_id = params[:team_id]
    drawerstr = params[:is_controller] ? "drawer_controller$t_id" : "drawer$t_id"
    [btn("",icon="menu", @click("$drawerstr = ! $drawerstr"))
    btn("",icon="chevron_left", @click("current_id$t_id > 1 ? current_id$t_id-- : null"))
    btn("",icon="navigate_next", @click("current_id$t_id < num_slides ? current_id$t_id++ : null"))]
end

function iftitleslide(slides::Vector{Slide}, params::Dict)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(current_id$(params[:team_id]))")
end

function slide_id(params::Dict) span("", @text(Symbol("current_id$(params[:team_id])")), class = "slide_id") end

function menu_slides(slides::Vector{Slide}, params::Dict, item_fun; side = "left")
    t_id = params[:team_id]
    drawerstr = params[:is_controller] ? "drawer_controller$t_id" : "drawer$t_id"
    drawer_js = params[:persist_drawer] ? "" : "; $drawerstr = ! $drawerstr"
    listHTML = list([item(item_section(item_fun(id, title)), 
        :clickable, @click("current_id$t_id = $(id)" * drawer_js)) 
        for (id, title) in enumerate(getproperty.(slides, :title))])
    drawer(v__model = drawerstr, listHTML; side)
end

function ui(pmodel::ReactiveModel, gen_content::Function, settings::Dict, request_params::Dict{Symbol, Any})
    params = merge(settings, request_params)
    params[:team_id] = get(request_params, :team_id, 1)::Int
    params[:team_id] > settings[:num_teams] && return "Only $(settings[:num_teams]) teams can participate as per current settings."
    if get(request_params, :reset, "0") != "0" || get(request_params, :hardreset, "0") != "0"
        params[:init] = true
        ModelManager.reset_handlers()
    else
        params[:init] = isempty(pmodel.counters) ? true : false #only initialize fields/handlers if they have not already been initialized
    end
    params[:shift] = try parse(Int, get(request_params, :shift, "0")); catch; return "Shift parameter needs to be an integer."; end
    params[:persist_drawer] = try parse(Bool, get(params, :persist_drawer, "0")); catch; return "persist_drawer parameter needs to be 0, 1 true, or false."; end
    params[:is_controller] = params[:shift] != 0
    empty!(pmodel.counters)
    slides, auxUI = gen_content(pmodel, params)
    pmodel.num_slides[] = length(slides)
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            auxUI,
            Html.div(v__hotkey = "$(params[:team_id])"),
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

function simpleslide(slides, params, heading, content, args...; row_class = "flex-center", kwargs...)
    slide(slides, params, args..., heading, row(content, class = row_class); kwargs...)
end

macro slide(exprs...)
    esc(:(slides = slide(slides, params, $(eqtokw!(exprs)...))))
end

macro titleslide(exprs...)
    esc(:(slides = titleslide(slides, params, $(eqtokw!(exprs)...))))
end

macro simpleslide(exprs...)
    esc(:(slides = simpleslide(slides, params, $(eqtokw!(exprs)...))))
end

end