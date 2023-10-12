var gulp = require('gulp'),
    shell = require('gulp-shell'),
    util = require('gulp-util');

gulp.task('test', shell.task([
  'node ' + __dirname + '/../tests/mocha_run/auth.js'
]))

// Run test for only one file / group of endpoints.
//  gulp testone --model account
gulp.task('testone', shell.task([
  'node ' + __dirname + '/../tests/mocha_run/auth.js ' + util.env.model
]))
