gulp = require("gulp")
process = require("process")
fs = require("fs")
supervisor = require("gulp-supervisor")
print = require("gulp-print")
livereload = require("gulp-livereload")
gutil = require("gulp-util")
_ = require("lodash")
path = require('path')
Q = require('q')
mocha = require('gulp-spawn-mocha')


# =====
# Setup
# =====
paths =
  app: "./"
  migrations: './migrations'
  tests: [ # We can specify some ordering here
    'test/sanity.spec.coffee'
    'test/**/*.coffee'
  ]

env = gutil.env.e or "development"

cl = gutil.colors


# =====
# Tasks
# =====


runTests = ->
  gulp.src(paths.tests, {read: false})
    .pipe(mocha(
      ui: 'bdd'
      compilers: 'coffee:coffee-script/register'
      reporter: 'spec'
    ))


gulp.task 'test', -> runTests()


gulp.task 'tdd', (cb) ->
  # Test-Driven development: watch and rerun tests upon file changes
  runTests()
    .on "error", ->
  gulp.watch([paths.tests].concat(paths.app + '/**'))
    .on "change", (file) ->
      runTests().on "error", ->


gulp.task "serve", ->
  # Run server and watch for changes
  supervisor paths.app + "app.coffee",
    args: process.argv[2...]
    watch: [paths.app]
    extensions: ["coffee"]
    ignore: []
    debug: false
    debugBrk: false
    quiet: true


gulp.task "livereload", ->

  # Trigger browser refresh when smth changes in app/
  server = livereload()
  gulp.watch(paths.app + "**").on "change", (file) ->
    setTimeout (->server.changed file.path), 500


gulp.task "default", [
  "serve"
  "livereload"
]