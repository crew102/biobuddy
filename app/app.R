library(shiny)
library(argonR)
library(argonDash)
library(bslib)
library(readr)
library(dplyr)
library(markdown)
library(here)

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

# c("GA553", "NH177", "VA321", "VA68")
one_tab <- gen_dogs_tab("NH177")

cards_tab <- argonTabItem(tabName = "cards-tab-1", one_tab)

shinyApp(

  ui = argonDashPage(
    header = navbar,
    body = argonDashBody(
      tags$head(includeCSS("www/biobuddy.css")),
      tags$head(includeScript("www/biobuddy.js")),
      tags$head(includeScript("https://kit.fontawesome.com/42822e2abc.js")),
      argonTabItems(cards_tab)
    ),
    footer = footer
  ),

  server = function(input, output) {

  }

)
