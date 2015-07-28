gulp = require('gulp')
$ = require('gulp-load-plugins')()
path = require('path')
browser_sync = require('browser-sync')
reload = browser_sync.reload
sass = require('gulp-sass')
concat = require 'gulp-concat'
nodemon = require 'gulp-nodemon'

reportChange = (event) ->
    console.log 'File ' + event.path + ' was ' + event.type + ', building assets...'

gulp.task 'browser-sync', ->
    browser_sync
        port: '3001'
        proxy: 'http://localhost:3000/geoserver-preview'

gulp.task 'bs-reload', ->
    browser_sync.reload()

gulp.task 'compass', ->
    gulp.src('./src/stylesheets/*.css').pipe gulp.dest('./dist/stylesheets')
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

gulp.task 'nodemon', ->
    nodemon
        script: 'src/server.coffee'

gulp.task 'develop', [
    'compass'
    'coffee'
    'images'
    'nodemon'
    'browser-sync'
], ->
    (gulp.watch 'src/stylesheets/*.scss', ['compass','bs-reload']).on 'change', reportChange
    (gulp.watch 'src/scripts/*.coffee', ['coffee','bs-reload']).on 'change', reportChange
    (gulp.watch 'src/images/**/*', ['images','bs-reload']).on 'change', reportChange
    (gulp.watch 'src/**/*.jade', ['bs-reload']).on('change', reportChange)
    return

#production
gulp.task 'default', [
    'compass'
    'coffee'
    'images'
], ->
    return
