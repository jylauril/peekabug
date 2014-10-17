var gulp = require('gulp');
var coffeelint = require('gulp-coffeelint');

gulp.task('lint', function() {
    gulp.src(['index.coffee', 'lib/*.coffee'])
      .pipe(coffeelint('.coffeelint'))
      .pipe(coffeelint.reporter())
});

gulp.task('default', ['lint']);
