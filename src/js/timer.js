// This timer is controlled by the frontend, and as such stops on a page reload. 
// One can also implement a backend-controlled timer (see commit for version 2.8 in the InteractiveSlidesDemos repo where I dropped that approach), 
// but that timer then seems to be affected by backend computations (e.g. due to listeners)

function checkIfChanged() { 
  //this is to avoid multiple timers at the same time. Checking timer_isactive fails upon page reload (won't be set to false even though it should be)
  return new Promise((resolve, reject) => {
    previous = PresentationModel.timer;
    setTimeout(() => {
      resolve(PresentationModel.timer != previous);
    }, 1300);
  });
}

async function count(step) {
  hasChanged = await checkIfChanged();
  if (!hasChanged) {
    PresentationModel.timer_isactive = true
    function Increment() {
      if (PresentationModel.timer_isactive) {
        PresentationModel.timer += step;
        setTimeout(Increment.bind(this), 1000);
      }
    }
    setTimeout(Increment(), 0);
  }
}

function countDown() {
  count(-1);
}

function countUp() {
  count(1);
}
  
function pauseTimer() {
  PresentationModel.timer_isactive = false
}