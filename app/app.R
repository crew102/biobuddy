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
      tabName = "showcase_tab",
      icon = argonIcon(name = "tv-2", color = "info"),
      "Showcase"
    ),
    argonSidebarItem(
      tabName = "customize_tab",
      icon = argonIcon(name = "planet", color = "warning"),
      "Customize"
    ),
    argonDropNavDivider(),
    argonSidebarItem(
      tabName = "account_tab",
      icon = argonIcon(name = "planet", color = "warning"),
      "Account"
    )
  )
)

### org id will be passed in as input when sign in. we'll have showcase
### the data in lorem-ipsum-bios.csv in batch process.
org_id <- "GA553"
dogs <- read_csv(here("app/data/lorem-ipsum-bios.csv")) %>%
  filter(organization_id == org_id)

# showcase tab
long_stays <- dogs %>% filter(is_oldest_five) %>% slice(1:5)
showcase_tab_ui <- lapply(long_stays$id, function(x) {
    p <- long_stays %>% filter(id == x)
    card_b <- with(p, inner_body(id, raw_bio, interview_rw, pupper_rw, sectioned_rw))
    with(p, dog_card(id, name, url, breeds_primary, card_b))
})
showcase_tab <- argonTabItem("showcase_tab", showcase_tab_ui)

first_dog <- long_stays %>% slice(1)

customize_tab <- argonTabItem(
  tabName = "customize_tab",
    tags$div(
      hidden(textInput("biotype", "", "raw_bio")),
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
              uiOutput("out_card_b"),
              uiOutput("customize_rewrite_card")
            )
          )
        )

      )
    )
)

account_tab <- argonTabItem(
  tabName = "account_tab",
  tags$div()
)

ui <- argonDashPage(
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
)

server <- function(input, output, session) {

  # temp solution to programmatically hiding sidebar
  observeEvent(input$`tab-showcase_tab`, {
    shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
  })
  observeEvent(input$`tab-customize_tab`, {
    shinyjs::runjs("document.querySelectorAll('.navbar-toggler')[0].click()")
  })

  chosen_dog <- reactive({
    # Not terribly clever, but choosing to just clear the customized card
    # whenever new dog is chosen.
    output$customize_rewrite_card <- renderUI({
      shiny::tags$div()
    })

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
    tags$div(
      chosen_dog() %$%
        inner_body(
          id, raw_bio,
          interview_rw, pupper_rw, sectioned_rw,
          tab_num = 2, limit_growth = FALSE, customize = TRUE
        )
    )
  })

  observeEvent(input$show, {

    showModal(modalDialog(
      id = "settings_modal",
      easyClose = TRUE,
      title = "Customize settings",
      footer = NULL,
      tags$div(class = "p-4 bg-secondary",
        pickerInput(
          inputId = "length_input",
          label = "Length",
          choices = c("No change", "Shorter", "Longer"),
          selected = "No change",
          width = "fit"
        ),
        pickerInput(
          inputId = "emotive_input",
          label = "Emotional tone",
          choices = c("No change", "Less emotive", "More emotive"),
          selected = "No change",
          width = "fit"
        ),
        pickerInput(
          inputId = "humor_input",
          label = "Humour",
          choices = c("No change", "Less humour", "Drier", "More sarcastic"),
          selected = "No change",
          width = "fit"
        ),
        # TODO: Include info button with more suggestions like "include the
        # fact that the dog wags his tail when you walk in a room."
        textInput(
          "arbit_input", "Additional instructions", "",
          placeholder = "Write it in Spanish"
        )
      ),
      tags$br(),
      tags$div(
        style = "display: flex;",
        HTML('
          <button type="button" class="btn btn-outline-default btn-sm" data-dismiss="modal"
            data-bs-dismiss="modal">
            Dismiss
          </button>
          <button id="run_cust" type="button" class="btn action-button customize">
            <i class="fa-regular fa-pen-to-square" role="presentation" aria-label="pencil icon"></i>
            Write it
          </button>
        ')
      )
    ))
  }, ignoreNULL = TRUE)

  observeEvent(input$run_cust, {

    bio_to_rewrite <- chosen_dog() %>% pull(one_of(input$biotype))

    w <- Waiter$new(
      id = "settings_modal",
      html = tagList(spin_three_bounce()),
      color = transparent(),
      hide_on_error = TRUE
    )
    w$show()

    # Create prompt input to send to API
    prompt_file <- here(glue("app/prompts/customize.json"))
    prompt_df <- read_json(prompt_file, TRUE)
    null_if_nada <- function(input) {
      if (input == "" || input == "No change") NULL else input
    }
    changes <- c(
      "* Length:" = input$length_input,
      "* Emotional tone:" = input$emotive_input,
      "* Humour:" = input$humor_input,
      "* Additional instructions:" = input$arbit_input
    )
    changes_2 <- ifelse(changes == "" | changes == "No change", NA, changes)
    changes_2 <- changes_2[!is.na(changes_2)]
    # TODO: logic to have different prompt if no change indicated
    changes_2 <- paste(names(changes_2), changes_2)
    changes_2 <- paste0(changes_2, collapse = "\n")
    prompt_df$content[1] <- paste(
      prompt_df$content[1],
      "However, I would like you to make the following changes:\n",
      changes_2
    )
    prompt_df$content[2] <- bio_to_rewrite

    out <- generic_openai_request(prompt_df, "gpt-3.5-turbo-0125")
    # TODO: handle case where out is a string (error from API) and not response
    customize_rewrite_txt <- out$choices[[1]]$message$content
    output$customize_rewrite_card <- renderUI({
      HTML(glue('
        <br>
        <div class="card shadow">
          <div class="card-body">
            <h4 class="card-title">Customized version</h5>
            <p>{shiny::includeMarkdown(customize_rewrite_txt)}</p>
          </div>
        </div>
    '))
    })

    removeModal()
    w$hide()

  })

}

shinyApp(ui, server)
