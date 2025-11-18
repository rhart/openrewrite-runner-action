# GitHub Copilot Instructions

## Project Overview

This is a reusable GitHub Actions workflow for running OpenRewrite recipes without requiring the consuming repository to have any build tool configuration. The workflow temporarily adds Gradle to run OpenRewrite recipes, then removes all build tool files afterward, leaving only the code changes.

## Project Context

### Purpose
- Provide a centralized, reusable workflow for OpenRewrite recipe execution
- Eliminate the need for consuming repositories to configure or maintain build tools
- Enable automated code refactoring and migrations across multiple repositories regardless of their build setup

### Key Concepts
- **Reusable Workflow**: Called by other repositories using `workflow_call` trigger
- **OpenRewrite**: A refactoring ecosystem providing automated code transformations through "recipes"
- **Temporary Build Setup**: Gradle is added temporarily during execution, then cleaned up
- **No Build Tool Required**: Consuming repositories don't need Gradle, Maven, or any build tool - the workflow handles everything

## How It Works

1. **Setup**: Temporarily creates `build.gradle`, `settings.gradle`, and `rewrite.yml` in the target repository
2. **Execute**: Runs OpenRewrite recipes with specified parameters using Gradle
3. **Cleanup**: Removes all temporary build files (build.gradle, settings.gradle, rewrite.yml, .gradle/, gradle/, gradlew, gradlew.bat)
4. **PR Creation**: Creates a pull request with only the code changes

**Key Point**: The consuming repository never commits or maintains any build tool configuration. The Gradle setup exists only during workflow execution.

## Project Structure

```
.github/
  workflows/
    openrewrite-workflow.yml          # Main reusable workflow
    openrewrite-run.yml               # Manual test workflow
    openrewrite-examples-run.yml      # Example runner with defaults
  actions/
    openrewrite-runner/
      action.yml                      # Composite action definition
      scripts/
        process-recipes.sh            # Handles recipe loading and parameter substitution
        setup-gradle.sh               # Creates temporary Gradle build files
  copilot-instructions.md             # This file
examples/
  openrewrite/
    recipes/
      fix-kubernetes-manifests.yml    # Example recipe definition
    yaml/
      project-blue/manifests.yaml     # Example YAML file to transform
      project-green/manifests.yaml    # Example YAML file to transform
      README.md                       # Example documentation
README.md                              # Main project documentation
```

## Workflow Inputs

### openrewrite-workflow.yml (Reusable Workflow)

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `recipes` | Yes | - | Comma-separated fully qualified recipe names (e.g., `com.example.FixKubernetesManifests`) |
| `recipe-parameters` | No | - | Namespaced parameters: `recipeName.paramName=value` |
| `recipes-dir` | No | `recipes` | Directory containing recipe YAML files |
| `rewrite-dependencies` | No | - | OpenRewrite dependencies (e.g., `org.openrewrite:rewrite-yaml:8.66.3`) |
| `java-version` | No | `17` | Java version to use |
| `gradle-version` | No | `9.2.0` | Gradle version to use |
| `openrewrite-version` | No | `7.20.0` | OpenRewrite Gradle plugin version to use |

### openrewrite-runner (Action)

Same inputs as the reusable workflow. The action is called by the workflow and performs the actual OpenRewrite execution.

## OpenRewrite Versioning & Compatibility

OpenRewrite uses *two* distinct version lines that may legitimately differ:

1. **Gradle Plugin Version** (e.g., `7.20.0`) – Applied via `id 'org.openrewrite.rewrite' version 'X.Y.Z'` in `build.gradle`.
2. **Module / Library Versions** (e.g., `8.66.3`) – Individual artifacts such as `rewrite-yaml`, `rewrite-java`, `rewrite-maven`, etc.

It is normal for the Gradle plugin to be on a 7.x line while libraries are on 8.x. The plugin provides integration and task wiring; the libraries contain the recipes. Plugin 7.x is compatible with 8.x libraries.

**Example of valid mixed versions:**
```yaml
openrewrite-version: "7.20.0"                       # Gradle plugin
rewrite-dependencies: "org.openrewrite:rewrite-yaml:8.66.3"  # Library
```

### When to keep versions the same
- If a future 8.x plugin line exists and you want full release-train alignment for reproducibility/audits.
- If troubleshooting a suspected compatibility issue—temporarily align versions to rule out version skew.

### When differing versions are preferred
- Most day-to-day usage: choose latest stable libraries for newest recipes; update the plugin less frequently.

### Best practices
- Pin explicit versions (avoid dynamic `+`).
- Upgrade libraries to access new or fixed recipes.
- Upgrade the plugin only when new task behaviors or configuration improvements are needed.
- If an incompatibility arises (rare), bump the plugin first, then modules.

## Recipe Parameters Format

Recipe parameters use a **namespaced format**: `recipeName.parameterName=value`

**Examples:**
- Single parameter: `com.example.CreateFile.targetDirectory=kubernetes/instance-1`
- Multiple parameters: `com.example.Recipe1.param1=value1,com.example.Recipe2.param2=value2`
- Wildcards: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-*`

### Template Substitution

Recipe YAML files can use template variables that get replaced at runtime:
- Template format: `{{ parameterName }}` or `{{parameterName}}` (spaces optional)
- Example in recipe: `filePattern: "{{ targetDirectory }}/manifests.yaml"`
- Gets replaced with: `filePattern: "examples/openrewrite/yaml/project-blue/manifests.yaml"`

The `process-recipes.sh` script handles substitution using a sed pattern that tolerates optional spaces.

## Key Scripts

### process-recipes.sh
- **Purpose**: Loads recipe YAML files and substitutes parameters
- **Inputs**: recipes-dir, comma-separated recipe names, recipe parameters
- **Process**:
  1. Parses recipe parameters into an associative array
  2. Finds recipe YAML files by matching the `name:` field
  3. Safely substitutes `{{ paramName }}` templates (sed-escaped)
  4. Writes combined recipes to `rewrite.yml` as separate YAML documents
- **Output**: `rewrite.yml` with all recipes and substituted parameters

### setup-gradle.sh
- **Purpose**: Creates temporary Gradle build files
- **Inputs**: comma-separated recipes, rewrite dependencies, plugin version
- **Process**:
  1. Creates `settings.gradle` with project name
  2. Generates `build.gradle` with:
     - OpenRewrite Gradle plugin (version 7.20.0 by default)
     - Rewrite dependencies (if provided)
     - `activeRecipe()` calls for each recipe
     - `configFile = file('rewrite.yml')` configuration
  3. Creates `src/main/java` directory (required by Gradle)
- **Output**: `build.gradle`, `settings.gradle`, `src/` directory

## Important Implementation Details

### Permissions Required

Calling workflows must grant these permissions:
```yaml
permissions:
  contents: write
  pull-requests: write
```

Repository must have "Allow GitHub Actions to create and approve pull requests" enabled in Settings → Actions → General.

### Cleanup Process

The action always cleans up temporary files in a dedicated step:
- Removes: `settings.gradle`, `build.gradle`, `rewrite.yml`
- Removes directories: `.gradle/`, `gradle/`, `src/`
- Removes: `gradlew`, `gradlew.bat`

This ensures no build tool artifacts remain in the repository.

### Gradle Configuration

- Uses Gradle Build Action for caching (`gradle/gradle-build-action@v3`)
- Runs with `--no-daemon` to avoid background processes
- Java version and Gradle version are configurable via inputs

## Common Tasks

### Adding New Recipe Examples
1. Create recipe YAML in `examples/openrewrite/recipes/`
2. Add example files in `examples/openrewrite/yaml/`
3. Document in example README
4. Update default in `openrewrite-examples-run.yml` if appropriate

### Debugging Workflows
- Check `process-recipes.sh` output for parameter substitution logging
- Look for `📄 rewrite.yml content:` in logs to verify substitution
- Verify recipe files are found with `✅ Processing recipe:` messages
- Check cleanup step to ensure all temporary files are removed

### Updating OpenRewrite Versions
- Update the plugin version in workflow inputs or `setup-gradle.sh` default.
- Update module versions in `rewrite-dependencies` to pick up new recipes/fixes.

## Troubleshooting

### "Recipe not found" Error
- Check recipe YAML has correct `name:` field matching the recipe name
- Verify `recipes-dir` input points to correct directory
- Ensure recipe YAML file exists and is valid

### Template Variables Not Substituted
- Verify parameter name matches template variable (case-sensitive)
- Check namespacing: `recipeName.paramName=value`
- Look for substitution log: `🔄 Substituted {{paramName}} with value`

### PR Creation Failed
- Check repository has required PR permissions enabled
- Verify permissions block includes `contents: write` and `pull-requests: write`

### No Changes Detected
- Verify recipe makes a transformation (test locally)
- Check file patterns match target files
- Ensure relevant module (e.g., `rewrite-yaml`) is included via `rewrite-dependencies`

## Best Practices

- Always use namespaced parameters for recipe configuration
- Pin versions for reproducibility
- Keep recipe YAML files focused and documented
- Use wildcards to batch similar target directories
- Rely on automatic cleanup—don't manually delete build files in recipes

## OpenRewrite Specifics

- Recipes are identified by fully qualified names (e.g., `org.openrewrite.java.format.AutoFormat`)
- Recipes can be composed using `recipeList` in YAML
- Active recipes can come from various OpenRewrite modules (Java, Maven, Spring, YAML, JSON, etc.)
- Custom recipes can be defined in YAML files in the `recipes-dir`
- Recipe dependencies must be provided via `rewrite-dependencies` input if not using default

## Target Audience

Developers who want to:
- Apply consistent code style and refactorings across repositories
- Automate framework migrations (Spring Boot, JUnit upgrades, etc.)
- Fix security vulnerabilities through automated patches
- Transform YAML/JSON configuration files at scale
- Maintain code quality without local build tool setup
