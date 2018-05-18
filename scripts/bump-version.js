/**
 * Bump version utility
 */
const chalk = require('chalk')
const { execute } = require('./utils')

/**
 * Specify bump type in invocation args
 * -b <major|minor|patch>
 * @param {string} args
 * @returns {'major' | 'minor' | 'patch'}
 */
function getBumpType (args) {
  let type = 'patch'
  const bumpFlagIndex = args.indexOf('-b')
  if (bumpFlagIndex > -1) {
    type = args[bumpFlagIndex + 1]
  }
  return type
}

/**
 * Bump version base on bumpType
 */
function bumpVersion (args) {
  const type = getBumpType(args)
  try {
    execute([`npm version ${type} -m "Version %s"`])
    const { version } = require('../package.json')
    if (type !== 'patch') {
      execute([
        `git tag --annotate "v${version}" --message "Version ${version}"`
      ])
    }

    console.log(
      chalk.green('Version bumped to ') +
        chalk.yellow(version) +
        chalk.green(", don't forget to push!")
    )
  } catch (err) {
    console.error(err)
  }
}

module.exports = bumpVersion
