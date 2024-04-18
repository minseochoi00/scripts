function removeXrayQuickview() {
    var xrayquickviewElement = document.querySelector('.xrayQuickView');
    
    if (xrayquickviewElement) {
      xrayquickviewElement.remove();
      console.log('X-Ray quick view removed.');
      stopInterval();
    } else {
      console.error('X-Ray quick view not found.');
    }
}
  
  var intervalId = setInterval(removeXrayQuickview, 10000);
  
  function stopInterval() {
    clearInterval(intervalId);
    console.log('Interval stopped.');
  }
  
  // Optionally, you might want to clear the interval after a certain number of attempts
  var attempts = 200;
  setTimeout(function() {
      clearInterval(intervalId);
      console.log('Interval cleared after maximum attempts.');
  }, attempts * 10000);