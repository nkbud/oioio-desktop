---
description: >-
  Code signing is a security technology that you use to certify that an app was
  created by you.
---

# Signing a Windows app

## Using traditional certificates

{% hint style="warning" %}
Starting June 1, 2023 at 00:00 UTC, private keys for code signing certificates need to be stored on a hardware storage module compliant with FIPS 140 Level 2, Common Criteria EAL 4+ or equivalent.\
\
In practice, this means that software-based OV certificates used in the steps below will no longer be available for purchase. For instructions on how to sign applications with newer token-based certificates, consult your Certificate Authority's documentation.
{% endhint %}

### Prerequisites

#### Installing Visual Studio

On Windows, apps are signed using [Sign Tool](https://learn.microsoft.com/en-us/dotnet/framework/tools/signtool-exe), which is included in Visual Studio. Install Visual Studio to get the signing utility (the free [Community Edition](https://visualstudio.microsoft.com/vs/community/) is enough).

#### Acquiring a certificate

You can get a [Windows Authenticode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/authenticode) code signing certificate from many vendors. Prices vary, so it may be worth your time to shop around. Popular vendors include:

* [digicert](https://www.digicert.com/dc/code-signing/microsoft-authenticode.htm)
* [Sectigo](https://sectigo.com/ssl-certificates-tls/code-signing)
* Amongst others, please shop around to find one that suits your needs! 😄

{% hint style="danger" %}
**Keep your certificate password private**

Your certificate password should be a **secret**. Do not share it publicly or commit it to your source code.
{% endhint %}

### Configuring Electron Forge

On Windows, Electron apps are signed on the installer level at the **Make** step.

Once you have a Personal Information Exchange (`.pfx`) file for your certificate, you can sign [Squirrel.Windows](../../config/makers/squirrel.windows.md) and [MSI](../../config/makers/wix-msi.md) installers in Electron Forge with the `certificateFile` and `certificatePassword` fields in their respective configuration objects.

For example, if you are creating a Squirrel.Windows installer:

{% code title="forge.config.js" %}
```javascript
module.exports = {
  packagerConfig: {},
  makers: [
    {
      name: '@electron-forge/maker-squirrel',
      config: {
        certificateFile: './cert.pfx',
        certificatePassword: process.env.CERTIFICATE_PASSWORD
      }
    }
  ]
};
```
{% endcode %}

## Using Azure Trusted Signing

[Azure Trusted Signing](https://azure.microsoft.com/en-us/products/trusted-signing) is Microsoft's modern cloud-based alternative to EV certificates. It is the cheapest option for code signing on Windows, and it gets rid of SmartScreen warnings.

As of November 2024, Azure Trusted Signing is available to organizations with 3+ years of verifiable business history and to individuals. Microsoft is [looking to make the program available](https://github.com/Azure/trusted-signing-action/issues/42#issuecomment-2488402061) to organizations with a shorter history, too. If you're reading this at a later point, it could make sense to check.

### Prerequisites <a href="#prerequisites-trusted-signing" id="prerequisites-trusted-signing"></a>

First, create an Azure account and set up Azure Trusted Signing in your account as described [here](https://melatonin.dev/blog/code-signing-on-windows-with-azure-trusted-signing/).

Then install the dependencies for local code signing as described [here](https://melatonin.dev/blog/code-signing-on-windows-with-azure-trusted-signing/#step-8-signing-locally). Also create the required `metadata.json` file in an arbitrary location on your computer.

### Configuring Electron Forge <a href="#configuring-forge-trusted-signing" id="configuring-forge-trusted-signing"></a>

#### Installing npm dependencies

In your project directory, do the following:

1. Install the `dotenv-cli` package: `npm i -D dotenv-cli`
2. Update `@electron/windows-sign` to version 1.2.0 or later: `npm update @electron/windows-sign`

#### Creating the `.env.trustedsigning` file

Create a file `.env.trustedsigning` in your project root with the following content:

{% code title=".env.trustedsigning" %}
```text
AZURE_CLIENT_ID='xxx'
AZURE_CLIENT_SECRET='xxx'
AZURE_TENANT_ID='xxx'
AZURE_METADATA_JSON='C:\path\to\metadata.json'
AZURE_CODE_SIGNING_DLIB='C:\path\to\bin\x64\Azure.CodeSigning.Dlib.dll'
SIGNTOOL_PATH='C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe'
```
{% endcode %}

Fill in the credentials for your Azure App Registration user into the first three variables.

Adjust the other variables to be the absolute paths to the `metadata.json`, `Azure.CodeSigning.Dlib.dll` and `signtool.exe` files that you created or installed as part of the prerequisites.

{% hint style="warning" %}
Ensure that none of the paths have spaces in them. Otherwise, signing will fail. (`@electron/windows-sign` issue [#45](https://github.com/electron/windows-sign/issues/45) currently prevents quoting of paths with spaces.)
{% endhint %}

#### Adjusting your `.gitignore`

Add `.env.trustedsigning` to your `.gitignore` file. You should never commit login credentials to version control.

In addition, add `electron-windows-sign.log` to `.gitignore`. This file will be created automatically during the signing process.

{% code title=".gitignore" %}
```gitignore
.env.trustedsigning
electron-windows-sign.log
```
{% endcode %}

#### Creating the `windowsSign.ts` file

Create a file `windowsSign.ts` in your project root with the following content:

{% code title="windowsSign.ts" %}
```typescript
import type { WindowsSignOptions } from "@electron/packager";
import type { HASHES } from "@electron/windows-sign/dist/esm/types";

export const windowsSign: WindowsSignOptions = {
  ...(process.env.SIGNTOOL_PATH
    ? { signToolPath: process.env.SIGNTOOL_PATH }
    : {}),
  signWithParams: `/v /debug /dlib ${process.env.AZURE_CODE_SIGNING_DLIB} /dmdf ${process.env.AZURE_METADATA_JSON}`,
  timestampServer: "http://timestamp.acs.microsoft.com",
  hashes: ["sha256" as HASHES],
};
```
{% endcode %}

{% hint style="info" %}
If you are using JavaScript for your configuration instead of TypeScript, adjust the file accordingly. Name the file `windowsSign.js` and remove the type information.
{% endhint %}

Some notes:

We specify the `/v` and `/debug` parameters even though they aren't technically required. This ensures that warnings are logged if timestamping fails.

**Do not** use the `debug` parameter on the `WindowsSignOptions`. Similarly, **do not** enable the `DEBUG` environment variable for `electron-windows-sign`. (If you do either of them, the `debug` npm package will log all debug messages to stderr. An executable in `@electron/windows-sign` will interpret the existence of messages printed to stderr as a signing failure. Then your build will fail.)

#### Adjusting your `forge.config.ts`

In your `forge.config.ts`, add the following:

{% code title="forge.config.ts" %}
```typescript
// Add import:
import { windowsSign } from "./windowsSign";

const config: ForgeConfig = {
  packagerConfig: {
    // Add this line:
    windowsSign,
  },
  makers: [
    new MakerSquirrel({
      // Add the following two lines:
      // @ts-expect-error - incorrect types exported by MakerSquirrel
      windowsSign,
    }),
  ],
};
```
{% endcode %}

#### Updating your npm scripts

<!-- markdownlint-disable-next-line MD038 -->
When you call scripts such as `electron-forge make` or `electron-forge publish`, you will now have to prefix them with `dotenv -e .env.trustedsigning -- `. This loads the environment variables from the `.env.trustedsigning` file.

For example, your npm scripts in your `package.json` might then look like this:

{% code title="package.json" %}
```json
{
  "scripts": {
    "make": "dotenv -e .env.trustedsigning -- electron-forge make",
    "publish": "dotenv -e .env.trustedsigning -- electron-forge publish"
  }
}
```
{% endcode %}
