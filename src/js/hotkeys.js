
Vue.directive('hotkeys', {
  inserted: function (el, binding) {
    const params = new Proxy(new URLSearchParams(window.location.search), {
      get: (searchParams, prop) => searchParams.get(prop),
    }); //https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
    iscontroller = !(params.shift == null) || !(params.ctrl == null);

    this._keyListener = function(e) {
      var activeElement = document.activeElement;
      var inputs = ['input', 'select', 'button', 'textarea'];

      team_id = binding.expression
      slide_id = 'PresentationModel.slide_id' + team_id
      slide_state = 'PresentationModel.slide_state' + team_id
      num_states = 'PresentationModel.num_states[' + slide_id + '-1]'
      drawer = 'PresentationModel.drawer' + team_id
      drawer_controller = 'PresentationModel.drawer_controller' + team_id

      // the logic below could also be implemented in the form of listeners on slide_state instead (see commit for version 0.18.2), however, the below solution is more performant (immediate switch between slides)
      if (!inputs.indexOf(activeElement.tagName.toLowerCase()) == -1 || !activeElement.hasAttribute("contenteditable")) { //do nothing if user is writing something
      switch (e.key) {
      case "ArrowRight":
        eval(slide_state + "==" + num_states + "?" + slide_id + '< PresentationModel.num_slides ? (' + slide_id + '++, ' + slide_state + '=1) : null : ' + slide_state + '++;');
        break;
      case "ArrowLeft":
        eval(slide_state + "== 1 ?" + slide_id + '> 1 ? (' + slide_id + '--, ' + slide_state + '=' + num_states + ') : null : ' + slide_state + '--;');
        break;
      case "m":
        if (iscontroller) {
          eval(drawer_controller + '= !' + drawer_controller + ';');
        }
        else {
          eval(drawer + '= !' + drawer + ';');
        }
        break;
      case "u":
        setTimeout(countUp(), 50);
        break;
      case "d":
        setTimeout(countDown(), 50);
        break;
      case "p":
        setTimeout(pauseTimer(), 50);
        break;
      };
    }
    }
    document.addEventListener('keydown', this._keyListener.bind(this));
},
})