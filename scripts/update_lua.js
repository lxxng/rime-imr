const files = {
    'lua/librime.lua': 'https://raw.githubusercontent.com/hchunhui/librime-lua/master/contrib/librime.lua'
}

require(require('path').join(__dirname, '_update_files')).update(files)