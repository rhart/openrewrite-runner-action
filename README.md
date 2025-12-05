# OpenRewrite Runner Action

A GitHub Action that runs [OpenRewrite](https://docs.openrewrite.org/) recipes without requiring build tool configuration in your repository. Use runtime parameters to make recipes reusable across multiple directories, projects, or repositories. Works with both monorepos and multi-repo setups.

## Key Features

- **Runtime Parameterization** - Pass parameters at workflow execution time, not recipe definition time. One recipe, configured differently per run using `{{ placeholder }}` syntax
- **No Build Tools Required** - Target repositories don't need Maven, Gradle, or any build configuration
- **Run Anywhere** - Apply recipes to any checked-out repository in your workflow, not just the repository containing build configuration
- **Temporary Setup** - Gradle is added only during execution, then completely removed
- **Clean Execution** - Only your code changes remain after the action completes

## Why Runtime Parameterization Matters

**The key advantage: parameters are passed at workflow runtime, not at recipe definition time.** This means you decide which directories, files, or values to target *when you run the workflow*, not when you write the recipe.

This is particularly useful for monorepos where you want to apply the same transformation to different services or projects selectively, or multi-repo workflows where you want to target different directories in different repositories.

**Without parameterization**, you must choose between:
- **Broad wildcards** - `filePattern: "**/manifests.yaml"` applies to all matching files (no selectivity)
- **Separate recipes** - One hardcoded recipe per target for selective execution

```yaml
# Option 1: Applies to all matching files
filePattern: "**/manifests.yaml"

# Option 2: Multiple recipe files for selective targeting
# recipes/fix-project-blue.yml
# recipes/fix-project-green.yml
# recipes/fix-project-red.yml
```

**With parameterization**, one recipe adapts to each workflow run:
```yaml
# One recipe definition, configured per workflow run
filePattern: "{{ targetDirectory }}/manifests.yaml"
```

Benefits:
- **Per-run configuration** - Same recipe, different targets for each workflow execution
- **Workflow-level control** - Decide which directories or projects to target at runtime
- **Staged rollouts** - Create PRs incrementally (e.g., one service at a time) rather than all at once
- **Recipe reusability** - One definition works across multiple targets
- **Reduced maintenance** - Update logic once rather than across multiple recipe files

## Quick Start

### Basic Usage

```yaml
- name: Run OpenRewrite
  uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.MyRecipe'
    recipes-dir: 'recipes'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

### With Parameters

```yaml
- name: Run OpenRewrite
  uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.FixKubernetesManifests'
    recipe-parameters: 'com.example.FixKubernetesManifests.targetDirectory=project-blue/*'
    recipes-dir: 'recipes'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

Define your recipe with `{{ placeholders }}`:
```yaml
# recipes/fix-kubernetes-manifests.yml
name: com.example.FixKubernetesManifests
recipeList:
  - org.openrewrite.yaml.ChangePropertyValue:
      filePattern: '{{ targetDirectory }}/manifests.yaml'
      propertyKey: 'spec.selector.app'
      newValue: 'hello-kubernetes'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `recipes` | Yes | - | Comma-separated recipe names |
| `recipe-parameters` | No | - | Parameters in format `recipeName.paramName=value` |
| `recipes-dir` | No | `recipes` | Directory containing recipe YAML files (searches subdirectories) |
| `rewrite-dependencies` | No | - | Comma-separated OpenRewrite dependencies |
| `java-version` | No | `17` | Java version to use |
| `gradle-version` | No | `9.2.0` | Gradle version to use |
| `openrewrite-version` | No | `7.20.0` | OpenRewrite Gradle plugin version |
| `working-directory` | No | `.` | Working directory for running OpenRewrite |

## Outputs

| Output | Description |
|--------|-------------|
| `changes-detected` | `true` if OpenRewrite made any changes, `false` otherwise |
| `activated-recipes` | Comma-separated list of activated recipes |

## Usage Examples

### Basic Usage

```yaml
name: OpenRewrite

on: workflow_dispatch

jobs:
  rewrite:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run OpenRewrite
        id: openrewrite
        uses: rhart/openrewrite-runner-action@main
        with:
          recipes: 'com.example.FixYamlFiles'
          recipes-dir: 'recipes'
          rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'

      - name: Show results
        run: |
          echo "Changes: ${{ steps.openrewrite.outputs.changes-detected }}"
```

### With PR Creation

```yaml
name: OpenRewrite with PR

on: workflow_dispatch

jobs:
  rewrite:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run OpenRewrite
        id: openrewrite
        uses: rhart/openrewrite-runner-action@main
        with:
          recipes: 'com.example.FixYamlFiles'
          recipes-dir: 'recipes'
          rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'

      - name: Create Pull Request
        if: steps.openrewrite.outputs.changes-detected == 'true'
        uses: peter-evans/create-pull-request@v6
        with:
          commit-message: 'chore: Apply OpenRewrite recipes'
          title: 'OpenRewrite: Apply recipes'
          branch: openrewrite-changes
```

### With Recipe Parameters

Pass parameters to recipes using the `recipe-parameters` input. Parameters use the format `recipeName.parameterName=value`:

```yaml
name: Fix Kubernetes Manifests

on:
  workflow_dispatch:
    inputs:
      target:
        description: 'Target directory pattern (e.g., project-blue/*, k8s/prod/*)'
        required: true

jobs:
  fix-manifests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Fix manifests in ${{ inputs.target }}
        uses: rhart/openrewrite-runner-action@main
        with:
          recipes: 'com.example.FixKubernetesManifests'
          recipe-parameters: 'com.example.FixKubernetesManifests.targetDirectory=${{ inputs.target }}'
          recipes-dir: 'recipes'
          rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

In your recipe YAML, use `{{ parameterName }}` placeholders:

```yaml
# recipes/fix-kubernetes-manifests.yml
name: com.example.FixKubernetesManifests
recipeList:
  - org.openrewrite.yaml.ChangePropertyValue:
      filePattern: '{{ targetDirectory }}/manifests.yaml'
      propertyKey: 'spec.selector.app'
      newValue: 'hello-kubernetes'
```

The same recipe can target any directory you specify when running the workflow - `project-blue/*`, `k8s/prod/*`, etc. - without modifying recipe files.

### Running on a Different Repository

Use `working-directory` to run recipes against code checked out to a subdirectory. This is useful when checking out multiple repositories or when your target code is not in the workflow's default checkout location:

```yaml
- uses: actions/checkout@v4
  with:
    repository: org/target-repo
    path: target

- uses: actions/checkout@v4
  with:
    repository: org/recipes-repo
    path: recipes-repo

- uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.MyRecipe'
    recipes-dir: '../recipes-repo/recipes'
    working-directory: 'target'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

### Multi-Repo Workflow

Apply the same recipe across multiple repositories using a matrix strategy:

```yaml
name: Fix Manifests Across Repos

on: workflow_dispatch

jobs:
  fix-repos:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        repo: [org/service-a, org/service-b, org/service-c]
    steps:
      - name: Checkout target repo
        uses: actions/checkout@v4
        with:
          repository: ${{ matrix.repo }}
          path: target

      - name: Checkout recipes repo
        uses: actions/checkout@v4
        with:
          repository: org/recipes-repo
          path: recipes-repo

      - name: Run OpenRewrite
        uses: rhart/openrewrite-runner-action@main
        with:
          recipes: 'com.example.FixKubernetesManifests'
          recipe-parameters: 'com.example.FixKubernetesManifests.targetDirectory=k8s/*'
          recipes-dir: '../recipes-repo/recipes'
          working-directory: 'target'
          rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

### Multiple Recipes

Run multiple recipes in a single execution, each with its own parameters:

```yaml
- uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.Recipe1,com.example.Recipe2'
    recipe-parameters: 'com.example.Recipe1.param=value1,com.example.Recipe2.param=value2'
    recipes-dir: 'recipes'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

## OpenRewrite Versions

This action uses two version inputs:

- **`openrewrite-version`** - The OpenRewrite Gradle plugin version (default: `7.20.0`)
- **`rewrite-dependencies`** - Individual module versions like `rewrite-yaml`, `rewrite-json`, etc.

These versions are independent. The OpenRewrite Gradle plugin (version 7.x) is compatible with OpenRewrite library modules (version 8.x). Choose versions based on:
- Plugin version: Features and compatibility requirements
- Module versions: Specific recipes and transformations needed

## How It Works

1. **Setup** - Creates temporary `build.gradle`, `settings.gradle`, and `rewrite.yml`
2. **Execute** - Runs OpenRewrite recipes with your parameters
3. **Cleanup** - Removes all temporary build files
4. **Output** - Only your code changes remain

## Examples

See the [examples](examples/) directory for:
- Example recipe definitions
- Example target files (Kubernetes YAML)
- Example workflow files

## License

See [LICENSE](LICENSE) for details.
