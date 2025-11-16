# openrewrite-workflow

A reusable GitHub Actions workflow for running OpenRewrite recipes without requiring build tool configuration in your repository.

## Overview

This workflow temporarily sets up Gradle to run OpenRewrite recipes, then cleans up all build files afterward - leaving only your code changes. No need to maintain Maven, Gradle, or OpenRewrite configuration in your repositories.

## Features

- **No Build Tool Required**: Consuming repositories don't need any build tool configuration
- **Temporary Setup**: Gradle is added only during workflow execution, then removed
- **Parameterized Recipes**: Pass configuration to recipes using namespaced parameters
- **Automated PRs**: Creates pull requests with changes for review
- **Reusable**: Call from any repository using the `uses` keyword

## Quick Start

### 1. Enable Repository Permission

Before using this workflow, enable PR creation in your repository:

**Settings** → **Actions** → **General** → **Workflow permissions**:
- ✅ Select "Read and write permissions"
- ✅ Check "Allow GitHub Actions to create and approve pull requests"

### 2. Call the Workflow

Create `.github/workflows/openrewrite.yml` in your repository:

```yaml
name: OpenRewrite

on:
  workflow_dispatch:
    inputs:
      recipes:
        description: 'Comma-separated recipe names'
        required: true
      recipe-parameters:
        description: 'Recipe parameters (recipeName.paramName=value)'
        required: false

jobs:
  run-openrewrite:
    permissions:
      contents: write
      pull-requests: write
    uses: rhart/openrewrite-workflow/.github/workflows/openrewrite-workflow.yml@main
    secrets: inherit
    with:
      recipes: ${{ github.event.inputs.recipes }}
      recipe-parameters: ${{ github.event.inputs.recipe-parameters }}
      recipes-dir: "examples/openrewrite/recipes"
      rewrite-dependencies: "org.openrewrite:rewrite-yaml:8.37.1"
```

### 3. Run It

Go to **Actions** → **OpenRewrite** → **Run workflow** and provide:
- **recipes**: `com.example.FixKubernetesManifests`
- **recipe-parameters**: `com.example.FixKubernetesManifests.targetDirectory=path/to/files`

## Input Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `recipes` | Yes | - | Comma-separated recipe names (e.g., `com.example.MyRecipe`) |
| `recipe-parameters` | No | - | Namespaced parameters: `recipeName.paramName=value` |
| `recipes-dir` | No | `recipes` | Directory containing recipe YAML files |
| `rewrite-dependencies` | No | - | OpenRewrite dependencies (e.g., `org.openrewrite:rewrite-yaml:8.37.1`) |
| `java-version` | No | `17` | Java version to use |
| `gradle-version` | No | `9.2.0` | Gradle version to use |

## Recipe Parameters

Use **namespaced format** to pass parameters to recipes:

**Format**: `recipeName.parameterName=value`

**Examples**:
- Single parameter: `com.example.MyRecipe.targetDir=src/main`
- Multiple parameters: `com.example.Recipe1.param1=value1,com.example.Recipe2.param2=value2`
- Wildcards: `com.example.MyRecipe.targetDir=projects/project-*`

## How It Works

1. **Setup**: Temporarily creates `build.gradle`, `settings.gradle`, and `rewrite.yml` 
2. **Execute**: Runs OpenRewrite recipes with your specified parameters
3. **Cleanup**: Removes all temporary build files
4. **PR**: Creates a pull request with only the code changes

The consuming repository remains clean - no build tool configuration is committed.

## Example

See the [YAML example](examples/openrewrite/yaml/README.md) for a complete working example that fixes Kubernetes manifest selectors.

## License

See [LICENSE](LICENSE) for details.

