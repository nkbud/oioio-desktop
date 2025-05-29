# oioio Desktop

Desktop application for oioio.

## Quick Start

### Prerequisites

- Node.js 18 or higher
- npm

### Setup & Run

```bash
# Install dependencies
npm install

# Start development server
npm start
```

## Building & Release

For detailed build instructions, code signing setup, and release process, see [BUILD.md](BUILD.md).

### Quick Commands

```bash
# Build for current platform
npm run make

# Run linting
npm run lint

# Clean build artifacts
npm run clean
```

## Automated Releases

This project uses GitHub Actions for automated cross-platform builds and releases:

- **Manual**: Trigger workflow in GitHub Actions with version selection
- **Automatic**: Push to main branch for automatic release
- **Platforms**: macOS (Intel & Apple Silicon), Windows, Linux

## Development

The app is built with:
- [Electron](https://electronjs.org/) - Desktop app framework
- [Electron Forge](https://www.electronforge.io/) - Build and packaging
- [Webpack](https://webpack.js.org/) - Module bundling
- [ESLint](https://eslint.org/) - Code quality

### Project Structure

```
├── src/                 # Source code
│   ├── main.js         # Main process
│   ├── renderer.js     # Renderer process
│   └── preload.js      # Preload script
├── assets/             # Static assets
├── .github/workflows/  # CI/CD workflows
├── forge.config.js     # Electron Forge configuration
└── BUILD.md           # Detailed build instructions
```

## Features

- ✅ Cross-platform support (macOS, Windows, Linux)
- ✅ Auto-updater integration
- ✅ Code signing and notarization (macOS)
- ✅ Modern development workflow
- ✅ Automated CI/CD pipeline

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `npm run lint` to check code quality
5. Create a pull request

See [BUILD.md](BUILD.md) for detailed development and release instructions.