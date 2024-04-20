# Source code pulled from argonR with some minor changes
dog_card <- function(id, name, profile_url, breed, card_b) {

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
            img(src = paste0(".bio-images/", id, ".png"), class = "rounded-circle")
          )
        )
      ),
      # name/breed
      tags$div(
        class = "row",
        tags$div(
          class = "col mt-5",
          tags$div(
            class = "text-center mt-5 pt-5",
            tags$a(
              href = profile_url,
              name
            ),
            tags$div(
              class = "h5 font-weight-300",
              breed
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

inner_body <- function(id, raw_bio,
                       interview_rr, pupper_rr, sectioned_rr,
                       tab_num = 1,
                       limit_growth = FALSE,
                       customize = FALSE) {

  if (limit_growth) {
    style <- 'style="overflow-y: scroll; height:auto; max-height: 50vh;"'
  } else {
    style <- ''
  }

  if (customize) {
    cust <-
      # '<div style="display:flex">
      #   <a href="#"
      #   class="badge badge-pill badge-default"
      #   data-toggle="modal"
      #   data-target="#modal-form">Customize</a>
      # </div>'

    '<div style="display:flex">
        <a href="#" id="show" class="badge badge-pill badge-default action-button">Customize</a>
    </div>'
  } else {
    cust <- ''
  }

  HTML(glue('
    <ul class="nav nav-pills">

      <li class="nav-item">
        <a class="nav-link active" href="#tabs-icons-text-0-{id}-{tab_num}"
           data-toggle="tab" style="margin-right: .75rem">Original</a>
      </li>

      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" data-toggle="dropdown" href="#"
           role="button">Rewrites</a>
        <div class="dropdown-menu">
          <a class="dropdown-item" href="#tabs-icons-text-1-{id}-{tab_num}" data-toggle="tab">
            <i style="margin-right: 0.5rem!important;" class="fa-solid fa-clipboard-question"></i>
            Interview
          </a>
          <a class="dropdown-item" href="#tabs-icons-text-2-{id}-{tab_num}" data-toggle="tab">
            <i style="margin-right: 0.5rem!important;" class="fa fa-paw"></i>
            Pup perspective
          </a>
          <a class="dropdown-item" href="#tabs-icons-text-3-{id}-{tab_num}" data-toggle="tab">
            <i class="ni ni-calendar-grid-58 mr-2"></i>
            Sectioned
          </a>
        </div>
      </li>
    </ul>

    {cust}

    <div class="card shadow">
      <div class="card-body">
        <div class="tab-content" id="{id}-{tab_num}-tcont" {style}>
          <div class="tab-pane fade show active" id="tabs-icons-text-0-{id}-{tab_num}"
                role="tabpanel">
            <p>{raw_bio}</p>
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-1-{id}-{tab_num}"
                role="tabpanel">
            {shiny::includeMarkdown(interview_rr)}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-2-{id}-{tab_num}"
                role="tabpanel">
            {shiny::includeMarkdown(pupper_rr)}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-3-{id}-{tab_num}"
                role="tabpanel">
            {shiny::includeMarkdown(sectioned_rr)}
          </div>
        </div>
      </div>
    </div>
  '))
}

# Almost verbatim from argonDash, with a bugfix: "collapse navbar-collapse my--4"
# to "collapse navbar-collapse my-4" and positioning of logo to be non-flex
argonDashSidebar <- function(..., dropdownMenus = NULL, id, brand_url = NULL,
    brand_logo = NULL, vertical = TRUE, side = c("left", "right"),
    size = c("s", "md", "lg"), skin = c("light", "dark"), background = "white") {
  side <- match.arg(side)
  size <- match.arg(size)
  skin <- match.arg(skin)
  sidebarCl <- "navbar sidenav"
  if (vertical) {
    sidebarCl <- paste0(sidebarCl, " navbar-vertical")
  } else {
    sidebarCl <- paste0(sidebarCl, " navbar-horizontal")
  }
  if (!is.null(side)) {
    sidebarCl <- paste0(sidebarCl, " fixed-", side)
  }
  if (!is.null(size)) {
    sidebarCl <- paste0(sidebarCl, " navbar-collapse-s")
  }
  if (!is.null(skin)) {
    sidebarCl <- paste0(sidebarCl, " navbar-", skin)
  }
  if (!is.null(background)) {
    sidebarCl <- paste0(sidebarCl, " bg-", background)
  }
  items <- list(...)
  if (!vertical) {
    for (i in seq_along(items)) {
      if (items[[i]]$attribs[["class"]] == "nav-wrapper") {
        items[[i]]$children[[1]]$attribs$class <- "nav"
        items[[i]]$children[[1]]$attribs[["aria-orientation"]] <- "horizontal"
      }
    }
  }
  shiny::tags$nav(class = sidebarCl, id = id, shiny::tags$div(
    class = "container-fluid",
    shiny::tags$button(
      `aria-control` = id, `aria-expanded` = "false",
      `aria-label` = "Toggle navigation", class = "navbar-toggler collapsed",
      `data-target` = "#sidenav-collapse-main", `data-toggle` = "collapse",
      type = "button", shiny::tags$span(class = "navbar-toggler-icon")
    ),
    shiny::a(
      class = "navbar-brand  ml-auto", href = brand_url,
      target = "_blank", shiny::img(
        class = "navbar-brand-img",
        src = brand_logo
      )
    ), shiny::tags$ul(
      class = "nav align-items-center d-md-none",
      dropdownMenus
    ), shiny::tags$div(
      class = "collapse navbar-collapse my-4",
      id = "sidenav-collapse-main", shiny::tags$div(
        class = "navbar-collapse-header d-md-none",
        shiny::fluidRow(
          shiny::tags$div(
            class = "col-6 collapse-brand",
            shiny::a(
              href = brand_url, target = "_blank",
              shiny::img(class = "navbar-brand-img", src = brand_logo)
            )
          ),
          shiny::tags$div(
            class = "col-6 collapse-close",
            shiny::tags$button(
              `aria-control` = id, `aria-expanded` = "true",
              `aria-label` = "Toggle sidenav", class = "navbar-toggler",
              `data-target` = "#sidenav-collapse-main",
              `data-toggle` = "collapse", type = "button",
              shiny::tags$span(), shiny::tags$span()
            )
          )
        )
      ),
      items
    )
  ))
}

argonSidebarItem <- function (..., tabName = NULL, icon = NULL) {
  shiny::tags$a(
    # adding action-button class so shiny will respond on the server side
    class = "nav-link mt-1 mb-1 mx-2 shadow action-button",
    id = paste0("tab-", tabName),
    href = paste0("#shiny-tab-", tabName),
    `data-toggle` = "tab", `data-value` = tabName, icon,
    ...
  )
}

argonSidebarMenu <- function(id, ...) {
  shiny::tags$div(
    class = "nav-wrapper my-4",
    shiny::tags$div(
      class = "nav flex-column nav-pills",
      `aria-orientation` = "vertical",
      id = id,
      ...
    )
  )
}

## stand ins

footer <- argonDashFooter(
  copyrights = "@biobuddy, 2024",
  src = "https://github.com/crew102",
  argonFooterMenu(
    argonFooterItem("footer 1", src = "https://github.com/RinteRface"),
    argonFooterItem("footer 2", src = "https://demos.creative-tim.com/argon-design-system/index.html")
  )
)
