library(shiny)
library(argonR)
library(argonDash)
library(bslib)
library(readr)
library(dplyr)
library(markdown)
library(here)
library(shinyjs)

devtools::load_all()
options(shiny.port = 3838, shiny.host = "0.0.0.0")

dogs <- read_csv(here("cache/lorem-ipsum-bios.csv"))
dogs <- dogs %>% mutate(name = gsub("[^A-z]", "", name))

gen_dogs_tab <- function(org_id) {

  three_pups <- dogs %>% filter(organization_id == org_id) %>% slice(1:3)

  lapply(three_pups$name, function(x) {
    this_pup <- three_pups %>% filter(name == x)
    card_b <- inner_body(this_pup)
    dog_card(
      .x = this_pup,
      card_b = card_b
    )
  })
}

gen_dogs_tab_realtime <- function(org_id) {

  three_pups <- dogs %>% filter(organization_id == org_id) %>% slice(1:3)

  lapply(three_pups$name, function(x) {
    this_pup <- three_pups %>% filter(name == x)
    card_b <- inner_body(this_pup)
    dog_card(
      .x = this_pup,
      card_b = card_b
    )
  })
}

# c("GA553", "NH177", "VA321", "VA68")
cards_tab_1 <- argonTabItem(tabName = "cards_tab_1",  gen_dogs_tab("NH177"))

cards_tab_standin <- argonTabItem(
  tabName = "cards_tab_2",
  textInput("some_input", "Dog name"),
  actionButton("submit", "Do it"),
  htmlOutput("some_output")
)

sidebar <- argonDashSidebar(
  vertical = TRUE,
  skin = "light",
  background = "white",
  size = "md",
  side = "left",
  id = "my_sidebar",
  brand_url = "http://www.google.com",
  brand_logo = "bb-logo.svg",
  argonSidebarHeader(title = "Bios"),
  argonSidebarMenu(
    id = "sidebar-menu",
    argonSidebarItem(
      tabName = "cards_tab_1",
      icon = argonIcon(name = "tv-2", color = "info"),
      "Precomputed"
    ),
    argonSidebarItem(
      tabName = "cards_tab_2",
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
      tags$head(includeCSS("www/biobuddy.css")),
      tags$head(includeScript("www/biobuddy.js")),
      tags$head(includeScript("https://kit.fontawesome.com/42822e2abc.js")),
      argonTabItems(cards_tab_1, cards_tab_standin)
    ),
    footer = footer
  ),

  server = function(input, output, session) {

    # temp solution to programmatically hiding sidebar
    observeEvent(input$`tab-cards_tab_1`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })
    observeEvent(input$`tab-cards_tab_2`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })

    observeEvent(input$submit, {
      output$some_output <- renderUI({
        gen_dogs_tab("VA321")
      })
    })
  }

)
