## R: UI Helpers

Utilities for cleaning text and generating small UI fragments.

### Text cleaning

- **`clean_raw_bios(bios)`**: Normalizes whitespace and punctuation; returns `NA` if text length < 300.
- **`clean_pet_name(name)`**: Removes numeric prefixes and suffixes, decodes HTML, and title-cases.

Examples:

```r
clean_raw_bios("  123   Hello,  world!\n\n")
clean_pet_name("123 rover - id 9 &amp; friends")
```

### UI fragments

- **`info_icon(id, input_txt, tooltip_text)`**: Inline label with an info icon showing a tooltip.
- **`decode_html(encoded_string)`** and **`decode_html_apply(encoded_strings)`**: Decode HTML entities to plain text.

Example:

```r
info_icon("beh_info", "Endearing behaviors", "Pick all that apply")
```

