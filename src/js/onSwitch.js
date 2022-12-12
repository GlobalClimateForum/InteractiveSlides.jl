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
  