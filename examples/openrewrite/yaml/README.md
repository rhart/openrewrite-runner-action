# OpenRewrite YAML Example

This example demonstrates how to use the OpenRewrite workflow to automatically fix Kubernetes manifest files.

## The Problem

In both `project-blue` and `project-green` directories, the Kubernetes Service selector doesn't match the Deployment labels:

**Service (incorrect):**
```yaml
selector:
  app: goodbye-kubernetes
```

**Deployment (correct):**
```yaml
selector:
  matchLabels:
    app: hello-kubernetes
```

This mismatch would prevent the Service from routing traffic to the Deployment's pods.

## The Solution

The `FixKubernetesManifests` recipe automatically updates the Service selector to match the Deployment labels, changing `goodbye-kubernetes` to `hello-kubernetes`.

## How to Run This Example

### Option 1: Using GitHub Actions UI (Manual Trigger)

1. Go to the **Actions** tab in your GitHub repository
2. Select **"OpenRewrite Run"** from the workflows list
3. Click **"Run workflow"**
4. Fill in the parameters:
   - **recipes**: `com.example.FixKubernetesManifests` (already filled by default)
   - **recipe-parameters**: Use one of the following:
     - For project-blue only: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-blue`
     - For project-green only: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-green`
     - For both projects at once: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-*`
5. Click **"Run workflow"**

The workflow will:
- Apply the recipe to fix the selector mismatch
- Create a pull request with the changes
- Show you exactly what was modified

### Option 2: Calling from Another Workflow

```yaml
jobs:
  fix-manifests:
    uses: ./.github/workflows/openrewrite-workflow.yml
    secrets: inherit
    with:
      recipes-dir: "examples/openrewrite/recipes"
      rewrite-dependencies: "org.openrewrite:rewrite-yaml:8.37.1"
      recipes: "com.example.FixKubernetesManifests"
      recipe-parameters: "com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-blue"
```

## Expected Results

After running the recipe, the Service selector in the manifests will be updated:

**Before:**
```yaml
selector:
  app: goodbye-kubernetes
```

**After:**
```yaml
selector:
  app: hello-kubernetes
```

When using the wildcard pattern (`project-*`), both `project-blue` and `project-green` will be fixed in a single run.

## Recipe Parameters

The recipe uses a **namespaced parameter format**:

- **Format**: `recipeName.parameterName=value`
- **Examples**: 
  - Single project: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-blue`
  - Multiple projects: `com.example.FixKubernetesManifests.targetDirectory=examples/openrewrite/yaml/project-*`

This allows the recipe to be parameterized with different target directories without modifying the recipe definition itself.

## Files Involved

- **Recipe Definition**: `../recipes/fix-kubernetes-manifests.yml` - Defines the OpenRewrite recipe with parameterized file patterns
- **Target Files**: 
  - `project-blue/manifests.yaml` - Kubernetes manifests for project-blue
  - `project-green/manifests.yaml` - Kubernetes manifests for project-green
- **Test Workflow**: `.github/workflows/openrewrite-run.yml` - Manual trigger workflow for testing

## Learning Points

1. **Parameterized Recipes**: The recipe uses `{{ targetDirectory }}` as a template variable, which gets replaced at runtime
2. **Wildcard Patterns**: Use glob patterns like `project-*` to target multiple directories at once
3. **Targeted Changes**: The `filePattern` ensures only the specified project's manifests are modified
4. **No Build Tools Required**: This works on YAML files without needing any build tool configuration in your repository
5. **Automated PR Creation**: Changes are automatically packaged into a pull request for review

## Next Steps

Try modifying the recipe to:
- Change different properties in the manifests
- Target multiple files with different patterns
- Create your own custom recipe for your specific use case

For more information, see the main [README](../../../../README.md).

