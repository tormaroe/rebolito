require '.\\spechelp.rb'
require '.\\rebolito.rb'


explanation %(
  Rebolito is a programming language. It has literal data types like 
  numbers, symbols, and strings.
) do
  example %( this is how you would specify a number ) do
    Rebolito::Tokenizer.parse("123")[0] == Rebolito::Number.new("123")
  end
  example %( this is how you would specify a decimal number ) do
    Rebolito::Tokenizer.parse("1.5")[0] == Rebolito::Number.new("1.5")
  end
  example %( this is how you would specify a negative number ) do
    Rebolito::Tokenizer.parse("-0.20")[0] == Rebolito::Number.new("-0.20")
  end
  
  example %( this is how you would specify a symbol ) do
    Rebolito::Tokenizer.parse("foo")[0] == Rebolito::Symbol.new("foo")
  end
  example %( this is how you would specify a symbol with various characters ) do
    Rebolito::Tokenizer.parse("foo-bar_7?<>!@#&/=+.")[0] == Rebolito::Symbol.new("foo-bar_7?<>!@#&/=+.")
  end

  example %( this is how you would specify a string ) do
    Rebolito::Tokenizer.parse("\"foo bar quux\"")[0] == Rebolito::String.new("\"foo bar quux\"")
  end
  example %( this is how you would specify a string with escaped quotes ) do
    Rebolito::Tokenizer.parse('"foo \\"bar\\""')[0] == Rebolito::String.new("\"foo \\\"bar\\\"\"")
  end
end


explanation %(
  A chunk of code can be parsed into a stream of basic types.
) do
  source = %(  
              1 foo -1
              b.c.d "quux" 
            )
  tokens = Rebolito::Tokenizer.parse(source)

  example %( 0 ) do tokens.size == 5 end
  example %( 1 ) do tokens[0].value == 1 end
  example %( 2 ) do tokens[1].value == "foo" end
  example %( 3 ) do tokens[2].value == -1 end
  example %( 4 ) do tokens[3].value == "b.c.d" end
  example %( 5 ) do tokens[4].value == "quux" end
end


explanation %(
  This is how you assign a value to a variable.
) do
  source = %( foo: 10 ) 
  tokens = Rebolito::Tokenizer.parse(source)

  example %(  ) do tokens.size == 2 end
  example %(  ) do tokens[0].class == Rebolito::Assignment end
  example %( The Assignment contains a symbol as it's value ) do 
    tokens[0].value.value == "foo" 
  end
end

explanation %(
) do
  source = %( [foo bar 2] ) 
  tokens = Rebolito::Tokenizer.parse(source)

  example %( Result has size one ) do tokens.size == 1 end
  example %( Result is of type BLOCK  ) do tokens[0].class == Rebolito::Block end
  example %( The block contains the items  ) do 
    items = tokens[0].value
    items.size == 3 and
    items[0].class == Rebolito::Symbol and
    items[1].class == Rebolito::Symbol and
    items[2].class == Rebolito::Number and
    items[0].value == "foo" and
    items[2].value == 2
  end

  example %( A block can be empty ) do
    Rebolito::Tokenizer.parse(%([]))[0].class == Rebolito::Block 
  end
  example %( A block can span multiple lines ) do
    Rebolito::Tokenizer.parse(%(
      [
        "This is a test"
      ]
    ))[0].class == Rebolito::Block
  end
  
  example %( Nested blocks.. ) do
    tokens = Rebolito::Tokenizer.parse(%(
      [
        1 [
            2
          ]
      ]
    ))
    tokens.size == 1 and 
    tokens[0].class == Rebolito::Block and
    tokens[0].value.size == 2
  end
end


explanation %(
  Functions...
) do
  tokens = Rebolito::Tokenizer.parse(%(
    fun [] [
      0
    ]
  ))

  example %( function has three tokens ) do tokens.size == 3 end
  example %( first function token is the Function instance itself ) do tokens[0].class == Rebolito::Function end
  example %( the other two are blocks ) do tokens[1].class == Rebolito::Block and tokens[2].class == Rebolito::Block end
end

explanation %(
  
) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( foo: 10 )

  example %( Look up value based on symbol name ) do 
    rebolito.global.resolve("foo").class == Rebolito::Number and
    rebolito.global.resolve("foo").value == 10 
  end
end

explanation %(
  
) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( foo: fun [][bar] )

  example %( Value for symbol should be a Function ) do 
    rebolito.global.resolve("foo").class == Rebolito::Function 
  end
  example %( Function has a parameters block and body block ) do 
    rebolito.global.resolve("foo").parameters.class == Rebolito::Block and 
    rebolito.global.resolve("foo").body.class == Rebolito::Block 
  end
end


explanation %(
  Function invocation
) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         identity: fun [x][x]
                         foo: identity 4
                        )

  example %( Value for symbol foo should be a Number ) do 
    rebolito.global.resolve("foo").class == Rebolito::Number 
  end
  example %( Value for symbol foo should be the number 4 ) do 
    rebolito.global.resolve("foo").value == 4 
  end
end

explanation %(
  Math functions from core library
) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         x: + 1 2    "<-- a coment -->"     y: + 1 -5

                         p: - - - 10 8 3 -2 [ ... doing several (yes this is a comment) ]

                         z: * 3 5                           w: / 12 3

                         xXx: % 15 3
                         xXy: % 16 3
                        )
  
  example %( Add numbers ) do 
    rebolito.global.resolve("x").value == 3 and 
    rebolito.global.resolve("y").value == -4 
  end
  example %( Subtract ) do 
    rebolito.global.resolve("p").value == 1
  end
  example %( Multiply ) do 
    rebolito.global.resolve("z").value == 15 
  end
  example %( Devide ) do 
    rebolito.global.resolve("w").value == 4 
  end
  example %( Modulo ) do 
    rebolito.global.resolve("xXx").value == 0 and 
    rebolito.global.resolve("xXy").value == 1 
  end
end

explanation %( Nested scopes ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                      x: 3
                      y: fun [z][* x z]
                      q: y 2
                        )
                        
  example %( nested scopes working ) do 
    rebolito.global.resolve("q").value == 6 
  end
end

explanation %( IF and EQUAL ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                          x:  if "foo" 2 3
                          y:  if [] 1 2
                          xx: if "foo" [+ 1 2] [quit]
                          yy: if [quit foo bar] [111] [quit]
                          xxx: if = 1 1 "true" "false"
                          yyy: if = 1 2 "true" "false"
                        )
                        
  example %( simplest if with true condition ) do 
    rebolito.global.resolve("x").value == 2 
  end
  example %( empty list is false ) do 
    rebolito.global.resolve("y").value == 2 
  end
  example %( if with true condition using blocks ) do
    rebolito.global.resolve("xx").value == 3 
  end
  example %( if with true block condition  ) do
    rebolito.global.resolve("yy").value == 111 
  end
  example %( equal becomes true ) do
    rebolito.global.resolve("xxx").value == "true" 
  end
  example %( equal becomes false ) do
    rebolito.global.resolve("yyy").value == "false" 
  end
end


explanation %( Boolean operators: AND, OR, NOT ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                       t: true
                       f: false
                       n: not t
                       n2: not f

                       x: if and 1 1 "true" "false"
                       y: and 1 2
                       x2: if and 1 false "true" "falseX"
                       y2: and false 2
                       y3: and 2 false
                        )
                        # TODO: and true [println "foo"] -- returns the block unevaluated :(
  example %( and 1 1 ) do 
    rebolito.global.resolve("x").value == "true"
  end
  example %( not true ) do
    rebolito.global.resolve("n").class == Rebolito::Block and rebolito.global.resolve("n").value.size == 0
  end
  example %( not false ) do 
    rebolito.global.resolve("n2").value == "true"
  end
  example %( and should evaluate to last value if both is true ) do 
    rebolito.global.resolve("y").value == 2
  end
  example %( and 1 false ) do 
    rebolito.global.resolve("x2").value == "falseX"
  end
  example %( and should evaluate to [] if one value is false ) do 
    rebolito.global.resolve("y2").class == Rebolito::Block and rebolito.global.resolve("y2").value.size == 0
  end
  example %( and should evaluate to [] if one value is false (2) ) do 
    rebolito.global.resolve("y3").class == Rebolito::Block and rebolito.global.resolve("y2").value.size == 0
  end
end


explanation %( UNLESS ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         x: unless "foo" 
                            2 
                            3
                        )                        
  example %( simplest unless with true condition ) do
    rebolito.global.resolve("x").value == 3 
  end
end


explanation %( HEAD and TAIL ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         x: [1 2 3 4]
                         h: head x
                         t: tail x
                        )                        
  example %( head ) do
    rebolito.global.resolve("h").value == 1 
  end                 
  example %( tail ) do
    rebolito.global.resolve("t").class == Rebolito::Block and
    rebolito.global.resolve("t").value == [
      Rebolito::Number.new("2"), 
      Rebolito::Number.new("3"), 
      Rebolito::Number.new("4")]
  end
end

explanation %( PUSH, POP, SHIFT, and UNSHIFT ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         x: [2]
                         push x 3
                         unshift x 1
                         unshift x 0
                         y: shift x
                         z: []
                         push z pop x
                        )   
                        
  example %( fooooo ) do
    rebolito.global.resolve("x").value == [
      Rebolito::Number.new("1"),
      Rebolito::Number.new("2")]
  end
   example %( foooo3 ) do
    rebolito.global.resolve("z").value == [
      Rebolito::Number.new("3")]
  end
  example %( fooooo2 ) do
    rebolito.global.resolve("y").value == 0
  end
end

explanation %( Retrieve a function as a value ) do 
rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                        x: fun [][ "foo" ]
                        y: :x
                        z: y
                        x2: fun [][ :x ]
                        y2: x2
                        z2: y2
                        )
  example %( fooooo2 ) do
    rebolito.global.resolve("y").class == Rebolito::Function and
    rebolito.global.resolve("z").value == "foo"
  end
  example %( fooooo3 ) do
    rebolito.global.resolve("y2").class == Rebolito::Function and
    rebolito.global.resolve("z2").value == "foo"
  end
  
end

=begin
explanation %( MAP ) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( 
                         x: [1 2 3 4]
                         y: map x fun [z][
                              * z 2
                         ]
                        )                        
  example %( adsadssad ) do
    r = rebolito.global.resolve("y")
    p r
    r.class == Rebolito::Block and
    r.value == [
      Rebolito::Number.new("2"), 
      Rebolito::Number.new("4"), 
      Rebolito::Number.new("6"), 
      Rebolito::Number.new("8")]
  end
end
=end

## TODO: Metaprogramming: body, set-body, parameters, set-parameters
## TODO: ?vars only display user defined, and add ?core
## TODO: Add useful functions from Clojure.Core
## TODO: Add hashmap
## TODO: cond, < > <= >= even? odd? count/size/length block? string? number? partial compose, join (strings and blocks) split
## TODO: And & Or -- if evaluerer ikke blockene sine riktig - her har jeg en jobb å gjøre!!!!!!!!!!!!!!! <== PRI 1
## TODO: Function returning function                                                                     <== PRI 3
## TODO: Core iterator (each)                                                                            <== PRI 1
#          Also a FOR and/or LOOP and/or WHILE
## TODO: Each on strings should also work (convert to cons cells?)
## TODO: Base library: map filter reduce                                                                 <== PRI 2
## TODO: eval function
## TODO: funcall functions ?
## random
## file utils (spit slurp)
## curl commands
## regexps

the_end!
