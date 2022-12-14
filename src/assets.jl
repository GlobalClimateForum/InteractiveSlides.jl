module Assets
import ..Genie, ..Stipple, ..StippleUI, StipplePlotly, ..AS_EXECUTABLE

function add_js(file::AbstractString; ext = ".js", basedir = @__DIR__, subfolder = "", prefix = "", kwargs...)
    file = replace(file, ext => "")
    Genie.Router.route(Genie.Assets.asset_path(file; ext, package = "InteractiveSlides.jl", type = "", prefix, kwargs...)) do
    Genie.Renderer.WebRenderable(
        Genie.Assets.embedded(Genie.Assets.asset_file(cwd=basedir; prefix, type = subfolder, ext, file)),
    ext == ".js" ? :javascript : :css) |> Genie.Renderer.respond
    end
    filename = splitpath(file)[end]
    if ext == ".js"
        Stipple.DEPS[Symbol(file)] = () -> [Stipple.script(src = "/interactiveslides.jl/$(lowercase(filename)).js")]
    else
        push!(Stipple.Layout.THEMES, () -> [Stipple.stylesheet("/interactiveslides.jl/$(lowercase(filename)).css"), ""])
    end
end

function get_assets()
    out = []
    for (root, dirs, files) in walkdir(Genie.config.server_document_root)
        for file in files
            fileandfolder = joinpath(push!(splitpath(root)[2:end], file))
            if endswith(fileandfolder, ".css") && !endswith(fileandfolder, "theme.css") 
                #theme.css is loaded differently, in standard_assets(), as otherwise theme.css would be loaded before inline styles
                push!(out, Stipple.stylesheet(fileandfolder))
            elseif endswith(fileandfolder, ".js")
                add_js(file, basedir = root)
            end
        end
    end
    return out
end

function set_watchers(max_num_teams)
    eval(
    :(
    function Stipple.js_watch(m::T)::String where {T<:Stipple.ReactiveModel}
        str = ""
        for t_id in 0:$max_num_teams
        str = str * """
            slide_id$t_id: function (val) {
            setTimeout('onSwitch()', 50); 
            },
        """
        end
        return str
    end))
end

function set_methods(max_num_teams)
    eval(
    :(
    function Stipple.js_methods(m::T)::String where {T<:Stipple.ReactiveModel}
        str = ""
        for t_id in 0:$max_num_teams
        str = str * """
        next$t_id: function (val) {
            this.slide_state$t_id >= this.num_states[this.slide_id$t_id-1] ? this.slide_id$t_id < this.num_slides ? (this.slide_id$t_id++, this.slide_state$t_id = 1) : null : this.slide_state$t_id++
        },
        previous$t_id: function (val) {
            this.slide_state$t_id == 1 ? this.slide_id$t_id > 1 ? (this.slide_id$t_id--, this.slide_state$t_id = this.num_states[slide_id$t_id-1]) : null : this.slide_state$t_id--
        }$(t_id == $max_num_teams ? "" : ",")
        """
        end
        return str
    end))
end

function standard_assets(max_num_teams, use_Stipple_theme::Bool; local_pkg_assets::Bool)
    !use_Stipple_theme && Genie.Router.delete!(Symbol("get_stipple.jl_master_assets_css_stipplecore.css")) 
    basedir = local_pkg_assets ? pwd() : @__DIR__
    subfolder = local_pkg_assets ? joinpath("assets", "js") : "js"
    if local_pkg_assets
        filter!((x) -> x != StippleUI.theme, Stipple.Layout.THEMES)
        delete!(Stipple.DEPS, StippleUI)
        delete!(Stipple.DEPS, StipplePlotly)
        for oldasset in [:get_stipplecorejs, :get_vuefiltersjs, :get_vuejs, :get_underscorejs, :get_keepalivejs, :get_watchersjs, :get_genielogosvg]
            Genie.Router.delete!(oldasset)
        end
        for newasset in ["underscore-min", "vue.min", "stipplecore", "vue_filters", "watchers", "keepalive"]
            add_js(newasset; basedir, subfolder) #Stipple assets
        end
        for newasset in ["plotly2.min", "resizesensor.min", "lodash.min", "vueresize.min", "vueplotly.min", "sentinel.min", "syncplot", "quasar.umd.min"]
            add_js(newasset; basedir, subfolder) #StipplePlotly and StippleUI assets
        end
        add_js("quasar.min"; ext = ".css", basedir, subfolder = joinpath("assets", "css"))
    end
    add_js("timer"; basedir, subfolder)
    add_js("hotkeys"; basedir, subfolder)
    add_js("onSwitch"; basedir, subfolder)
    set_watchers(max_num_teams)
    set_methods(max_num_teams)
    push!(Stipple.Layout.THEMES, () -> [Stipple.stylesheet("css/theme.css"), ""])
    Stipple.DEPS[:hljs] = () -> [Stipple.script("setTimeout('hljs.highlightAll()', 1000); setTimeout('hljs.highlightAll()', 10000);")]
end

#Genie assets

get_module_path(m) = dirname(dirname(Base.functionloc(m.eval, Tuple{Nothing})[1]))
genie_path = get_module_path(Genie)
cwd_genie() = AS_EXECUTABLE[] ? pwd() : genie_path

function Genie.Assets.channels(channel::AbstractString = Genie.config.webchannels_default_route) :: String
    AS_EXECUTABLE[] && println("Stipple and Genie assets need to be in " * joinpath(cwd_genie(), "assets"))
    string(Genie.Assets.js_settings(channel), Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), type = "js", file = "channels")))
end

function Genie.Assets.webthreads(channel::String = Genie.config.webthreads_default_route) :: String
    string(Genie.Assets.js_settings(channel),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="pollymer.js")),
        Genie.Assets.embedded(Genie.Assets.asset_file(; cwd = cwd_genie(), file="webthreads.js")))
end

end