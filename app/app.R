library(shiny)
library(argonR)
library(argonDash)
library(magrittr)
library(bslib)
library(readr)
library(dplyr)
library(markdown)

devtools::load_all()
options(shiny.port = 3838, shiny.host = "0.0.0.0")

dogs <- read_csv("../rewriter/cache/lorem-ipsum-bios.csv")

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

one_tab <- gen_dogs_tab("MN441")

cards_tab <- argonTabItem(tabName = "some_tab", one_tab)

shinyApp(

  ui = argonDashPage(

    sidebar = NULL,
    header = navbar,

    body = argonDashBody(
      tags$head(includeCSS("www/biobuddy.css")),
      argonTabItems(cards_tab)
    ),

    footer = footer
  ),

  server = function(input, output) {


  }

)
