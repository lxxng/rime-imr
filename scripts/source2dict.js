/**
 * 将 https://github.com/HowcanoeWang/rime-lua-aux-code 格式的辅助码文件转为字典
 */
const aux_code_files = {
    'ZRM-wanxiang': {
        source: {
            file: 'tmp/aux_code/ZRM-wanxiang.txt',
        },
        // target: {
        //     file: 'dicts/lookup/ZRM-wanxiang.dict.yaml',
        //     name: 'ZRM-wanxiang',
        // },
    },
}

// 读取ZRM_wanxiang.dict.yaml文件并处理
const fs = require('fs');
const path = require('path');

Object.keys(aux_code_files).forEach(key => {
    const source = aux_code_files[key].source;
    const target = aux_code_files[key].target;
    const source_file = path.join(__dirname,
        '..',  // 因为当前脚本在scripts文件夹内
        source?.file ?? `tmp/aux_code/${key}.txt`);
    const target_file = path.join(__dirname,
        '..',
        target?.file ?? `dicts/lookup/${key}.dict.yaml`);

    // 读取文件内容
    fs.readFile(source_file, 'utf8', (err, data) => {
        if (err) {
            console.error('读取文件时出错:', err);
            return;
        }

        // 按行分割文件内容
        const lines = data.split('\n');
        const target_lines = [];

        // 遍历每一行
        for (let line of lines) {
            line = line.trim();
            if (line) {
                let parts = line.split('=', 2);
                if (parts.length == 2) {
                    target_lines.push(`${parts[0]}\t${parts[1]}`);
                }
            }
        }

        // 写入新文件
        fs.writeFile(target_file, `# Rime dictionary
# encoding: utf-8
# 

---
name: ${target?.name ?? key}
version: ${target?.version ?? 'zzz'}
...
` + target_lines.join('\n'), 'utf8', (err) => {
            if (err) {
                console.error('写入文件时出错:', err);
                return;
            }
            console.log('文件已成功写入:', target_file);
        });
    });

})
