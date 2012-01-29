window.RESET = function() {
  $( "content" ).innerHTML = "";
};

Array.implement({
  average: function(){
    return this.length ? this.sum() / this.length : 0;
  },

  sum: function(){
    var result = 0, l = this.length;
    if (l){
      while (l--) result += this[l];
    }
    return result;
  }
});

window.Timer = new Class({
  initialize: function( name, iterations, fn ) {
    iterations = new Number( iterations );
    var recordedTimes = [];
    iterations.each( function(i) {
      RESET();
      var start = new Date();
      fn();
      var stop = new Date();
      recordedTimes.push( stop - start );
    });
    var averageTime = recordedTimes.average();
    console.log( name + "\n----------\nTimes: " + recordedTimes.join(", ") + "\nAvg: " + averageTime + " msec");
  }
});
