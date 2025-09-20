clean_raw_bios <- function(bios) {
  bios <- gsub(" {2,}", " ", bios)
  bios <- gsub("\n", " ", bios)
  bios <- gsub(" {2,}", " ", bios)
  bios <- gsub("^ ", "", bios)
  bios <- gsub("^ +!|^! ", "", bios)
  bios <- gsub("^[0-9]* ", "", bios)
  bios <- gsub(" ,", ",", bios)
  ifelse(nchar(bios) < 300, NA, bios)
}

clean_pet_name <- function(name) {
  x <- gsub("[0-9]+ ", "", name)
  x <- gsub(" -.*", "", x)
  decoded <- decode_html_apply(x)
  str_to_title(decoded)
}

# Tweaked version of one of bsicons's functions
info_icon <- function(id, input_txt, tooltip_text) {
  HTML(glue('
      <span>{input_txt}
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" class="bi bi-info-circle"
          style="height:1em;width:1em;fill:currentColor;vertical-align:-0.125em;"
          aria-hidden="true" role="img" data-toggle="tooltip"
          id="{id}" data-toggle="tooltip" data-html="true" title="{tooltip_text}" tabindex="0">
          <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z">
          </path>
          <path d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533L8.93 6.588zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0z">
          </path>
        </svg>
      </span>
  '))
}

decode_html <- function(encoded_string) {
  wrapped_string <- paste0("<div>", encoded_string, "</div>")
  parsed_html <- xml2::read_html(wrapped_string)
  xml2::xml_text(parsed_html)
}

decode_html_apply <- function(encoded_strings) {
  vapply(encoded_strings, decode_html, FUN.VALUE = character(1))
}
