var gulp = require('gulp'),
	shell = require('gulp-shell');

// Generate js documentation.
// TODO: include entire js src as appropriate.
gulp.task('codedocs', shell.task([
  'jsdoc ' + __dirname + '/../src/app/v1/controllers/accountController.js -d docs'  // Testing with one controller.
]))
