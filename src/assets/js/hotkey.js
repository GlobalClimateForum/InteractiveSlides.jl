Vue.directive('hotkey', {
    inserted: function (el, binding) {
      this._keyListener = function(e) {
        team_id = binding.expression
        current_id = 'PresentationModel.current_id' + team_id
        drawer = 'PresentationModel.drawer' + team_id
        if (e.key === "ArrowRight") {
          eval(current_id + '< PresentationModel.num_slides ?' + current_id + '++ : null;');
        }
        if (e.key === "ArrowLeft") {
          eval(current_id + '> 1 ?' + current_id + '-- : null;');
        }
        if (e.key === "m") {
          eval(drawer + '= !' + drawer + ';');
        }
      };
  
      document.addEventListener('keydown', this._keyListener.bind(this));
  },
  })