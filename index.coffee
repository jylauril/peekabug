'use strict'

_ = require('underscore')
Command = require('commander').Command
pkg = require('./package.json')
Peek = require('./lib/Peek.coffee')

_int = (val) -> parseInt(val, 10)
cli = new Command(pkg.name)

cli.version(pkg.version)
  .usage('[options] <uri>')
  .option('-C, --chars <num>', 'define how many characters to include around the specified target', _int)
  .option('-r, --row <num>', 'define the row to look for', _int)
  .option('-c, --column --col <num>', 'define the character column to search for', _int)
  .option('-d, --depth <num>', 'define the depth', _int, 0)
  .option('-x, --cursor <row:col>', 'define cursor position to seek for', String)
  .option('-u, --uglify', 'no beautify for the output')
  .parse(process.argv)

uris = Array::slice.call(cli.args)
instances = {}

nextUri = ->
  uri = uris.shift()
  process.exit(0) unless uri

  opts = {}
  opts.buffer = cli.chars if cli.chars
  opts.depth = cli.depth if cli.depth
  opts.row = cli.row if cli.row > 0
  opts.col = cli.col if cli.col >= 0
  opts.beautify = not cli.uglify
  [opts.row, opts.col] = cli.cursor.split(':') if cli.cursor

  instance = new Peek(opts)

  instance.setUri(uri)
  formattedUri = instance.formattedUri
  exists = instances[formattedUri]
  if exists
    exists.setUri(uri)
    process.stdout.write(exists.getCursor() + '\n')
    nextUri()
    return

  instances[formattedUri] = instance
  instance.fetchFile().then(->
    process.stdout.write(instance.getCursor() + '\n')
    return
  ).then(nextUri)

  return

nextUri()
