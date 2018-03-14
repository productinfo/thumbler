// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Q = require('q');

module.exports = {
  connected: false,
  ifConnected() {
    return Q.Promise((resolve, reject, notify) => {
      if (this.connected) {
        resolve();
      } else {
        console.log('A10, I am not connected');
        reject();
      }
    });
  }
};

