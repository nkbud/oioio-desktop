#!/bin/bash

# Health check script for oioio desktop build process
# This script validates that the build environment and process are working correctly

set -e

echo "🔍 Running oioio desktop build health check..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js version
echo ""
echo "📦 Checking dependencies..."
if command_exists node; then
    NODE_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
    if [ $NODE_MAJOR -ge 18 ]; then
        print_status "ok" "Node.js version: $NODE_VERSION"
    else
        print_status "error" "Node.js version $NODE_VERSION is too old. Required: 18+"
        exit 1
    fi
else
    print_status "error" "Node.js not found"
    exit 1
fi

# Check npm version
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_status "ok" "npm version: $NPM_VERSION"
else
    print_status "error" "npm not found"
    exit 1
fi

# Check if package.json exists and is valid
if [ -f "package.json" ]; then
    if node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" 2>/dev/null; then
        print_status "ok" "package.json is valid"
        APP_VERSION=$(node -p "require('./package.json').version")
        print_status "ok" "Application version: $APP_VERSION"
    else
        print_status "error" "package.json is invalid"
        exit 1
    fi
else
    print_status "error" "package.json not found"
    exit 1
fi

# Check dependencies
echo ""
echo "🔧 Checking build environment..."
if [ -d "node_modules" ]; then
    print_status "ok" "node_modules directory exists"
else
    print_status "warn" "node_modules not found, running npm install..."
    npm install
fi

# Check critical dependencies
CRITICAL_DEPS=("@electron-forge/cli" "electron" "eslint")
for dep in "${CRITICAL_DEPS[@]}"; do
    if npm list "$dep" >/dev/null 2>&1; then
        print_status "ok" "$dep is installed"
    else
        print_status "error" "$dep is missing"
        exit 1
    fi
done

# Run linting
echo ""
echo "🔍 Running code quality checks..."
if npm run lint >/dev/null 2>&1; then
    print_status "ok" "Code linting passed"
else
    print_status "error" "Code linting failed"
    echo "Run 'npm run lint' to see details"
    exit 1
fi

# Check for security vulnerabilities
echo ""
echo "🔒 Checking security..."
AUDIT_OUTPUT=$(npm audit --audit-level=high 2>&1)
if [ $? -eq 0 ]; then
    print_status "ok" "No high-severity security vulnerabilities found"
else
    if echo "$AUDIT_OUTPUT" | grep -q "found 0 vulnerabilities"; then
        print_status "ok" "No security vulnerabilities found"
    else
        print_status "warn" "Security vulnerabilities found, run 'npm audit' for details"
    fi
fi

# Quick build validation
echo ""
echo "🏗️  Validating build configuration..."
if [ -f "forge.config.js" ]; then
    print_status "ok" "Electron Forge configuration found"
    # Check if config is valid JavaScript
    if node -c forge.config.js 2>/dev/null; then
        print_status "ok" "Forge configuration is valid"
    else
        print_status "error" "Forge configuration has syntax errors"
        exit 1
    fi
else
    print_status "error" "forge.config.js not found"
    exit 1
fi

echo ""
echo "✨ Health check completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Node.js: $NODE_VERSION"
echo "   - npm: $NPM_VERSION"
echo "   - App version: $APP_VERSION"
echo ""
echo "🚀 Your build environment is ready!"