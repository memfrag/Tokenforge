#!/usr/bin/env bash
#
# Build, sign, notarize, package, and release Tokenforge.
#
# Requires:
#   - Xcode with a valid "Developer ID Application: Apparata AB (DR5YAK7GKS)" identity
#   - `gh` authenticated against github.com (memfrag account)
#   - Keychain profile `notary` stored via:
#       xcrun notarytool store-credentials notary --apple-id <id> --team-id DR5YAK7GKS
#
set -euo pipefail

# ---------- Constants ----------
SCHEME="Tokenforge (Release)"
APP_NAME="Tokenforge"
BUNDLE_ID="io.apparata.Tokenforge"
TEAM_ID="DR5YAK7GKS"
KEYCHAIN_PROFILE="notary"
SPARKLE_VERSION="2.9.0"
GITHUB_REPO="memfrag/Tokenforge"
APPCAST_BRANCH="main"

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SPARKLE_TOOLS_DIR="$PROJECT_DIR/Sparkle-tools"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
INFO_PLIST="$PROJECT_DIR/Tokenforge/Info.plist"
PBXPROJ="$PROJECT_DIR/Tokenforge.xcodeproj/project.pbxproj"

# ---------- Helpers ----------
error() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo ""
    echo "==> $*"
}

show_log_tail() {
    local log_file="$1"
    if [ -f "$log_file" ]; then
        echo "--- last 30 lines of $log_file ---" >&2
        tail -30 "$log_file" >&2
        echo "--- end log ---" >&2
    fi
}

# ---------- Preflight ----------
command -v xcodebuild >/dev/null || error "xcodebuild not found"
command -v gh >/dev/null || error "gh CLI not found (install with: brew install gh)"
command -v hdiutil >/dev/null || error "hdiutil not found"
command -v /usr/libexec/PlistBuddy >/dev/null || error "PlistBuddy not found"

gh auth status >/dev/null 2>&1 || error "gh CLI not authenticated. Run: gh auth login"

info "Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ---------- Sparkle tools ----------
if [ ! -x "$SPARKLE_TOOLS_DIR/bin/sign_update" ]; then
    info "Downloading Sparkle $SPARKLE_VERSION tools"
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
        -o "$BUILD_DIR/Sparkle.tar.xz" || error "failed to download Sparkle"
    mkdir -p "$SPARKLE_TOOLS_DIR"
    tar -xf "$BUILD_DIR/Sparkle.tar.xz" -C "$SPARKLE_TOOLS_DIR" || error "failed to extract Sparkle"
    rm "$BUILD_DIR/Sparkle.tar.xz"
fi

[ -x "$SPARKLE_TOOLS_DIR/bin/sign_update" ] || error "Sparkle sign_update missing after extract"
[ -x "$SPARKLE_TOOLS_DIR/bin/generate_appcast" ] || error "Sparkle generate_appcast missing after extract"

# ---------- Version management ----------
info "Checking version"

CURRENT_VERSION=""
MARKETING_LINE="$(grep -m 1 "MARKETING_VERSION" "$PBXPROJ" || true)"
if [ -n "$MARKETING_LINE" ]; then
    CURRENT_VERSION="$(echo "$MARKETING_LINE" | sed -E 's/.*MARKETING_VERSION = ([^;]+);.*/\1/' | tr -d ' "')"
fi

if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" || true)"
fi

[ -n "$CURRENT_VERSION" ] || error "could not determine current version"

echo "Current version: $CURRENT_VERSION"

LATEST_TAG="$(gh release view --repo "$GITHUB_REPO" --json tagName -q '.tagName' 2>/dev/null || true)"

if [ -z "$LATEST_TAG" ]; then
    echo "No existing GitHub release found."
    LATEST_TAG="(none)"
else
    echo "Latest GitHub release: $LATEST_TAG"
fi

version_gt() {
    # returns 0 if $1 > $2
    [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

NEEDS_BUMP=0
if [ "$LATEST_TAG" = "(none)" ]; then
    # No prior release -- keep current unless user wants to change.
    :
else
    if ! version_gt "$CURRENT_VERSION" "$LATEST_TAG"; then
        NEEDS_BUMP=1
    fi
fi

if [ "$NEEDS_BUMP" -eq 1 ]; then
    echo "Current version $CURRENT_VERSION is not greater than latest release $LATEST_TAG."
    read -r -p "Enter new version (e.g. ${LATEST_TAG}.1): " NEW_VERSION
    [ -n "$NEW_VERSION" ] || error "no version entered"
    version_gt "$NEW_VERSION" "$LATEST_TAG" || error "new version $NEW_VERSION must be greater than $LATEST_TAG"
else
    read -r -p "Release version [$CURRENT_VERSION]: " NEW_VERSION
    NEW_VERSION="${NEW_VERSION:-$CURRENT_VERSION}"
fi

VERSION="$NEW_VERSION"
TAG="$VERSION"

VERSION_CHANGED=0
if [ "$VERSION" != "$CURRENT_VERSION" ]; then
    VERSION_CHANGED=1
fi

# Also check if Info.plist CFBundleShortVersionString differs
PLIST_SHORT="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || true)"
PLIST_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || true)"
if [ "$PLIST_SHORT" != "$VERSION" ] || [ "$PLIST_VERSION" != "$VERSION" ]; then
    VERSION_CHANGED=1
fi

if [ "$VERSION_CHANGED" -eq 1 ]; then
    info "Updating version to $VERSION"

    # Update MARKETING_VERSION and CURRENT_PROJECT_VERSION in pbxproj
    /usr/bin/sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ"
    /usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = $VERSION;/g" "$PBXPROJ"

    # Update Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST" || error "failed to set CFBundleShortVersionString"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$INFO_PLIST" || error "failed to set CFBundleVersion"

    cd "$PROJECT_DIR"
    if ! git diff --quiet -- "$PBXPROJ" "$INFO_PLIST"; then
        git add "$PBXPROJ" "$INFO_PLIST"
        git commit -m "Bump version to $VERSION"
        git push origin HEAD
    fi
fi

# ---------- Release title ----------
read -r -p "Release title [Tokenforge $VERSION]: " RELEASE_TITLE
RELEASE_TITLE="${RELEASE_TITLE:-Tokenforge $VERSION}"
read -r -p "Release subtitle (optional): " RELEASE_SUBTITLE

# ---------- Archive ----------
info "Archiving $SCHEME"
xcodebuild archive \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -arch arm64 \
    ENABLE_HARDENED_RUNTIME=YES \
    2>&1 | tee "$BUILD_DIR/archive.log" | tail -5 \
    || { show_log_tail "$BUILD_DIR/archive.log"; error "archive failed"; }

[ -d "$ARCHIVE_PATH" ] || { show_log_tail "$BUILD_DIR/archive.log"; error "archive not produced at $ARCHIVE_PATH"; }

# ---------- Export ----------
info "Exporting signed app"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    2>&1 | tee "$BUILD_DIR/export.log" | tail -5 \
    || { show_log_tail "$BUILD_DIR/export.log"; error "export failed"; }

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
[ -d "$APP_PATH" ] || { show_log_tail "$BUILD_DIR/export.log"; error "exported app not found at $APP_PATH"; }

# Re-read version from the actually-built app
BUILT_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")"
BUILT_BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")"
echo "Built version: $BUILT_VERSION (CFBundleVersion: $BUILT_BUNDLE_VERSION)"

[ "$BUILT_VERSION" = "$VERSION" ] || error "built CFBundleShortVersionString ($BUILT_VERSION) does not match release version ($VERSION)"
[ "$BUILT_BUNDLE_VERSION" = "$VERSION" ] || error "built CFBundleVersion ($BUILT_BUNDLE_VERSION) does not match release version ($VERSION)"

# ---------- Verify codesign ----------
info "Verifying codesign"
codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1 | tee "$BUILD_DIR/codesign-verify.log" \
    || { show_log_tail "$BUILD_DIR/codesign-verify.log"; error "codesign verification failed"; }

# ---------- Create DMG ----------
info "Creating DMG"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_STAGING="$BUILD_DIR/dmg-staging"

rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -a "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    2>&1 | tee "$BUILD_DIR/dmg.log" | tail -5 \
    || { show_log_tail "$BUILD_DIR/dmg.log"; error "hdiutil create failed"; }

rm -rf "$DMG_STAGING"
[ -f "$DMG_PATH" ] || error "DMG not created"

# ---------- Notarize ----------
info "Submitting DMG for notarization"
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait 2>&1 | tee "$BUILD_DIR/notarize.log" \
    || { show_log_tail "$BUILD_DIR/notarize.log"; error "notarization failed"; }

if grep -q "status: Invalid" "$BUILD_DIR/notarize.log"; then
    SUBMISSION_ID="$(grep -E "^[[:space:]]*id: " "$BUILD_DIR/notarize.log" | head -1 | awk '{print $2}')"
    if [ -n "$SUBMISSION_ID" ]; then
        echo "--- notarization log ---" >&2
        xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$KEYCHAIN_PROFILE" >&2 || true
    fi
    error "notarization returned Invalid"
fi

grep -q "status: Accepted" "$BUILD_DIR/notarize.log" || { show_log_tail "$BUILD_DIR/notarize.log"; error "notarization not accepted"; }

info "Stapling DMG"
xcrun stapler staple "$DMG_PATH" 2>&1 | tee "$BUILD_DIR/staple.log" \
    || { show_log_tail "$BUILD_DIR/staple.log"; error "stapler failed"; }

xcrun stapler validate "$DMG_PATH" || error "staple validation failed"

# ---------- Sparkle sign ----------
info "Signing DMG for Sparkle"
SPARKLE_SIGNATURE="$("$SPARKLE_TOOLS_DIR/bin/sign_update" "$DMG_PATH")" \
    || error "Sparkle sign_update failed (did you generate EdDSA keys with generate_keys?)"
echo "Sparkle signature: $SPARKLE_SIGNATURE"

# ---------- GitHub release ----------
info "Creating GitHub release $TAG"

cd "$PROJECT_DIR"

# Tag and push
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists locally."
else
    git tag "$TAG"
fi

git push origin "$TAG" || error "failed to push tag $TAG"

RELEASE_NOTES_ARG=(--generate-notes)
if [ -n "$RELEASE_SUBTITLE" ]; then
    RELEASE_NOTES_ARG=(--notes "$RELEASE_SUBTITLE")
fi

gh release create "$TAG" \
    --repo "$GITHUB_REPO" \
    --title "$RELEASE_TITLE" \
    "${RELEASE_NOTES_ARG[@]}" \
    "$DMG_PATH" \
    || error "gh release create failed"

# ---------- Appcast ----------
info "Generating appcast"
APPCAST_DIR="$BUILD_DIR/appcast-assets"
mkdir -p "$APPCAST_DIR"

if [ -f "$PROJECT_DIR/appcast.xml" ]; then
    cp "$PROJECT_DIR/appcast.xml" "$APPCAST_DIR/"
fi

cp "$DMG_PATH" "$APPCAST_DIR/"

"$SPARKLE_TOOLS_DIR/bin/generate_appcast" \
    --download-url-prefix "https://github.com/$GITHUB_REPO/releases/download/$TAG/" \
    -o "$APPCAST_DIR/appcast.xml" \
    "$APPCAST_DIR" \
    || error "generate_appcast failed"

cp "$APPCAST_DIR/appcast.xml" "$PROJECT_DIR/appcast.xml"

cd "$PROJECT_DIR"
git add appcast.xml
if ! git diff --cached --quiet; then
    git commit -m "Update appcast for $VERSION"
    git push origin "$APPCAST_BRANCH"
else
    echo "No appcast changes to commit."
fi

info "Done. Released $VERSION"
echo "DMG:      $DMG_PATH"
echo "Release:  https://github.com/$GITHUB_REPO/releases/tag/$TAG"
