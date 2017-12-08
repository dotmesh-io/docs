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

## Building static site

```bash
$ make hugo.build
```

This will output the document_root to `hugo/public`

## Editing CSS / Design files

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

## Making SVG's

1. Export the SVG from a graphics package as simple path or stroke data, combining as required.
2. No text in icons please. If you do have a Glyph, outline the font.
3. Clip the SVG to artboard so there are no borders or gaps from the edge
4. Save icons to the source folder in `assets/icons/source`
5. Run the gulp task `gulp build:icons` when you want to build icons. They output to the `assets/icons/renders` folder. Additionally, we pull a copy of the example page and spirte into our 'templates' folder, so we can reference the icons visually.

