# Cooper

*Base style and functional layers. Dale Cooper approved.*

![Dale Cooper Approved](https://i.imgur.com/ZDWFHnB.jpg "Dale Cooper Approved")

## What is?

Default SCSS, JS and assets for starting new projects

## How

It all runs on gulp and inputs and outputs are configured via the gulpfile.js. Change as needed on a per project basis.
(As a default, there are templates bundled with the build and a local server setup from flat files. This is to test elements as it's hard to code base css without looking).

## Setup

1. Install [gulp](https://gulpjs.com/) locally if you don't have it
2. run `npm install` where you need it
3. run `gulp` to compile assets only
4. run `gulp serve` to display test set of elements and re-compile everything at the same time
5. run `gulp build:icons` to re-build a set of icon when required (see icon generation)

## Icon generation

We use [una's boilerplate](https://github.com/una/svg-icon-system-boilerplate) to generate a sprite of SVG's from individual source files. We can manipulate these with CSS and JS as required.

The boilerplate hangs on [svg-sprite](https://github.com/jkphl/svg-sprite) which is really comprehensive.

### Making SVG's

1. Export the SVG from a graphics package as simple path or stroke data, combining as required.
2. No text in icons please. If you do have a Glyph, outline the font.
3. Clip the SVG to artboard so there are no borders or gaps from the edge
4. Save icons to the source folder in `assets/icons/source`
5. Run the gulp task `gulp build:icons` when you want to build icons. They output to the `assets/icons/renders` folder. Additionally, we pull a copy of the example page and spirte into our 'templates' folder, so we can reference the icons visually.


# Starting a new project

The power of Cooper is in having a solid base to start from.

When using it in projects, it's unlikely you'll need to use it to run the local server to test elements, so 'gulp' is the default command for assets. You can ignore 'gulp serve' all together unless you want to check something or add to the core codebase.

What you should do to get started on a new project is the following:

1. Pull this repo to where it's needed
2. Delete the templates and public folders.
2. Alter the gulpfile.js to out put css, js, and assets where you need them
3. Remove the 'test templates' section and related task runner from gulpfile.js (optional)
