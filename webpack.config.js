const { join } = require('path')
const webpack = require('webpack')
const CleanWebpackPlugin = require('clean-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')

const outPath = join(__dirname, 'build')

const dir = name => join(__dirname, name)

const outDir = name => join(outPath, name)

// Extraneous consolidate dynamic requires
const extraneousConsRequires = /(atpl|bracket-template|dot|dustjs-linkedin|ect|haml-coffee|hamlet|hamljs|hogan.js|htmling|jazz|jqtpl|just|liquor|marko|mote|mustache|plates|ractive|react|slm|teacup|templayed|toffee|twig|vash|velocityjs|walrus|whiskers)/

module.exports = {
  mode: 'development',
  target: 'node',
  node: {
    __dirname: true
  },
  stats: { warnings: !false },
  entry: join(__dirname, 'bin', 'www.js'),
  output: {
    path: outDir('bin'),
    filename: 'www'
  },
  module: {
    rules: [{ test: /bin\/coffee$/, use: 'shebang-loader' }]
  },
  resolve: {
    extensions: ['.web.js', '.mjs', '.js', '.json']
  },
  plugins: [
    new webpack.IgnorePlugin(extraneousConsRequires),
    new CleanWebpackPlugin(outPath),
    new CopyWebpackPlugin([
      { from: dir('public'), to: outDir('public') },
      { from: dir('views'), to: outDir('views') }
    ])
  ]
}
