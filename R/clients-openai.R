make_openai_responses_roundtrip <- function(input_user = NULL,
                                            input_developer = NULL,
                                            image_paths = NULL,
                                            model = "gpt-5-nano") {
  requests <- build_openai_responses_request_apply(
    input_user, input_developer, image_paths, model
  )
  results <- req_perform_parallel(requests, on_error = "continue")

  lapply(results, function(x) {
    if (resp_is_error(x)) {
      return(resp_status_desc(x))
    }
    out <- resp_body_json(x)
    extracted_text <- extract_response_text(out)
    if (!is.null(extracted_text)) extracted_text else NA
  })
}

build_openai_responses_request_apply <- function(input_user = NULL,
                                                 input_developer = NULL,
                                                 image_paths = NULL,
                                                 model = "gpt-5-nano") {
  l <- max(c(length(input_user), length(input_developer), length(image_paths)))

  if (length(input_user) == 0) {
    input_user <- rep(list(NULL), l)
  }
  if (length(input_developer) == 0) {
    input_developer <- rep(list(NULL), l)
  }
  if (length(image_paths) == 0) {
    image_paths <- rep(list(NULL), l)
  }

  purrr::pmap(
    .l = list(
      input_user = input_user,
      input_developer = input_developer,
      image_paths = image_paths
    ),
    .f = function(input_user, input_developer, image_paths) {
      build_openai_responses_request(
        input_user = input_user,
        input_developer = input_developer,
        image_paths = image_paths,
        model = model
      )
    }
  )
}

build_openai_responses_request <- function(input_user = NULL,
                                           input_developer = NULL,
                                           image_paths = NULL, # can be non-atomic
                                           model = "gpt-5-nano") {
  input <- list()

  if (!is.null(input_user)) {
    input <- c(
      input,
      list(list(
        role = "user",
        content = list(list(
          type = "input_text",
          text = input_user
        ))
      ))
    )
  }

  if (!is.null(input_developer)) {
    input <- c(
      input,
      list(list(
        role = "developer",
        content = list(list(
          type = "input_text",
          text = input_developer
        ))
      ))
    )
  }

  if (!is.null(image_paths)) {
    image_contents <- purrr::map(image_paths, ~ {
      base64_image <- encode_image(.x)
      list(
        type = "input_image",
        image_url = paste0("data:image/jpeg;base64,", base64_image),
        detail = "auto"
      )
    })

    input[[1]]$content <- c(input[[1]]$content, image_contents)
  }


  payload <- list(
    model = model,
    input = input
  )

  request("https://api.openai.com/v1/responses") %>%
    req_headers(
      Authorization = paste0("Bearer ", get_secret("OPENAI_API_KEY")),
      "Content-Type" = "application/json"
    ) %>%
    req_body_json(payload) %>%
    # TODO: Use data provided in response re: when you can request next
    req_retry(max_tries = 8, backoff = function(i) runif(1, 2^i, 2^(i + 1))) %>%
    # requests per second
    req_throttle(rate = 5)
}

encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    stop("Image file does not exist: ", image_path)
  }
  image_data <- readBin(image_path, "raw", file.info(image_path)$size)
  base64enc::base64encode(image_data)
}

extract_response_text <- function(result) {
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
