function setBioType() {
  h = document.querySelector("#out_card_b .tab-pane.show.active");
  val = h.attributes.biotype.value;
  Shiny.setInputValue('biotype', val);
}
