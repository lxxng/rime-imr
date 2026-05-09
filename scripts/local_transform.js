const t93_numbers = {
    /**
      # |by*|kvc|qso|
      # |fnz|pix|gte|
      # |jml|ruw|hda|
     */
    'b': [1, 1], 'y': [1, 2],
    'k': [2, 1], 'v': [2, 2], 'c': [2, 3],
    'q': [3, 1], 's': [3, 2], 'o': [3, 3],
    'f': [4, 1], 'n': [4, 2], 'z': [4, 3],
    'p': [5, 1], 'i': [5, 2], 'x': [5, 3],
    'g': [6, 1], 't': [6, 2], 'e': [6, 3],
    'j': [7, 1], 'm': [7, 2], 'l': [7, 3],
    'r': [8, 1], 'u': [8, 2], 'w': [8, 3],
    'h': [9, 1], 'd': [9, 2], 'a': [9, 3],
}
const numpad_t9_numbers = {
    // ### 小键盘九宫格映射
    // ***  abc def
    // ghi  jkl mno
    // pqrs tuv wxyz
    'a': 8, 'b': 8, 'c': 8,
    'd': 9, 'e': 9, 'f': 9,
    'g': 4, 'h': 4, 'i': 4,
    'j': 5, 'k': 5, 'l': 5,
    'm': 6, 'n': 6, 'o': 6,
    'p': 1, 'q': 1, 'r': 1, 's': 1,
    't': 2, 'u': 2, 'v': 2,
    'w': 3, 'x': 3, 'y': 3, 'z': 3,
}
function lookup_transform(source_map) {
    const source_lines = source_map.aux_code.split('\n');
    let target_lines = [];
    // 遍历每一行
    for (let source_line of source_lines) {
        source_line = source_line.trim();
        if (source_line) {
            let parts = source_line.split('\t', 2);
            if (parts.length == 2) {
                let aux_codes = parts[1].split(';')
                if (
                    aux_codes.length >= 5
                    && aux_codes[4].length != 0
                ) {
                    for (let aux_code of aux_codes[4].split(',')) {
                        if (aux_code.length != 0) {
                            target_lines.push(`${parts[0]}\t${aux_code}`);
                        }
                    }
                }
                // ['', [1], [2], [3], zrm, ... ]
            }
        }
    }
    return { aux_code: target_lines.join('\n') };
}
function lookup_t93_transform(source_map) {
    const source_lines = source_map.aux_code.split('\n');
    let target_lines = [];
    // 遍历每一行
    for (let source_line of source_lines) {
        source_line = source_line.trim();
        if (source_line) {
            let parts = source_line.split('\t');
            let cn = parts[0];
            let en = parts[1];
            if (en && en.length == 1) {
                target_lines.push(`${cn}\t${t93_numbers[en.charAt(0)][0]}`);
            }
            if (en && en.length >= 2) {
                let en1 = en.charAt(0);
                let en2 = en.charAt(1);
                let number1 = t93_numbers[en1][0];
                let number2 = t93_numbers[en2][0];
                let number3 = (t93_numbers[en1][1] - 1) * 3
                    + (t93_numbers[en2][1]);
                target_lines.push(`${cn}\t${number1}${number2}${number3}`);
                target_lines.push(`${cn}\t${number1}${number2}0`);
            }
        }
    }
    return { aux_code: target_lines.join('\n') };
}
function wanxiang_pro_transform(source_map) {
    const aux_code_lines = source_map.aux_code.split('\n');
    const aux_code_map = {};
    for (let source_line of aux_code_lines) {
        source_line = source_line.trim();
        if (source_line) {
            let parts = source_line.split('\t', 2);
            if (parts.length == 2) {
                let aux_codes = parts[1].split(';')
                if (
                    aux_codes.length >= 5
                    && aux_codes[4].length != 0
                ) {
                    aux_code_map[parts[0]] = aux_codes[4];
                }
            }
        }
    }
    const target_map = {};
    Object.keys(source_map).filter(key => key != 'aux_code')
        .forEach(key => {
            const source_lines = source_map[key].split('\n');
            const target_lines = [];
            let shift = undefined;
            while ((shift = source_lines.shift()) != '...' && shift != undefined);
            source_lines
                .map(source_line => source_line.trim())
                .filter(source_line => source_line != '')
                .filter(source_line => source_line.charAt(0) != '#')
                .forEach(source_line => {
                    source_line = source_line.trim();
                    let data = source_line.split('\t', 3)
                    let cn = data[0];
                    let cn_arr = cn.split('');
                    let en = data[1];
                    if (en == undefined) {
                        console.log('line', source_line)
                    }
                    let en_arr = en.split(' ');
                    for (i = 0; i < cn_arr.length && i < en_arr.length; i++) {
                        en_arr[i] = en_arr[i] + ';' + aux_code_map[cn_arr[i]];
                    }
                    if (data.length >= 2) {
                        target_lines.push([cn, en_arr.join(' '), data[2]].join('\t'))
                    }
                })
            target_map[key] = target_lines.join('\n');
        })
    return target_map;
}
function numpad_t9_reverse_transform(source_map) {
    const source_lines = source_map.zi.split('\n');
    let shift = undefined;
    while ((shift = source_lines.shift()) != '...' && shift != undefined);
    const target_lines = source_lines
        .map(source_line => source_line.trim())
        .filter(source_line => source_line != '')
        .map(source_line => source_line.split('\t'))
        .map(([cn, en,]) => {
            en = en
                .replace(/[āáǎà]/g, 'a')
                .replace(/[ēéěè]/g, 'e')
                .replace(/[īíǐì]/g, 'i')
                .replace(/[ōóǒò]/g, 'o')
                .replace(/[ūúǔù]/g, 'u')
                .replace(/[ǖǘǚǜü]/g, 'v')
                .replace('ń', 'n')
                .replace('ň', 'n')
                .replace('ǹ', 'n')
                .replace('ḿ', 'm')
                .replace('m̀', 'm')
                .replace(/^ng$/g, 'eng')
                .replace(/^n$/g, 'en')
                .replace(/^m$/g, 'me')
            return en
        })
        .reduce((acc, current) => {
            if (acc.indexOf(current) === -1) {
                acc.push(current);
            }
            return acc;
        }, [])
        .map(en => {
            let numbers = [...en].map(en_char => numpad_t9_numbers[en_char]).join('')
            return [numbers, en].join('\t')
        })
    return { reverse: target_lines.join('\n') }
}
const files = [
    // {
    //     source: {
    //         aux_code: 'tmp/wanxiang/aux_code.txt',
    //     },
    //     target: {
    //         aux_code: {
    //             file: 'dicts/lookup/ZRM-wanxiang.dict.yaml',
    //             name: 'ZRM-wanxiang',
    //         },
    //     },
    //     transform: lookup_transform,
    // },
    // {
    //     source: {
    //         aux_code: 'dicts/lookup/ZRM-wanxiang.dict.yaml',
    //     },
    //     target: {
    //         aux_code: {
    //             file: 'dicts/lookup/ZRM-wanxiang_t93.dict.yaml',
    //             name: 'ZRM-wanxiang_t93',
    //         },
    //     },
    //     transform: lookup_t93_transform,
    // },
    // {
    //     source: {
    //         aux_code: 'tmp/wanxiang/aux_code.txt',
    //         zi: 'dicts/wanxiang/zi.dict.yaml',
    //         jichu: 'dicts/wanxiang/jichu.dict.yaml',
    //         lianxiang: 'dicts/wanxiang/lianxiang.dict.yaml',
    //         cuoyin: 'dicts/wanxiang/cuoyin.dict.yaml',
    //         duoyin: 'dicts/wanxiang/duoyin.dict.yaml',
    //         shici: 'dicts/wanxiang/shici.dict.yaml',
    //         diming: 'dicts/wanxiang/diming.dict.yaml',
    //     },
    //     target: {
    //         zi: { file: 'dicts/wanxiang/zi.pro.dict.yaml', name: 'zi' },
    //         jichu: { file: 'dicts/wanxiang/jichu.pro.dict.yaml', name: 'jichu' },
    //         lianxiang: { file: 'dicts/wanxiang/lianxiang.pro.dict.yaml', name: 'lianxiang' },
    //         cuoyin: { file: 'dicts/wanxiang/cuoyin.pro.dict.yaml', name: 'cuoyin' },
    //         duoyin: { file: 'dicts/wanxiang/duoyin.pro.dict.yaml', name: 'duoyin' },
    //         shici: { file: 'dicts/wanxiang/shici.pro.dict.yaml', name: 'shici' },
    //         diming: { file: 'dicts/wanxiang/diming.pro.dict.yaml', name: 'diming' },
    //     },
    //     transform: wanxiang_pro_transform,
    // },
    {
        source: {
            zi: 'dicts/wanxiang/zi.dict.yaml',
        },
        target: {
            reverse: {
                file: 'dicts/lookup/numpad_t9_reverse_pinyin.dict.yaml',
                name: 'numpad_t9_reverse_pinyin',
            },
        },
        transform: numpad_t9_reverse_transform,
    }
]

const { log } = require('console');
// 读取ZRM_wanxiang.dict.yaml文件并处理
const fs = require('fs');
const path = require('path');

function work() {
    files.forEach(file => {
        const source = file.source;
        const target = file.target;
        const transform = file.transform;
        const source_map = {}
        Object.keys(source).forEach(source_key => {
            const source_file = path.join(__dirname, '..', source[source_key]);
            source_map[source_key] = fs.readFileSync(source_file, 'utf8');
        })
        const target_map = transform(source_map)
        Object.keys(target_map).forEach(target_key => {
            const target_file = path.join(__dirname, '..', target[target_key].file);
            fs.writeFileSync(target_file, [
                `# Rime dictionary`,
                `# encoding: utf-8`,
                `#`,
                ``,
                `---`,
                `name: ${target[target_key].name}`,
                `version: ${target[target_key].version ?? 'zzz'}`,
                `...`,
                target_map[target_key]
            ].join('\n'), 'utf8');
            console.log('文件已成功写入', target_file)
        })
        //     const source_lineses = source_file.map(file => {
        //         const context = fs.readFileSync(file, 'utf8');
        //         return context.split('\n');
        //     })
        //     const target_lines = transform(source_lineses)
        //     // 写入新文件
    })
}

module.exports = work;
if (require.main === module) {
    work();
}
