# Build and Release Guide

This document provides comprehensive instructions for building, testing, and releasing the oioio desktop application.

## Quick Start

### Prerequisites

- Node.js 18 or higher
- npm 8 or higher
- Git

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/nkbud/oioio-desktop.git
cd oioio-desktop

# Install dependencies
npm install

# Run development server
npm start
```

## Development Workflow

### Available Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Start the app in development mode |
| `npm run start:dev` | Start with explicit development environment |
| `npm run lint` | Run ESLint to check code quality |
| `npm run lint:fix` | Automatically fix linting issues |
| `npm run clean` | Remove build artifacts and cache |
| `npm run deps:check` | Check for security vulnerabilities |
| `npm run deps:fix` | Fix security vulnerabilities |

### Code Quality

The project uses ESLint for code quality. Before committing:

```bash
# Check for issues
npm run lint

# Fix automatically fixable issues
npm run lint:fix
```

## Building

### Development Build

```bash
# Build for your current platform
npm run package
```

### Production Build

```bash
# Build distributables for your current platform
npm run make

# Build for all supported platforms (requires platform-specific dependencies)
npm run make:all
```

### Build Artifacts

After building, artifacts are located in:
- `./out/` - Packaged applications
- `./out/make/` - Distribution packages (.dmg, .exe, .deb, .rpm)

## Release Process

### Automated Release (Recommended)

The GitHub Actions workflow handles building and releasing automatically:

1. **Manual Release**:
   - Go to GitHub Actions
   - Select "Build and Release" workflow
   - Click "Run workflow"
   - Choose version type (patch/minor/major) or specify exact version
   - The workflow will build for all platforms and create a release

2. **Automatic Release on Main Branch**:
   - Push to main branch
   - Workflow automatically builds and releases

### Version Management

```bash
# Increment patch version (1.0.0 -> 1.0.1)
npm run version:patch

# Increment minor version (1.0.0 -> 1.1.0)
npm run version:minor

# Increment major version (1.0.0 -> 2.0.0)
npm run version:major
```

### Manual Release (Advanced)

If you need to release manually:

1. **Update Version**:
   ```bash
   npm run version:patch  # or minor/major
   ```

2. **Build for All Platforms**:
   ```bash
   npm run make:all
   ```

3. **Create GitHub Release**:
   ```bash
   # Tag the release
   git tag v$(node -p "require('./package.json').version")
   git push origin --tags

   # Create release using GitHub CLI
   gh release create v$(node -p "require('./package.json').version") \
     --title "Release v$(node -p "require('./package.json').version")" \
     --notes "Release notes here" \
     ./out/make/**/*
   ```

## Platform-Specific Instructions

### macOS

**Requirements**:
- Xcode Command Line Tools
- Valid Apple Developer certificate (for code signing)

**Code Signing Setup**:
1. Obtain a "Developer ID Application" certificate from Apple Developer
2. Export as .p12 file
3. Convert to base64: `base64 -i certificate.p12 -o certificate-base64.txt`
4. Add secrets to GitHub repository (see CI/CD Configuration)

### Windows

**Requirements**:
- Windows 10/11 or Windows Server 2019+
- Visual Studio Build Tools or Visual Studio 2019+

**Code Signing** (Optional):
- Obtain a code signing certificate
- Configure in `forge.config.js`

### Linux

**Requirements**:
- Ubuntu 18.04+ or equivalent
- `fpm` for building packages: `gem install fpm`

**Supported Packages**:
- `.deb` (Debian/Ubuntu)
- `.rpm` (RedHat/CentOS/Fedora)

## CI/CD Configuration

### Required GitHub Secrets

For automated releases, configure these secrets in your GitHub repository:

| Secret | Description | Required For |
|--------|-------------|--------------|
| `APPLE_ID` | Apple ID email | macOS notarization |
| `APPLE_ID_PASSWORD` | App-specific password | macOS notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID | macOS signing |
| `APPLE_DEVELOPER_IDENTITY` | Certificate name | macOS signing |
| `APPLE_DEVELOPER_CERTIFICATE_P12_BASE64` | Base64 certificate | macOS signing |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | Certificate password | macOS signing |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | macOS signing |

### Workflow Features

- ✅ Cross-platform builds (macOS, Windows, Linux)
- ✅ Automatic version management
- ✅ Code quality checks (linting, security audit)
- ✅ Code signing and notarization (macOS)
- ✅ Comprehensive error handling
- ✅ Artifact upload and release creation

## Troubleshooting

### Common Build Issues

**Webpack Asset Relocator Error**:
```bash
# Clear cache and reinstall
npm run clean
rm -rf node_modules package-lock.json
npm install
```

**Code Signing Issues (macOS)**:
- Verify certificate is valid and not expired
- Check keychain access permissions
- Ensure Apple ID has app-specific password

**Linux Package Dependencies**:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential libnss3-dev libxss1

# CentOS/RHEL
sudo yum install gcc-c++ make nss-devel libXScrnSaver
```

### Performance Tips

- Use `npm run clean` before major builds
- Enable parallel builds: `npm config set jobs max`
- Consider using local cache for faster CI builds

## Security

### Code Signing

All releases are automatically code signed:
- **macOS**: Developer ID certificate + notarization
- **Windows**: Authenticode signing (when configured)
- **Linux**: GPG signing (when configured)

### Dependency Security

```bash
# Check for vulnerabilities
npm run deps:check

# Fix automatically
npm run deps:fix
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting: `npm run lint`
5. Create a pull request

### Code Style

- Follow ESLint configuration
- Use meaningful commit messages
- Update documentation for significant changes

## Support

For build and release issues:
1. Check this documentation
2. Review GitHub Actions logs
3. Create an issue with detailed error information