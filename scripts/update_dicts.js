const files = {
    'cn_dicts/8105.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/8105.dict.yaml',
    'cn_dicts/41448.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/41448.dict.yaml',
    'cn_dicts/base.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/base.dict.yaml',
    'cn_dicts/ext.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/ext.dict.yaml',
    'cn_dicts/others.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/others.dict.yaml',
    'cn_dicts/tencent.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/cn_dicts/tencent.dict.yaml',
    'en_dicts/cn_en_double_pinyin.txt': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/cn_en_double_pinyin.txt',
    'en_dicts/cn_en.txt': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/cn_en.txt',
    'en_dicts/en_ext.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/en_ext.dict.yaml',
    'en_dicts/en.dict.yaml': 'https://raw.githubusercontent.com/iDvel/rime-ice/main/en_dicts/en.dict.yaml',
    'radical_dicts/radical_pinyin.dict.yaml': 'https://raw.githubusercontent.com/mirtlecn/rime-radical-pinyin/master/radical_pinyin.dict.yaml',
    'radical_dicts/stroke.dict.yaml': 'https://raw.githubusercontent.com/rime/rime-stroke/master/stroke.dict.yaml',
    'aux_code/ZRM-wanxiang.txt': 'https://raw.githubusercontent.com/HowcanoeWang/rime-lua-aux-code/main/aux_code/ZRM-wanxiang.txt',
};

require(require('path').join(__dirname, '_update_files')).update(files)