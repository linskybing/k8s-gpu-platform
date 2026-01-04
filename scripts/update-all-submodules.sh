#!/bin/bash

# Update all submodules to their latest remote state
# This script updates each submodule to the latest commit from their respective branches

set -e

echo "Updating all submodules to latest remote state..."

# Update k8s-multicast-setting
echo "Updating k8s-multicast-setting (master branch)..."
cd k8s-multicast-setting
git fetch origin
git merge origin/master
cd ..

# Update k8s-device-plugin
echo "Updating k8s-device-plugin (mps-individual-gpu branch)..."
cd k8s-device-plugin
git fetch origin
git merge origin/mps-individual-gpu
cd ..

# Update frontend-go
echo "Updating frontend-go (main branch)..."
cd frontend-go
git fetch origin
git merge origin/main
cd ..

# Update platform-go
echo "Updating platform-go (main branch)..."
cd platform-go
git fetch origin
git merge origin/main
cd ..

echo ""
echo "All submodules updated successfully!"
echo ""
echo "To commit these updates to the main repository, run:"
echo "  git add -A"
echo "  git commit -m 'Update all submodules to latest'"
