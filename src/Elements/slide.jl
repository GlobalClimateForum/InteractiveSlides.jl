export Slide
export slide, titleslide, controllerslide, simpleslide
export @slide, @titleslide, @controllerslide, @simpleslide

struct Slide
    title::String
    HTMLattr::Dict
    body::ParsedHTMLString
    num_states::Int
end

"""
    slide(slides::Vector{Slide}, params::Dict, HTMLelem...; num_states = 1, class = ""::String, title = ""::String, HTMLattr...)

Takes a vector of slides, and appends another slide to it (which is generated according to params and the HTML elements which are supplied as args).

### Example
```julia
julia> params = Dict(:URLid => 1)
julia> slide(Slide[], params, h1("Heading"), p("Content"))
1-element Vector{Slide}:
 Slide("Heading", Dict{Symbol, Any}(:class => "slide "), "<q-page class=\"slide \" v-show='1 == slide_id1 + 0'><h1>Heading</h1><p>Content</p></q-page>", 1)
```
"""
function slide(slides::Vector{Slide}, params::Dict, HTMLelem...; num_states = 1, class = ""::String, title = ""::String, color = "", HTMLattr...)
    HTMLattr = Dict{Symbol, Any}(HTMLattr)
    HTMLattr[:class] = "slide " * class * ifelse(get(params, :show_whole_slide, false), " scroll-always", "") * ifelse(color == "", "", " slide-color")
    HTMLattr[:style] = ifelse(color == "", "", "background-color:$color;") * get(HTMLattr, :style, "")
    slide_id = length(slides) + 1
    HTMLattr[:id] = slide_id
    if isempty(title) 
        try
            title = match(r"(?<=\<h[1-2]\>).+(?=<)", String(HTMLelem[1])).match
            title = replace(title, "<br>" => " - ")
            title = strip(replace(title, r"<[^>]*>" => ""))
        catch
            title = "Untitled"; println("Warning: Untitled slide")
        end
    end
    shift = get(params, :shift, 0)
    condition = "$slide_id == slide_id$(params[:URLid]) + $shift"
    body = quasar(:page, ["", HTMLelem...], @v__bind("[{slide_current: $condition}]", :class), @showif(condition); HTMLattr...)
    push!(slides, Slide(title, HTMLattr, body, num_states))
    return slides
end

function titleslide(args...; class = "text-center flex-center"::String, title = ""::String, HTMLattr...)
    slide(args...; class = "titleslide " * class, title, HTMLattr...)
end

function controllerslide(slides, params, args...; class = "text-center flex-center"::String, title = ""::String, HTMLattr...)
    params[:URLid] != 99 ? slides : slide(slides, params, args...; class = "controllerslide " * class, title, HTMLattr...)
end

function simpleslide(slides, params, heading, content...; contentstyle = "", contentclass = "flex-center", kwargs...)
    style = "height:100%; display:flex;" * contentstyle
    slide(slides, params, heading, Html.div([content...], style = style, class = "col " * contentclass); class = "column", kwargs...)
end

####################### CONVENIENCE MACROS ####################

"""
    @slide(exprs...)

This macro returns an expression which calls the "slide" function with the args and kwargs you passed to it, plus the list "slides" and the dict "params". 
It is thus merely for convenience, as it saves you from having to explicitly type pass "slides" and "params" everytime you want to create a slide.
The macro thus requires slides and params to be defined within the scope it is called.
### Example
```julia
julia> params = Dict(:URLid => 1)
julia> slides = Slide[]
julia> @slide(h1("Heading"), p("Content"))
1-element Vector{Slide}:
 Slide("Heading", Dict{Symbol, Any}(:class => "slide "), "<q-page class=\"slide \" v-show='1 == slide_id1 + 0'><h1>Heading</h1><p>Content</p></q-page>", 1)
```
"""
macro slide(exprs...)
    esc(:(slides = slide(slides, params, $(eqtokw!(exprs)...))))
end

macro titleslide(exprs...)
    esc(:(slides = titleslide(slides, params, $(eqtokw!(exprs)...))))
end

macro controllerslide(exprs...)
    esc(:(slides = controllerslide(slides, params, $(eqtokw!(exprs)...))))
end

macro simpleslide(exprs...)
    esc(:(slides = simpleslide(slides, params, $(eqtokw!(exprs)...))))
end