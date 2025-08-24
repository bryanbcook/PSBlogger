# Contribution Guide

## Environment Setup

### Tools

Local development requires the following:

- PowerShell 7.x
- Pester 5.7.1
- [Pandoc](https://pandoc.org)
- Visual Studio Code, with the following extensions:
  - Test Adapter Converter
  - Test Explorer UI
  - Pester Tests

Development is presently done on Windows 11, though conceptually it should work on Linux

### Codespace

As an alternative to local development environments, a GitHub Codespace can be used to build and test. Codespace usage has an [associated cost](https://docs.github.com/en/billing/concepts/product-billing/github-codespaces). The free option should be sufficient for most developers.

Codespaces are Linux based and require the above tools to be installed.

TODO: DevContainer configuration with tools installed is pending.

### Google Application

The environment uses a Google Application with the following setup. The published module has credentials defined, but if you may want to create an application for local testing purposes.

While this is not a fully documented walk-through on how to create a Google Application in the [Developer Console](https://console.cloud.google.com), the application has the following details.

- Branding:
  - An app name + support email
- Audience: Testing
- Clients:
  - Web Application
  - Authorized redirect URIs:
    - <http://localhost/oauth2callback>
    - <https://localhost:8040/oauth2callback>
- Data Access: uses the following scopes:

- <https://www.googleapis.com/auth/blogger>: manage blogger account and posts
- <https://www.googleapis.com/auth.drive.file>: upload and manage files into Google Drive that are scoped to the application.

For local testing, you'll need the Client ID and Client Secret

## Running Locally

Within Visual Studio Code, you should be able to run the tests with no additional configuration.

To test the module manually, you will need to provide your client-id and client-secret as environment variables.

```shell
cd ./src
./reload.ps1 # to load the source into memory

$env:PSBLOGGER_CLIENT_ID = "<your-id>"
$env:PSBLOGGER_CLIENT_SECRET = "<your-secret>"

Initialize-Blogger
```
