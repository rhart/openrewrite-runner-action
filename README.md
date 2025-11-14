# openrewrite-workflow

A reusable GitHub Actions workflow for running OpenRewrite recipes without requiring a build tool (Maven, Gradle, etc.).

## Overview

This workflow provides a simple, centralized way to run OpenRewrite recipes across multiple repositories. Instead of configuring Maven or Gradle plugins in each repository, you can call this reusable workflow to apply OpenRewrite transformations directly to your codebase.

## Features

- **Build Tool Independent**: No need to configure Maven, Gradle, or the OpenRewrite CLI
- **Reusable**: Call from any repository using the `uses` keyword
- **Flexible Recipe Configuration**: Support for multiple recipes with customizable parameters
- **Automated PR Creation**: Automatically creates pull requests with the changes
- **Recipe Options**: Pass configuration to recipes using namespaced parameters

## Usage

Call this workflow from your repository by creating a workflow file (e.g., `.github/workflows/openrewrite.yml`):

```yaml
name: OpenRewrite Auto-Upgrade

on:
  workflow_dispatch:
    inputs:
      recipes:
        description: 'Comma-separated list of recipe names.'
        required: false
        default: 'com.example.FixKubernetesManifests'
      recipe-options:
        description: 'Comma-separated key=value pairs in namespaced format.'
        required: false
        default: ''

jobs:
  call-openrewrite-workflow:
    uses: ./.github/workflows/reusable-openrewrite-auto-pr.yml
    secrets: inherit
    with:
      recipes: ${{ github.event.inputs.recipes }}
      recipe-options: ${{ github.event.inputs.recipe-options }}
```

### Input Parameters

#### `recipes`
Comma-separated list of fully qualified recipe names to run.

**Example:**
```
com.example.FixKubernetesManifests
```

#### `recipe-options`
Comma-separated key=value pairs for configuring recipe parameters using namespaced format.

**Format:** `recipeName.parameterName=value`

**Examples:**
- Single option: `com.example.CreateFile.targetDirectory=kubernetes/instance-1`
- Multiple options: `com.example.Recipe1.param1=value1,com.example.Recipe2.param2=value2`

## How It Works

This workflow runs OpenRewrite recipes directly without requiring a build tool configuration in your repository. It:

1. Accepts recipe names and configuration options as inputs
2. Runs the specified OpenRewrite recipes on your codebase
3. Creates a pull request with the changes (if any)

## Use Cases

- **Code Modernization**: Upgrade frameworks and libraries automatically (e.g., Spring Boot, JUnit)
- **Style Enforcement**: Apply consistent code formatting and style across repositories
- **Security Patches**: Automatically fix security vulnerabilities
- **Refactoring**: Apply automated refactorings at scale
- **Custom Transformations**: Run custom OpenRewrite recipes for organization-specific patterns

## Requirements

- GitHub Actions enabled in your repository
- Appropriate permissions for creating pull requests

## License

See [LICENSE](LICENSE) for details.
