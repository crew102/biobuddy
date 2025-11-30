# =============================================================================
# SENIOR LONG STAYS DOG VIEWER APP
# =============================================================================
# Minimal Shiny app to view details and photos of senior long stay dogs

library(shiny)
library(here)
library(dplyr)
library(readr)

devtools::load_all()

# Load data
pet_data <- read_rds(here("dev/pf-db-download/data/final-df.rds"))
random_seniors <- pet_data %>%
  filter(between(yrs_on_pf, .5, 1)) %>%
  filter(age == "Senior") %>%
  filter(bio_len >= 50) %>%
  sample_n(50)

# Helper function to sanitize filename (matching download script)
.sanitize_filename <- function(name) {
  sanitized <- gsub("[^a-zA-Z0-9._-]", "_", name)
  sanitized <- gsub("_{2,}", "_", sanitized)
  sanitized <- gsub("^_+|_+$", "", sanitized)
  sanitized
}

# Helper function to find image file
.find_image_file <- function(org_id, pet_name, image_dir) {
  org_dir <- file.path(image_dir, as.character(org_id))
  if (!dir.exists(org_dir)) {
    return(NULL)
  }

  safe_name <- .sanitize_filename(pet_name)
  all_files <- list.files(org_dir, full.names = TRUE)

  # Look for file matching sanitized name
  pattern <- paste0("^", gsub(".", "\\.", safe_name, fixed = TRUE), "\\.")
  matching_files <- all_files[grepl(pattern, basename(all_files))]

  if (length(matching_files) > 0) {
    return(matching_files[1])
  }

  return(NULL)
}

# UI
ui <- fluidPage(
  titlePanel("Senior Long Stay Dogs"),
  tags$style(HTML("
    .dog-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 15px;
      margin-bottom: 20px;
      background-color: #f9f9f9;
    }
    .dog-image {
      max-width: 300px;
      max-height: 300px;
      border-radius: 4px;
      margin-right: 20px;
      float: left;
    }
    .dog-details {
      overflow: hidden;
    }
    .dog-name {
      font-size: 24px;
      font-weight: bold;
      margin-bottom: 10px;
      color: #333;
    }
    .dog-info {
      margin-bottom: 8px;
    }
    .dog-bio {
      margin-top: 15px;
      line-height: 1.6;
      color: #555;
    }
    .no-image {
      color: #999;
      font-style: italic;
    }
  ")),
  mainPanel(
    width = 12,
    uiOutput("dog_cards")
  )
)

# Server
server <- function(input, output, session) {
  image_dir <- here("dev/pf-db-download/data/pet-images")

  # Add resource path for images
  addResourcePath("pet_images", image_dir)

  output$dog_cards <- renderUI({
    cards <- lapply(seq_len(nrow(random_seniors)), function(i) {
      dog <- random_seniors[i, ]

      # Find image
      image_file <- .find_image_file(
        dog$organization_id,
        dog$name,
        image_dir
      )

      # Build image HTML
      if (!is.null(image_file) && file.exists(image_file)) {
        # Construct relative path: org_id/filename
        rel_path <- file.path(
          as.character(dog$organization_id),
          basename(image_file)
        )
        image_html <- tags$img(
          src = file.path("pet_images", rel_path),
          class = "dog-image",
          alt = paste("Photo of", dog$name)
        )
      } else {
        image_html <- tags$p(class = "no-image", "No photo available")
      }

      # Format tags
      tags_text <- ""
      if (!is.null(dog$tags) && length(dog$tags) > 0) {
        tags_list <- unlist(dog$tags)
        if (length(tags_list) > 0) {
          tags_text <- paste(tags_list, collapse = ", ")
        }
      }

      # Build card
      tags$div(
        class = "dog-card",
        image_html,
        tags$div(
          class = "dog-details",
          tags$div(class = "dog-name", dog$name),
          tags$div(
            class = "dog-info",
            tags$strong("Organization: "), dog$organization_name, br(),
            tags$strong("Location: "),
            paste(dog$organization_city, dog$organization_state, sep = ", "), br(),
            tags$strong("Breed: "), ifelse(is.na(dog$breeds_primary), "Unknown", dog$breeds_primary), br(),
            tags$strong("Age: "), dog$age, br(),
            tags$strong("Gender: "), ifelse(is.na(dog$gender), "Unknown", dog$gender), br(),
            tags$strong("Size: "), ifelse(is.na(dog$size), "Unknown", dog$size), br(),
            tags$strong("Color: "), ifelse(is.na(dog$colors_primary), "Unknown", dog$colors_primary), br(),
            if (nchar(tags_text) > 0) {
              list(
                tags$strong("Tags: "), tags_text, br()
              )
            },
            tags$strong("Years on Petfinder: "), round(dog$yrs_on_pf, 2), br(),
            tags$strong("Petfinder URL: "),
            tags$a(href = dog$url, target = "_blank", dog$url), br()
          ),
          if (!is.na(dog$bio_text) && nchar(dog$bio_text) > 0) {
            tags$div(
              class = "dog-bio",
              tags$strong("Bio: "), br(),
              tags$pre(style = "white-space: pre-wrap; font-family: inherit;",
                      dog$bio_text)
            )
          }
        ),
        tags$div(style = "clear: both;")
      )
    })

    do.call(tagList, cards)
  })
}

# Run app
shinyApp(ui = ui, server = server)

