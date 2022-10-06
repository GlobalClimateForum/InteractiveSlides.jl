module UI
using ..Stipple
import ..eqtokw!, ..Reexport, ..ModelManager, ..MAX_NUM_TEAMS
Reexport.@reexport using StippleUI
export Slide, ui, ui_setting, ui_landing, slide, titleslide, iftitleslide, slide_id, navcontrols, menu_slides, @v__bind, @appear_on, @hide_on, @show_from_to
export spacer, autocell, simplelist, simpleslide, @slide, @titleslide, @simpleslide #convenience functions

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
    num_states::Int
end

function slide(slides::Vector{Slide}, params::Dict, HTMLelem...; num_states = 1, class = ""::String, title = ""::String, HTMLattr...)
    HTMLattr = Dict(HTMLattr)
    if isempty(HTMLattr)
        HTMLattr = Dict{Symbol, Any}() 
    end
    HTMLattr[:class] = "slide " * class * ifelse(params[:is_controller], " scroll-always", "")
    slide_id = length(slides) + 1
    if isempty(title) 
        try
            title = strip(match(r"(?<=\<h[1-2]\>).+(?=<)", String(HTMLelem[1])).match)
        catch
            title = "Untitled"; println("Warning: Untitled slide")
        end
    end
    body = quasar(:page, [HTMLelem...], @iif("$slide_id == slide_id$(params[:team_id]) + $(params[:shift])"); HTMLattr...)
    push!(slides, Slide(title, HTMLattr, body, num_states))
    return slides
end

macro v__bind(expr, type)
    :( "v-bind:$($(esc(type)))='$($(esc(expr)))'" )
end

function navcontrols(params::Dict)
    t_id = params[:team_id]
    drawerstr = params[:is_controller] ? "drawer_controller$t_id" : "drawer$t_id"
    [btn("",icon="menu", @click("$drawerstr = ! $drawerstr"))
    btn("",icon="chevron_left", @click("slide_state$t_id == 1 ? slide_id$t_id > 1 ? (slide_id$t_id--, slide_state$t_id = num_states[slide_id$t_id-1]) : null : slide_state$t_id--"))
    btn("",icon="navigate_next", @click("slide_state$t_id == num_states[slide_id$t_id-1] ? slide_id$t_id < num_slides ? (slide_id$t_id++, slide_state$t_id = 1) : null : slide_state$t_id++"))]
    # see hotkeys.js for similar js logic (anyone has any idea for how to reduce that redundancy?)
end

function iftitleslide(slides::Vector{Slide}, params::Dict)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(slide_id$(params[:team_id]))")
end

function slide_id(params::Dict) span("", @text(Symbol("slide_id$(params[:team_id])")), class = "slide_id") end

function menu_slides(slides::Vector{Slide}, params::Dict, item_fun; side = "left")
    t_id = params[:team_id]
    drawerstr = params[:is_controller] ? "drawer_controller$t_id" : "drawer$t_id"
    drawer_js = params[:persist_drawer] ? "" : "; $drawerstr = ! $drawerstr"
    listHTML = list([item(item_section(item_fun(id, title)), 
        :clickable, @click("slide_state$t_id = 1; slide_id$t_id = $id" * drawer_js), @v__bind("[{ current: slide_id$t_id == $id }]", :class)) 
        for (id, title) in enumerate(getproperty.(slides, :title))])
    drawer(v__model = drawerstr, listHTML; side)
end

function ui(pmodel::ReactiveModel, gen_content::Function, request_params::Dict{Symbol, Any}, assets; kwargs...)
    params = merge!(Dict{Symbol, Any}(kwargs), request_params)
    params[:team_id] > pmodel.num_teams[] && return "Only $(pmodel.num_teams[]) teams can participate as per current settings."
    if get(params, :reset, "0") != "0" || get(params, :modelreset, "0") != "0" || pmodel.reset_required[]
        params[:init] = true
        ModelManager.reset_handlers()
        pmodel.reset_required[] = false
        pmodel.timer_isactive[] = false
    else
        params[:init] = isempty(pmodel.counters) ? true : false #only initialize fields/handlers if they have not already been initialized
    end
    params[:shift] = try parse(Int, get(params, :shift, "0")); catch; return "Shift parameter needs to be an integer."; end
    params[:is_controller] = params[:shift] != 0 || get(params, :ctrl, "0") == "1"
    params[:persist_drawer] = params[:is_controller] #persist the drawer for controllers
    empty!(pmodel.counters)
    slides, auxUI = gen_content(pmodel, params)
    pmodel.num_slides[] = length(slides)
    pmodel.num_states[] = getproperty.(slides, :num_states)
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            auxUI,
            Html.div(v__hotkeys = "$(params[:team_id])"),
            quasar(:page__container, 
                getproperty.(slides, :body)
            )
        ], 
        v__cloak = true), #https://v2.vuejs.org/v2/api/#v-cloak
    ], assets,
    )
end

function ui_setting(pmodel::ReactiveModel)
    page(pmodel, [h2("Settings", style = "margin: 1rem"), row([
        cell("Number of teams"; size = 3), 
        cell(slider(1:1:MAX_NUM_TEAMS, :num_teams; draggable = true, snap = true, step = 1, marker__labels = true, style = "padding:1rem"); size = 5)
        ], class = "flex-center")], class = "settings-page")
end

function ui_landing(pmodel::ReactiveModel)
    page(pmodel, [h2("Welcome", style = "margin: 1rem"), list(
        append!(["""<a href="$id">Team $id</a> <a href="$id?ctrl=1">Controller $id</a><br>""" for id in 1:pmodel.num_teams[]], [item(item_section(a("Settings", href = "settings")))])
        )], class = "landing-page")
end

macro appear_on(state_id::Int)
    esc(:(@v__bind("[{ invisible: slide_state$team_id < $($(state_id)) }]", :class)))
end

macro hide_on(state_id::Int)
    esc(:(@v__bind("[{ invisible: slide_state$team_id >= $($(state_id)) }]", :class)))
end

macro show_from_to(state_id_appear::Int, state_id_hide::Int)
    esc(:(@v__bind("[{ invisible: slide_state$team_id < $($(state_id_appear)) || slide_state$team_id > $($(state_id_hide)) }]", :class)))
end

####################### CONVENIENCE FUNCTIONS ####################
spacer(padstr) = Html.div(style = "padding:$padstr")

autocell(args...; sizestr = "sm", kwargs...) = Html.div(args...; class = "col-$sizestr-auto")

function simplelist(args...; ordered = false, cellfun = autocell, size = 0, kwargs...)
    if ordered listfun = ol else listfun = ul end
    cellfun(listfun(
        [contains(x, "<") ? x : li(x) for x in args]; kwargs...); size)
end

function titleslide(args...; class = "text-center flex-center"::String, title = ""::String, HTMLattr...)
    slide(args...; class = "titleslide " * class, title, HTMLattr...)
end

function simpleslide(slides, params, heading, content...; contentstyle = "", contentclass = "flex-center", kwargs...)
    style = "height:100%; display:flex;" * contentstyle
    slide(slides, params, heading, Html.div([content...], style = style, class = "col " * contentclass); class = "column", kwargs...)
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