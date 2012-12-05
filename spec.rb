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
  source = %(  1 foo -1
 b.c.d "quux" ) ### TODO: Make it work with an embedded newline (not sure why it doesn't work)
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
  example %(  ) do tokens[0].class == Rebolito::Block end
end

explanation %(
  
) do
  rebolito = Rebolito::Interpreter.new
  rebolito.eval_string %( foo: 10 )

  example %( Look up value based on symbol name ) do 
    rebolito.global.resolve("foo").value == 10 
  end
end




## TODO: Functions parsing, including block start/end (need to seperate lexing and parsing)
## TODO: Function invocation
## TODO: Core functions: + - * / % print
## TODO: Core conditional (if)
## TODO: Lists (cons cells, or maybe just block?)
## TODO: Core iterator (each)
## TODO: head / tail (alternative to each)
## TODO: Each on strings should also work (convert to cons cells?)
## TODO: Base library: map filter reduce

the_end!
