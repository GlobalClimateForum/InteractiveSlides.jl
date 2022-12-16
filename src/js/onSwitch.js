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
  

function next(URLid) {
  pmodel[`slide_state${URLid}`] >= pmodel.num_states[pmodel[`slide_id${URLid}`]-1] ? pmodel[`slide_id${URLid}`] < pmodel.num_slides ? (pmodel[`slide_id${URLid}`]++, pmodel[`slide_state${URLid}`] = 1) : null : pmodel[`slide_state${URLid}`]++
}

function previous(URLid) {
  pmodel[`slide_state${URLid}`] == 1 ? pmodel[`slide_id${URLid}`] > 1 ? (pmodel[`slide_id${URLid}`]--, pmodel[`slide_state${URLid}`] = pmodel.num_states[pmodel[`slide_id${URLid}`]-1]) : null : pmodel[`slide_state${URLid}`]--
}