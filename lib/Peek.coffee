'use strict'

_ = require('underscore')
fs = require('fs')
url = require('url')
path = require('path')
request = require('request')
Promise = require('bluebird')
beautify = require('js-beautify').js_beautify

DIR_FORWARD = 1
DIR_BACK = -1

rowColMatch = /:(\d+:\d+)$/
fileMatch = /^file:/
protocols = ['http:', 'https:']
protocolSupported = (protocol) -> !!~protocols.indexOf(protocol)

class Peek
  constructor: (options = {}) ->
    @options = _.extend({
      beautify: true
      depth: 0
      cursor: ''
      buffer: null
      row: null
      col: null
    }, options)

  formattedUri: null
  uri: null

  @create: (options) -> new Peek(options)

  setUrl: (uri) => @setUri(uri)
  setUri: (uri) =>
    @formattedUri = null
    @uri = null
    delete @options.url
    @options.uri = uri
    @_formatUri(uri)

  _formatUri: (uri) =>
    if uri
      if _.isObject(uri) and _.isFunction(uri.format)
        uri = uri.format()

      match = uri.match(rowColMatch)
      if match
        [row, col] = match[1].split(':')
        @options.row = parseInt(row, 10)
        @options.col = parseInt(col, 10)
        uri = uri.replace(rowColMatch, '')

      if fileMatch.test(uri)
        uri = path.normalize(uri)
        uri = uri.replace(fileMatch, '')

      uri = url.parse(uri)

      unless uri.protocol
        @type = 'local'
      else if protocolSupported(uri.protocol)
        @type = 'remote'
      else
        throw new Error('Protocol "' + uri.protocol + '" currently not supported')

      @uri = uri
      @formattedUri = uri.format()
    uri

  fetchFile: (uri) =>
    if _.isObject(uri)
      options = uri
      uri = options.uri or options.url

    if uri
      try
        @setUri(uri)
      catch err
        return Promise.reject(err)

    uri = @uri
    formattedUri = @formattedUri
    switch @type
      when 'remote'
        return Promise.promisify(request.get, request)(formattedUri).then((@data) => data)
      when 'local'
        return Promise.promisify(fs.readFile, fs)(formattedUri, 'utf8').then((@data) => data)
      else
        return Promise.reject(new Error('Cannot fetch URI: ' + @options.uri))

  findScope: (dir, data, depth = 0) ->
    forward = dir is DIR_FORWARD
    bufStr = Array::slice.call(data)

    conf = ({
      '-1': { terminator: '{', scope: '}', extract: 'pop' }
      '1': { terminator: '}', scope: '{', extract: 'shift' }
    })[dir]

    return '' unless conf

    terminated = false
    singleQuoted = false
    doubleQuoted = false
    regExpd = false
    cursor = if forward then 0 else data.length - 1

    while bufStr.length
      break if terminated
      char = bufStr[conf.extract]()
      escaped = data[cursor - 1] is '\\'

      switch char
        when conf.terminator
          unless escaped or singleQuoted or doubleQuoted or regExpd
            terminated = not depth
            depth-- if depth

        when conf.scope
          unless escaped or singleQuoted or doubleQuoted or regExpd
            depth++

        when '"'
          unless escaped or singleQuoted or regExpd
            doubleQuoted = not doubleQuoted

        when "'"
          unless escaped or doubleQuoted or regExpd
            singleQuoted = not singleQuoted

        when '/'
          unless escaped or singleQuoted or doubleQuoted
            regExpd = not regExpd

      cursor += dir

    cursor++ unless forward

    obj = { done: true, depth }

    if depth
      obj.done = false
      cursor = if forward then data.length - 1 else 0

    obj.data = if forward then data.slice(0, cursor) else data.slice(cursor)
    obj

  getCursor: (row, col) =>
    if _.isString(row)
      [row, col] = row.split(':') if _.isEmpty(col)
      row = parseInt(row, 10)

    col = parseInt(col, 10) if _.isString(col)

    unless _.isNumber(row) and _.isNumber(col)
      if @options.row isnt null and @options.col isnt null
        row = parseInt(@options.row, 10)
        col = parseInt(@options.col, 10)

      if isNaN(row) or isNaN(col)
        throw new Error('Cannot resolve cursor, row: "' + row + '", col: "' + col + '"')

    data = String(@data)
    content = null
    if data and data.length
      rows = data.split(/\n/gm)
      if row > rows.length
        throw new Error('Cannot find row ' + row + ' from ' + rows.length + ' rows.')

      currentRow = row - 1
      content = rows[currentRow]

      if col >= content.length
        throw new Error('Cannot find character column ' + col + ' from ' + content.length + ' characters.')

      if col
        before = content.slice(0, col)
        after = content.slice(col)
        buffer = @options.buffer

        if _.isNumber(buffer)
          buf = before.length - buffer
          buf = 0 if buf < 0
          beforeBuffer = before.slice(buf)

          buf = buffer
          buf = after.length - 1 if buf >= after.length
          afterBuffer = after.slice(0, buf)
        else
          beginDepth = 0
          beginDepth = @options.depth - 1 if @options.depth
          targetRow = currentRow

          resolved = @findScope(DIR_BACK, before, beginDepth)
          data = resolved.data
          while not resolved.done and targetRow
            targetRow--
            resolved = @findScope(DIR_BACK, rows[targetRow], resolved.depth)
            data = resolved.data + data

          beforeBuffer = data

          targetRow = currentRow
          resolved = @findScope(DIR_FORWARD, after, beginDepth)
          data = resolved.data
          while not resolved.done and targetRow < rows.length
            targetRow++
            resolved = @findScope(DIR_FORWARD, rows[row], resolved.depth)
            data += resolved.data

          afterBuffer = data

        content = [beforeBuffer, @options.cursor, afterBuffer].join('')

      content = beautify(content, { indent_size: 4 }) if @options.beautify

    content

module.exports = Peek
