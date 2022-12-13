
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
      slide_id = 'pmodel.slide_id' + URLid
      drawer = 'pmodel.drawer' + URLid
      drawer_shift = 'pmodel.drawer_shift' + URLid
      
      if (!inputs.indexOf(activeElement.tagName.toLowerCase()) == -1 || !activeElement.hasAttribute("contenteditable")) { //do nothing if user is writing something
      switch (e.key) {
      case "ArrowRight":
        eval('pmodel.next' + URLid + '();');
        break;
      case "ArrowLeft":
        eval('pmodel.previous' + URLid + '();');
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
      case "ArrowDown":
        document.getElementById(eval(slide_id)).classList.add("scroll-always");
        break;
      };
    }
    }
    document.addEventListener('keydown', this._keyListener.bind(this));
},
})