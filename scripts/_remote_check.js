#!/usr/bin/env node

// 用法: node sync-via-etag.js <远程原始文件URL> <本地文件路径>
// 示例: node sync-via-etag.js https://raw.githubusercontent.com/torvalds/linux/master/README ./linux-readme.md

const fs = require('fs');
const path = require('path');

// 获取项目根目录（脚本所在目录的父目录）
const PROJECT_ROOT = path.join(__dirname, '..');

/**
 * 从本地 .etag 文件读取保存的 ETag
 * @param {string} localFile
 * @returns {string|null}
 */
function loadLocalETag(localFile) {
    const etagFile = path.join(PROJECT_ROOT, 'etags', localFile + '.etag');
    if (fs.existsSync(etagFile)) {
        return fs.readFileSync(etagFile, 'utf-8').trim();
    }
    return null;
}

/**
 * 保存 ETag 到 .etag 文件
 */
function saveETag(localFile, etag) {
    const etagFile = path.join(PROJECT_ROOT, 'etags', localFile + '.etag');
    const dir = path.dirname(etagFile);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(etagFile, etag, 'utf-8');
}

async function syncViaConditionalRequest(url, localPath) {
    // 确保目录存在
    const dir = path.dirname(localPath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }

    // 构造请求头
    const headers = {
        'User-Agent': 'NodeSyncScript/1.0',
    };

    const cachedETag = loadLocalETag(localPath);
    if (cachedETag && fs.existsSync(localPath)) {
        headers['If-None-Match'] = cachedETag;
        console.log(`[缓存] 使用 ETag: ${cachedETag}`);
    }

    const response = await fetch(url, { headers });

    // 304 → 文件未变化
    if (response.status === 304) {
        console.log('结果：远程文件未变化（304），无需下载。');
        return true;
    }

    if (!response.ok) {
        throw new Error(`请求失败: ${response.status} ${response.statusText}`);
    }

    // 200 → 文件更新或首次下载
    const newETag = response.headers.get('etag');
    if (newETag == cachedETag) {
        console.log('结果：远程文件未变化（ETag 相同），无需下载。');
        return true;
    }
    saveETag(localPath, newETag);
    console.log(`[更新] 新 ETag: ${newETag}`);

    // 写入文件
    const buffer = Buffer.from(await response.arrayBuffer());
    fs.writeFileSync(localPath, buffer);
    console.log('文件已保存到', localPath);
    return true;
}


module.exports = syncViaConditionalRequest
