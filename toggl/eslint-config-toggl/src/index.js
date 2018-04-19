module.exports = {
  plugins: ['node', 'promise'],
  extends: [
    'standard',
    'plugin:node/recommended',
    'plugin:promise/recommended'
  ],
  env: {
    node: true
  },
  rules: {
    // Built-in ESLint rules
    'no-mixed-operators': 'off',
    'promise/avoid-new': 'off'
  }
}
