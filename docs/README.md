## BioBuddy Documentation

Welcome to the BioBuddy docs. This section describes all public APIs, functions, and UI components, with examples and usage guidance.

### Contents

- **R API Reference**
  - [Clients (APIs, OpenAI, Gmail)](r/clients.md)
  - [Utilities (env, S3 helpers, secrets)](r/etc.md)
  - [Image Processing](r/img-process.md)
  - [UI Helpers](r/ui-helpers.md)
  - [Server Helpers](r/server-helpers.md)
- **Shiny Application Components**
  - [UI Components and Layout](../docs/app/ui.md)
- **Python Utilities**
  - [S3 Helpers](python/s3.md)
  - [Secrets Manager](python/secrets.md)
  - [Detector](python/detector.md)
- **JavaScript Helpers**
  - [Browser Utilities](js/biobuddy.md)

### Quickstart

- **Prerequisites**
  - R 4.3+, renv activated; Python 3.10+ available to reticulate
  - AWS credentials configured for S3 and Secrets Manager
  - Required secrets present in AWS Secrets Manager and/or environment variables

- **Key environment variables**
  - `LOCAL` set to `true` for local file I/O
  - `ENVIRONMENT` one of `staging` or `production`

