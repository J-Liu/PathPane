#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright © 2026 Jia Liu
#
# Compile PathPane.icon to Assets.car for macOS
# Run this locally after updating the icon, then commit the result.
#
# Prerequisites:
#   - Create Resources/PathPane.icon directory with icon assets
#   - Icon assets should be in .icon format for macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if icon directory exists
ICON_DIR="${SCRIPT_DIR}/Resources/PathPane.icon"
if [ ! -d "$ICON_DIR" ]; then
    echo "❌ Error: Icon directory not found at ${ICON_DIR}"
    echo ""
    echo "   Please create the icon directory first:"
    echo "     mkdir -p Resources/PathPane.icon"
    echo ""
    echo "   Then add your icon assets to it."
    exit 1
fi

echo "🔧 Compiling icon..."

# Create output directory
mkdir -p "${SCRIPT_DIR}/Resources/Compiled"

# Compile .icon to Assets.car
xcrun actool "$ICON_DIR" \
    --compile "${SCRIPT_DIR}/Resources/Compiled" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon PathPane \
    --output-partial-info-plist /dev/null

echo "✅ Icon compiled: Resources/Compiled/Assets.car"
echo ""
echo "   Now commit and push:"
echo "     git add Resources/Compiled/Assets.car"
echo "     git commit -m 'Update compiled icon'"
echo "     git push"