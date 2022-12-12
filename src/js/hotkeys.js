
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
      slide_state = 'pmodel.slide_state' + URLid
      num_states = 'pmodel.num_states[' + slide_id + '-1]'
      drawer = 'pmodel.drawer' + URLid
      drawer_shift = 'pmodel.drawer_shift' + URLid
      num_slides = 'pmodel.num_slides'
      
      // the logic below could also be implemented in the form of listeners on slide_state instead (see commit for version 0.18.2), however, the below solution is more performant (immediate switch between slides)
      if (!inputs.indexOf(activeElement.tagName.toLowerCase()) == -1 || !activeElement.hasAttribute("contenteditable")) { //do nothing if user is writing something
      switch (e.key) {
      case "ArrowRight":
        eval(slide_state + ">=" + num_states + "?" + slide_id + '< ' + 'pmodel.num_slides ? (' + slide_id + '++, ' + slide_state + '=1) : null : ' + slide_state + '++;');
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
      case "ArrowDown":
        document.getElementById(eval(slide_id)).classList.add("scroll-always");
        break;
      };
      setTimeout("onSwitch()", 5);
    }
    }
    document.addEventListener('keydown', this._keyListener.bind(this));
},
})

function onSwitch() {
  colored_slide = document.getElementsByClassName('slide_current slide-color')
  if (colored_slide.length > 0) {
    document.querySelector(':root').style.setProperty('--bg-color', window.getComputedStyle(colored_slide[0]).backgroundColor)
  }
  else {
    document.querySelector(':root').style.setProperty('--bg-color', document.querySelector(':root').style.getPropertyValue('--q-color-white'))
  }
}

setTimeout('onSwitch()', 500); 
setTimeout('onSwitch()', 1000);
setTimeout('onSwitch()', 3000);

window.pmodel.$watch(function(){return this.drawer_shift4}, _.debounce(function(newVal, oldVal){setTimeout('onSwitch()', 5); ;}, 300), {deep: true});
