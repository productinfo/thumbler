const gulp = require('gulp')
const process = require('process')
const fs = require('fs')
const supervisor = require('gulp-supervisor')
let print = require('gulp-print')
const livereload = require('gulp-livereload')
const gutil = require('gulp-util')
const _ = require('lodash')
const path = require('path')
const mocha = require('gulp-spawn-mocha')
const shell = require('gulp-shell')
const bump = require('gulp-bump')
const tap = require('gulp-tap')
const { exec } = require('child_process')
print = require('gulp-print')

const cl = gutil.colors

// =====
// Setup
// =====
const paths = {
  appRoot: 'app.js',
  app: [
    // For some reason, watching a blacklist-style array errors with max call stack size exceeded
    'model/**',
    'routes/**',
    'public/**',
    'test/**',
    'util/**',
    'views/**',
    'app.js',
    'README.md',
    'LICENSE',
    'package.json',
    'local_config/hooks.*',
    'local_config/package.json'
  ],
  tests: [
    // We can specify some ordering here
    'test/sanity.spec.js',
    'test/**/*.js'
  ],
  build: 'dist/'
}

let deployConfig = null
try {
  deployConfig = require('./local_config/deploy_config')
} catch (err) {
  deployConfig = null
  gutil.log(cl.yellow('Warning: You need a deploy config to be able to deploy'))
}

const env = gutil.env.e || 'development'

// =====
// Tasks
// =====

const runTests = () =>
  gulp.src(paths.tests, { read: false }).pipe(
    mocha({
      ui: 'bdd',
      compilers: 'coffee:coffee-script/register',
      reporter: 'spec'
    })
  )

gulp.task('test', () => {
  const logging = require('./util/logging')
  logging.setEnv()
  return runTests()
})

gulp.task('tdd', cb => {
  // Test-Driven development: watch and rerun tests upon file changes
  const logging = require('./util/logging')
  logging.setEnv()
  runTests().on('error', () => {})
  return gulp
    .watch(paths.app)
    .on('change', file => runTests().on('error', () => {}))
})

gulp.task('serve', () =>
  // Run server and watch for changes
  supervisor(paths.appRoot, {
    args: process.argv.slice(2),
    watch: '.',
    extensions: ['js', 'coffee'],
    ignore: [],
    debug: false,
    debugBrk: false,
    quiet: true
  })
)

gulp.task('livereload', () => {
  // Trigger browser refresh when smth changes in app/
  livereload.listen()
  return gulp
    .watch(paths.app)
    .on('change', file => setTimeout(() => livereload.changed(file.path), 500))
})

gulp.task('build', ['clean'], () =>
  gulp
    .src(
      paths.app.concat([
        'node_modules/**',
        'local_config/node_modules/**',
        'bin/**',
        'gulpfile*'
      ]),
      { base: './' }
    )
    .pipe(gulp.dest(paths.build))
)

gulp.task('clean', cb => exec(`rm -rf ${paths.build}`, () => cb()))

gulp.task('deploy', ['build'], function () {
  if (!deployConfig) {
    gutil.log(
      cl.red('Error: You need a deploy_config.json to be able to deploy')
    )
    return
  }

  if (env === 'development') {
    gutil.log(
      cl.red(
        'Error: Please specify a deployment target other than development using -e'
      )
    )
    return
  }

  if (!deployConfig.targets[env]) {
    gutil.log(
      cl.red(
        'Error: Please specify a deployment target that exists in deploy_config.json using -e'
      )
    )
    return
  }

  const targetConfig = deployConfig.targets[env]

  if (!targetConfig.root[0] === '/') {
    gutil.log(
      cl.red('Error: Please specify the remote root as an absolute path')
    )
    return
  }

  if (!targetConfig.root.match('/$')) {
    targetConfig.root += '/'
  }

  const sshConfig = {
    host: targetConfig.host,
    port: targetConfig.port || 22
  }

  if (gutil.env.b) {
    bumpVersion(gutil.env.b)
  }

  const deployStart = Date.now()

  const sshCmd = `ssh ${(targetConfig.user && targetConfig.user + '@') || ''}${
    targetConfig.host
  } -p ${targetConfig.port}`

  return gulp
    .src('')
    .pipe(
      shell([
        sshCmd +
          ` \"cd ${
            targetConfig.root
          }; mkdir -p current; rm -rf previous; cp -r current previous\"`,
        `rsync -e 'ssh -p ${
          targetConfig.port
        }' --checksum --archive --compress --delete --safe-links dist/ ${(targetConfig.user &&
          targetConfig.user + '@') ||
          ''}${targetConfig.host}:${targetConfig.root}current/`,
        sshCmd + ' "sudo toggl_thumbler_restart"'
      ])
    )
    .pipe(
      tap(function () {
        const time = Date.now() - deployStart
        return gutil.log(
          cl.green('Successfully deployed to ') +
            cl.yellow(env) +
            cl.green(' in ') +
            cl.yellow((time / 1000).toFixed(2) + ' seconds')
        )
      })
    )
})

var bumpVersion = (type = 'patch') => {
  let version = ''
  return gulp
    .src(['./package.json'])
    .pipe(bump({ type }))
    .pipe(gulp.dest('./'))
    .pipe(
      tap((file, t) => (version = JSON.parse(file.contents.toString()).version))
    )
    .on('end', () =>
      gulp
        .src('')
        .pipe(
          shell(
            [
              `git commit --all --message "Version ${version}"`,
              type !== 'patch'
                ? `git tag --annotate "v${version}" --message "Version ${version}"`
                : 'true'
            ],
            { ignoreErrors: true }
          )
        )
        .pipe(
          tap(() =>
            gutil.log(
              cl.green('Version bumped to ') +
                cl.yellow(version) +
                cl.green(", don't forget to push!")
            )
          )
        )
    )
}

gulp.task('bump', () => bumpVersion('patch'))
gulp.task('bump:patch', () => bumpVersion('patch'))
gulp.task('bump:minor', () => bumpVersion('minor'))
gulp.task('bump:major', () => bumpVersion('major'))

gulp.task('default', ['serve', 'livereload'])
