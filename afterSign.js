const { notarize } = require('electron-notarize');
const path = require('path');
const fs = require('fs');

module.exports = async function (params) {
  // Only notarize the app if we're on macOS and running in a CI environment
  if (process.platform !== 'darwin' || !process.env.CI) {
    console.log('Skipping notarization - not on macOS or not in CI environment');
    return;
  }
  
  console.log('Notarizing macOS application...');

  const appBundleId = params.packagerConfig.appBundleId;
  const appName = params.packagerConfig.name;
  const appPath = path.join(params.appOutDir, `${appName}.app`);
  
  if (!fs.existsSync(appPath)) {
    throw new Error(`Cannot find application at: ${appPath}`);
  }

  try {
    // Check if the required environment variables are available
    if (!process.env.APPLE_ID || !process.env.APPLE_ID_PASSWORD || !process.env.APPLE_TEAM_ID) {
      throw new Error('Required environment variables APPLE_ID, APPLE_ID_PASSWORD, or APPLE_TEAM_ID are missing');
    }

    await notarize({
      appBundleId,
      appPath,
      appleId: process.env.APPLE_ID,
      appleIdPassword: process.env.APPLE_ID_PASSWORD,
      teamId: process.env.APPLE_TEAM_ID,
    });
    
    console.log(`Successfully notarized ${appName}`);
  } catch (error) {
    console.error('Error during notarization:', error);
    throw error;
  }
};