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
cards_tab_1 <- argonTabItem(tabName = "cards-tab-1",  gen_dogs_tab("NH177"))
cards_tab_standin <- argonTabItem(tabName = "cards-tab-2", gen_dogs_tab("VA321"))

sidebar <- argonDashSidebar(
  vertical = TRUE,
  skin = "light",
  background = "white",
  size = "md",
  side = "left",
  id = "my_sidebar",
  brand_url = "http://www.google.com",
  brand_logo = "https://demos.creative-tim.com/argon-design-system/assets/img/brand/blue.png",
  argonSidebarHeader(title = "Main Menu"),
  argonSidebarMenu(
    argonSidebarItem(
      tabName = "cards-tab-1",
      icon = argonIcon(name = "tv-2", color = "info"),
      "Profiles"
    ),
    argonSidebarItem(
      tabName = "cards-tab-2",
      icon = argonIcon(name = "planet", color = "warning"),
      "standin"
    ),
    argonSidebarItem(
      tabName = "tabs",
      icon = argonIcon(name = "planet", color = "warning"),
      "Tabs"
    )
  ),
  argonSidebarDivider(),
  argonSidebarHeader(title = "Other Items")
)

shinyApp(

  ui = argonDashPage(
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

    observeEvent(input$controller, {
      session$sendCustomMessage(
        type = "update-tabs",
        message = input$controller
      )
    })
  }

)
