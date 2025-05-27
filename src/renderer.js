/**
 * This file will automatically be loaded by webpack and run in the "renderer" context.
 * To learn more about the differences between the "main" and the "renderer" context in
 * Electron, visit:
 *
 * https://electronjs.org/docs/tutorial/process-model
 *
 * By default, Node.js integration in this file is disabled. When enabling Node.js integration
 * in a renderer process, please be aware of potential security implications. You can read
 * more about security risks here:
 *
 * https://electronjs.org/docs/tutorial/security
 */

import './index.css';

document.addEventListener('DOMContentLoaded', async () => {
  console.log('👋 This message is being logged by "renderer.js", included via webpack');
  
  // Create About section
  const aboutSection = document.createElement('div');
  aboutSection.className = 'about-section';
  
  // Get app version from main process
  try {
    const version = await window.electronAPI.getAppVersion();
    
    // Create version display
    const versionElement = document.createElement('p');
    versionElement.textContent = `Version: ${version}`;
    aboutSection.appendChild(versionElement);
    
    // Create update button
    const updateButton = document.createElement('button');
    updateButton.textContent = 'Check for Updates';
    updateButton.addEventListener('click', async () => {
      try {
        updateButton.textContent = 'Checking...';
        updateButton.disabled = true;
        await window.electronAPI.checkForUpdates();
        setTimeout(() => {
          updateButton.textContent = 'Check for Updates';
          updateButton.disabled = false;
        }, 5000);
      } catch (error) {
        console.error('Error checking for updates:', error);
        updateButton.textContent = 'Check for Updates';
        updateButton.disabled = false;
      }
    });
    aboutSection.appendChild(updateButton);
    
    // Create update notification area
    const updateNotification = document.createElement('div');
    updateNotification.id = 'update-notification';
    updateNotification.style.display = 'none';
    updateNotification.className = 'update-notification';
    aboutSection.appendChild(updateNotification);
    
    // Add About section to the page
    document.body.appendChild(aboutSection);
    
    // Handle update events
    window.electronAPI.onUpdateAvailable(() => {
      updateNotification.style.display = 'block';
      updateNotification.innerHTML = '<p>Update available. Downloading...</p>';
    });
    
    window.electronAPI.onDownloadProgress((event, progressObj) => {
      updateNotification.innerHTML = `<p>Downloading update: ${Math.round(progressObj.percent)}%</p>`;
    });
    
    window.electronAPI.onUpdateDownloaded(() => {
      updateNotification.innerHTML = '<p>Update downloaded. <button id="restart-button">Restart Now</button></p>';
      document.getElementById('restart-button').addEventListener('click', () => {
        window.electronAPI.quitAndInstall();
      });
    });
  } catch (error) {
    console.error('Error getting app version:', error);
    // Display error in About section
    const errorElement = document.createElement('p');
    errorElement.textContent = 'Error loading version information';
    aboutSection.appendChild(errorElement);
    document.body.appendChild(aboutSection);
  }
});
