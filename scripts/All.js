const path = require('path')
const PROJECT_ROOT = path.join(__dirname, '..');
require(path.join(PROJECT_ROOT, 'scripts', 'update_files'))
require(path.join(PROJECT_ROOT, 'scripts', 'source2dict'))
require(path.join(PROJECT_ROOT, 'scripts', 'dict2t93dict'))