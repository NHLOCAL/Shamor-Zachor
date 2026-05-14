// --- Release Fetcher ---
const GITHUB_OWNER = 'NHLOCAL';
const GITHUB_REPO = 'Shamor-Zachor';
const API_URL = `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`;

const versionDownloadsEl = document.getElementById('version-downloads');
const downloadWindowsBtn = document.getElementById('download-windows');
const downloadWindowsPortableBtn = document.getElementById('download-windows-portable');
const downloadAndroidBtn = document.getElementById('download-android');
const errorMessageEl = document.getElementById('error-message');

function selectDownloadAssets(assets) {
    return {
        windowsInstaller: assets.find(asset => /windows.*setup.*\.exe$/i.test(asset.name) || /setup.*windows.*\.exe$/i.test(asset.name) || /windows.*installer.*\.exe$/i.test(asset.name)),
        windowsPortable: assets.find(asset => /windows.*portable.*\.zip$/i.test(asset.name) || /portable.*windows.*\.zip$/i.test(asset.name) || /-windows\.zip$/i.test(asset.name)),
        android: assets.find(asset => asset.name.endsWith('.apk')),
    };
}

async function fetchLatestRelease() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) {
            throw new Error(`GitHub API error: ${response.status}`);
        }
        const release = await response.json();
        
        const tagName = release.tag_name;
        const version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        
        const { windowsInstaller, windowsPortable, android } = selectDownloadAssets(release.assets);
        versionDownloadsEl.textContent = `גרסה ${version}`;

        if (windowsInstaller) {
            downloadWindowsBtn.href = windowsInstaller.browser_download_url;
            downloadWindowsBtn.innerHTML = '<i class="fa-brands fa-windows"></i><span><strong>ווינדוס - התקנה</strong><small>מומלץ: התקנה רגילה למחשב</small></span>';
            downloadWindowsBtn.classList.remove('disabled');
        } else {
            downloadWindowsBtn.textContent = 'גרסת התקנה לא זמינה';
        }

        if (windowsPortable) {
            downloadWindowsPortableBtn.href = windowsPortable.browser_download_url;
            downloadWindowsPortableBtn.innerHTML = '<i class="fa-solid fa-file-zipper"></i><span><strong>ווינדוס - ניידת</strong><small>ללא התקנה, מתוך קובץ ZIP</small></span>';
            downloadWindowsPortableBtn.classList.remove('disabled');
        } else {
            downloadWindowsPortableBtn.textContent = 'גרסה ניידת לא זמינה';
        }

        if (android) {
            downloadAndroidBtn.href = android.browser_download_url;
            downloadAndroidBtn.innerHTML = '<i class="fa-brands fa-android"></i><span><strong>אנדרואיד</strong><small>קובץ APK להתקנה בטלפון</small></span>';
            downloadAndroidBtn.classList.remove('disabled');
        } else {
            downloadAndroidBtn.textContent = 'Android לא זמין';
        }

    } catch (error) {
        console.error('Failed to fetch release info:', error);
        errorMessageEl.style.display = 'block';
        document.getElementById('download-loader').style.display = 'none';
    }
}

// Run the release fetcher when the DOM is ready
document.addEventListener('DOMContentLoaded', fetchLatestRelease);
