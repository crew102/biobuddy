#' Call OpenAI Responses API and return raw results
#'
#' Sends parallel requests to the OpenAI Responses API and returns the raw
#' results from \code{httr2::req_perform_parallel()}. This function handles
#' request building and execution but does not extract or process the response
#' content.
#'
#' @param input_developer Character vector or NULL. Developer/system messages
#'   to send to the API. Each element represents a separate developer message.
#'   Can be recycled with other inputs if lengths differ.
#' @param input_user Character vector or NULL. User messages to send to the API.
#'   Each element represents a separate user message. Can be recycled with
#'   other inputs if lengths differ.
#' @param image_paths List or NULL. If list, the list should be of character
#'   vectors containing the paths to the images to use for the relevant API call.
#' @param model Character scalar. The OpenAI model to use for the request.
#'   Defaults to "gpt-5-nano".
#' @param reasoning_effort Character scalar or NULL. Controls the depth of the
#'   model's reasoning process. Must be one of "low", "medium", or "high".
#'   Defaults to NULL (not included in request). Note that this would equate to
#'   using "medium" reasoning, as that's the underlying default.
#'
#' @return List of httr2 response objects or error objects. The exact structure
#'   depends on the results from \code{httr2::req_perform_parallel()} with
#'   \code{on_error = "continue"}.
#'
#' @examples
#' \dontrun{
#' # Make API calls and get raw results
#' results <- call_openai_responses(
#'   input_user = "Hello, how are you?",
#'   model = "gpt-5-nano"
#' )
#' }
call_openai_responses <- function(input_developer = NULL,
                                 input_user = NULL,
                                 image_paths = NULL,
                                 model = "gpt-5-nano",
                                 reasoning_effort = NULL) {
  requests <- .build_openai_responses_request_apply(
    input_developer,
    input_user,
    image_paths,
    model,
    reasoning_effort
  )
  httr2::req_perform_parallel(requests, on_error = "continue")
}

#' Build multiple OpenAI API requests for parallel execution
#'
#' Creates a list of httr2 request objects from input vectors, recycling
#' inputs as needed to match the maximum length. Used internally for parallel
#' request processing.
#'
#' @inheritParams call_openai_responses
#'
#' @return List of httr2 request objects. Each request is ready to be executed
#'   via \code{req_perform()} or \code{req_perform_parallel()}.
#'
#' @seealso \code{\link{.build_openai_responses_request}} for building a single
#'   request.
.build_openai_responses_request_apply <- function(input_developer = NULL,
                                                  input_user = NULL,
                                                  image_paths = NULL,
                                                  model = "gpt-5-nano",
                                                  reasoning_effort = NULL) {
  l <- max(c(length(input_developer), length(input_user), length(image_paths)))

  # Handle empty inputs
  if (length(input_developer) == 0) {
    input_developer <- rep(list(NULL), l)
  } else {
    input_developer <- as.list(input_developer)
  }
  if (length(input_user) == 0) {
    input_user <- rep(list(NULL), l)
  } else {
    input_user <- as.list(input_user)
  }
  if (length(image_paths) == 0) {
    image_paths <- rep(list(NULL), l)
  }

  # Recycle reasoning parameter to match length
  reasoning_effort <- rep(list(reasoning_effort), l)

  purrr::pmap(
    .l = list(
      input_developer = input_developer,
      input_user = input_user,
      image_paths = image_paths,
      reasoning_effort = reasoning_effort
    ),
    .f = function(input_developer, input_user, image_paths,
                  reasoning_effort) {
      .build_openai_responses_request(
        input_developer_atomic = input_developer,
        input_user_atomic = input_user,
        image_paths_vec = image_paths,
        model = model,
        reasoning_effort = reasoning_effort
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
#' @param input_developer_atomic Character scalar or NULL. Developer/system
#'   message to send to the API. Will be added as a message with role
#'   "developer".
#' @param input_user_atomic Character scalar or NULL. User message to send to
#'   the API. Will be added as a message with role "user".
#' @param image_paths_vec Character vector or NULL. File paths to images
#'   to include in the request.
#' @param reasoning_effort Character scalar or NULL. Controls the depth of the
#'   model's reasoning process. Must be one of "low", "medium", or "high".
#'   Defaults to NULL (not included in request).
#'
#' @return An httr2 request object.
#'
#' @seealso \code{\link{.build_openai_responses_request_apply}} for building
#'   multiple requests.
.build_openai_responses_request <- function(input_developer_atomic = NULL,
                                            input_user_atomic = NULL,
                                            image_paths_vec = NULL,
                                            model = "gpt-5-nano",
                                            reasoning_effort = NULL) {
  input <- list()

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

  if (!is.null(input_user_atomic)) {
    input_user <- list(list(
      role = "user",
      content = list(list(
        type = "input_text",
        text = input_user_atomic
      ))
    ))
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

    input_user[[1]]$content <- c(input_user[[1]]$content, image_contents)
  }

  if (!is.null(input_user_atomic)) {
    input <- c(input, input_user)
  }

  payload <- list(
    model = model,
    input = input
  )

  # Add reasoning parameter if provided
  if (!is.null(reasoning_effort)) {
    payload$reasoning <- list(effort = reasoning_effort)
  }

  request("https://api.openai.com/v1/responses") %>%
    req_headers(
      Authorization = paste0("Bearer ", get_secret("OPENAI_API_KEY")),
      "Content-Type" = "application/json"
    ) %>%
    req_body_json(payload) %>%
    # TODO: Use data provided in response re: when you can request next
    req_retry(max_tries = 8, backoff = function(i) runif(1, 2^i, 2^(i + 1))) %>%
    # requests per second
    req_throttle(rate = 20)
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


#' Extract text content from OpenAI API response results
#'
#' Processes a list of httr2 response objects (or error objects) from
#' \code{call_openai_responses()} and extracts text content from each. Handles
#' errors gracefully and returns error descriptions when requests fail.
#'
#' @param results List. Results from \code{call_openai_responses()} or
#'   \code{httr2::req_perform_parallel()}. Each element should be either an
#'   httr2 response object or an error object.
#'
#' @return Character vector. Extracted text content from successful responses,
#'   or error status descriptions (character) for failed requests, or NA if
#'   response could not be parsed.
#'
#' @examples
#' \dontrun{
#' # Get raw results
#' results <- call_openai_responses(
#'   input_user = "Hello, how are you?",
#'   model = "gpt-5-nano"
#' )
#'
#' # Extract text from results
#' text <- extract_openai_responses_text(results)
#' }
extract_openai_responses_text <- function(results) {
  lapply(results, function(x) {
    # Check if x is a response object first
    if (!inherits(x, "httr2_response")) {
      # If it's not a response object, it's likely an error
      return(paste("Error:", as.character(x)))
    }

    if (resp_is_error(x)) {
      return(resp_status_desc(x))
    }

    out <- resp_body_json(x)
    extracted_text <- .extract_response_text(out)
    if (!is.null(extracted_text)) extracted_text else NA
  })
}

#' Extract text content from a single OpenAI API response
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
