## Shiny Application Components

Key UI functions and server structure used by the BioBuddy app.

### Cards and body

- **`dog_card(name, profile_url, headshot_url, breed, card_b)`**: Renders a profile card. Provide the inner body as `card_b` (see `inner_body`).

- **`inner_body(id, raw_bio, interview_rw, pupper_rw, sectioned_rw, tab_num = 1, limit_growth = FALSE, customize = FALSE)`**: Tabbed content showing the original and three rewrite styles. When `customize = TRUE`, shows the Customize pill; otherwise displays copy-to-clipboard buttons.

Example:

```r
card_b <- inner_body(
  id = 123, raw_bio = "Loves walks.",
  interview_rw = "/tmp/interview.md",
  pupper_rw = "/tmp/pupper.md",
  sectioned_rw = "/tmp/sectioned.md"
)
dog_card("Rover", "https://example.com/rover", "/img/rover.png", "Mixed", card_b)
```

### Sidebar utilities (forked from argonDash)

- **`argonDashSidebar(...)`**: Layout container for vertical/horizontal navbar/sidebar.
- **`argonSidebarItem(..., tabName, icon)`**: Navigational item that Shiny can observe via `input$tab-<tabName>`.
- **`argonSidebarMenu(id, ...)`**: Vertical menu wrapper.
- **`argonDashPage(...)`**: Page skeleton with head/body deps and main-content structure.

### App scaffolding

- **`gen_showcase_tab(dog_df)`**: Returns an `argonTabItem` showing the five longest-stay dogs using `dog_card` and `inner_body`.
- **`gen_customize_tab(dog_df)`**: Returns an `argonTabItem` with selectors and dynamic outputs for custom rewrites.

The exported `ui` and `server` in `app/ui.R` wire these together and use `polished` for auth and `shinylogs` for analytics.

Usage snippet:

```r
ui <- argonDashPage(navbar = navbar, body = argonDashBody(
  argonTabItems(uiOutput("showcase_tab"), shinyjs::hidden(uiOutput("customize_tab")))
))

server <- function(input, output, session) {
  dog_df <- readr::read_csv("/path/to/data.csv")
  output$showcase_tab <- renderUI(gen_showcase_tab(dog_df))
  output$customize_tab <- renderUI(gen_customize_tab(dog_df))
}
```

