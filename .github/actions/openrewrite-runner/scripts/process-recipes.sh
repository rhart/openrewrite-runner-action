#!/bin/bash
set -euo pipefail
# Fail on unset vars, pipe failures; safer globbing
shopt -s nullglob

# Arguments:
# $1 recipes dir
# $2 comma-separated recipe names
# $3 recipe parameters (comma-separated key=value pairs in format recipeName.parameterName=value)

RECIPES_DIR="${1:-recipes}"
RAW_RECIPES="${2:-}"
RECIPE_PARAMETERS="${3:-}"

IFS=',' read -r -a RECIPE_ARRAY <<< "${RAW_RECIPES}"

> rewrite.yml

# Parse recipe parameters into an associative array using namespaced keys
declare -A params
if [ -n "${RECIPE_PARAMETERS}" ]; then
  echo "📝 Parsing namespaced recipe parameters..."
  IFS=',' read -r -a OPTS_ARRAY <<< "${RECIPE_PARAMETERS}"
  for opt in "${OPTS_ARRAY[@]}"; do
    opt_trim=$(echo "${opt}" | xargs)
    [ -z "${opt_trim}" ] && continue
    if [[ "${opt_trim}" =~ ^([^=]+)=(.+)$ ]]; then
      params["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
      echo "  ✓ Parameter: ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    else
      echo "  ⚠ Ignoring malformed parameter: ${opt_trim}" >&2
    fi
  done
fi

# Track used parameters
declare -A used_params

# Escape value for safe sed replacement
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\&/]/\\&/g'
}

# Add recipe definitions with parameter substitution
for SELECTED_RECIPE in "${RECIPE_ARRAY[@]}"; do
  SELECTED_RECIPE_TRIM=$(echo "${SELECTED_RECIPE}" | xargs)
  [ -z "${SELECTED_RECIPE_TRIM}" ] && continue

  # Support both .yml and .yaml; anchor name line exactly (allow trailing spaces)
  RECIPE_FILE=""
  for f in "${RECIPES_DIR}"/*.yml "${RECIPES_DIR}"/*.yaml; do
    [ -e "$f" ] || continue
    if grep -Eq "^name: *${SELECTED_RECIPE_TRIM}[[:space:]]*$" "$f"; then
      RECIPE_FILE="$f"
      break
    fi
  done

  if [ -z "${RECIPE_FILE}" ]; then
    echo "❌ Recipe '${SELECTED_RECIPE_TRIM}' not found in ${RECIPES_DIR} (.yml/.yaml)" >&2
    exit 1
  fi

  echo "✅ Processing recipe: ${SELECTED_RECIPE_TRIM} (${RECIPE_FILE})"

  # Read the recipe content
  recipe_content=$(<"${RECIPE_FILE}")

  # Substitute parameters for this recipe
  for param_key in "${!params[@]}"; do
    if [[ "${param_key}" =~ ^${SELECTED_RECIPE_TRIM}\.(.+)$ ]]; then
      param_name="${BASH_REMATCH[1]}"
      param_value="${params[${param_key}]}"
      escaped_value=$(escape_sed "${param_value}")
      # Perform safe substitution
      recipe_content=$(printf '%s' "${recipe_content}" | sed "s|{{ *${param_name} *}}|${escaped_value}|g")
      echo "  🔄 Substituted {{${param_name}}} with ${param_value}"
      used_params["${param_key}"]=1
    fi
  done

  # Append recipe definition as separate document
  echo "---" >> rewrite.yml
  echo "${recipe_content}" >> rewrite.yml
done

# Warn about unused namespaced parameters
for param_key in "${!params[@]}"; do
  if [[ -z "${used_params[${param_key}]:-}" ]]; then
    # Only namespaced params (must contain a dot) are considered unmatched
    if [[ "${param_key}" == *.* ]]; then
      echo "⚠ Unused parameter (no matching recipe placeholder): ${param_key}" >&2
    fi
  fi
done

# Output the activated recipes
echo "activated_recipes=${RAW_RECIPES}" >> "${GITHUB_OUTPUT}"

echo "✅ Generated rewrite.yml with parameter substitutions (sed-safe)"
