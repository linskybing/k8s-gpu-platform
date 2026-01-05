#!/bin/bash

# Stop script on error
set -e

echo "Starting submodule update process..."

echo "Initializing submodules..."
git submodule update --init --recursive

echo "------------------------------------------------"

# Update k8s-multicast-setting
echo "Updating k8s-multicast-setting (master branch)..."
cd k8s-cluster-setup
git fetch origin
git checkout master
git pull origin master
cd ..

# Update k8s-device-plugin
echo "Updating k8s-device-plugin (mps-individual-gpu branch)..."
cd k8s-device-plugin
git fetch origin

git checkout mps-individual-gpu
git pull origin mps-individual-gpu
cd ..

# Update frontend-go
echo "Updating frontend-go (main branch)..."
cd frontend
git fetch origin
git checkout main
git pull origin main
cd ..

# Update platform-go
echo "Updating platform-go (main branch)..."
cd backend
git fetch origin
git checkout main
git pull origin main
cd ..

echo "------------------------------------------------"
echo "All submodules updated successfully!"
echo ""
echo "To commit these updates to the main repository, run:"
echo "  git add -A"
echo "  git commit -m 'chore: update all submodules to latest remote HEAD'"