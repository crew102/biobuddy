parallel_request_rewrites <- function(prompt_df, raw_bios,
                                      model = "gpt-5-nano") {
  reqs <- lapply(raw_bios, function(x) {
    # Update the last row's content with the new bio
    prompt_df[nrow(prompt_df), "content"] <- x

    # Convert prompt_df to list of messages (role + content pairs)
    input_messages <- lapply(seq_len(nrow(prompt_df)), function(i) {
      list(
        role = prompt_df$role[i],
        content = prompt_df$content[i]
      )

    })
    payload <- list(
      model = model,
      input = input_messages
    )

    httr2::request("https://api.openai.com/v1/responses") %>%
      httr2::req_headers(
        Authorization = paste0("Bearer ", get_secret("OPENAI_API_KEY")),
        "Content-Type" = "application/json"
      ) %>%
      httr2::req_body_json(payload)
  })

  resps <- httr2::req_perform_parallel(reqs, on_error = "continue")

  vapply(resps, function(x) {
    if (httr2::resp_is_error(x)) {
      return(httr2::resp_status_desc(x))
    }
    out <- httr2::resp_body_json(x)
    extracted_text <- extract_response_text(out)
    if (!is.null(extracted_text)) extracted_text else NA_character_
  }, character(1))
}

generic_openai_request <- function(prompt_df, model = "gpt-5-nano") {
  # Convert prompt_df to list of messages (role + content pairs)
  input_messages <- lapply(seq_len(nrow(prompt_df)), function(i) {
    list(
      role = prompt_df$role[i],
      content = prompt_df$content[i]
    )
  })

  payload <- list(
    model = model,
    input = input_messages
  )

  req <- httr2::request("https://api.openai.com/v1/responses") %>%
    httr2::req_headers(
      Authorization = paste0("Bearer ", get_secret("OPENAI_API_KEY")),
      "Content-Type" = "application/json"
    ) %>%
    httr2::req_body_json(payload)

  resp <- httr2::req_perform(req)
  if (httr2::resp_is_error(resp)) {
    return(httr2::resp_status_desc(resp))
  }
  out <- httr2::resp_body_json(resp)
  extracted_text <- extract_response_text(out)
  if (!is.null(extracted_text)) extracted_text else out
}

# Function to encode image to base64
encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    stop("Image file does not exist: ", image_path)
  }
  image_data <- readBin(image_path, "raw", file.info(image_path)$size)
  base64enc::base64encode(image_data)
}

# Extract text from OpenAI API response with fallback logic
extract_response_text <- function(result) {
  # Handle Responses API format (newer format)
  if (!is.null(result$output) && length(result$output) > 0) {
    # Find the last output item (usually contains the response)
    last_output <- result$output[[length(result$output)]]

    if (!is.null(last_output$content)) {
      # Look for text content items using purrr::detect
      text_item <- purrr::detect(last_output$content, function(x) {
        x$type %in% c("output_text", "text")
      })

      if (!is.null(text_item)) {
        return(text_item$text)
      }
    }
  }

  # Handle Chat Completions API format (legacy format)
  if (!is.null(result$choices) && length(result$choices) > 0) {
    return(result$choices[[1]]$message$content)
  }

  NULL
}

openai_responses_request <- function(prompt, model = "gpt-5-nano",
                                     image_paths = NULL) {
  content_list <- list()

  # Add images if provided
  if (!is.null(image_paths) && length(image_paths) > 0) {
    image_contents <- purrr::map(image_paths, ~ {
      base64_image <- encode_image(.x)
      list(
        type = "input_image",
        image_url = paste0("data:image/jpeg;base64,", base64_image),
        detail = "auto"
      )
    })
    content_list <- c(content_list, image_contents)
  }

  # Add text prompt
  content_list <- c(content_list, list(list(
    type = "input_text",
    text = prompt
  )))

  input <- list(
    list(
      type = "message",
      role = "user",
      content = content_list
    )
  )

  payload <- list(
    model = model,
    input = input
  )

  resp <- httr2::request("https://api.openai.com/v1/responses") %>%
    httr2::req_headers(
      Authorization = paste0("Bearer ", get_secret("OPENAI_API_KEY")),
      "Content-Type" = "application/json"
    ) %>%
    httr2::req_body_json(payload) %>%
    httr2::req_perform()

  if (httr2::resp_is_error(resp)) {
    return(httr2::resp_status_desc(resp))
  }
  out <- httr2::resp_body_json(resp)
  extracted_text <- extract_response_text(out)
  if (!is.null(extracted_text)) extracted_text else out
}
