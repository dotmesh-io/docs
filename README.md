# Docs

An initial setup of hugo and datamesh styles for the docs site.

This is not a deployable repo - it is the scratchpad for how it will work.

## Installing





To get started you need to install:
- [gulp](https://gulpjs.com/) globally: `$ npm install -g gulp`
- [hugo](https://github.com/gohugoio/hugo) globally (it's a golang binary)
- run: `$ npm-install`

## Run Hugo website (need)

1. In /app run 'hugo server -v'
2. In root run 'gulp'

## Running Patterns

Pattern copies core elements from the Hugo site and generates a style guide. To do this, run the following.

1. In root, run 'gulp build'. This builds all the needed files for patterns
2. In another tab, in root run 'gulp patterns'. This starts the pattern library server
3. At any point, run 'gulp build' in a separate tab to update patterns to the latest version. If this errors the server, just re-start it with 'gulp patterns' 
