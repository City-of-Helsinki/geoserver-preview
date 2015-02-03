gulp = require('gulp')
$ = require('gulp-load-plugins')()
path = require('path')
browserSync = require('browser-sync')
reload = browserSync.reload
sass = require('gulp-sass')

gulp.task 'browser-sync', ->
    browserSync server: baseDir: './dist'
    return

gulp.task 'compass', ->
    gulp.src('./src/stylesheets/*.scss').pipe($.plumber()).pipe($.compass(
        css: 'dist/stylesheets'
        sass: 'src/stylesheets')).pipe gulp.dest('dist/stylesheets')

gulp.task 'coffee', ->
    gulp.src('src/scripts/main.coffee', read: false).pipe($.plumber()).pipe($.browserify(
        debug: true
        insertGlobals: false
        transform: [ 'coffeeify' ]
        extensions: [ '.coffee' ])).pipe($.rename('app.js')).pipe gulp.dest('dist/scripts')

gulp.task 'images', ->
    gulp.src('./src/images/*').pipe gulp.dest('./dist/images')

gulp.task 'templates', ->
    gulp.src('src/*.jade').pipe($.plumber()).pipe($.jade(pretty: true)).pipe gulp.dest('dist/')

gulp.task 'default', [
    'compass'
    'coffee'
    'images'
    'templates'
    'browser-sync'
], ->
    gulp.watch 'src/stylesheets/*.scss', [
        'compass'
        reload
    ]
    gulp.watch 'src/scripts/*.coffee', [
        'coffee'
        reload
    ]
    gulp.watch 'src/images/**/*', [
        'images'
        reload
    ]
    gulp.watch 'src/*.jade', [
        'templates'
        reload
    ]
    return
