const files = {
    'dicts/ice/8105.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/8105.dict.yaml',
    'dicts/ice/41448.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/41448.dict.yaml',
    'dicts/ice/base.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/base.dict.yaml',
    'dicts/ice/ext.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/ext.dict.yaml',
    'dicts/ice/others.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/others.dict.yaml',
    'dicts/ice/tencent.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/tencent.dict.yaml',
    'dicts/ice/cn_en_double_pinyin.txt': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/cn_en_double_pinyin.txt',
    'dicts/ice/cn_en.txt': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/cn_en.txt',
    'dicts/ice/en_ext.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/en_ext.dict.yaml',
    'dicts/ice/en.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/en.dict.yaml',
    'dicts/lookup/radical_pinyin.dict.yaml': 'https://raw.githubusercontent.com/mirtlecn/rime-radical-pinyin/master/radical_pinyin.dict.yaml',
    'dicts/lookup/stroke.dict.yaml': 'https://raw.githubusercontent.com/rime/rime-stroke/master/stroke.dict.yaml',
    'tmp/aux_code/ZRM-wanxiang.txt': 'https://raw.githubusercontent.com/HowcanoeWang/rime-lua-aux-code/main/aux_code/ZRM-wanxiang.txt',
    'dicts/wanxiang/zi.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/zi.dict.yaml',
    'dicts/wanxiang/jichu.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/jichu.dict.yaml',
    'dicts/wanxiang/lianxiang.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/lianxiang.dict.yaml',
    'dicts/wanxiang/cuoyin.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/cuoyin.dict.yaml',
    'dicts/wanxiang/duoyin.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/duoyin.dict.yaml',
    'dicts/wanxiang/shici.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/shici.dict.yaml',
    'dicts/wanxiang/diming.dict.yaml': 'https://cnb.cool/amzxyz/rime-wanxiang/-/git/raw/wanxiang/dicts/diming.dict.yaml',
    'lua/librime.lua': 'https://raw.githubusercontent.com/hchunhui/librime-lua/master/contrib/librime.lua'
};

// 同步远程数据


const fs = require('fs');
const path = require('path');
const https = require('https');
const PROJECT_ROOT = path.join(__dirname, '..');
const checkAndUpdateFile = require(path.join(PROJECT_ROOT, 'scripts', '_remote_check'));



// 主函数
async function updateFiles() {
    console.log('开始检查并同步文件...');
    console.log(`共配置了 ${Object.keys(files).length} 个文件\n`);
    
    let successCount = 0;
    let totalCount = 0;
    
    // 遍历所有配置的文件
    for (const [projectRelativePath, remoteUrl] of Object.entries(files)) {
        totalCount++;
        const success = await checkAndUpdateFile(remoteUrl, projectRelativePath);
        if (success) successCount++;
    }
    
    console.log(`\n====================`);
    console.log(`同步完成! 成功: ${successCount}/${totalCount} 个文件`);
    if (successCount < totalCount) {
        console.log('⚠ 部分文件同步失败，请检查上面的错误信息');
        process.exit(1);
    }
}
updateFiles()