# vim-nodecompl

> nodejs `omnifunc/completefunc` function for Vim

It'll expand node core module, global variables any reference to a require statement.

**wip**

- [x] use nodejs docs api (https://nodejs.org/api/all.json) to build completion
  on core modules and globals
- [x] `Object.keys()` variables that are reference to a require statement (`var
  name = require('package')` => `name.<completehere>` leads to
  `Object.keys(require('package'))`)
- [] `Object.keys()` require statements that are local (`require('./thing')`
- [] use tern to lookup variable definition
- [] integration with deoplete
- [] integration with neocomplete
- [] integration with YouCompleteMe
