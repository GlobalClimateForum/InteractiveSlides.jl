Vue.directive('hotkeys', {
    inserted: function (el, binding) {
      const params = new Proxy(new URLSearchParams(window.location.search), {
        get: (searchParams, prop) => searchParams.get(prop),
      }); //https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
      iscontroller = !(params.shift == null) || !(params.ctrl == null);

      this._keyListener = function(e) {
        team_id = binding.expression
        current_id = 'PresentationModel.current_id' + team_id
        slide_state = 'PresentationModel.slide_state' + team_id
        num_states = 'PresentationModel.num_states[' + current_id + '-1]'
        drawer = 'PresentationModel.drawer' + team_id
        drawer_controller = 'PresentationModel.drawer_controller' + team_id
        // the logic below could also be implemented in the form of listeners on slide_state instead (see commit for version 0.18.2), however, the below solution is more performant (immediate switch between slides)
        if (e.key === "ArrowRight") {
          eval(slide_state + "==" + num_states + "?" + current_id + '< PresentationModel.num_slides ? (' + current_id + '++, ' + slide_state + '=1) : null : ' + slide_state + '++;');
        }
        if (e.key === "ArrowLeft") {
          eval(slide_state + "== 1 ?" + current_id + '> 1 ? (' + current_id + '--, ' + slide_state + '=' + num_states + ') : null : ' + slide_state + '--;');
        }
        if (iscontroller) {
          if (e.key === "m") {
            eval(drawer_controller + '= !' + drawer_controller + ';');
          }
        }
        else {
          if (e.key === "m") {
            eval(drawer + '= !' + drawer + ';');
          }
        }
      };
  
      document.addEventListener('keydown', this._keyListener.bind(this));
  },
  })