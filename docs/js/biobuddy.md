## JavaScript: Browser Utilities (`app/www/biobuddy.js`)

Helpers used by the Shiny UI for tab state, tooltips, and copying.

- **`setBioType()`**: Reads the active tab's `biotype` attribute and sets Shiny input `biotype`.
- **`tooltipsOn()`**: Activates Bootstrap tooltips on elements with `data-toggle="tooltip"`.
- **`setTabToCustomize()`**: Programmatically selects the "customize" tab from the navbar.
- **`copyToClipboard(elementId)`**: Copies text content of the hidden element to the clipboard and shows visual feedback on the calling button.
- **`fallbackCopyTextToClipboard(text, elementId)`**: Fallback path for non-secure contexts.
- **`showCopySuccess(elementId)`** / **`showCopyError(elementId)`**: Button feedback states.

Example usage in UI (R):

```r
tags$head(includeScript("www/biobuddy.js"))
```

