# Docs

The CSS and hugo build for the datamesh docs site.

## Installing

You need docker installed and this repo pulled.

Then you need to make the images:

```bash
$ make.images
```

## Writing new content

The blog posts live in `hugo/content`, add a new file to this folder.

Run the following command to get a hot-reloading version of the site in your browser:

```bash
$ make hugo.watch
```

Then you can open [http://localhost:1313](http://localhost:1313) for a preview.

## Stop container

To stop the `design.watch` command:

```bash
$ make design.stop
```


## Building static site

```bash
$ make hugo.build
```

This will output the document_root to `hugo/public`

## Viewing Design Templates

If you want to view the template designs, outside of Hugo, do:

```bash
$ make design.watch
```
Then open your browser to [http://localhost:3000](http://localhost:3000) to view static templates and style items

## Editing Design files.

If you change anything inside `design` - then you must stop hugo, then:

```bash
$ make design.build
```

If you want the design to be hot-reloading:

```bash
$ make design.watch
```

Then you can restart hugo.


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

## Docker commands

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
