#!/bin/bash
set -e

# Arguments:
# $1 recipes dir
# $2 comma-separated recipe names
# $3 recipe parameters (comma-separated key=value pairs in format recipeName.parameterName=value)

RECIPES_DIR="${1:-recipes}"
RAW_RECIPES="$2"
RECIPE_PARAMETERS="$3"

IFS=',' read -r -a RECIPE_ARRAY <<< "$RAW_RECIPES"

> rewrite.yml

# Parse recipe parameters into an associative array using namespaced keys
declare -A params
if [ -n "$RECIPE_PARAMETERS" ]; then
  echo "📝 Parsing namespaced recipe parameters..."
  IFS=',' read -r -a OPTS_ARRAY <<< "$RECIPE_PARAMETERS"
  for opt in "${OPTS_ARRAY[@]}"; do
    opt_trim=$(echo "$opt" | xargs)
    [ -z "$opt_trim" ] && continue
    if [[ "$opt_trim" =~ ^([^=]+)=(.+)$ ]]; then
      params["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
      echo "  ✓ Parameter: ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
  done
fi

# Add recipe definitions with parameter substitution
for SELECTED_RECIPE in "${RECIPE_ARRAY[@]}"; do
  SELECTED_RECIPE_TRIM=$(echo "$SELECTED_RECIPE" | xargs)
  [ -z "$SELECTED_RECIPE_TRIM" ] && continue

  RECIPE_FILE=$(grep -l "^name: *${SELECTED_RECIPE_TRIM}$" "$RECIPES_DIR"/*.yml 2>/dev/null | head -1)
  if [ -z "$RECIPE_FILE" ]; then
    echo "❌ Recipe '$SELECTED_RECIPE_TRIM' not found in $RECIPES_DIR" >&2
    exit 1
  fi

  echo "✅ Processing recipe: $SELECTED_RECIPE_TRIM"

  # Read the recipe content
  recipe_content=$(cat "$RECIPE_FILE")

  # Substitute parameters for this recipe
  for param_key in "${!params[@]}"; do
    # Check if parameter is namespaced for this recipe (recipeName.paramName)
    if [[ "$param_key" =~ ^${SELECTED_RECIPE_TRIM}\.(.+)$ ]]; then
      param_name="${BASH_REMATCH[1]}"
      param_value="${params[$param_key]}"
      recipe_content=$(echo "$recipe_content" | sed "s|{{${param_name}}}|${param_value}|g")
      echo "  🔄 Substituted {{${param_name}}} with ${param_value}"
    fi
  done

  # Append recipe definition as separate document
  echo "---" >> rewrite.yml
  echo "$recipe_content" >> rewrite.yml
done

# Output the activated recipes
echo "activated_recipes=$RAW_RECIPES" >> "$GITHUB_OUTPUT"

echo "✅ Generated rewrite.yml with parameter substitutions"
