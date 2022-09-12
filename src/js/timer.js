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