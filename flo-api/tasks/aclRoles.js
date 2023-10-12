var gulp = require('gulp');
var shell = require('gulp-shell');

gulp.task('aclRoles', shell.task([
	'node ' + __dirname + '/../scripts/cacheAclRoles.js',
	// 'node ' + __dirname + '/../scripts/createSystemUsers.js'
]));