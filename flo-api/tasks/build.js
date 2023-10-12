import gulp from 'gulp';
import sourceMaps from 'gulp-sourcemaps';
import babel from 'gulp-babel';
import uglify from 'gulp-uglify';
import path from "path";
import strip from 'gulp-strip-comments';

import clean from './clean';
import copy from './copy';

gulp.task('build', ['copy', 'clean'], function() {
  return gulp.src(['src/**/*.js','!src/public/**/*.js'])
    .pipe(sourceMaps.init())
    .pipe(babel())
    .pipe(uglify({ mangle: false }))    // skip mangling names.
    .pipe(strip())
    .pipe(sourceMaps.write('.',
      {
        includeContent: false,
        sourceRoot: path.join(__dirname, 'src').replace('tasks/', '')
      }
    ))
    .pipe(gulp.dest('dist'));
});
