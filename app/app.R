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
library(magrittr)

devtools::load_all()

source(here("app/ui.R"))

options(shiny.port = 3838, shiny.host = "0.0.0.0")

### org id will be passed in as input when sign in. we'll have showcase
### the data in lorem-ipsum-bios.csv in batch process.
org_id <- "GA553"
dogs <- read_csv(here("app/data/lorem-ipsum-bios.csv")) %>%
  filter(organization_id == org_id)


# showcase tab
long_stays <- dogs %>% filter(is_oldest_five) %>% slice(1:5)
showcase_tab_ui <- lapply(long_stays$id, function(x) {
    p <- long_stays %>% filter(id == x)
    card_b <- with(p, inner_body(id, raw_bio, interview_rr, pupper_rr, sectioned_rr))
    with(p, dog_card(id, name, url, breeds_primary, card_b))
})
showcase_tab <- argonTabItem("showcase_tab", showcase_tab_ui)

first_dog <- long_stays %>% slice(1)

customize_tab <- argonTabItem(
  tabName = "customize_tab",
    tags$div(
      tags$br(),
      tags$br(),
      tags$div(
        class = "card card-profile shadow px-4",
        # image
        tags$div(class = "row",
           tags$div(class = "col",
              tags$div(class = "card-profile-image", uiOutput("out_img"))
           )
        ),
        # name/breed
        tags$div(
          class = "row",
          tags$div(
            class = "col mt-5",
            tags$div(
              class = "text-center mt-5 pt-5",
              pickerInput(
                inputId = "in_dog_name",
                choices = dogs$name,
                selected = first_dog$name[1],
                multiple = FALSE,
                autocomplete = TRUE,
                options = list(`live-search` = TRUE),
                width = "fit"
              ),

              tags$div(
                class = "h5 font-weight-300",
                uiOutput("out_breed")
              )
            )
          )
        ),
        # card body
        tags$div(
          class = "mt-2 py-2 border-top text-center",
          tags$div(
            class = "row justify-content-center",
            tags$div(
              class = "col-lg-9",
              uiOutput("out_card_b")
            )
          )
        )
      )
      # ,

      # htmlTemplate("modal.html", sliderValue = 50)
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
      tabName = "showcase_tab",
      icon = argonIcon(name = "tv-2", color = "info"),
      "Showcase"
    ),
    argonSidebarItem(
      tabName = "customize_tab",
      icon = argonIcon(name = "planet", color = "warning"),
      "Customize"
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
      argonTabItems(showcase_tab, customize_tab)
    ),
    footer = footer
  ),

  server = function(input, output, session) {

    # temp solution to programmatically hiding sidebar
    observeEvent(input$`tab-showcase_tab`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })
    observeEvent(input$`tab-customize_tab`, {
      shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
    })

    chosen_dog <- reactive({
      dogs %>%
        filter(name == input$in_dog_name)
    })

    output$out_img <- renderUI({
      chosen_dog() %$%
        img(src = paste0(".bio-images/", id, ".png"), class = "rounded-circle")
    })

    output$out_breed <- renderUI({
      chosen_dog() %>% pull(breeds_primary)
    })

    output$out_card_b <- renderUI({
      chosen_dog() %$%
        inner_body(id, raw_bio, interview_rr, pupper_rr, sectioned_rr, tab_num = 2)
    })

  }
)
