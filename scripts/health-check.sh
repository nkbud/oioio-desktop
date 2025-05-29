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

# Test build process
echo ""
echo "🏗️  Testing build process..."
if npm run package >/dev/null 2>&1; then
    print_status "ok" "Package command succeeded"
else
    print_status "error" "Package command failed"
    exit 1
fi

# Check if output directory exists
if [ -d "out" ]; then
    print_status "ok" "Build output directory created"
    
    # Count built files
    BUILT_FILES=$(find out -type f | wc -l)
    print_status "ok" "Generated $BUILT_FILES build files"
else
    print_status "error" "Build output directory not found"
    exit 1
fi

# Platform-specific checks
echo ""
echo "🖥️  Platform-specific checks..."
case "$(uname -s)" in
    Darwin*)
        print_status "ok" "Running on macOS"
        if command_exists security; then
            print_status "ok" "macOS security tools available"
        fi
        if command_exists xcrun; then
            print_status "ok" "Xcode command line tools available"
        fi
        ;;
    Linux*)
        print_status "ok" "Running on Linux"
        if command_exists fpm; then
            print_status "ok" "FPM available for package building"
        else
            print_status "warn" "FPM not found - some package formats may not be available"
        fi
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        print_status "ok" "Running on Windows"
        ;;
    *)
        print_status "warn" "Unknown platform: $(uname -s)"
        ;;
esac

echo ""
echo "✨ Health check completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Node.js: $NODE_VERSION"
echo "   - npm: $NPM_VERSION"
echo "   - App version: $APP_VERSION"
echo "   - Platform: $(uname -s)"
echo ""
echo "🚀 Your build environment is ready!"