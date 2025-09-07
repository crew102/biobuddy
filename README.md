# BioBuddy

> Rewrites dog adoption bios for rescue dogs on Petfinder

https://biobuddyai.com

## Project Structure

### `app/` - Main Shiny Application

Core web application that provides the user interface for rescue organizations to view and customize AI-generated dog adoption bios:

- `app.R` - Main application with authentication, user session management, and bio customization logic
- `ui.R` - Shiny UI components including dog selection, bio display, and customization modal
- `data/endearing-behaviors.csv` - Database of dog behaviors used for bio customization prompts
- `prompts/` - JSON templates for different AI rewrite styles (interview format, dog's perspective, sectioned bio)
- `www/` - Static assets including CSS styling, JavaScript interactions, and BioBuddy branding

### `aws/` - AWS Infrastructure

Infrastructure as code for deploying BioBuddy to AWS using CDK:

- `bbstack.py` - Defines EC2 spot instances, VPC, security groups, S3 buckets, and Lambda functions
- `app.py` - CDK app configuration for staging and production environments
- `ec2-startup.sh` - Bootstraps EC2 instances with Docker, clones repo, and starts services
- `shutdown/` - Lambda functions that handle spot instance interruptions and trigger redeployment

### `db/` - Data Management

Handles all data storage, processing, and management operations:

- `img/raw/` & `img/cropped/` - Stores dog photos downloaded from Petfinder (raw originals and AI-cropped versions)
- `lorem-ipsum.R` - Generates sample data for testing bio rewrite functionality
- `update_orgs.py` - Updates organization data stored in S3 for participating rescue groups
- `wipe_db.py` - Clears all database files from S3 storage for testing/cleanup

### `services/` - Supporting Services

Infrastructure services that support the main application:

- `nginx/` - Reverse proxy server with SSL termination, static landing page, and routing to Shiny app
- `shiny-proxy/` - Manages containerized Shiny app instances and handles user sessions

### `scripts/` - Automation

Automated daily tasks that keep the system updated:

- `daily-update.R` - Main automation script that fetches new dogs from Petfinder API, downloads/crops photos, generates AI rewrites, and uploads to S3
- `daily-update.sh` - Shell wrapper that sets environment variables for the R script
- `daily-update.crontab` - Cron job configuration for daily automated runs at 11 PM EST

### `R/` - R Package Functions

Core R package functionality that powers the application:

- `clients.R` - API integrations for Petfinder (dog data), OpenAI (bio rewrites), and Gmail (notifications)
- `etc.R` - Utility functions for AWS secrets management, S3 file operations, and environment detection
- `img-process.R` - Downloads dog photos and uses computer vision to detect and crop dog heads
- `ui-helpers.R` - Generates Shiny UI components for displaying dogs and bios
- `server-helpers.R` - Processes bio customization requests and manages user interactions

### `inst/python/` - Python Utilities

Python modules for AWS integration and computer vision:

- `s3.py` - Handles all S3 operations (upload/download files, list directories, manage buckets)
- `secrets.py` - Retrieves secrets from AWS Secrets Manager for API keys and credentials
- `detector.py` - Uses computer vision to detect dog heads in photos for automatic cropping

### `dev/` - Development Tools

Development resources, documentation, and experimental code:

- Contains development notes, best practices documentation, and experimental scripts
- Backup files and temporary development utilities
- Literature references and project planning documents

### `renv/` - R Environment Management

R package dependency management using renv:

- `library/` - Local R package installations
- `staging/` - Staging area for package updates
- `activate.R` - Environment activation script
- `settings.json` - renv configuration settings

### Root Files

- `docker-compose.yml` - Multi-service Docker orchestration for local development and testing
- `Dockerfile` - Main application container configuration with R, Python, and system dependencies
- `DESCRIPTION` - R package metadata, dependencies, and project information
- `renv.lock` - Locked R package versions for reproducible builds across environments
- `Makefile` - Build automation and common development tasks
