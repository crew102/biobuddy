library(shiny)
library(polished)

polished_config(
  app_name = "biobuddy-dev",
  api_key = Sys.getenv("POLISHED_API_KEY")
)

ui <- fluidPage(
  fluidRow(
    column(
      6,
      h1("Hello Shiny!")
    ),
    column(
      6,
      br(),
      actionButton(
        "sign_out",
        "Sign Out",
        icon = icon("sign-out-alt"),
        class = "pull-right"
      )
    ),
    column(
      12,
      verbatimTextOutput("user_out")
    )
  )
)

server <- function(input, output, session) {
  output$user_out <- renderPrint({
    session$userData$user()
  })

  observeEvent(input$sign_out, {
    sign_out_from_shiny()
    session$reload()
  })
}

shinyApp(
  secure_ui(ui),
  secure_server(server)
)
