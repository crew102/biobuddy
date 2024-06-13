function setBioType() {
  h = document.querySelector("#out_card_b .tab-pane.show.active");
  val = h.attributes.biotype.value;
  Shiny.setInputValue('biotype', val);
}

function tooltipsOn() {
  $('[data-toggle=\"tooltip\"]').tooltip({ container: 'body' });
}

function setTabToCustomize() {
  x = document.getElementById('shiny-tab-showcase_tab');
  x.setAttribute('class', 'tab-pane container-fluid');
  x = document.getElementById('shiny-tab-customize_tab');
  x.setAttribute('class', 'tab-pane container-fluid active show');
  document.getElementById('tab-customize_tab').classList.add('active', 'show');
  document.getElementById('tab-showcase_tab').classList.remove('active', 'show');
}
