#!/usr/bin/env bash

set -euo pipefail

# 1. Resolve bump type from PR labels
if echo "$LABELS" | grep -qE "MicroApp:major"; then
  BUMP_TYPE="major"
elif echo "$LABELS" | grep -qE "MicroApp:minor|type/Implementation|type/feature"; then
  BUMP_TYPE="minor"
elif echo "$LABELS" | grep -qE "MicroApp:patch"; then
  BUMP_TYPE="patch"
fi

# 2. Find the latest existing tag
APP_PREFIX="${APP_NAME}-v"
LATEST_TAG=$(git tag -l "${APP_PREFIX}*" | sort -V | tail -n 1)

# 3. Parse current version components
MAJOR=1; MINOR=0; PATCH=0; BUILD=0

if [ -n "$LATEST_TAG" ]; then
  # Use the latest git tag (created automatically after each workflow run)
  VERSION_STR=${LATEST_TAG#"$APP_PREFIX"}

  if [[ "$VERSION_STR" == *"-build."* ]]; then
    SEMVER=${VERSION_STR%-build.*}
    BUILD=${VERSION_STR##*-build.}
    IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"
  elif [[ "$VERSION_STR" == *"+"* ]]; then
    SEMVER=${VERSION_STR%+*}
    BUILD=${VERSION_STR##*+}
    IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"
  else
    IFS='_' read -r MAJOR MINOR PATCH BUILD _ <<< "$VERSION_STR"
  fi

  MAJOR=${MAJOR:-1}
  MINOR=${MINOR:-0}
  PATCH=${PATCH:-0}
  BUILD=${BUILD:-0}

elif [ -n "${INITIAL_VERSION:-}" ]; then
  # No git tag yet — use the version from the caller (last known DB version)
  # Format: 2.4.0-build.5
  SEMVER=${INITIAL_VERSION%-build.*}
  BUILD=${INITIAL_VERSION##*-build.}
  IFS='.' read -r MAJOR MINOR PATCH <<< "$SEMVER"
  MAJOR=${MAJOR:-1}
  MINOR=${MINOR:-0}
  PATCH=${PATCH:-0}
  BUILD=${BUILD:-0}
fi

# 4. Increment based on bump type
case "$BUMP_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0; PATCH=0; BUILD=$((BUILD + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0; BUILD=$((BUILD + 1))
    ;;
  patch|*)
    PATCH=$((PATCH + 1))
    BUILD=$((BUILD + 1))
    ;;
esac

# 5. Emit outputs
VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "version=${VERSION}" >> "$GITHUB_OUTPUT"
echo "build=${BUILD}" >> "$GITHUB_OUTPUT"
echo "Bump type: ${BUMP_TYPE} → version: ${VERSION}, build: ${BUILD}"
