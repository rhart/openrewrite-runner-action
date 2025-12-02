# OpenRewrite Runner Action

A GitHub Action that runs [OpenRewrite](https://docs.openrewrite.org/) recipes without requiring build tool configuration in your repository.

## Features

- **No Build Tools Required** - Target repositories don't need Maven, Gradle, or any build configuration
- **Temporary Setup** - Gradle is added only during execution, then completely removed
- **Parameterized Recipes** - Pass runtime parameters to recipes using namespaced format
- **Clean Execution** - Only your code changes remain after the action completes

## Quick Start

```yaml
- name: Run OpenRewrite
  uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.MyRecipe'
    recipes-dir: 'recipes'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `recipes` | Yes | - | Comma-separated recipe names |
| `recipe-parameters` | No | - | Parameters in format `recipeName.paramName=value` |
| `recipes-dir` | No | `recipes` | Directory containing recipe YAML files |
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

Pass parameters to recipes using namespaced format:

```yaml
- uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.FixKubernetesManifests'
    recipe-parameters: 'com.example.FixKubernetesManifests.targetDirectory=k8s/manifests/*'
    recipes-dir: 'recipes'
    rewrite-dependencies: 'org.openrewrite:rewrite-yaml:8.66.3'
```

Parameters use the format `recipeName.parameterName=value`. In your recipe YAML, use `{{ parameterName }}` placeholders:

```yaml
# recipes/fix-kubernetes-manifests.yml
name: com.example.FixKubernetesManifests
recipeList:
  - org.openrewrite.yaml.ChangePropertyValue:
      fileMatcher: '{{ targetDirectory }}/manifests.yaml'
      propertyKey: '$.spec.selector.app'
      newValue: 'hello-kubernetes'
```

### Multiple Recipes

```yaml
- uses: rhart/openrewrite-runner-action@main
  with:
    recipes: 'com.example.Recipe1,com.example.Recipe2'
    recipe-parameters: 'com.example.Recipe1.param=value1,com.example.Recipe2.param=value2'
```

### Running on a Different Repository

Use `working-directory` when you need to run recipes against code checked out to a subdirectory:

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
```

## OpenRewrite Versions

This action uses two version inputs:

- **`openrewrite-version`** - The OpenRewrite Gradle plugin version (default: `7.20.0`)
- **`rewrite-dependencies`** - Individual module versions like `rewrite-yaml`, `rewrite-json`, etc.

These version lines are independent. Plugin 7.x works with 8.x library releases. Choose:
- Plugin version based on plugin features needed
- Module versions based on the recipes/transformations you require

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
