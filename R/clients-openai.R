#' Make OpenAI API requests and extract response text
#'
#' Sends parallel requests to the OpenAI Responses API and extracts text content
#' from the responses. Handles errors gracefully and returns error descriptions
#' when requests fail.
#'
#' @param input_user Character vector or NULL. User messages to send to the API.
#'   Each element represents a separate user message. Can be recycled with
#'   other inputs if lengths differ.
#' @param input_developer Character vector or NULL. Developer/system messages
#'   to send to the API. Each element represents a separate developer message.
#'   Can be recycled with other inputs if lengths differ.
#' @param image_paths List or NULL. If list, the list should be of character
#'   vectors containing the paths to the images to use for the relevant API call.
#' @param model Character scalar. The OpenAI model to use for the request.
#'   Defaults to "gpt-5-nano".
#'
#' @return Character vector. Extracted text content from successful responses,
#'   or error status descriptions (character) for failed requests, or NA if
#'   response could not be parsed.
#'
#' @examples
#' \dontrun{
#' # Simple text request
#' make_openai_responses_roundtrip(
#'   input_user = "Hello, how are you?",
#'   model = "gpt-5-nano"
#' )
#'
#' # Multiple requests with images
#' make_openai_responses_roundtrip(
#'   input_user = c("What's in this image?", "And this one?"),
#'   image_paths = list(c("image1.jpg"), c("image2.jpg")),
#'   model = "gpt-5-nano"
#' )
#' }
make_openai_responses_roundtrip <- function(input_user = NULL,
                                            input_developer = NULL,
                                            image_paths = NULL,
                                            model = "gpt-5-nano") {
  requests <- .build_openai_responses_request_apply(
    input_user, input_developer, image_paths, model
  )
  results <- req_perform_parallel(requests, on_error = "continue")

  lapply(results, function(x) {
    if (resp_is_error(x)) {
      return(resp_status_desc(x))
    }
    out <- resp_body_json(x)
    extracted_text <- .extract_response_text(out)
    if (!is.null(extracted_text)) extracted_text else NA
  })
}

#' Build multiple OpenAI API requests for parallel execution
#'
#' Creates a list of httr2 request objects from input vectors, recycling
#' inputs as needed to match the maximum length. Used internally for parallel
#' request processing.
#'
#' @inheritParams make_openai_responses_roundtrip
#'
#' @return List of httr2 request objects. Each request is ready to be executed
#'   via \code{req_perform()} or \code{req_perform_parallel()}.
#'
#' @seealso \code{\link{.build_openai_responses_request}} for building a single
#'   request.
.build_openai_responses_request_apply <- function(input_user = NULL,
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
      .build_openai_responses_request(
        input_user_atomic = input_user,
        input_developer_atomic = input_developer,
        image_paths_vec = image_paths,
        model = model
      )
    }
  )
}

#' Build a single OpenAI API request
#'
#' Constructs an httr2 request object for the OpenAI Responses API v1 endpoint.
#' Supports text messages (user and developer roles) and image inputs. Includes
#' retry logic and rate throttling.
#'
#' @param input_user_atomic Character scalar or NULL. User message to send to
#'   the API. Will be added as a message with role "user".
#' @param input_developer_atomic Character scalar or NULL. Developer/system
#'   message to send to the API. Will be added as a message with role
#'   "developer".
#' @param image_paths_vec Character vector or NULL. File paths to images
#'   to include in the request.
#' @inheritParams make_openai_responses_roundtrip
#'
#' @return An httr2 request object. Configured with:
#'   \itemize{
#'     \item Authorization header with OpenAI API key
#'     \item JSON body with model and input messages
#'     \item Retry logic (max 8 tries with exponential backoff)
#'     \item Rate throttling (5 requests per second)
#'   }
#'
#' @seealso \code{\link{.build_openai_responses_request_apply}} for building
#'   multiple requests.
.build_openai_responses_request <- function(input_user_atomic = NULL,
                                            input_developer_atomic = NULL,
                                            image_paths_vec = NULL,
                                            model = "gpt-5-nano") {
  input <- list()

  if (!is.null(input_user_atomic)) {
    input <- c(
      input,
      list(list(
        role = "user",
        content = list(list(
          type = "input_text",
          text = input_user_atomic
        ))
      ))
    )
  }

  if (!is.null(input_developer_atomic)) {
    input <- c(
      input,
      list(list(
        role = "developer",
        content = list(list(
          type = "input_text",
          text = input_developer_atomic
        ))
      ))
    )
  }

  if (!is.null(image_paths_vec)) {
    image_contents <- purrr::map(image_paths_vec, ~ {
      base64_image <- .encode_image(.x)
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

#' Encode an image file to base64
#'
#' Reads an image file from disk and encodes it as a base64 string, suitable
#' for embedding in API requests.
#'
#' @param image_path Character scalar. Path to an image file. Must exist and
#'   be readable.
#'
#' @return Character scalar. Base64-encoded string representation of the image
#'   file contents.
#'
#' @examples
#' \dontrun{
#' # Encode an image file
#' base64_string <- .encode_image("path/to/image.jpg")
#' }
.encode_image <- function(image_path) {
  if (!file.exists(image_path)) {
    stop("Image file does not exist: ", image_path)
  }
  image_data <- readBin(image_path, "raw", file.info(image_path)$size)
  base64enc::base64encode(image_data)
}

#' Extract text content from OpenAI API response
#'
#' Parses a JSON response from the OpenAI API and extracts text content.
#' Supports both the Responses API format (new) and Chat Completions API
#' format (legacy).
#'
#' @param result List. Parsed JSON response from the OpenAI API. Expected to
#'   contain either:
#'   \itemize{
#'     \item \code{output}: List of output items with \code{content} containing
#'       items with \code{type} "output_text" or "text" (Responses API format)
#'     \item \code{choices}: List with message content (Chat Completions API
#'       format, legacy)
#'   }
#'
#' @return Character scalar or NULL. Extracted text content from the response,
#'   or NULL if no text content could be found.
#'
#' @details For Responses API format, extracts text from the last output item's
#'   content, looking for items with type "output_text" or "text". For legacy
#'   Chat Completions format, extracts content from the first choice's message.
.extract_response_text <- function(result) {
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
