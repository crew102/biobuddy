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

dogs <- read_csv(here("cache/lorem-ipsum-bios.csv"))
dogs <- dogs %>% mutate(name = gsub("[^A-z]", "", name))

gen_dogs_tab <- function(org_id) {

  three_pups <- dogs %>% filter(organization_id == org_id) %>% slice(1:3)

  lapply(three_pups$name, function(x) {
    p <- three_pups %>% filter(name == x)
    card_b <- with(p, inner_body(name, raw_bio, interview_rr, pupper_rr, sectioned_rr))
    with(p, dog_card(name, url, primary_photo_cropped_full, breeds_primary, card_b))
  })
}

# c("GA553", "NH177", "VA321", "VA68")
precomputed_tab <- argonTabItem(
  tabName = "precomputed_tab",  gen_dogs_tab("NH177")
)

on_demand_tab <- argonTabItem(
  tabName = "on_demand_tab",
  bslib::card(
  fluidRow(
  column(width = 6,
    HTML('

        <div class="form-group">
           <label class="form-control-label" for="basic-url">Dog\'s name</label>
              <a href="#" title="Dog\'s name as it appears on PetFinder"
                data-toggle="tooltip" data-content="Choose a favorite" data-placement="right">
                <i class="fas fa-circle-info" role="presentation"></i>
              </a>
           <div class="input-group mb-3">
              <input type="text" class="form-control shiny-input-container"
              placeholder="Fido" id="dog_name">
              <div class="input-group-append" style="margin-left: 1px">
                 <button class="btn btn-outline-primary action-button"
                 type="button" id="search_dog_button">Search</button>
              </div>
           </div>
        </div>

    ')
  )
  ),
  fluidRow(
    column(width = 6,
      htmlOutput("some_output")
    )
  )
  )
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

        one_page <- fetch_pf_pages(
          auth_pf(),
          organization = "DC22"
        )
        one_page <- one_page$animals %>%
          filter(!is.na(primary_photo_cropped_full)) %>%
          filter(nchar(description) > 50)

        pickerInput(
          inputId = "Id084",
          label = "Dog",
          choices = one_page$name,
          multiple = FALSE,
          autocomplete = TRUE,
          options = list(
            `live-search` = TRUE)
        )

      })
    })

  }

)
