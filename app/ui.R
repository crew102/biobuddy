# Source code pulled from argonR with some minor changes
dog_card <- function(name, profile_url, headshot_url, breed, card_b) {

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
            img(
              src = headshot_url,
              class = "rounded-circle"
            )
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
                       interview_rw, pupper_rw, sectioned_rw,
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
      '<div style="display:flex">
          <a href="#" id="show" class="customize customize-pill badge badge-pill
          badge-default action-button" onclick="setBioType()">Customize</a>
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

    <div class="card shadow">
      <div class="card-body">
          {cust}
        <div class="tab-content" id="{id}-{tab_num}-tcont" {style}>
          <div class="tab-pane fade show active" id="tabs-icons-text-0-{id}-{tab_num}"
               role="tabpanel" biotype="raw_bio">
            <p>{raw_bio}</p>
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-1-{id}-{tab_num}"
                role="tabpanel" biotype="interview_rw">
            {shiny::includeMarkdown(interview_rw)}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-2-{id}-{tab_num}"
                role="tabpanel" biotype="pupper_rw">
            {shiny::includeMarkdown(pupper_rw)}
          </div>
          <div class="tab-pane fade" id="tabs-icons-text-3-{id}-{tab_num}"
                role="tabpanel" biotype="sectioned_rw">
            {shiny::includeMarkdown(sectioned_rw)}
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

# Taken from argonDash with Waiter dependency added
addDeps <- function(x) {
  dashboardDeps <- list(
    # argonDash custom js
    htmltools::htmlDependency(
      name = "argonDash",
      version = as.character(utils::packageVersion("argonDash")),
      src = c(file = system.file("argonDash-0.1.0", package = "argonDash")),
      script = "argonDash.js"
    ),
    htmltools::htmlDependency(
      name = "bootstrap",
      version = "4.1.3",
      src = c(file = system.file("bootstrap-4.1.3", package = "argonDash")),
      script = "bootstrap.bundle.min.js"
    ),
    htmltools::htmlDependency(
      name = "googlefonts",
      version = as.character(utils::packageVersion("argonDash")),
      src = c(href = "https://fonts.googleapis.com/css?family=Open+Sans:300,400,600,700"),
      stylesheet = ""
    ),
    htmltools::htmlDependency(
      name = "nucleo",
      version = as.character(utils::packageVersion("argonDash")),
      src = c(file = system.file("nucleo-0.1.0", package = "argonDash")),
      stylesheet = "nucleo.css"
    ),
    htmltools::htmlDependency(
      name = "fontawesome",
      version = "5.3.1",
      src = c(file = system.file("fontawesome-5.3.1", package = "argonDash")),
      stylesheet = "all.min.css"
    ),
    htmltools::htmlDependency(
      name = "argon",
      version = "1.0.0",
      src = c(file = system.file("argon-1.0.0", package = "argonDash")),
      stylesheet = "argon.min.css",
      script = "argon.min.js"
    ),
    htmltools::htmlDependency(
      name = "waiter",
      version = utils::packageVersion("waiter"),
      src = "packer",
      package = "waiter",
      script = "waiter.js"
    )

  )
  argonDash:::appendDependencies(x, dashboardDeps)
}

# Same as argonDash, except I need to redefine it here so that addDeps uses
# my version
argonDashPage <- function(title = NULL, description = NULL, author = NULL,
                          navbar = NULL, sidebar = NULL, header = NULL,
                          body = NULL, footer = NULL){

  shiny::tags$html(
    # Head
    shiny::tags$head(
      shiny::tags$meta(charset = "utf-8"),
      shiny::tags$meta(
        name = "viewport",
        content = "width=device-width, initial-scale=1, shrink-to-fit=no"
      ),
      shiny::tags$meta(name = "description", content = description),
      shiny::tags$meta(name = "author", content = author),
      shiny::tags$title(title)
    ),
    # Body
    addDeps(
      shiny::tags$body(
        sidebar,
        shiny::tags$div(
          class = "main-content",
          navbar,
          header,
          # page content
          shiny::tags$div(
            class = "container-fluid mt--1",
            body,
            footer
          )
        )
      )
    )
  )
}

footer <- argonDashFooter(
  copyrights = "@biobuddy, 2024",
  src = "https://github.com/crew102/biobuddy/blob/main/LICENSE.md"
)


# https://developers.google.com/identity/branding-guidelines
google_sign_in_button <- HTML('
  <div id="sign_in-providers_ui">
    <button class="gsi-material-button" id="sign_in-sign_in_with_google">
      <div class="gsi-material-button-state"></div>
      <div class="gsi-material-button-content-wrapper">
        <div class="gsi-material-button-icon">
          <svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" xmlns:xlink="http://www.w3.org/1999/xlink" style="display: block;">
            <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path>
            <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path>
            <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path>
            <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path>
            <path fill="none" d="M0 0h48v48H0z"></path>
          </svg>
        </div>
        <span class="gsi-material-button-contents">Sign in with Google</span>
        <span style="display: none;">Sign in with Google</span>
      </div>
    </button>
    <br/>
    <br/>
  </div>
')

# Tweaked from polished original:
# https://github.com/Tychobra/polished/blob/master/R/sign_in_module_2.R
# IMPORTANT: The names of inputs and namespaces have to align with those chosen
# by polished.
sign_in_module_2_ui_bb <- function(id) {
  ns <- shiny::NS(id)

  sign_in_email_ui <- tags$div(
    id = ns("email_ui"),
    tags$br(),
    tags$div(
      style = "text-align: left;",
      email_input("sign_in-sign_in_email")
    ),
    tags$div(
      id = ns("sign_in_panel_bottom"),
      div(
        id = ns("sign_in_password_ui"),
        div(
          class = "form-group",
          style = "width: 100%; text-align: left;",
          tags$label(
            tagList(icon("unlock-alt"), "Password"),
            class = "control-label",
            `for` = ns("sign_in_password")
          ),
          tags$input(
            id = ns("sign_in_password"),
            type = "password",
            class = "form-control",
            value = ""
          )
        ),
        shinyFeedback::loadingButton(
          ns("sign_in_submit"),
          label = "Sign In",
          class = "btn btn-primary btn-lg text-center",
          style = "width: 30%; font-size: 1.2rem; letter-spacing: 0.025em;",
          loadingLabel = "",
          loadingClass = "btn btn-primary btn-lg text-center",
          loadingStyle = "width: 30%; font-size: 1.2rem; letter-spacing: 0.025em;"
        )
      ),
      div(
        style = "text-align: center;",
        br(),
        send_password_reset_email_module_ui(ns("reset_password"))
      )
    )
  )

  continue_registration <- div(
    id = ns("continue_registration"),
    shiny::actionButton(
      inputId = ns("submit_continue_register"),
      label = "Register",
      class = "btn btn-primary btn-lg text-center",
      style = "width: 30%; font-size: 1.2rem; letter-spacing: 0.025em; margin-bottom: 10px"
    )
  )

  register_passwords <- div(
    id = ns("register_passwords"),
    div(
      class = "form-group",
      style = "width: 100%; text-align: left;",
      tags$label(
        tagList(icon("unlock-alt"), "password"),
        class = "control-label",
        `for` = ns("register_password")
      ),
      tags$input(
        id = ns("register_password"),
        type = "password",
        class = "form-control",
        value = ""
      )
    ),
    div(
      class = "form-group shiny-input-container",
      style = "width: 100%",
      tags$label(
        tagList(shiny::icon("unlock-alt"), "verify password"),
        class = "control-label",
        `for` = ns("register_password_verify")
      ),
      tags$input(
        id = ns("register_password_verify"),
        type = "password",
        class = "form-control",
        value = ""
      )
    ),
    div(
      style = "text-align: center;",
      shinyFeedback::loadingButton(
        ns("register_submit"),
        label = "Register",
        class = "btn btn-primary btn-lg",
        style = "width: 100%",
        loadingLabel = "",
        loadingClass = "btn btn-primary btn-lg text-center",
        loadingStyle = "width: 100%"
      )
    )
  )

  register_ui <- div(
    br(),
    tags$div(
      style = "text-align: left;",
      email_input("sign_in-register_email")
    ),
    tagList(continue_registration, shinyjs::hidden(register_passwords))
  )

  sign_in_email_ui <- tags$div(
    sign_in_email_ui,
    tags$br(),
    google_sign_in_button
  )

  sign_in_register_email <- shiny::tabsetPanel(
    id = ns("tabs"),
    shiny::tabPanel("Sign In", sign_in_email_ui),
    shiny::tabPanel("Register", register_ui)
  )

  sign_in_ui <- tags$div(
    class = "auth_panel",
    sign_in_register_email
  )

  htmltools::tagList(
    shinyjs::useShinyjs(),
    sign_in_ui,
    tags$script(src = "polish/js/auth_keypress.js?version=2"),
    tags$script(paste0("auth_keypress('", ns(''), "')")),
    tags$script(
      "$('input').attr('autocomplete', 'off');"
    ),
    sign_in_js(ns)
  )
}
