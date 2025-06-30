# PSBlogger DevContainer Setup

This devcontainer provides a complete PowerShell development environment with all necessary tools for developing and testing the PSBlogger module.

## What's Included

- **PowerShell 7+** - Latest version of PowerShell Core
- **Pester** - PowerShell testing framework (auto-installed)
- **powershell-yaml** - YAML module dependency (auto-installed)
- **VS Code Extensions**:
  - PowerShell Extension - Full PowerShell language support
  - YAML Extension - For configuration files
  - Test Explorer - For running tests

## Getting Started

1. **Rebuild the container**: Press `Ctrl+Shift+P` → "Codespaces: Rebuild Container"
2. **Wait for setup**: The container will automatically install PowerShell modules
3. **Open a PowerShell terminal**: Press `Ctrl+Shift+P` → "Terminal: Create New Terminal" → Select "pwsh"

## Available Tasks

Use `Ctrl+Shift+P` → "Tasks: Run Task" to access these predefined tasks:

- **Run All Pester Tests** - Executes all tests in the `/src/tests` directory
- **Run Current Test File** - Runs tests in the currently open file

## Running Pester Tests

```powershell
cd src
Import-Module Pester
Invoke-Pester -Path .\tests -Output Detailed
```

## Debugging

The launch.json configuration provides debugging options:
- **PowerShell: Interactive Session** - Start a debug session
- **PowerShell: Launch Current File** - Debug the current PowerShell file
- **PowerShell: Launch Pester Tests** - Debug Pester tests

## Troubleshooting

If you encounter issues:

1. Ensure the container has rebuilt completely
2. Check that PowerShell is available: `$PSVersionTable`
3. Verify modules are installed: `Get-Module -ListAvailable Pester, powershell-yaml`
4. Try reimporting the module: `.\src\reload.ps1`
