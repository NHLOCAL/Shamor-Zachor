// --- Release Fetcher ---
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
        
        const tagName = release.tag_name;
        const version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        
        const assets = release.assets;
        
        const windowsAsset = assets.find(asset => asset.name.endsWith('-windows.zip'));
        const androidAsset = assets.find(asset => asset.name.endsWith('.apk'));

        if (windowsAsset) {
            versionWindowsEl.textContent = `גרסה ${version}`;
            downloadWindowsBtn.href = windowsAsset.browser_download_url;
            downloadWindowsBtn.innerHTML = '<i class="fa-solid fa-download"></i> הורדה';
            downloadWindowsBtn.classList.remove('disabled');
        } else {
            versionWindowsEl.textContent = 'לא נמצאה גרסה';
            downloadWindowsBtn.textContent = 'לא זמין';
        }

        if (androidAsset) {
            versionAndroidEl.textContent = `גרסה ${version}`;
            downloadAndroidBtn.href = androidAsset.browser_download_url;
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

// Run the release fetcher when the DOM is ready
document.addEventListener('DOMContentLoaded', fetchLatestRelease);


// --- Screenshot Carousel ---
// FIX: Run carousel logic only after all images are loaded
window.addEventListener('load', () => {
    const track = document.querySelector('.carousel-track');
    if (!track) return;

    const slides = Array.from(track.children);
    const nextButton = document.querySelector('.carousel-button.next');
    const prevButton = document.querySelector('.carousel-button.prev');
    const dotsNav = document.querySelector('.carousel-nav');
    
    if (slides.length === 0) return;

    // Create dots
    slides.forEach((_, index) => {
        const dot = document.createElement('button');
        dot.classList.add('carousel-dot');
        if (index === 0) dot.classList.add('active');
        dotsNav.appendChild(dot);
    });
    
    const dots = Array.from(dotsNav.children);
    let slideWidth = slides[0].getBoundingClientRect().width;
    let currentIndex = 0;
    let autoPlayInterval;

    const moveToSlide = (targetIndex) => {
        // Recalculate width just in case of resize
        slideWidth = slides[0].getBoundingClientRect().width;
        track.style.transform = 'translateX(-' + (slideWidth * targetIndex) + 'px)';
        if(dots[currentIndex]) dots[currentIndex].classList.remove('active');
        if(dots[targetIndex]) dots[targetIndex].classList.add('active');
        currentIndex = targetIndex;
    };
    
    dots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            moveToSlide(index);
            resetInterval();
        });
    });

    const startInterval = () => {
        autoPlayInterval = setInterval(() => {
            const nextIndex = (currentIndex + 1) % slides.length;
            moveToSlide(nextIndex);
        }, 6000); // 6 seconds
    };
    
    const resetInterval = () => {
        clearInterval(autoPlayInterval);
        startInterval();
    };

    // Button event listeners
    nextButton.addEventListener('click', () => {
        const nextIndex = (currentIndex + 1) % slides.length;
        moveToSlide(nextIndex);
        resetInterval();
    });

    prevButton.addEventListener('click', () => {
        const prevIndex = (currentIndex - 1 + slides.length) % slides.length;
        moveToSlide(prevIndex);
        resetInterval();
    });
    
    // Add resize listener to fix layout on window size changes
    window.addEventListener('resize', () => {
        moveToSlide(currentIndex);
    });

    // Initial start
    moveToSlide(0); // Set initial position
    startInterval();
});