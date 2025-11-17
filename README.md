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
      rewrite-dependencies: "org.openrewrite:rewrite-yaml:8.66.3"
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
| `rewrite-dependencies` | No | - | OpenRewrite dependencies (e.g., `org.openrewrite:rewrite-yaml:8.66.3`) |
| `java-version` | No | `17` | Java version to use |
| `gradle-version` | No | `9.2.0` | Gradle version to use |
| `openrewrite-version` | No | `7.20.0` | OpenRewrite Gradle plugin version to use |

## OpenRewrite Versions Explained

OpenRewrite uses distinct version lines for its Gradle plugin and its libraries (modules). It is normal for these numbers to differ:

- **Gradle Plugin Version** (input: `openrewrite-version`) – Controls the OpenRewrite Gradle plugin applied in `build.gradle`.
- **Library / Module Versions** (input: `rewrite-dependencies`) – Individual artifacts like `rewrite-yaml`, `rewrite-java`, etc.

Compatibility note: Plugin 7.x is designed to work with 8.x library releases. You do *not* need matching numeric versions. Choose:

- The plugin version based on plugin release notes / features you need.
- Module versions based on the transformations you require (e.g., latest `rewrite-yaml` for YAML recipes).

When to align versions exactly:
- If you stay within a single release train for auditing or reproducibility, you can pin both to the same major/minor if that train exists (e.g., all 8.x once a plugin 8.x line is published).

When differing versions is fine:
- Using `openrewrite-version: 7.20.0` with `rewrite-yaml:8.66.3` is expected and supported.

Best practice:
- Pin versions explicitly (avoid `+` or dynamic versions) for repeatable refactors.
- Update module versions when new recipes or fixes are needed; update the plugin less frequently unless new plugin features matter.

If you encounter incompatibilities (rare), upgrade the plugin first, then adjust module versions.

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
