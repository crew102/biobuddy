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

## stand ins

navbar <- HTML('
 <nav class="navbar navbar-expand-lg navbar-dark bg-default">
    <div class="container">

      <a class="navbar-brand" href="#">NH177</a>

      <button class="navbar-toggler" type="button" data-toggle="collapse"
              data-target="#navbar-default" aria-controls="navbar-default"
              aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
      </button>

      <div class="collapse navbar-collapse" id="navbar-default">

        <div class="navbar-collapse-header">

          <div class="row">
            <div class="col-6 collapse-brand">
            </div>
            <div class="col-6 collapse-close">
              <button type="button" class="navbar-toggler" data-toggle="collapse"
                  data-target="#navbar-default" aria-controls="navbar-default"
                  aria-expanded="false" aria-label="Toggle navigation">
              <span></span>
              <span></span>
              </button>
            </div>
          </div>

        </div>

        <ul class="navbar-nav ml-lg-auto">

          <li class="nav-item">
            <a class="nav-link nav-link-icon" href="#">
            <i class="ni ni-favourite-28"></i>
            <span class="nav-link-inner--text d-lg-none">Discover</span>
            </a>
          </li>

          <li class="nav-item">
            <a class="nav-link nav-link-icon" href="#">
            <i class="ni ni-notification-70"></i>
            <span class="nav-link-inner--text d-lg-none">Profile</span>
            </a>
          </li>

          <li class="nav-item dropdown">

            <a class="nav-link nav-link-icon" href="#" id="navbar-default_dropdown_1"
               role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <i class="ni ni-settings-gear-65"></i>
            <span class="nav-link-inner--text d-lg-none">Settings</span>
            </a>

            <div class="dropdown-menu dropdown-menu-right"
                 aria-labelledby="navbar-default_dropdown_1">

              <a class="dropdown-item" href="#">Action</a>
              <a class="dropdown-item" href="#">Another action</a>

              <div class="dropdown-divider"></div>
              <a class="dropdown-item" href="#">Something else here</a>

            </div>

          </li>

        </ul>

      </div>
    </div>
  </nav>

')

footer <- argonDashFooter(
  copyrights = "@biobuddy, 2024",
  src = "https://github.com/crew102",
  argonFooterMenu(
    argonFooterItem("footer 1", src = "https://github.com/RinteRface"),
    argonFooterItem("footer 2", src = "https://demos.creative-tim.com/argon-design-system/index.html")
  )
)
