# OpenRewrite YAML Example

This example fixes a common Kubernetes issue: Service selectors that don't match Deployment labels.

## The Problem

Both `project-blue` and `project-green` have mismatched selectors:

```yaml
# Service (incorrect)
selector:
  app: goodbye-kubernetes

# Deployment (correct)
selector:
  matchLabels:
    app: hello-kubernetes
```

This prevents the Service from routing traffic to the Deployment's pods.

## Running the Example

### Quick Test

1. Go to **Actions** → **OpenRewrite Run** → **Run workflow**
2. Use the pre-filled default or set:
   - **recipes**: `com.example.FixKubernetesManifests`
   - **recipe-parameters**: One of:
     - `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-blue`
     - `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-green`
     - `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-*` (both at once)
3. The workflow creates a PR with the fixes

### From Another Workflow

```yaml
jobs:
  fix-manifests:
    permissions:
      contents: write
      pull-requests: write
    uses: ./.github/workflows/openrewrite-workflow.yml
    secrets: inherit
    with:
      recipes-dir: "examples/openrewrite/recipes"
      rewrite-dependencies: "org.openrewrite:rewrite-yaml:8.37.1"
      recipes: "com.example.FixKubernetesManifests"
      recipe-parameters: "com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-*"
```

## What Gets Fixed

The recipe changes `goodbye-kubernetes` to `hello-kubernetes` in the Service selector:

```yaml
# Before
selector:
  app: goodbye-kubernetes

# After
selector:
  app: hello-kubernetes
```

## Key Features Demonstrated

- **Parameterized recipes**: `{{ targetDirectory }}` gets replaced at runtime
- **Wildcard patterns**: `project-*` targets multiple directories
- **No build tools needed**: Works on YAML files directly
- **Automated PRs**: Changes are packaged for review

## Files

- `../recipes/fix-kubernetes-manifests.yml` - Recipe definition
- `project-blue/manifests.yaml` - Example manifests
- `project-green/manifests.yaml` - Example manifests

For more information, see the main [README](../../../../README.md).

