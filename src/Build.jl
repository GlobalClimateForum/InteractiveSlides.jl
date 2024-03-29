module Build
using ..Stipple, ..StippleUI

function presentation(pmodel::ReactiveModel, gen_content::Function, params::Dict{Symbol, Any}, assets; isdev, qview, use_Stipple_theme)
    params[:team_id] > pmodel.num_teams[] && return "Only $(pmodel.num_teams[]) teams can participate as per current settings."
    if pmodel.isprocessing[] && params[:init] && !isdev #without this check, loading the page multiple time upon initialiation results in an error (e.g. when double-clicking link).
        return page(pmodel, span("The presentation had not been fully loaded yet. Please reload this page.", class = "errormsg"), assets)
    end
    params[:init] && (pmodel.isprocessing[] = true)
    slides, auxUI = gen_content(pmodel, params)
    pmodel.isprocessing[] = false
    pmodel.num_slides[] = length(slides)
    pmodel.num_states[] = getproperty.(slides, :num_states)
    page(pmodel, prepend = style("[v-cloak] {display: none}"), v__cloak = true, core_theme = use_Stipple_theme,
    [
        StippleUI.Layouts.layout(view = qview, [ #see https://v1.quasar.dev/layout/layout#understanding-the-view-prop
            auxUI,
            Html.div(v__hotkeys = "$(params[:URLid])"),
            page_container(
                getproperty.(slides, :body)
            )
        ], 
        ), #https://v2.vuejs.org/v2/api/#v-cloak
    ], assets,
    )
end

function settings(pmodel::ReactiveModel)
    page(pmodel, [h2("Settings", style = "margin: 1rem"), row([
        cell("Number of teams"; size = 3), 
        cell(slider(1:1:pmodel.max_num_teams[], :num_teams; draggable = true, snap = true, step = 1, marker__labels = true, style = "padding:1rem"); size = 5)
        ], class = "flex-center")], class = "settings-page")
end

function landing(pmodel::ReactiveModel)
    page(pmodel, [h2("Welcome", style = "margin: 1rem"), list(
        append!([item(item_section(btn(id > 0 ? "Team $id" : "Plenum", type = "a", href = "$id"))) for id in 0:pmodel.num_teams[]], 
            [item(item_section(btn("Controller", type = "a", href = "99"))),
             item(item_section(btn("Settings", type = "a", href = "settings")))])
        )], class = "landing-page")
end

end