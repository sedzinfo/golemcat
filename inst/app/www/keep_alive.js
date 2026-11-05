// Sends a ping to the server every 15 seconds, so proxies do not close idle connections
var keepAliveInterval;
var keepAliveCount = 0;

$(document).on('shiny:connected', function() {
  keepAliveInterval = setInterval(function() {
    Shiny.setInputValue('count', keepAliveCount++);
  }, 15000);
});

$(document).on('shiny:disconnected', function() {
  clearInterval(keepAliveInterval);
});
