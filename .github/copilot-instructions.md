# GitHub Copilot Instructions

## Project Overview
This is a reusable GitHub Actions workflow for running OpenRewrite recipes without requiring the consuming repository to have any build tool configuration. The workflow temporarily adds Gradle to run OpenRewrite recipes, then removes all build tool files afterward, leaving only the code changes.

## Project Context

### Purpose
- Provide a centralized, reusable workflow for OpenRewrite recipe execution
- Eliminate the need for consuming repositories to configure or maintain build tools
- Enable automated code refactoring and migrations across multiple repositories regardless of their build setup

### Key Concepts
- **Reusable Workflow**: This is a `.github/workflows/*.yml` file that can be called by other repositories using the `workflow_call` trigger
- **OpenRewrite**: A refactoring ecosystem for source code, providing automated code transformations through "recipes"
- **Temporary Build Setup**: The workflow temporarily adds Gradle configuration files to run OpenRewrite, then cleans them up automatically
- **No Build Tool Required in Target Repo**: Consuming repositories don't need Gradle, Maven, or any build tool configured - the workflow handles everything
## Usage Example

Here's how consumers call this reusable workflow:

1. Temporarily creates Gradle configuration files (build.gradle, settings.gradle, rewrite.yml) in the target repository
2. Sets up Java and Gradle in the GitHub Actions runner environment

4. Removes all temporary build tool files after execution
5. Only the actual code changes from OpenRewrite remain in the repository

**Key Point**: The consuming repository never needs to commit or maintain any build tool configuration. The Gradle setup exists only during workflow execution.
    inputs:
      recipes:
        description: 'Comma-separated list of recipe names.'
        required: false
        default: 'com.example.FixKubernetesManifests'
      recipe-parameters:
        description: 'Comma-separated key=value pairs in namespaced format. Format: "recipeName.parameterName=value". Example: "com.example.CreateFile.targetDirectory=kubernetes/instance-1"'
        required: false
        default: ''

jobs:
  call-openrewrite-workflow:
    uses: ./.github/workflows/reusable-openrewrite-auto-pr.yml
    secrets: inherit
    with:
      recipe-parameters: ${{ github.event.inputs.recipe-parameters }}
```

## Technical Guidelines

### Workflow Design
- Use `workflow_call` as the trigger for reusable workflows
- **Primary Inputs**:
  - `recipes`: Comma-separated list of fully qualified recipe names (e.g., `com.example.FixKubernetesManifests`)
  - `recipe-parameters`: Comma-separated key=value pairs for recipe parameters in namespaced format
    - Format: `recipeName.parameterName=value`
    - Example: `com.example.CreateFile.targetDirectory=kubernetes/instance-1`
  - `rewrite-dependencies`: OpenRewrite module dependencies to include
  - `java-version`: Java version for running OpenRewrite (default: 17)
  - `gradle-version`: Gradle version to use temporarily (default: 9.2.0)
  - Additional inputs as needed (OpenRewrite version, target paths, etc.)
- Provide outputs for:
  - Success/failure status
  - Files changed
- **Critical cleanup step**: Removes all temporary files after execution:
  - build.gradle, settings.gradle, rewrite.yml
  - .gradle/, gradle/, gradlew, gradlew.bat
  - Ensures consuming repository remains clean of build tool artifacts

### Recipe Parameters Format
- Recipe parameters use a **namespaced format**: `recipeName.parameterName=value`
- Examples:
  - Single option: `com.example.CreateFile.targetDirectory=kubernetes/instance-1`
- Ensure complete cleanup of temporary files to avoid polluting the repository

### Best Practices
- Use official OpenRewrite CLI or Docker images when available
- Cache dependencies to improve performance
- Support both GAV coordinates and custom recipe files
- Include proper error handling and logging
- Generate clear summaries for PR comments
- Support dry-run mode for validation

### File Structure
- `.github/workflows/` - Contains the reusable workflow definition(s)
- `README.md` - Documentation for consumers of this workflow
- Examples or templates for common use cases

### Integration Points
- Should work with GitHub's dependency graph and security features
- Support creating PRs with changes automatically
- Integrate with GitHub Actions artifacts for change reports
- Consider SARIF output for code scanning integration

## Common Tasks
- Creating/updating the reusable workflow YAML
- Adding new input parameters for flexibility
- Improving error messages and user feedback
- Adding examples for common OpenRewrite recipes
- Writing documentation for workflow consumers
- Testing workflow with different OpenRewrite recipe scenarios

## OpenRewrite Specifics
- Recipes are identified by fully qualified names (e.g., `org.openrewrite.java.format.AutoFormat`)
- Recipes can be composed and configured via YAML files
- Active recipes can come from various OpenRewrite modules (Java, Maven, Spring, etc.)
- Consider supporting custom recipe JARs via URL or artifact coordinates

## Target Audience
Developers who want to:
- Apply consistent code style and refactorings across repositories
- Automate framework migrations (e.g., Spring Boot, JUnit upgrades)
- Fix security vulnerabilities through automated patches
- Maintain code quality without local build tool setup
