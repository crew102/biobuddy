# Source code pulled from argonR with some minor changes
dog_card <- function(.x, card_b) {
  tags$div(
    tags$br(),
    tags$br(),
    tags$div(
      class = "card card-profile shadow px-4",
      # image
      tags$div(class = "row",
        tags$div(
          class = "col",
          tags$div(class = "card-profile-image",
            tags$a(
              href = .x["url"],
              img(src = .x["primary_photo_cropped_full"], class = "rounded-circle")
              # use after image processing:
              # img(src = paste0(.x["name"], ".png"), class = "rounded-circle")
            )
          )
        )
      ),
      # name/breed/original bio
      tags$div(
        class = "row",
        tags$div(
          class = "col mt-5",
          tags$div(
            class = "text-center mt-5 pt-5",
            tags$a(
              href = .x["url"],
              .x["name"]
            ),
            tags$div(
              class = "h5 font-weight-300",
              .x["breeds_primary"]
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
              card_b
            )
        )
      )
    )
  )
}

inner_body <- function(.x) {

  HTML(glue('
    <ul class="nav nav-pills">

      <li class="nav-item">
        <a class="nav-link active" href="#tabs-icons-text-0-{.x[\"name\"]}"
           data-toggle="tab" style="margin-right: .75rem">Original</a>
      </li>

      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" data-toggle="dropdown" href="#"
           role="button" aria-expanded="false">Rewrites</a>
        <div class="dropdown-menu">
          <a class="dropdown-item" href="#tabs-icons-text-1-{.x[\"name\"]}" data-toggle="tab">
            <i style="margin-right: 0.5rem!important;" class="fa-solid fa-clipboard-question"></i>
            Interview
          </a>
          <a class="dropdown-item" href="#tabs-icons-text-2-{.x[\"name\"]}" data-toggle="tab">
            <i style="margin-right: 0.5rem!important;" class="fa fa-paw" aria-hidden="true"></i>
            Pup perspective
          </a>
          <a class="dropdown-item" href="#tabs-icons-text-3-{.x[\"name\"]}" data-toggle="tab">
            <i class="ni ni-calendar-grid-58 mr-2"></i>
            Sectioned
          </a>
        </div>
      </li>
    </ul>

    <div class="card shadow">
      <div class="card-body">
        <div class="tab-content" id="{.x[\"name\"]}-tcont">
          <div class="tab-pane fade show active" id="tabs-icons-text-0-{.x[\"name\"]}"
                role="tabpanel" aria-labelledby="tabs-icons-text-0-tab-{.x[\"name\"]}">
            <p>{.x[[\"raw_bio\"]]}</p>
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-1-{.x[\"name\"]}"
                role="tabpanel" aria-labelledby="tabs-icons-text-1-tab-{.x[\"name\"]}">
            {shiny::includeMarkdown(.x[[\"interview_rr\"]])}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-2-{.x[\"name\"]}"
                role="tabpanel" aria-labelledby="tabs-icons-text-2-tab-{.x[\"name\"]}">
            {shiny::includeMarkdown(.x[[\"pupper_rr\"]])}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-3-{.x[\"name\"]}"
                role="tabpanel" aria-labelledby="tabs-icons-text-3-tab-{.x[\"name\"]}">
            {shiny::includeMarkdown(.x[[\"sectioned_rr\"]])}
          </div>
        </div>
      </div>
    </div>

'))
}




footer <- argonDashFooter(
  copyrights = "@biobuddy, 2024",
  src = "https://github.com/crew102",
  argonFooterMenu(
    argonFooterItem("footer 1", src = "https://github.com/RinteRface"),
    argonFooterItem("footer 2", src = "https://demos.creative-tim.com/argon-design-system/index.html")
  )
)
