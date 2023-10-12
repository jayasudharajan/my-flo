var gulp = require('gulp');
var concat = require('gulp-concat');
var insert = require('gulp-insert')

gulp.task('roles', () => {
	return gulp.src('src/config/roles/*')
		.pipe(insert.append(','))
		.pipe(concat('aclRoles.json'))
		.pipe(insert.transform((contents, file) => {
			return contents.slice(0, contents.length - 1);
		}))
		.pipe(insert.wrap('[', ']'))
		.pipe(gulp.dest('scripts/'));
});