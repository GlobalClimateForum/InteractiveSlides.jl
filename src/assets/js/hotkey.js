Vue.directive('hotkey', {
    inserted: function (el, binding) {
      const params = new Proxy(new URLSearchParams(window.location.search), {
        get: (searchParams, prop) => searchParams.get(prop),
      }); //https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
      iscontroller = !(params.shift == null) || !(params.ctrl == null);

      this._keyListener = function(e) {
        team_id = binding.expression
        current_id = 'PresentationModel.current_id' + team_id
        drawer = 'PresentationModel.drawer' + team_id
        drawer_controller = 'PresentationModel.drawer_controller' + team_id
        if (e.key === "ArrowRight") {
          eval(current_id + '< PresentationModel.num_slides ?' + current_id + '++ : null;');
        }
        if (e.key === "ArrowLeft") {
          eval(current_id + '> 1 ?' + current_id + '-- : null;');
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