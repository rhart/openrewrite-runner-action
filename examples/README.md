# Examples

This directory contains examples demonstrating how to use the OpenRewrite Runner Action.

## Directory Structure

```
examples/
├── recipes/                    # Example OpenRewrite recipe definitions
│   └── fix-kubernetes-manifests.yml
├── yaml/                       # Example target files (Kubernetes manifests)
│   ├── project-blue/
│   └── project-green/
└── workflows/                  # Example GitHub workflow files
    ├── basic-usage.yml
    └── with-pr-creation.yml
```

## Kubernetes YAML Example

This example fixes a common Kubernetes issue: Service selectors that don't match Deployment labels.

### The Problem

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

### Running the Example

1. Go to **Actions** → **Test OpenRewrite Runner** → **Run workflow**
2. Use the pre-filled default or set:
   - **recipes**: `com.example.FixKubernetesManifests`
   - **recipe-parameters**: One of:
     - `com.example.FixKubernetesManifests.targetDirectory=examples/yaml/project-blue`
     - `com.example.FixKubernetesManifests.targetDirectory=examples/yaml/project-green`
     - `com.example.FixKubernetesManifests.targetDirectory=examples/yaml/project-*` (both at once)
3. The workflow runs the action and shows the results

### What Gets Fixed

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

## Files

- `recipes/fix-kubernetes-manifests.yml` - Recipe definition
- `yaml/project-blue/manifests.yaml` - Example manifests
- `yaml/project-green/manifests.yaml` - Example manifests
- `workflows/` - Example workflow files you can copy

For more information, see the main [README](../README.md).
