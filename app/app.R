library(shiny)
library(argonR)
library(argonDash)
library(bslib)
library(readr)
library(dplyr)
library(markdown)
library(here)
library(shinyjs)
library(waiter)
library(cropcircles)
library(magick)
library(glue)
library(bsplus)
library(shinyWidgets)

devtools::load_all()

source(here("app/ui.R"))

options(shiny.port = 3838, shiny.host = "0.0.0.0")

### org id will be passed in as input when sign in. we'll have precomputed
### the data in lorem-ipsum-bios.csv in batch process.
org_id <- "GA553"
dogs <- read_csv(here("app/data/lorem-ipsum-bios.csv")) %>%
  filter(organization_id == org_id)


# precomputed tab
long_stays <- dogs %>% filter(is_oldest_five) %>% slice(1:3)
precomputed_tab_ui <- lapply(long_stays$id, function(x) {
    p <- long_stays %>% filter(id == x)
    card_b <- with(p, inner_body(id, raw_bio, interview_rr, pupper_rr, sectioned_rr))
    with(p, dog_card(id, name, url, breeds_primary, card_b))
})
precomputed_tab <- argonTabItem("precomputed_tab", precomputed_tab_ui)

# on demand
x <- dogs %>% slice(1)
card_b <- with(x, inner_body2(name, raw_bio, 'hi there'))
z <- with(x, dog_card(id, name, url, breeds_primary, card_b))
on_demand_tab <- argonTabItem(
  tabName = "on_demand_tab",
  z
)

sidebar <- argonDashSidebar(
  vertical = TRUE,
  skin = "light",
  background = "white",
  size = "s",
  side = NULL,
  id = "my_sidebar",
  brand_url = "http://www.google.com",
  brand_logo = "bb-logo.svg",
  argonSidebarHeader(title = "Bios"),
  argonSidebarMenu(
    id = "sidebar-menu",
    argonSidebarItem(
      tabName = "precomputed_tab",
      icon = argonIcon(name = "tv-2", color = "info"),
      "Precomputed"
    ),
    argonSidebarItem(
      tabName = "on_demand_tab",
      icon = argonIcon(name = "planet", color = "warning"),
      "On demand"
    )
  )
)

shinyApp(

  ui = argonDashPage(
    useShinyjs(),
    sidebar = sidebar,
    body = argonDashBody(
      use_bs_tooltip(),
      tags$head(includeCSS("www/biobuddy.css")),
      tags$head(includeScript("www/biobuddy.js")),
      tags$head(includeScript("https://kit.fontawesome.com/42822e2abc.js")),
      argonTabItems(precomputed_tab, on_demand_tab)
    ),
    footer = footer
  ),

  server = function(input, output, session) {

    # temp solution to programmatically hiding sidebar
    observeEvent(input$`tab-precomputed_tab`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })
    observeEvent(input$`tab-on_demand_tab`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })

    observeEvent(input$search_dog_button, {

      output$some_output <- renderUI({

        # one_page <- fetch_pf_pages(
        #   auth_pf(),
        #   organization = "DC22"
        # )
        # one_page <- one_page$animals %>%
        #   filter(!is.na(primary_photo_cropped_full)) %>%
        #   filter(nchar(description) > 50)

      tags$div(
        fluidRow(
        pickerInput(
          inputId = "Id084",
          label = "Dog",
          choices = dogs$name,
          multiple = FALSE,
          autocomplete = TRUE,
          options = list(`live-search` = TRUE)
        )
        # ),
        # fluidRow(
        #   awesomeRadio(
        #     inputId = "style",
        #     label = "Style",
        #     choices = c("Interview", "Pup perspective", "Sectioned"),
        #     selected = "Interview",
        #     inline = TRUE,
        #     status = "success"
        #   )
        )
      )

      })
    })

  }

)
