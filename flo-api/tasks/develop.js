var gulp = require('gulp');
var nodemon = require('gulp-nodemon');

gulp.task('develop', ['clean', 'copy', 'build'], function() {
  nodemon({
    script: './dist/app.js',
    ext: 'js',
    env: {
      PORT:8000
    },
    nodeArgs: ['--debug=5878'],
    delay: 2000,
    ignore: ['../node_modules/**','./dist'],
    tasks: ['build']
  }).on('restart', function() {
    console.log('Restarting')
  });
});
