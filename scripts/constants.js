const paths = {
  appRoot: 'app.js',
  app: [
    // For some reason, watching a blacklist-style array errors with max call stack size exceeded
    'model',
    'routes',
    'public',
    'test',
    'util',
    'views',
    '.nvmrc',
    'app.js',
    'README.md',
    'LICENSE',
    'package.json',
    'local_config'
  ],
  tests: [
    // We can specify some ordering here
    'test/sanity.spec.js',
    'test/**/*.js'
  ],
  build: 'dist/'
}

module.exports = { paths }
