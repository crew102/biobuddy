# taken from argonR with some minor changes
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
            a(
              href = .x["url"],
              img(src = .x["primary_photo_cropped_full"], class = "rounded-circle")
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
            h3(.x["name"]),
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
    <div class="nav-wrapper" style="text-align: start;">
      <ul class="nav nav-pills nav-fill flex-column flex-md-row" id="tabs-icons-text-{.x[\"name\"]}" role="tablist">

        <li class="nav-item">
          <a class="nav-link mb-sm-3 mb-md-0 active" id="tabs-icons-text-1-tab-{.x[\"name\"]}"
            data-toggle="tab" href="#tabs-icons-text-1-{.x[\"name\"]}" role="tab"
            aria-controls="tabs-icons-text-1-{.x[\"name\"]}" aria-selected="true">
              <i class="ni ni-cloud-upload-96 mr-2"></i>

          Home

          </a>
        </li>

        <li class="nav-item">
          <a class="nav-link mb-sm-3 mb-md-0" id="tabs-icons-text-2-tab-{.x[\"name\"]}" data-toggle="tab"
            href="#tabs-icons-text-2-{.x[\"name\"]}" role="tab" aria-controls="tabs-icons-text-2-{.x[\"name\"]}"
            aria-selected="false">
            <i class="ni ni-bell-55 mr-2"></i>

            Profile

          </a>
        </li>

        <li class="nav-item">
          <a class="nav-link mb-sm-3 mb-md-0" id="tabs-icons-text-3-tab-{.x[\"name\"]}" data-toggle="tab"
            href="#tabs-icons-text-3-{.x[\"name\"]}" role="tab" aria-controls="tabs-icons-text-3-{.x[\"name\"]}"
            aria-selected="false">
              <i class="ni ni-calendar-grid-58 mr-2"></i>

              Messages
          </a>
        </li>

      </ul>
    </div>

    <div class="card shadow">
      <div class="card-body">
        <div class="tab-content" id="{.x[\"name\"]}-tcont">

          <div class="tab-pane fade show active" id="tabs-icons-text-1-{.x[\"name\"]}" role="tabpanel" aria-labelledby="tabs-icons-text-1-tab-{.x[\"name\"]}">
            {shiny::includeMarkdown(.x[[\"interview_rr\"]])}
          </div>

          <div class="tab-pane fade" id="tabs-icons-text-2-{.x[\"name\"]}" role="tabpanel" aria-labelledby="tabs-icons-text-2-tab-{.x[\"name\"]}">
            {shiny::includeMarkdown(.x[[\"pupper_rr\"]])}
          </div>

          <div class="tab-pane fade" id="tabs-icons-text-3-{.x[\"name\"]}" role="tabpanel" aria-labelledby="tabs-icons-text-3-tab-{.x[\"name\"]}">
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
      <a class="navbar-brand" href="#">PAW</a>
      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar-default" aria-controls="navbar-default" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbar-default">
        <div class="navbar-collapse-header">
          <div class="row">
            <div class="col-6 collapse-brand">
            </div>
            <div class="col-6 collapse-close">
              <button type="button" class="navbar-toggler" data-toggle="collapse" data-target="#navbar-default" aria-controls="navbar-default" aria-expanded="false" aria-label="Toggle navigation">
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
            <a class="nav-link nav-link-icon" href="#" id="navbar-default_dropdown_1" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <i class="ni ni-settings-gear-65"></i>
            <span class="nav-link-inner--text d-lg-none">Settings</span>
            </a>
            <div class="dropdown-menu dropdown-menu-right" aria-labelledby="navbar-default_dropdown_1">
              <a class="dropdown-item" href="#">Action</a>
              <a class="dropdown-item" href="#">Another action</a>
              <div class="dropdown-divider"></div>
              <a class="dropdown-item"
              href="#">Something else here</a>
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
    argonFooterItem("blahblah", src = "https://github.com/RinteRface"),
    argonFooterItem("hi there", src = "https://demos.creative-tim.com/argon-design-system/index.html")
  )
)

