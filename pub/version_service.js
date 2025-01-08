const express = require('express');
const fs = require('fs').promises;
const app = express();
const port = 3290;
const pubspecPath = '../pubspec.yaml';
const changeLogPath = '../CHANGELOG.md';
const cacheValidity = 3 * 60 * 1000; // 3 minutes
// const cacheValidity = 0;

const parseVersion = async () => {
    const pubspec = await fs.readFile(pubspecPath, 'utf8');
    const lines = pubspec.split('\n');
    let version;
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.startsWith('version:')) {
            version = line.split(':')[1].trim();
        }
    }

    const changeLog = await fs.readFile(changeLogPath, 'utf8');
    const changeLogLines = changeLog.split('\n');
    let changeLogContent = '';
    let found = false;
    for (let i = 0; i < changeLogLines.length; i++) {
        const line = changeLogLines[i];
        if (line.length === 0) continue;
        if (line.startsWith('## ' + version)) {
            if (found) break;
            found = true;
        } else if (found) {
            // changeLogContent += '- ' + line.slice(1).trim() + '\n';
            changeLogContent += `- ${line.slice(1).trim()}\n`;
        }
    }

    return {
        version: version,
        changeLog: changeLogContent,
    };
};

let lastParseTime = 0;
let versionCache = null;

app.get('/tieba-image-fetch/latest-version', async (req, res) => {
    const currentTime = new Date().getTime();
    if (currentTime - lastParseTime > cacheValidity || !versionCache) {
        versionCache = await parseVersion();
        lastParseTime = currentTime;
    }
    res.json(versionCache);
});

app.listen(port, () => {
    console.log(`listening at http://localhost:${port}`);
});
