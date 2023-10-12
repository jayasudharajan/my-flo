var gulp = require('gulp');
var babel = require('gulp-babel');
var concat = require('gulp-concat');

require('./tasks/build');
require('./tasks/develop');
require('./tasks/db');
require('./tasks/document');
require('./tasks/test');
require('./tasks/aclRoles');
require('./tasks/roles');

gulp.task('default',['build', 'develop'], function(){
});
