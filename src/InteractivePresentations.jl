module InteractivePresentations
using Reexport, Mixers
@reexport using Stipple, StippleUI

const m_max = 4 #max number of monitors. Note: This setting does not really (yet) affect anything except error messages (the max number of monitors depends on the model fields which are hardcoded).

#PresentationModels
#region
export @presentation!, @addfields, get_or_create_pmodel, PresentationModel, reset_counters
register_mixin(@__MODULE__)

@mix Stipple.@with_kw struct presentation!
    Stipple.@reactors #This line is from the definition of reactive! (Stipple.jl)
    counters::Dict{String, Int8} = Dict()
    num_slides::R{Int8} = 0
    current_id0::R{Int8} = 1
    current_id1::R{Int8} = 1
    current_id2::R{Int8} = 1
    current_id3::R{Int8} = 1
    current_id4::R{Int8} = 1
    drawer0::R{Bool} = false
    drawer1::R{Bool} = false
    drawer2::R{Bool} = false
    drawer3::R{Bool} = false
    drawer4::R{Bool} = false
end

function to_fieldname(typename, id)
    replace(lowercase(string(typename, id)), "{" => "", "}" => "")
end

macro addfields(num, type, init)
    exprs = [esc(Expr(:(=), 
                            Expr(:(::), Symbol(to_fieldname(type.args[1], i)), Meta.parse("R{$(type.args[1])}")),
                 init)) for i = 1:num]
    return Expr(:block, exprs...)
end

function create_pmodel(PresentationModel)
    println("Time to initialize model:")
    @time pmodel = Stipple.init(PresentationModel)
    on(pmodel.isready) do ready
        ready || return
        push!(pmodel)        
    end

    return pmodel
end

let pmodel_ref = Ref{ReactiveModel}() 
    #https://discourse.julialang.org/t/how-to-correctly-define-and-use-global-variables-in-the-module-in-julia/65720/6?u=jochen2
    #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global get_or_create_pmodel
    function get_or_create_pmodel(PresentationModel; force_create = false::Bool)
        if !isassigned(pmodel_ref) || force_create
            pmodel_ref[] = create_pmodel(PresentationModel)
        end
        pmodel_ref[]
    end
end

#endregion

#ModelManager
#region
export new_field!, new_multi_field!, new_handler
#this module should generate handlers and somehow populate fields for each pmodel (depending on slides), or expose functions/macros toward such ends

mutable struct ManagedField
    str::String
    sym::Symbol
    ref::Reactive
end

function new_field!(pmodel::ReactiveModel, type::String; value = Nothing)
    name = to_fieldname(type, get!(pmodel.counters, type, 1))
    name_sym = Symbol(name)
    if value != Nothing
        getfield(pmodel, name_sym).o.val = value
    end
    pmodel.counters[type] += 1
    return ManagedField(name, name_sym, getfield(pmodel, name_sym))::ManagedField
end

function new_multi_field!(pmodel::ReactiveModel, type::String, num_monitors::Int; value = Nothing)
    [new_field!(pmodel, type; value) for i in 1:num_monitors]
end

function Base.getindex(field::Vector{ManagedField}, sym::Symbol)
    return Symbol(field[1].sym, "<f_id")
end

let handlers = Observables.ObserverFunction[] #https://stackoverflow.com/questions/24541723/does-julia-support-static-variables-with-function-scope
    global new_handler
    global reset_handlers

    function new_handler(fun::Function, field::Reactive)
        handler = on(field, weak = true) do val
            fun(val)
        end
        notify(field)
        push!(handlers, handler)
    end

    function reset_handlers()
        off.(handlers)
        empty!(handlers)
    end
end

function new_handler(fun::Function, field::ManagedField)
    new_handler(fun, field.ref)
end

#endregion

#SLIDE UI
#region
export serve_slideshow, slide, titleslide, iftitleslide, slide_id, navcontrols, menu

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
end

slides = Ref{NTuple{4, Vector{Slide}}}(([],[],[],[])) #4 monitors, https://discourse.julialang.org/t/how-to-correctly-define-and-use-global-variables-in-the-module-in-julia/65720/6?u=jochen2

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

function menu(m_id::Int, item_fun; side = "left")
drawer(v__model = "drawer$m_id", [
    list([
        item(item_section(item_fun(id, title)), :clickable, @click("current_id$m_id = $(id); drawer$m_id = ! drawer$m_id")) 
        for 
        (id, title) in enumerate(getproperty.(slides[][m_id], :title))
        ])
    ]; side)
end

function ui(pmodel::ReactiveModel, create_slideshow::Function, create_auxUI::Function, settings::Dict, request_params::Dict{Symbol, Any})
    m_id = get(request_params, :monitor_id, 1)::Int
    !(0 < m_id <= m_max) && return "1 is the minimum monitor number, $m_max the maximum."
    m_id > settings[:num_monitors] && return "Only $(settings[:num_monitors]) monitors are active."
    if isempty(slides[][1]) || get(request_params, :reset, "0") != "0" || get(request_params, :hardreset, "0") != "0"
        push!(Stipple.Layout.THEMES, () -> [link(href = "$(settings[:folder])/theme.css", rel = "stylesheet"), ""])
        foreach(x -> empty!(x),slides[])
        Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
        create_slideshow(pmodel)
    end
    pmodel.num_slides[] = length(slides[][m_id])
    page(pmodel,
    [
        StippleUI.Layouts.layout(view="hHh lpR lFf", [
            create_auxUI(m_id)
            quasar(:page__container, 
                getproperty.(slides[][m_id], :body)
            )
        ])
    ])
end

function serve_slideshow(PresentationModel::DataType, create_slideshow::Function, create_auxUI::Function, settings::Dict, request_params::Dict{Symbol, Any})
    hardreset = get(request_params, :hardreset, "0") != "0"
    if hardreset
        pmodel = get_or_create_pmodel(PresentationModel; force_create = true)
    else
        pmodel = get_or_create_pmodel(PresentationModel)
    end
    println("Time to build UI:")
    if hardreset || get(request_params, :reset, "0") != "0"
        empty!(pmodel.counters)
        reset_handlers()
        pop!(Stipple.Layout.THEMES)
    end
    @time ui(pmodel, create_slideshow, create_auxUI, settings, request_params) |> html 
end
#endregion
end
