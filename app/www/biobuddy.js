function setBioType() {
  h = document.querySelector("#out_card_b .tab-pane.show.active");
  val = h.attributes.biotype.value;
  Shiny.setInputValue('biotype', val);
}

function tooltipsOn() {
  $('[data-toggle=\"tooltip\"]').tooltip({ container: 'body' });
}

function setTabToCustomize() {
  document.getElementById('tab-customize_tab').classList.add('active', 'show');
  document.getElementById('tab-showcase_tab').classList.remove('active', 'show');
}

// Temp solution to programmatically hiding sidebar
function collapseSidebar() {
  document.querySelectorAll('.navbar-toggler')[0].click();
}

function toggle_dropdown() {
  $('#dropdown_button').click();
}
