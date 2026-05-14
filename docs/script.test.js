const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

function loadScriptContext() {
    const scriptPath = path.join(__dirname, 'script.js');
    const scriptCode = fs.readFileSync(scriptPath, 'utf8');
    const elements = new Map();
    const context = {
        console,
        fetch: async () => {
            throw new Error('fetch should not run in asset selection tests');
        },
        document: {
            getElementById(id) {
                if (!elements.has(id)) {
                    elements.set(id, {
                        id,
                        classList: {
                            remove() {},
                        },
                        style: {},
                    });
                }
                return elements.get(id);
            },
            addEventListener() {},
        },
    };

    vm.createContext(context);
    vm.runInContext(scriptCode, context, { filename: scriptPath });
    return context;
}

test('selectDownloadAssets prefers Windows installer and also exposes portable build', () => {
    const context = loadScriptContext();
    const assets = [
        { name: 'shamor-vezachor-windows-portable.zip', browser_download_url: 'https://example.test/portable.zip' },
        { name: 'shamor-vezachor-windows-setup.exe', browser_download_url: 'https://example.test/setup.exe' },
        { name: 'shamor-vezachor.apk', browser_download_url: 'https://example.test/app.apk' },
    ];

    const selected = context.selectDownloadAssets(assets);

    assert.equal(selected.windowsInstaller.name, 'shamor-vezachor-windows-setup.exe');
    assert.equal(selected.windowsPortable.name, 'shamor-vezachor-windows-portable.zip');
    assert.equal(selected.android.name, 'shamor-vezachor.apk');
});

test('download section renders Android, Windows portable, and Windows installer in one button row', () => {
    const htmlPath = path.join(__dirname, 'index.html');
    const html = fs.readFileSync(htmlPath, 'utf8');
    const rowMatch = html.match(/<div[^>]+class="download-buttons"[^>]*>([\s\S]*?)<\/div>/);

    assert.ok(rowMatch, 'expected a single download-buttons row');
    assert.match(rowMatch[1], /id="download-android"/);
    assert.match(rowMatch[1], /id="download-windows-portable"/);
    assert.match(rowMatch[1], /id="download-windows"/);
    assert.ok(
        rowMatch[1].indexOf('id="download-android"') < rowMatch[1].indexOf('id="download-windows"') &&
        rowMatch[1].indexOf('id="download-windows"') < rowMatch[1].indexOf('id="download-windows-portable"'),
        'expected Windows installer to be the middle button'
    );
    assert.match(rowMatch[1], /ווינדוס - התקנה/);
    assert.match(rowMatch[1], /מומלץ: התקנה רגילה למחשב/);
    assert.doesNotMatch(html, /class="download-card"/);
});
