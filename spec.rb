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
  source = %(  1 foo -1 b.c.d "quux" ) ### TODO: Make it work with an embedded newline (not sure why it doesn't work)
  tokens = Rebolito::Tokenizer.parse(source)

  example %(  ) do tokens.size == 5 end
  example %(  ) do tokens[0].value == 1 end
  example %(  ) do tokens[1].value == "foo" end
  example %(  ) do tokens[2].value == -1 end
  example %(  ) do tokens[3].value == "b.c.d" end
  example %(  ) do tokens[4].value == "quux" end
end

## TODO: Assignment statements
## TODO: Functions parsing, including block start/end (need to seperate lexing and parsing)
## TODO: Global scope
## TODO: Function invocation
## TODO: Core functions: + - * / %

the_end!
