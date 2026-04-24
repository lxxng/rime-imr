// 同步远程数据


const fs = require('fs');
const path = require('path');
const https = require('https');

// 获取项目根目录（脚本所在目录的父目录）
const PROJECT_ROOT = path.join(__dirname, '..');

// 下载远程文件内容 - 正确处理UTF-8编码
function downloadRemoteFile(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                reject(new Error(`下载失败: ${response.statusCode} ${response.statusMessage}`));
                return;
            }
            
            // 明确设置响应编码为utf8
            response.setEncoding('utf8');
            
            let data = '';
            response.on('data', (chunk) => {
                data += chunk;
            });
            
            response.on('end', () => {
                resolve(data);
            });
            
            response.on('error', (error) => {
                reject(error);
            });
        }).on('error', (error) => {
            reject(error);
        });
    });
}

// 读取本地文件内容 - 明确指定UTF-8编码
function readLocalFile(projectRelativePath) {
    const fullPath = path.join(PROJECT_ROOT, projectRelativePath);
    return new Promise((resolve, reject) => {
        fs.readFile(fullPath, { encoding: 'utf8' }, (err, data) => {
            if (err) {
                if (err.code === 'ENOENT') {
                    resolve(null); // 文件不存在，返回null
                } else {
                    reject(err);
                }
            } else {
                resolve(data);
            }
        });
    });
}

// 写入本地文件 - 明确指定UTF-8编码，不添加BOM
function writeLocalFile(projectRelativePath, data) {
    const fullPath = path.join(PROJECT_ROOT, projectRelativePath);
    // 确保目录存在
    const dir = path.dirname(fullPath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    
    return new Promise((resolve, reject) => {
        // 确保不添加BOM
        const buffer = Buffer.from(data, 'utf8');
        fs.writeFile(fullPath, buffer, (err) => {
            if (err) {
                reject(err);
            } else {
                resolve();
            }
        });
    });
}

// 检查并更新单个文件
async function checkAndUpdateFile(projectRelativePath, remoteUrl) {
    try {
        console.log(`\n检查文件: ${projectRelativePath}`);
        
        // 下载远程文件
        const remoteContent = await downloadRemoteFile(remoteUrl);
        console.log('✓ 远程文件下载成功');
        
        // 读取本地文件
        const localContent = await readLocalFile(projectRelativePath);
        
        if (localContent === null) {
            // 本地文件不存在
            console.log('  ⚠ 本地文件不存在，正在创建并同步...');
            await writeLocalFile(projectRelativePath, remoteContent);
            console.log('  ✓ 文件已创建并同步完成');
        } else if (localContent === remoteContent) {
            // 文件内容相同
            console.log('  ✓ 本地文件已是最新版本');
        } else {
            // 文件内容不同，需要更新
            console.log('  ⚠ 检测到文件需要更新');
            await writeLocalFile(projectRelativePath, remoteContent);
            console.log('  ✓ 文件已更新');
        }
        
        return true;
    } catch (error) {
        console.error(`  ❌ 处理文件 ${projectRelativePath} 时出错:`, error.message);
        return false;
    }
}

// 主函数
async function update(files) {
    console.log('开始检查并同步文件...');
    console.log(`项目根目录: ${PROJECT_ROOT}`);
    console.log(`共配置了 ${Object.keys(files).length} 个文件\n`);
    
    let successCount = 0;
    let totalCount = 0;
    
    // 遍历所有配置的文件
    for (const [projectRelativePath, remoteUrl] of Object.entries(files)) {
        totalCount++;
        const success = await checkAndUpdateFile(projectRelativePath, remoteUrl);
        if (success) successCount++;
    }
    
    console.log(`\n====================`);
    console.log(`同步完成! 成功: ${successCount}/${totalCount} 个文件`);
    if (successCount < totalCount) {
        console.log('⚠ 部分文件同步失败，请检查上面的错误信息');
        process.exit(1);
    }
}


module.exports = {
    update: update
}