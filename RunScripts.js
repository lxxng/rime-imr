const path = require('path')
const PROJECT_ROOT = __dirname;
const updateFiles = require(path.join(PROJECT_ROOT, 'scripts', 'update_files'));
const transform = require(path.join(PROJECT_ROOT, 'scripts', 'local_transform'));

// 使用异步函数确保顺序执行
(async () => {
    try {
        // 先执行update_files
        await updateFiles();
        // 再执行local_transform
        await transform();
        console.log('所有任务执行完成!');
    } catch (error) {
        console.error('执行过程中出现错误:', error);
        process.exit(1);
    }
})();