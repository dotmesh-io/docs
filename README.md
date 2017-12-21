# Docs

The CSS and hugo build for the datamesh docs site.

## Installing

You need docker installed and this repo pulled.

Then you need to make the images:

```bash
$ make.images
```

# Writing docs
All documentation is to be written in Hugo, using the predefined architypes and structure.
See the [Wiki page](https://github.com/datamesh-io/docs/wiki) for full details on how to write documentation in a consistent manner


## Writing new content

The document pages live in `hugo/content`. See the [Wiki page](https://github.com/datamesh-io/docs/wiki) for formatting and markdown help.

Run the following command to get a hot-reloading version of the site in your browser:

```bash
$ make hugo.watch
```

Then you can open [http://localhost:1313](http://localhost:1313) for a preview.


# Design
The design for the docs is built static, and then all relevant assets (CSS,JS etc...) are pulled across to hugo during the `hugo build` command.
This allows us to design, test and add new features, as well as fix design related bugs, outside of Hugo.
Any changes that affect things visually (HTML, CSS, JS etc...) should be first made in design before being pulled across into Hugo.


## Viewing Design Templates

If you want to view the template designs, outside of Hugo, do:

```bash
$ make design.watch
```
Then open your browser to [http://localhost:3000](http://localhost:3000) to view static templates and style items


## Building a static site

To build a static version (for example, to push to surge.sh for testing or review), run:

```bash
$ make design.build
```

This outputs the site to `design/public`

## Stopping the container

To stop the `design.watch` command:

```bash
$ make design.stop
```

## Icon generation
We use [una's boilerplate](https://github.com/una/svg-icon-system-boilerplate) to generate a sprite of SVG's from individual source files. We can manipulate these with CSS and JS as required.
The boilerplate hangs on [svg-sprite](https://github.com/jkphl/svg-sprite) which is really comprehensive.

### Making SVG's

1. Export the SVG from a graphics package as simple path or stroke data, combining as required.
2. No text in icons please. If you do have Glyphs, outline the font.
3. Clip the SVG to artboard so there are no borders or gaps from the edge
4. If its colour is anything other than black, go full Spinal Tap and make it black `#000000`.
5. Save icons to the source folder in `assets/icons/source`

### Generating the sprite

```bash
$ make design.icons
```

# Working between Design and Hugo
Sometimes you might need to work with both design and Hugo running. This workflow requires a few extra steps.
The below assumes you currently have both design and Hugo in watch mode.

_Note:_ HTML changes will need to be ported manually as Hugo has it's own template system. CSS and external JS will update auto-magically

## Editing Design files.
Work within the design folder, making changes and previewing at [http://localhost:3000](http://localhost:3000) as described above

## Editing Hugo files
Work within the hugo folder, making changes and previewing at [http://localhost:1313](http://localhost:1313)

## Moving design assets into Hugo

First, stop Hugo from watching (Cmd + c), then:

```bash
$ make hugo.build
```

This will output the design assets document_root to `hugo/public`
Hugo can now reference the up-to-date assets.

Start Hugo watching again

```bash
$ make hugo.watch
```

You should see changes reflected in Hugo

# Docker commands

Show containers:

```bash
$ docker ps -a
```

Remove container:

```bash
$ docker rm -f docs-design
```

Get command line inside running container:

```bash
$ docker exec -ti docs-design bash
$ cd ..
```

You should now be in the root of the design folder (i.e. `/app/design`)

## Installing new node modules

```bash
$ docker exec -ti docs-design bash
$ cd ..
$ npm install --save async
$ exit
$ make images
$ # now git commit
```

## Connecting using external devices

The URL that is printed by the watch command is wrong - instead, use this command and type the url in your phone (note - the phone must be on the same WIFI as your dev machine):

```bash
$ make design.url
```
