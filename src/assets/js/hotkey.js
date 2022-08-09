Vue.directive('hotkey', {
    inserted: function (el, binding) {
      this._keyListener = function(e) {
        monitor_id = binding.expression
        current_id = 'PresentationModel.current_id' + monitor_id
        drawer = 'PresentationModel.drawer' + monitor_id
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