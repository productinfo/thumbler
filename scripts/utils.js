const chalk = require('chalk')
const { execSync } = require('child_process')

/**
 * Execute commands
 * @param {string[]} commands
 */
function execute (commands) {
  commands.forEach(command => {
    console.log('Executing:', chalk.yellow(command))
    execSync(command)
  })
}

module.exports.execute = execute
