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
shell = require("gulp-shell")
bump = require("gulp-bump")
tap = require("gulp-tap")
exec = require("child_process").exec
print = require('gulp-print')


# =====
# Setup
# =====
paths =
  appRoot: "app.coffee"
  app: [
    # For some reason, watching a blacklist-style array errors with max call stack size exceeded
    "model/**"
    "public/**"
    "test/**"
    "util/**"
    "views/**"
    "app.coffee"
    "README.md"
    "package.json"
  ]
  tests: [ # We can specify some ordering here
    'test/sanity.spec.coffee'
    'test/**/*.coffee'
  ]
  build: "dist/"


deployConfig = null
try
  deployConfig = require("./deploy_config.json")
catch err
  deployConfig = null
  gutil.log cl.yellow("Warning: You need a deploy_config.json to be able to deploy")

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


gulp.task 'test', ->
  logging = require('./util/logging.coffee')
  logging.setEnv()
  runTests()


gulp.task 'tdd', (cb) ->
  # Test-Driven development: watch and rerun tests upon file changes
  logging = require('./util/logging.coffee')
  logging.setEnv()
  runTests()
    .on "error", ->
  gulp.watch((paths.app))
    .on "change", (file) ->
      runTests().on "error", ->


gulp.task "serve", ->
  # Run server and watch for changes
  supervisor paths.appRoot,
    args: process.argv[2...]
    watch: "."
    extensions: ["coffee"]
    ignore: []
    debug: false
    debugBrk: false
    quiet: true


gulp.task "livereload", ->

  # Trigger browser refresh when smth changes in app/
  server = livereload()
  gulp.watch(paths.app).on "change", (file) ->
    setTimeout (->server.changed file.path), 500

gulp.task "build", ["clean"], ->
  gulp.src(paths.app)
    .pipe gulp.dest(paths.build)

gulp.task "clean", (cb) ->
  exec "rm -rf " + paths.build, -> cb()

notifyDeploy = (duration) ->

  postNotification = (head) ->
    postData =
      token: localConfig.deployInfo.appToken
      operator: process.env.USER
      target: env
      branch: head.branch
      revision: head.revision
      duration: duration

    request.post
      url: localConfig.deployInfo.url
      method: "POST"
      form: postData
    , (error, response) ->
      gutil.log cl.red("Error: Failed to send deployment notification, error was:\n"), error if error

  gitInfo = (cb) ->
    exec "echo \"`git rev-parse HEAD` `git branch | sed -n '/* /s///p'`\"", (error, stdout, stderr) ->
      output = stdout.trim().split(" ")
      head =
        branch: output and output[1] or "unknown"
        revision: output and output[0] or "unknown"
      cb head

  gitInfo(postNotification)

gulp.task "deploy", ['build'], ->

  if not deployConfig
    gutil.log cl.red("Error: You need a deploy_config.json to be able to deploy")
    return

  if env is "development"
    gutil.log cl.red("Error: Please specify a deployment target other than development using -e")
    return

  if not deployConfig.targets[env]
    gutil.log cl.red("Error: Please specify a deployment target that exists in deploy_config.json using -e")
    return

  targetConfig = deployConfig.targets[env]

  if not targetConfig.root[0] is "/"
    gutil.log cl.red("Error: Please specify the remote root as an absolute path")
    return

  targetConfig.root += "/"  unless targetConfig.root.match("/$")

  sshConfig =
    host: targetConfig.host
    port: targetConfig.port or 22

  bumpVersion(gutil.env.b) if gutil.env.b

  deployStart = Date.now()

  gulp.src("")
    .pipe shell([
      "ssh " + targetConfig.host + " \"cd " + targetConfig.root + "; mkdir -p current; rm -rf previous; cp -r current previous\""
      "rsync --checksum --archive --compress --delete --safe-links dist/ " + ((if targetConfig.user then targetConfig.user + "@" else "")) + targetConfig.host + ":" + targetConfig.root + "current/"
    ])
    .pipe tap ->
      time = Date.now() - deployStart
      gutil.log cl.green("Successfully deployed to ") + cl.yellow(env) + cl.green(" in ") + cl.yellow((time / 1000).toFixed(2) + " seconds")
      # notifyDeploy(time) if deployConfig.deployInfo

bumpVersion = (type) ->
  type = type or "patch"
  version = ""
  gulp.src [
    "./package.json"
  ]
  .pipe bump(type: type)
  .pipe gulp.dest("./")
  .pipe tap (file, t) -> version = JSON.parse(file.contents.toString()).version
  .on "end", ->
    gulp.src("")
      .pipe shell([
        "git commit --all --message \"Version " + version + "\""
        (if type isnt "patch" then "git tag --annotate \"v" + version + "\" --message \"Version " + version + "\"" else "true")
      ], ignoreErrors: true)
      .pipe tap ->
        gutil.log cl.green("Version bumped to ") + cl.yellow(version) + cl.green(", don't forget to push!")

gulp.task "bump", -> bumpVersion("patch")
gulp.task "bump:patch", -> bumpVersion("patch")
gulp.task "bump:minor", -> bumpVersion("minor")
gulp.task "bump:major", -> bumpVersion("major")

gulp.task "default", [
  "serve"
  "livereload"
]