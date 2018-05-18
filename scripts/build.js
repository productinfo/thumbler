const { paths } = require('./constants')
const { execute } = require('./utils')

const srcPaths = paths.app.concat(['node_modules', 'bin', 'gulpfile.js'])

function build () {
  execute([
    `rm -rf ${paths.build}`,
    `mkdir ${paths.build}`,
    `cp -R ${srcPaths.join(' ')} ${paths.build}`
  ])
}

build()
