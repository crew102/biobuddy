// More code copied verbatim from argonDash:
// recover the R export in JS in the message arg. Message is an object.
// If on the R side message was a list, you can access its children by
// message.children.
Shiny.addCustomMessageHandler("update-tabs", function(message) {
  var currentTab = parseInt(message);
  console.log(message); // we check if the message is displayed

  // hide and inactivate all not selected tabs
  $(".active.show").removeClass("active show");
  $(".tab-pane.active.show").removeClass("active show");

  // add active class to the current selected tab and show its content
  $("#tab-Tab" + currentTab).addClass("active show");
  $("#shiny-tab-Tab" + currentTab).addClass("active show");
});
