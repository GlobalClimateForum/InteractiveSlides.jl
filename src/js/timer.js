function CountDown() {
    function Decrement(previous) {
        if (isNaN(previous) || PresentationModel.timer == previous) {
            PresentationModel.timer--;
            previous = PresentationModel.timer
            setTimeout(Decrement.bind(this, previous), 1000);
        }
    }
    setTimeout(Decrement(NaN), 50);
  }
  
  function CountUp() {
    function Increment(previous) {
        if (isNaN(previous) || PresentationModel.timer == previous) {
            PresentationModel.timer++;
            previous = PresentationModel.timer
            setTimeout(Increment.bind(this, previous), 1000);
        }
    }
    setTimeout(Increment(NaN), 50);
  }
  
  function PauseTimer() {
    setTimeout(PresentationModel.timer++, 1000);
  }