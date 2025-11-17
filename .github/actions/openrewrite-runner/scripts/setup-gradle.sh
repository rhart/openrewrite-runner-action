#!/bin/bash
set -euo pipefail

RECIPES="${1:-}"
REWRITE_DEPS="${2:-}"
OPENREWRITE_VERSION="${3:-7.20.0}"

[ -z "${RECIPES}" ] && { echo "❌ No recipes provided" >&2; exit 1; }
[ -z "${OPENREWRITE_VERSION}" ] && { echo "❌ OpenRewrite plugin version is empty" >&2; exit 1; }

mkdir -p src/main/java

cat > settings.gradle << 'EOF'
rootProject.name = 'openrewrite-temp'
EOF

# Dependencies block only if provided
DEPS_BLOCK=""
if [ -n "${REWRITE_DEPS}" ]; then
  IFS=',' read -r -a DEP_ARRAY <<< "${REWRITE_DEPS}"
  for dep in "${DEP_ARRAY[@]}"; do
    dep_trim=$(echo "${dep}" | xargs)
    [ -n "${dep_trim}" ] && DEPS_BLOCK+="    rewrite(\"${dep_trim}\")\n"
  done
fi

# Active recipes lines
ACTIVE_RECIPES=""
IFS=',' read -r -a RECIPE_ARRAY <<< "${RECIPES}"
for recipe in "${RECIPE_ARRAY[@]}"; do
  recipe_trim=$(echo "${recipe}" | xargs)
  [ -n "${recipe_trim}" ] && ACTIVE_RECIPES+="    activeRecipe(\"${recipe_trim}\")\n"
done

cat > build.gradle << EOF
plugins {
    id 'java'
    id 'org.openrewrite.rewrite' version '${OPENREWRITE_VERSION}'
}

repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

dependencies {
$(echo -e "${DEPS_BLOCK}")}

rewrite {
    configFile = file("rewrite.yml")
$(echo -e "${ACTIVE_RECIPES}")}
EOF

echo "🔍 build.gradle:"
sed 's/^/     /' build.gradle
echo "✅ Gradle build files created"
