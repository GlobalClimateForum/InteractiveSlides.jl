module UI
using ..Stipple, ..Reexport
@reexport using StippleUI
export ui, slide, titleslide, iftitleslide, slide_id, navcontrols, menu_slides
export HTMLdiv, spacer, autocell, simplelist, simpleslide #convenience functions

const m_max = 4 #max number of monitors. Note: Changing this does not yet allow to change the number of max monitors, as some parts are still hard-coded

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
end

slides = Ref{NTuple{m_max, Vector{Slide}}}(([],[],[],[])) #https://discourse.julialang.org/t/how-to-correctly-define-and-use-global-variables-in-the-module-in-julia/65720/6?u=jochen2

function slide(num_monitors::Int, HTMLelem...; prepend_class = ""::String, title = ""::String, HTMLattr...)
    HTMLattr = Dict(HTMLattr)
    if isempty(HTMLattr)
        HTMLattr = Dict{Symbol, Any}() 
    end #"text-center flex-center q-gutter-sm q-col-gutter-sm slide"
    HTMLattr[:class] = prepend_class * " " * get(HTMLattr, :class, "slide")
    slide_id = length(slides[][1]) + 1
    for m_id in 1:num_monitors
        body = [replace(x,  
                                                "m_id" => "$m_id", 
                                    r"[0-9+](<f_id)" => y -> string(parse(Int8,y[1])+m_id-1))
                                    for x in HTMLelem]
        if isempty(title) 
            try
                title = strip(match(r"(?<=\<h[1-2]\>).+(?=<)", String(body[1])).match)
            catch
                title = "Untitled"; println("Warning: Untitled slide")
            end
        end
        body = quasar(:page, body, @iif("$slide_id == current_id$m_id"); HTMLattr...)
        push!(slides[][m_id], Slide(title, HTMLattr, body))
    end
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

function iftitleslide(m_id::Int)
    titleslide_ids = findall(contains.([slide.HTMLattr[:class] for slide in slides[][m_id]], "titleslide"))
    isempty(titleslide_ids) ? "" : @iif("!$titleslide_ids.includes(current_id$m_id)")
end

function slide_id(m_id::Int) span("", @text(Symbol("current_id$m_id")), class = "slide_id") end

function menu_slides(m_id::Int, item_fun; side = "left")
drawer(v__model = "drawer$m_id", [
    list([
        item(item_section(item_fun(id, title)), :clickable, @click("current_id$m_id = $(id); drawer$m_id = ! drawer$m_id")) 
        for 
        (id, title) in enumerate(getproperty.(slides[][m_id], :title))
        ])
    ]; side)
end

function ui(pmodel::ReactiveModel, gen_content::Function, gen_auxUI::Function, settings::Dict, request_params::Dict{Symbol, Any})
    m_id = get(request_params, :monitor_id, 1)::Int
    !(0 < m_id <= m_max) && return "1 is the minimum monitor number, $m_max the maximum."
    m_id > settings[:num_monitors] && return "Only $(settings[:num_monitors]) monitors are active."
    if isempty(slides[][1]) || get(request_params, :reset, "0") != "0" || get(request_params, :hardreset, "0") != "0"
        push!(Stipple.Layout.THEMES, () -> [link(href = "$(settings[:folder])/theme.css", rel = "stylesheet"), ""])
        foreach(x -> empty!(x),slides[])
        Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
        gen_content(pmodel)
    end
    pmodel.num_slides[] = length(slides[][m_id])
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            gen_auxUI(m_id)
            quasar(:page__container, 
                getproperty.(slides[][m_id], :body)
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

function simpleslide(num_monitors::Int, heading, content; row_class = "flex-center", kwargs...)
    slide(num_monitors, heading, row(content, class = row_class); kwargs...)
end

end