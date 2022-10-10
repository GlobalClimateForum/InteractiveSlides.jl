# InteractiveSlides.jl

Swiftly create interactive presentations in Julia which run in the browser as single-page applications. InteractiveSlides.jl leverages the [Genie framework](https://www.genieframework.com/) and therefore allows for presentations to contain reactive UI elements, including beautiful input forms, tables, and plots. InteractiveSlides.jl simplifies tasks such as creating a sidebar, a header, a footer, and of course the slides themselves. The package also allows to serve presentations on multiple screens, where each screen accepts different inputs, which is useful when there are several teams. The inputs (and potential outputs based on those inputs) of each team can easily be visualized and compared.

Other features include:
- Hotkeys: While presenting, switch between slides with arrow keys, and open/close the sidebar with "m"
- Slide states: Each slide can have multiple states, which can be used e.g. for initially hiding an element on a slide
- The style of each presentation can easily be changed simply by editing the theme.css file which is part of every presentation

You can find demos in the following repository: [InteractiveSlidesDemos](https://github.com/GlobalClimateForum/InteractiveSlidesDemos).

For creating your own presentation, it is probably easiest to simply clone and edit the demo repository.

## Screenshots:

![Screenshot 1](https://i.ibb.co/19QcnVx/demo-decision-time.jpg)
![Screenshot 2](https://i.ibb.co/0BG19BX/demo-results.jpg)

[![Build Status](https://github.com/GlobalClimateForum/InteractiveSlides.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/GlobalClimateForum/InteractiveSlides.jl/actions/workflows/CI.yml?query=branch%3Amain)

TODO: Make appear_on, hide_on, from_to also available in forms where the content disappears completely (like @iff or @show_if)