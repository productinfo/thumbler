# Thumbler

## Environment setup

### 1. Install MongoDB

### 2. Install NodeJS from http://nodejs.org/. Npm should come with it.

### 3. Install gulp & coffeescript globally

  `$ npm install -g coffee-script gulp`

### 4. Verify installation

  ```
  $ node --version
  v0.10.25
  ```

  ```
  $ npm --version
  1.3.24
  ```

### 5. Cd into project directory and issue

  `$ npm install`

### 6. Configure database connection

  Add db_config.json to the project folder.

  Sample config:

  ```
  {
    "url": "mongodb://localhost/thumbler"
  }
  ```

### 7. Run the dev environment + server

  `$ gulp`

This watches app directory and restarts the server every time it detects a change in code.
Also supports chrome livereload plugin so you don't have to refresh the browser manually.
Get the plugin here: https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei?hl=en

By default rewrites the database on each run and file change. To turn off automatic db rebuilds, call it like this:

  `$ gulp --no-rebuild`

### 8. Test Driven Development

To simply run the tests

  `$ gulp test`

To watch for file changes and run the tests every time something changes

  `$ gulp tdd`

### 9. Enjoy

## Some util commands

Displays a fortune. Often comes in handy.

  `$ fortune`
