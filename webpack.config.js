const { join } = require('path')
const nodeExternals = require('webpack-node-externals')
const CleanWebpackPlugin = require('clean-webpack-plugin')

const outPath = join(__dirname, 'build')

module.exports = {
  mode: 'development',
  target: 'node',
  node: {
    __dirname: true
  },
  externals: nodeExternals(),
  entry: join(__dirname, 'bin', 'www'),
  output: {
    path: outPath,
    filename: 'app.js'
  },
  resolve: {
    extensions: ['.web.js', '.mjs', '.js', '.json']
  },
  plugins: [new CleanWebpackPlugin(outPath)]
}
