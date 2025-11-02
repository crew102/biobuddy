library(testthat)
library(biobuddy)
library(here)

# Test 1: Basic test with user_input and input_developer
test_that("openai_responses_request works with user_input and input_developer", {
  # Skip test if no API key is available
  skip_if_not(
    nzchar(Sys.getenv("OPENAI_API_KEY")),
    "OpenAI API key not available"
  )

  user_input <- "What is the capital of France?"
  input_developer <- "Please provide a brief, factual answer."

  # Call API and get raw results
  results <- call_openai_responses(
    input_developer = input_developer,
    input_user = user_input,
    reasoning_effort = "minimal"
  )

  # Extract text from results
  result <- extract_openai_responses_text(results)
  result <- result[[1]]

  # Check that result is not empty and is a character string
  expect_type(result, "character")
  expect_true(nchar(result) > 0)

  # Check that the response mentions Paris (capital of France)
  expect_true(
    grepl("Paris", result, ignore.case = TRUE),
    info = "Response should mention Paris as the capital of France"
  )
})

# Test 2: Test with user_input, input_developer, and two input_paths
test_that("openai_responses_request works with images asking if dogs are the same", {
  # Skip test if no API key is available
  skip_if_not(
    nzchar(Sys.getenv("OPENAI_API_KEY")),
    "OpenAI API key not available"
  )
  # Skip test if image files don't exist
  dog1_path <- here("tests/testthat/photos/dog-1.png")
  dog2_path <- here("tests/testthat/photos/dog-2.png")

  skip_if_not(
    file.exists(dog1_path) && file.exists(dog2_path),
    "Test image files not available"
  )

  user_input <- "Are these two dogs the same dog? Please analyze the images and tell me if they are the same dog or different dogs."
  input_developer <- "You are an expert at analyzing dog photos. Look carefully at the physical characteristics, markings, and features of each dog to determine if they are the same animal or different dogs."
  input_paths <- list(c(dog1_path, dog2_path))

  # Call API and get raw results
  results <- call_openai_responses(
    input_developer = input_developer,
    input_user = user_input,
    image_paths = input_paths,
    reasoning_effort = "minimal"
  )

  # Extract text from results
  result <- extract_openai_responses_text(results)
  result <- result[[1]]

  # Check that result is not empty and is a character string
  expect_type(result, "character")
  expect_true(nchar(result) > 0)

})
