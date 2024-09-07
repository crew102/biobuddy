library(shiny)
library(argonR)
library(argonDash)
library(bslib)
library(dplyr)
library(markdown)
library(here)
library(shinyjs)
library(waiter)
library(glue)
library(bsplus)
library(shinyWidgets)
library(magrittr)
library(polished)
library(readr)

devtools::load_all()

source(here("app/ui.R"))

polished_config(
  app_name = "biobuddy-dev",
  api_key = get_secret("POLISHED_API_KEY"),
  firebase_config = list(
    apiKey = get_secret("FIREBASE_API_KEY"),
    authDomain = "pf-analytics-232522.firebaseapp.com",
    projectId = "pf-analytics-232522"
  ),
  sign_in_providers = c("google", "email")
)

options(shiny.port = 3838, shiny.host = "0.0.0.0")

all_dogs <- read_s3_file(file = "db/rewrites.csv", read_csv)

gen_showcase_tab <- function(dog_df) {
  # showcase tab
  long_stays <- dog_df %>% filter(is_oldest_five) %>% slice(1:5)
  showcase_tab_ui <- lapply(long_stays$id, function(x) {
    p <- long_stays %>% filter(id == x)
    card_b <- with(p, inner_body(id, raw_bio, interview_rw, pupper_rw, sectioned_rw))
    with(p, dog_card(name, url, headshot_url, breeds_primary, card_b))
  })
  showcase_tab <- argonTabItem("showcase_tab", showcase_tab_ui)
  showcase_tab <- tagAppendChildren(
    showcase_tab,
    tags$br(),
    tags$div(
      style = "display: flex; justify-content: flex-end;",
      actionButton("view_more", "More")
    )
  )
}

sidebar <- argonDashSidebar(
  vertical = TRUE,
  skin = "light",
  background = "white",
  size = "md",
  side = "left",
  id = "my_sidebar",
  # TODO: Replace with landing page
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

gen_customize_tab <- function(dog_df) {
  first_dog <- dog_df %>% slice(1)

  argonTabItem(
    tabName = "customize_tab",
    tags$div(
      tags$br(),
      tags$br(),
      tags$div(
        class = "card card-profile shadow px-4",
        # image
        tags$div(
          class = "row",
          tags$div(
            class = "col",
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
                choices = dog_df$name,
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
      ),
      tags$div(hidden(textInput("biotype", "", "raw_bio")))
    )
  )

}

account_tab <- argonTabItem(
  tabName = "account_tab",
  tags$div()
)

ui <- argonDashPage(
  # id = "my_page",
  useShinyjs(),
  sidebar = sidebar,
  body = argonDashBody(
    use_bs_tooltip(),
    tags$head(includeCSS("www/biobuddy.css")),
    tags$head(includeScript("www/biobuddy.js")),
    tags$head(includeScript("https://kit.fontawesome.com/42822e2abc.js")),
    argonTabItems(uiOutput("showcase_tab"), shinyjs::hidden(uiOutput("customize_tab")))
  ),
  footer = footer
)

server <- function(input, output, session) {

  # TODO: Replace this with actual user (via email address)
  # user <- session$userData$user()
  # user$email
  org_id <- "GA553"
  dog_df <- all_dogs %>% filter(organization_id == org_id)

  output$showcase_tab <- renderUI(gen_showcase_tab(dog_df))
  output$customize_tab <- renderUI(gen_customize_tab(dog_df))

  # TODO: Save final result as rds instead of csv, for faster loading
  behaviors <- read_csv(here("app/data/endearing-behaviors.csv"))
  behaviors <- behaviors %>% filter(level > 1) %>% arrange(group_name, desc(level))
  behaviors <- split(behaviors, behaviors$group_name)
  behaviors <- lapply(behaviors, function(x) x$behavior)

  observeEvent(input$`tab-showcase_tab`, {
    shinyjs::hide("customize_tab")
    shinyjs::show("showcase_tab")
    runjs("collapseSidebar()")
  })
  observeEvent(input$`tab-customize_tab`, {
    shinyjs::hide("showcase_tab")
    shinyjs::show("customize_tab")
    runjs("collapseSidebar()")
  })

  # observeEvent(input$view_more, {
  #   shinyjs::runjs("setTabToCustomize();")
  #   shinyjs::hide("showcase_tab")
  #   shinyjs::show("customize_tab")
  # })

  # Temp, for dev purposes:
  observeEvent(input$view_more, {

    tryCatch({

      sign_out_from_shiny(session)
      session$reload()

    }, error = function(err) {

      msg <- "unable to sign out"
      warning(msg)
      warning(conditionMessage(err))

      invisible(NULL)
    })

  })

  chosen_dog <- reactive({
    # Not terribly clever, but choosing to just clear the customized card
    # whenever new dog is chosen.
    output$customize_rewrite_card <- renderUI({
      shiny::tags$div()
    })
    dog_df %>%
      filter(name == input$in_dog_name)
  })

  output$out_img <- renderUI({
    chosen_dog() %$%
      img(
        src = headshot_url,
        class = "rounded-circle"
      )
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
        pickerInput(
          inputId = "end_beh",
          label =  info_icon(
            "beh_info",
            "Endearing behaviors",
            "Does your dog exhibit any of these behaviors?
            Select all those that should be mentioned in the bio."
          ),
          choices = behaviors,
          multiple = TRUE,
          autocomplete = TRUE,
          # TODO: Fix check mark appearing in middle of box
          options = pickerOptions(
            noneSelectedText = "None"
          )
        ),
        textInput(
          "arbit_input",
          label = info_icon(
            "arbit_input_info",
            "Additional instructions",
            "Convey additional instructions just like you would to a human, e.g.,
            'Make the first sentence grab the reader's attention'"
          ),
          value = "",
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
    shinyjs::runjs("tooltipsOn();")
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
      "* Incorporate that the dog exhibits these endearing behaviors:" = input$end_beh,
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

    out <- generic_openai_request(prompt_df)
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

sign_in_page_ui = sign_in_ui_default(
  sign_in_module = sign_in_module_2_ui_bb("sign_in"),
  color = "#5e72e4",
  company_name = "BioBuddy",
  logo_top = tagList(
    tags$img(
      src = "bb-logo-white.svg",
      alt = "BioBuddy",
      style = "width: 100px; margin-top: 30px; margin-bottom: 0px;"
    ),
    tags$head(includeCSS("www/biobuddy.css")),
    tags$div(
      style = "width: 125px; margin-top: 30px; margin-bottom: 30px;"
    ),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/three.js/r121/three.min.js"),
  )
)

shinyApp(
  secure_ui(ui, sign_in_page_ui = sign_in_page_ui),
  secure_server(server)
)
