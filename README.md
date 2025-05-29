# oioio Desktop

Desktop application for oioio.

## Development

### Prerequisites

- Node.js 18 or higher
- npm

### Setup

```bash
npm install
```

### Running Development Mode

```bash
npm start
```

### Building for Production

```bash
npm run make
```

## macOS Code Signing and Notarization

The application is automatically code signed and notarized for macOS during the GitHub Actions build process. This ensures the app can be run on macOS without Gatekeeper warnings.

### Required Secrets for macOS Signing

The following GitHub secrets need to be set up in the repository settings for proper code signing and notarization:

- `APPLE_ID`: The Apple ID email used for notarization
- `APPLE_ID_PASSWORD`: An app-specific password for the Apple ID
- `APPLE_TEAM_ID`: The Team ID from your Apple Developer account
- `APPLE_DEVELOPER_IDENTITY`: The name of your Developer ID certificate (e.g., "Developer ID Application: Your Name (TEAM_ID)")
- `APPLE_DEVELOPER_CERTIFICATE_P12_BASE64`: The base64-encoded p12 certificate file
- `APPLE_DEVELOPER_CERTIFICATE_PASSWORD`: The password for the p12 certificate
- `KEYCHAIN_PASSWORD`: A password to secure the keychain during the build process

### Generating a Certificate for Code Signing

1. Obtain a "Developer ID Application" certificate from your [Apple Developer Account](https://developer.apple.com/account/resources/certificates/list)
2. Export the certificate from Keychain Access as a .p12 file
3. Convert the .p12 file to base64 format:
   ```bash
   base64 -i path/to/certificate.p12 -o certificate-base64.txt
   ```
4. Use the contents of certificate-base64.txt as the value for the `APPLE_DEVELOPER_CERTIFICATE_P12_BASE64` secret

### Manual Notarization (if needed)

To manually notarize an app:

1. Package the app using electron-forge:
   ```bash
   npm run make
   ```

2. Notarize the .app bundle using Apple's notarytool:
   ```bash
   xcrun notarytool submit path/to/YourApp.app --apple-id your-apple-id@example.com --password your-app-specific-password --team-id YOUR_TEAM_ID --wait
   ```

3. Staple the notarization to the app:
   ```bash
   xcrun stapler staple path/to/YourApp.app
   ```

## Release Process

Releases are automatically created when code is pushed to the main branch. The GitHub Actions workflow:

1. Increments the version number
2. Builds and signs the application
3. Notarizes the application (macOS only)
4. Creates a GitHub release with the packaged artifacts