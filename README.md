# Peek-A-Bug

Peek into a minified source code to find a bug.

[![NPM version](https://badge.fury.io/js/peekabug.svg)](http://badge.fury.io/js/peekabug)

Ever tried to debug JavaScript code in production and all you get is a reference to an ambiguous line of minified file with a high number column location?
Then you try to reproduce the problem in development mode and it never happens again?
Eventually give up and download the minified source code and try to decipher the column location and context in question?

Well I used to do that in order to find the most cryptical of errors that happened in rare circumstances.
I eventually got tired of it and created this little command line tool that automatically fetches the file,
looks up the row and column, deciphers the current context and prettifies the scope to produce a human readable block of code.

## How to install

Requirements: [NodeJS](http://nodejs.org/)

```sh
npm install peekabug -g
```

## Running


```
peekabug [options] <url>[:row[:col]]
```

Where the `url` can be either a local file path or a web URI.

## Options

    -h, --help                output usage information
    -V, --version             output the version number
    -C, --chars <num>         define how many characters to include around the specified target
    -r, --row <num>           define the row to look for
    -c, --column --col <num>  define the character column to search for
    -d, --depth <num>         define the depth
    -x, --cursor <row:col>    define cursor position to seek for
    -u, --uglify              no beautify for the output


## Examples


```sh
peekabug http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js:16:1545
```

Output:

```js
{
    c || bq.test(a) ? e(a, f) : bO(a + "[" + (typeof f === "object" || d.isArray(f) ? b : "") + "]", f, c, e)
}
```
---
You can expand the search area by defining the depth to seek:

```sh
peekabug --depth 2 http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js:16:1545
```

or

```sh
peekabug --depth 2 --cursor 16:1545 http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js
```

Output:

```js
{
    if (d.isArray(b) && b.length) d.each(b, function(b, f) {
        c || bq.test(a) ? e(a, f) : bO(a + "[" + (typeof f === "object" || d.isArray(f) ? b : "") + "]", f, c, e)
    });
    else if (c || b == null || typeof b !== "object") e(a, b);
    else if (d.isArray(b) || d.isEmptyObject(b)) e(a, "");
    else
        for (var f in b) bO(a + "[" + f + "]", b[f], c, e)
}
```
---
From a local file:

```sh
peekabug vendor/jquery.min.js:16:1545
```

Output:

```js
{
    c || bq.test(a) ? e(a, f) : bO(a + "[" + (typeof f === "object" || d.isArray(f) ? b : "") + "]", f, c, e)
}
```
---
Prefer to output the code non-minified? No problem:

```sh
peekabug --uglify vendor/jquery.min.js:16:1545
```

Output:

```js
{c||bq.test(a)?e(a,f):bO(a+"["+(typeof f==="object"||d.isArray(f)?b:"")+"]",f,c,e)}
```


## Author

[Jyrki Laurila](https://github.com/jylauril)

## License (MIT)

```
WWWWWW||WWWWWW
 W W W||W W W
      ||
    ( OO )__________
     /  |           \
    /o o|    MIT     \
    \___/||_||__||_|| *
         || ||  || ||
        _||_|| _||_||
       (__|__|(__|__|
```

Copyright &copy; 2014 Jyrki Laurila

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

