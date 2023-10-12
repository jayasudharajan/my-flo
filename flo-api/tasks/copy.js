var gulp = require('gulp');
//require('./clean');

gulp.task('copy', ['clean', /* 'copyPublic', 'copyViews', */ 'copyConfig', 'copyData'], function() {
});

// gulp.task('copyPublic', ['clean'], function(){
//   return gulp.src('./src/public/**/*').pipe(gulp.dest('./dist/public'));
// });

// gulp.task('copyViews', ['clean'], function(){
//   return gulp.src('./src/app/views/**/*').pipe(gulp.dest('./dist/app/views'));
// })

// .json config files.
gulp.task('copyConfig', ['clean'], function(){
  return gulp.src('./src/config/*.json').pipe(gulp.dest('./dist/config'));
})

// TODO: Remove this in production.
//  Stock ICD list in a static text file.
gulp.task('copyData', ['clean'], function(){
  return gulp.src('./data/*').pipe(gulp.dest('./dist/data'));
})
