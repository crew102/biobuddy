function setBioType() {
  h = document.querySelector("#out_card_b .tab-pane.show.active");
  val = h.attributes.biotype.value;
  Shiny.setInputValue('biotype', val);
}

function tooltipsOn() {
  $('[data-toggle=\"tooltip\"]').tooltip({ container: 'body' });
}
