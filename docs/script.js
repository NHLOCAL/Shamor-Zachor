const GITHUB_OWNER = 'NHLOCAL';
const GITHUB_REPO = 'Shamor-Zachor';
const API_URL = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`;

const versionWindowsEl = document.getElementById('version-windows');
const versionAndroidEl = document.getElementById('version-android');
const downloadWindowsBtn = document.getElementById('download-windows');
const downloadAndroidBtn = document.getElementById('download-android');
const errorMessageEl = document.getElementById('error-message');

async function fetchLatestRelease() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) {
            throw new Error(`GitHub API error: ${response.status}`);
        }
        const release = await response.json();
        
        const tagName = release.tag_name; // e.g., "v0.9.0"
        const version = tagName.startsWith('v') ? tagName.substring(1) : tagName; // "0.9.0"
        
        const assets = release.assets;
        
        // --- Find assets ---
        const windowsAsset = assets.find(asset => asset.name.endsWith('-windows.zip'));
        const androidAsset = assets.find(asset => asset.name.endsWith('.apk'));

        // --- Update UI ---
        if (windowsAsset) {
            versionWindowsEl.textContent = `גרסה ${version}`;
            downloadWindowsBtn.href = windowsAsset.browser_download_url;
            // The line below was updated
            downloadWindowsBtn.innerHTML = '<i class="fa-solid fa-download"></i> הורדה';
            downloadWindowsBtn.classList.remove('disabled');
        } else {
            versionWindowsEl.textContent = 'לא נמצאה גרסה';
            downloadWindowsBtn.textContent = 'לא זמין';
        }

        if (androidAsset) {
            versionAndroidEl.textContent = `גרסה ${version}`;
            downloadAndroidBtn.href = androidAsset.browser_download_url;
            // The line below was updated
            downloadAndroidBtn.innerHTML = '<i class="fa-solid fa-download"></i> הורדה';
            downloadAndroidBtn.classList.remove('disabled');
        } else {
            versionAndroidEl.textContent = 'לא נמצאה גרסה';
            downloadAndroidBtn.textContent = 'לא זמין';
        }

    } catch (error) {
        console.error('Failed to fetch release info:', error);
        errorMessageEl.style.display = 'block';
        document.getElementById('download-loader').style.display = 'none';
    }
}

fetchLatestRelease();