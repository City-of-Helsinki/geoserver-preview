gulp = require('gulp')
$ = require('gulp-load-plugins')()
path = require('path')
browser_sync = require('browser-sync')
reload = browser_sync.reload
sass = require('gulp-sass')
concat = require 'gulp-concat'
insert = require 'gulp-insert'
server = require './src/server'

gulp.task 'browser-sync', ->
    browser_sync server: baseDir: './dist'
    return

gulp.task 'server', ->
    server.createServer()

gulp.task 'compass', ->
    gulp.src('./src/stylesheets/*.scss').pipe($.plumber()).pipe($.compass(
        css: 'dist/stylesheets'
        sass: 'src/stylesheets')).pipe gulp.dest('dist/stylesheets')

gulp.task 'coffee', ->
    gulp.src('src/scripts/main.coffee', read: false).pipe($.plumber()).pipe($.browserify(
        debug: true
        insertGlobals: true
        transform: [ 'coffeeify' ]
        extensions: [ '.coffee' ])).pipe($.rename('app.js')).pipe gulp.dest('dist/scripts')

gulp.task 'images', ->
    gulp.src('./src/images/*').pipe gulp.dest('./dist/images')

gulp.task 'templates', ->
    gulp.src('src/*.jade').pipe($.plumber()).pipe($.jade(pretty: true)).pipe gulp.dest('dist/')

gulp.task 'client-templates', ->
    wrap_begin = (file) ->
        fname = path.basename file.path, '.js'
        return "this[\"JadeJST\"][\"#{fname}\"] = "
    wrap_end = ";\n"

    gulp.src('src/templates/*.jade').pipe($.jade({client: true}))
        .pipe(insert.wrap(wrap_begin, wrap_end))
        .pipe(concat('templates.js'))
        .pipe(gulp.dest('./dist'))
        .pipe(insert.prepend("this[\"JadeJST\"] = {};"))


gulp.task 'default', [
    'compass'
    'coffee'
    'images'
    'templates'
    'client-templates'
    'browser-sync'
    'server'
], ->
    gulp.watch 'src/stylesheets/*.scss', [
        'compass'
        reload
    ]
    gulp.watch 'src/**/*.coffee', [
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
