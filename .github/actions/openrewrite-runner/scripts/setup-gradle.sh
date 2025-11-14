#!/bin/bash
set -e

RECIPES="$1"
REWRITE_DEPS="$2"

mkdir -p src/main/java

# Simple settings.gradle without unnecessary plugins
cat > settings.gradle << 'EOF'
rootProject.name = 'openrewrite-temp'
EOF

# Build dependencies block only if dependencies are provided
DEPS_BLOCK=""
if [ -n "$REWRITE_DEPS" ]; then
  IFS=',' read -r -a DEP_ARRAY <<< "$REWRITE_DEPS"
  for dep in "${DEP_ARRAY[@]}"; do
    dep_trim=$(echo "$dep" | xargs)
    [ -n "$dep_trim" ] && DEPS_BLOCK="${DEPS_BLOCK}    rewrite(\"${dep_trim}\")\n"
  done
fi

# Convert comma-separated recipes to individual activeRecipe calls
IFS=',' read -r -a RECIPE_ARRAY <<< "$RECIPES"
ACTIVE_RECIPES=""
for recipe in "${RECIPE_ARRAY[@]}"; do
  recipe_trim=$(echo "$recipe" | xargs)
  [ -n "$recipe_trim" ] && ACTIVE_RECIPES="${ACTIVE_RECIPES}    activeRecipe(\"${recipe_trim}\")\n"
done

cat > build.gradle << EOF
plugins {
    id 'java'
    id 'org.openrewrite.rewrite' version '6.25.0'
}

repositories { mavenCentral() }

dependencies {
$(echo -e "$DEPS_BLOCK")
}

rewrite {
    configFile = file("rewrite.yml")
$(echo -e "$ACTIVE_RECIPES")
}
EOF

echo "🔍 build.gradle:"
sed 's/^/     /' build.gradle
echo "✅ Gradle build files created!"
