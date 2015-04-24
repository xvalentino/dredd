gulp   = require 'gulp'
coffee = require 'gulp-coffee'
mocha  = require 'gulp-mocha'
coffeelint = require 'gulp-coffeelint'


gulp.task 'lint', ->
  gulp.src('src/*.coffee')
    .pipe coffeelint()
    .pipe coffeelint.reporter()
    .pipe coffeelint.reporter('fail')


gulp.task 'build', ->
  gulp.src('src/**/*.coffee')
    .pipe coffee bare: true
    .pipe gulp.dest 'lib/'


gulp.task 'prepublish', ['build', 'lint']


gulp.task 'test', ['build'], ->
  gulp.src('test/**/*-test.coffee', read: false)
    .pipe mocha(
        compilers: 'coffee:coffee-script/register'
        timeout: 120000
        reporter: 'spec'
      )

gulp.task 'test-win', ['build'], ->
  gulp.src('test/**/*-test.coffee', read: false)
    .pipe mocha(
        compilers: 'coffee:coffee-script/register'
        timeout: 120000
        reporter: 'spec'
        invert: true
        grep: /(Using workaround for hooks in ruby)|(--server)/
      )

