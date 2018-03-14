const process = require('process');
before((cb) => {
  process.env.DEBUG = 'thumbler:*';
  const thumbler = require('../app.coffee');
  global.app = thumbler.app;
  return thumbler.run()
  .then(() => cb());
});

after(cb => cb());
