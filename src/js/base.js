function onSwitch(newval, oldval, URLid) {
    colored_slide = document.getElementsByClassName('slide_current slide-color')
    if (colored_slide.length > 0) {
      document.querySelector(':root').style.setProperty('--bg-color', window.getComputedStyle(colored_slide[0]).backgroundColor)
    }
    else {
      document.querySelector(':root').style.setProperty('--bg-color', document.querySelector(':root').style.getPropertyValue('--q-color-white'))
    }
    if (Math.abs(newval - oldval) == 1)
    {
      skip_slide = document.getElementsByClassName('slide_current skip-slide')
      if (skip_slide.length > 0) {
        pmodel[`slide_id${URLid}`] = pmodel[`slide_id${URLid}`] + newval - oldval
      }
    }
  }

var initialize_attempt = 0;
var intervalID = setInterval(function () {

    onSwitch();
    try {
      hljs.highlightAll()
    }
    catch (err) {
      initialize_attempt == 4 ? (console.info("No highlight.js detected.")) : null
    }
    pmodel.is_fully_loaded ? null : (pmodel.push_again = Math.floor(Math.random() * 10))

    if (++initialize_attempt === 5) {
      window.clearInterval(intervalID);
    }
}, 5000);
  

function next(URLid) {
  if (pmodel[`slide_state${URLid}`] >= pmodel.num_states[pmodel[`slide_id${URLid}`]-1]) {
    if (pmodel[`slide_id${URLid}`] < pmodel.num_slides) {
      pmodel[`slide_id${URLid}`]++;
      pmodel[`slide_state${URLid}`] = 1;
    }
  }
  else {
    pmodel[`slide_state${URLid}`]++;
  }
}

function previous(URLid) {
  if (pmodel[`slide_state${URLid}`] == 1) {
    if (pmodel[`slide_id${URLid}`] > 1) {
      pmodel[`slide_id${URLid}`]--;
      pmodel[`slide_state${URLid}`] = pmodel.num_states[pmodel[`slide_id${URLid}`]-1];
    }
  }
  else {
    pmodel[`slide_state${URLid}`]--;
  }
}