/**
 * Thumbler deploy script
 */
const chalk = require('chalk')
const argv = require('minimist')(process.argv.slice(2))

const { execute } = require('./utils')
const bumpVersion = require('./bump-version')

const env = process.env.NODE_ENV

let deployConfig = null
try {
  deployConfig = require('../local_config/deploy_config')
} catch (err) {
  deployConfig = null
  console.log(
    chalk.yellow('Warning: You need a deploy config to be able to deploy')
  )
}

function deploy () {
  if (!deployConfig) {
    console.log(
      chalk.red('Error: You need a deploy_config.json to be able to deploy')
    )
    return
  }

  if (env === 'development') {
    console.log(
      chalk.red(
        'Error: Please specify a deployment target other than development using -e'
      )
    )
    return
  }

  if (!deployConfig.targets[env]) {
    console.log(
      chalk.red(
        'Error: Please specify a deployment target that exists in deploy_config.json using -e'
      )
    )
    return
  }

  const targetConfig = deployConfig.targets[env]

  if (!targetConfig.root[0] === '/') {
    console.log(
      chalk.red('Error: Please specify the remote root as an absolute path')
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

  if (argv.b) {
    bumpVersion(argv.b)
  }

  const deployStart = Date.now()

  const sshCmd = `ssh ${(targetConfig.user && targetConfig.user + '@') || ''}${
    sshConfig.host
  } -p ${sshConfig.port}`

  // Backup current deployment to previous folder
  const backupCmd = `${sshCmd} "cd ${
    targetConfig.root
  }; mkdir -p current; rm -rf previous; cp -r current previous"`

  // Upload local build to server
  const copyCmd = `rsync -e 'ssh -p ${
    sshConfig.port
  }' --checksum --archive --compress --delete --safe-links build/ ${(targetConfig.user &&
    targetConfig.user + '@') ||
    ''}${sshConfig.host}:${targetConfig.root}current/`

  // Restart thumbler
  const restartCmd = `${sshCmd} "sudo toggl_thumbler_restart"`

  try {
    execute([backupCmd, copyCmd, restartCmd])
  } catch (err) {
    console.error(err)
    return
  }

  const time = Date.now() - deployStart

  console.log(
    chalk.green('Successfully deployed to ') +
      chalk.yellow(env) +
      chalk.green(' in ') +
      chalk.yellow((time / 1000).toFixed(2) + ' seconds')
  )
}

deploy()
