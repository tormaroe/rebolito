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
    Rebolito::Tokenizer.parse("\"foo bar\"")[0] == Rebolito::String.new("\"foo bar\"")
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
    Rebolito::Tokenizer.parse(%([]))[0].class == Rebolito::Block and
    Rebolito::Tokenizer.parse(%([]))[0].closed 
  end
  example %( A block can span multiple lines ) do
    Rebolito::Tokenizer.parse(%(
      [
        "This is a test"
      ]
    ))[0].class == Rebolito::Block
  end
  
  #example %( Nested blocks.. ) do
  #  tokens = Rebolito::Tokenizer.parse(%(
  #    [
  #      1 [
  #          2
  #        ]
  #    ]
  #  ))
  #  p tokens
  #  tokens.size == 1 and 
  #  tokens[0].class == Rebolito::Block and
  #  tokens[0].value.size == 2
  #end
end


explanation %(
  Functions...
) do
  tokens = Rebolito::Tokenizer.parse(%(
    fun [] [
      0
    }
  ))
  example %() do tokens.size == 3 end
  example %() do tokens[0].class == Rebolito::Function end
  example %() do tokens[1].class == Rebolito::Block and tokens[2].class == Rebolito::Block end
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
    p rebolito.global.resolve("foo")
    rebolito.global.resolve("foo").class == Rebolito::Number 
  end
  example %( Value for symbol foo should be the number 4 ) do 
    rebolito.global.resolve("foo").value == 4 
  end
end



## TODO: Function invocation
## TODO: code comments ??
## TODO: Core functions: + - * / % print
## TODO: Core conditional (if)
## TODO: Lists (cons cells, or maybe just block?)
## TODO: Core iterator (each)
## TODO: head / tail (alternative to each)
## TODO: Each on strings should also work (convert to cons cells?)
## TODO: Base library: map filter reduce

the_end!
