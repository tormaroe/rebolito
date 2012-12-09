Rebolito is a programming language drawing most of it's inspiration from Rebol. It's implemented as an interpreter on top of Ruby.

Status: Very early in development.

###Why?###
For now it's just an experiment, a programming exercise, and ambisions are low. What I'm hoping for is to create a small language I myself will find usefull for minor scripting tasks - as I really love parts of the Rebol language.

###Language characteristics###
* Minimal syntax
* Designed for flexibility and power. Readability is NOT a built-in feature.
* Space, indentation, and line breaks have no significance other than separating values
* First class functions
* Metaprogramming - functions can be constructed and manipulated as lists
* Symbolic

###Sample code###
A simple function, and it's usage:

    double: fun [x][+ x x]

    println double 5

Conditional and booleans:

    a-list: [1, 2, 3]

    println if a-list "List not empty" "List empty"

Add logging to an existing function:

    foo: fun [x][ println ["Doing something with " x] ]

    set-body :foo 
      concat [println "-Foo was called-"] 
        concat body :foo
          [println "-Foo DONE-"]

    foo 1

    ; Output:
    ; -Foo was called-
    ; Doing something with 1
    ; -Foo DONE-

##License##
Copyright (c) 2012 Torbjørn Marø

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

