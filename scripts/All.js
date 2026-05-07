const path = require('path')
const PROJECT_ROOT = path.join(__dirname, '..');
require(path.join(PROJECT_ROOT, 'scripts', 'update_files'))
require(path.join(PROJECT_ROOT, 'scripts', 'local_transform'))