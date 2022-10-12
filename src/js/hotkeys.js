
Vue.directive('hotkeys', {
  inserted: function (el, binding) {
    const params = new Proxy(new URLSearchParams(window.location.search), {
      get: (searchParams, prop) => searchParams.get(prop),
    }); //https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
    is_shift = !(params.shift == null);

    this._keyListener = function(e) {
      var activeElement = document.activeElement;
      var inputs = ['input', 'select', 'button', 'textarea'];

      URLid = binding.expression
      slide_id = 'PresentationModel.slide_id' + URLid
      slide_state = 'PresentationModel.slide_state' + URLid
      num_states = 'PresentationModel.num_states[' + slide_id + '-1]'
      drawer = 'PresentationModel.drawer' + URLid
      drawer_shift = 'PresentationModel.drawer_shift' + URLid

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
        if (is_shift) {
          eval(drawer_shift + '= !' + drawer_shift + ';');
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