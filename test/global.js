// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const process = require('process');
before(function(cb) {
  process.env.DEBUG = 'thumbler:*';
  const thumbler = require('../app.coffee');
  global.app = thumbler.app;
  return thumbler.run()
  .then(() => cb());
});

after(cb => cb());