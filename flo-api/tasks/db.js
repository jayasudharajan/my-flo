var gulp = require('gulp'),
    shell = require('gulp-shell');

// Create DynamoDB tables.
gulp.task('createtables', shell.task([
  'node ' + __dirname + '/../scripts/dynamoCreateTables.js'
]));

gulp.task('deletetables', shell.task([
  'node ' + __dirname + '/../scripts/dynamoDeleteTables.js'
]));

gulp.task('listtables', shell.task([
  'node ' + __dirname + '/../scripts/dynamoListTables.js'
]));

gulp.task('exporttables', shell.task([
  'node ' + __dirname + '/../scripts/dynamoExportTables.js'
]));

gulp.task('importtables', shell.task([
  'node ' + __dirname + '/../scripts/dynamoImportData.js'
]));

/*
// Seed with starter data.
gulp.task('seed', shell.task([
  // TODO
]))
*/
