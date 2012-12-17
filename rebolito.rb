
$__rebolito_version = 0.1

module Rebolito

  ## --------------------------------------------- BASE CLASS OF ALL TYPES
  class Type
    attr_reader :value
    def initialize value
      @value = value
    end
    def ==(other)
      other.class == self.class and @value == other.value
    end
  end

  ## ------------------------------------------ THE BASIC TYPE DEFINITIONS
  class Number < Type
    def initialize token
      super eval(token)
    end
  end
  
  class Symbol < Type
    def initialize token
      super token
    end
  end

  class String < Type
    def initialize token
      super token[1..-2]
    end
  end

  class Assignment < Type
    def initialize token
      super Symbol.new(token[0..-2])
    end
  end

  class RetrieveValue < Type
    def initialize token
      super Symbol.new(token[1..-1])
    end
  end

  class Block < Type
    attr_accessor :closed
    def initialize
      @closed = false
      super []
    end
    def to_s
      "(" + @value.join(", ") + ")-" + (unless @closed then "open" else "closed" end)
    end
  end

  class Function < Type
    attr_accessor :parameters, :body
    def initialize; end
  end

  ## ---------------------------------------------------- THE TOKENIZER
  module Tokenizer
    def self.parse source
      @@rules = {
        /^\"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\"/ => Proc.new {|s| String.new s },
        /^\[/ => Proc.new {|s| Block.new },
        /^\]/ => :block_end,
        /^(?:\-){0,1}\d+(?:\.\d+){0,1}/ => Proc.new {|s| Number.new s },
        /^[A-Za-z0-9%\-_\?\<\>\!\@\#\&\/\=\+\*\.\(\)]+\:/ => Proc.new {|s| Assignment.new s },
        /^\:[A-Za-z0-9%\-_\?\<\>\!\@\#\&\/\=\+\*\.\(\)]+/ => Proc.new {|s| RetrieveValue.new s },
        /^[A-Za-z0-9%\-_\?\<\>\!\@\#\&\/\=\+\*\.\(\)]+/ => Proc.new {|s| 
          if s == 'fun'
            Function.new
          else
            Symbol.new s 
          end
        },
        /^\s+/ => :whitespace
      }
      @@tokens = []
      index = 0
      while index < source.length
        index = next_token source, index
      end
      return @@tokens
    end

    def self.next_token source, index
      @@rules.each do |re, factory|
        match = source[index..-1].scan re
        if match.size > 0
          unless factory == :whitespace
            if factory == :block_end
              @@tokens[-1].closed = true
            elsif @@tokens[-1].class == Block and not @@tokens[-1].closed
              @@tokens[-1].value << factory.call(match[0]) ## TODO: PROBLEM HERE WITH NESTED BLOCKS
            else
              @@tokens << factory.call(match[0])
            end
          end
          return index + match[0].length
        end
      end
      raise "TOKENIZER NO MATCH on " + source[index..-1]
    end
  end

  ## --------------------------------------------------- ENVIRONMENT
  class Scope
    def initialize parent_scope
      @symbols = {}
      @parent = parent_scope
    end
    def add_binding symbol, value
      if symbol.class == ::String
        @symbols[symbol] = value
      else
        @symbols[symbol.value] = value
      end
    end
    def resolve symbol
      return @symbols[symbol] if @symbols.include? symbol
      return @parent.resolve(symbol) if @parent
      raise "Symbol #{symbol} is unbound"
    end
  end

  ## --------------------------------------------------- TYPE EVALUATION
  class ::Array
    def evaluate scope
      self[0].evaluate self, scope
    end
    
    def evaluate_n n, scope
      result = []
      n.times do 
        result << self[0].evaluate(self, scope)
      end
      result
    end
  end

  class Type
    def evaluate ast, scope
      ast.shift
    end
  end

  class Assignment
    def evaluate ast, scope
      assignment_token = ast.shift
      value_to_bind = ast.evaluate scope
      scope.add_binding assignment_token.value, value_to_bind
    end
  end

  class RetrieveValue
    def evaluate ast, scope
      scope.resolve(ast.shift.value.value)
    end
  end

  class Function
    def evaluate ast, scope
      unless ast.size >= 3 and ast[1].class == Block and ast[2].class == Block
        raise "Function needs to be followed by two blocks!"
      end

      fun = ast.shift
      fun.parameters  = ast.evaluate scope
      fun.body        = ast.evaluate scope
      fun
    end

    def invoke ast, scope
      result = nil
      function_scope = Scope.new scope
      # For each formal parameter, evaluate the next ast token 
      # and bind to symbol in function scope
      @parameters.value.each do |p|
        argument = ast.evaluate function_scope
        function_scope.add_binding p, argument
      end
      # evaluate copy of function body with function scope
      function_ast = @body.value.clone
      result = function_ast.evaluate(function_scope) while function_ast.size > 0
      return result
    end
  end

  class Symbol
    def evaluate ast, scope
      symbol = scope.resolve(ast.shift.value)
      
      if symbol.is_a? Function
        symbol.invoke ast, scope
      else
        symbol
      end
    end
  end

  ## --------------------------------------------------- INTERPRETER


  def Rebolito.eval_if_block x, scope
    if x.class == Block
      x.value.evaluate scope
    else
      x
    end
  end

  def Rebolito.false? x
    return x.value.size > 0 if x.class == Block
    return x.value
  end

  class DelegateToObjectFunction < Function
    def initialize message, arity, return_object, scope
      @message = message
      @arity = arity
      @return_object = return_object
      scope.add_binding message, self
    end
    def invoke ast, scope
      lst = ast.evaluate scope
      args = []
      @arity.times { args << ast.evaluate(scope) }
      tmp = lst.value.send @message, *args
      return lst if @return_object
      return tmp
    end
  end

  class Interpreter
    attr_accessor :global

    def initialize
      @global = Scope.new nil

      f = Function.new ; def f.invoke(ast, scope)
        abort "bye bye!"
      end ; @global.add_binding 'quit', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        Number.new (args.shift.value + args.shift.value).to_s
      end ; @global.add_binding '+', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        Number.new (args.shift.value - args.shift.value).to_s
      end ; @global.add_binding '-', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        Number.new (args.shift.value * args.shift.value).to_s
      end ; @global.add_binding '*', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        Number.new (args.shift.value / args.shift.value).to_s
      end ; @global.add_binding '/', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        Number.new (args.shift.value % args.shift.value).to_s
      end ; @global.add_binding '%', f

      f = Function.new ; def f.invoke(ast, scope)
        arg = ast.evaluate scope
        if arg.class == Block
          puts arg.value.map{|v| v.value }.join("")
        else
          puts arg.value
        end
      end ; @global.add_binding 'println', f

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 3, scope
        if Rebolito.false? args[0]
          Rebolito.eval_if_block args[1], scope
        else
          Rebolito.eval_if_block args[2], scope
        end
      end ; @global.add_binding 'if', f

      f = Function.new ; def f.invoke(ast, scope)
        lst = ast.evaluate scope
        lst.value.first
      end ; @global.add_binding 'head', f

      f = Function.new ; def f.invoke(ast, scope)
        lst = ast.evaluate scope
        tmp = Block.new
        lst.value.each {|e| tmp.value << e }
        tmp.value.shift
        return tmp
      end ; @global.add_binding 'tail', f

      DelegateToObjectFunction.new 'push', 1, true, @global
      DelegateToObjectFunction.new 'unshift', 1, true, @global
      DelegateToObjectFunction.new 'shift', 0, false, @global
      DelegateToObjectFunction.new 'pop', 0, false, @global

      eval_string %(
        unless: fun [cond then else][
          if cond else then
        ]
      )
       # map: fun [lst f][
       #   inner: fun [acc   ##### WORK IN PROGRESS!!  -- need append / cons
       # ]

     # )
    end

    def eval_string source
      ast = Tokenizer.parse(source)
      if ast.last.class == Block and not ast.last.closed
        raise SourceNotCompleteException.new
      end
      result = ast.evaluate(@global) while ast.size > 0
      return "NIL" unless result
      return result.value
    end
  end

  class SourceNotCompleteException < Exception
  end
end


## ----------------------------------------------------------- MAIN

if __FILE__ == $PROGRAM_NAME

  if ARGV[0] == "-e"
    ARGV.shift
    source = ARGV.join(" ")
  else
    maybe_file = ARGV[-1]
    if maybe_file and File.exist? maybe_file
      source = File.read(maybe_file)
    end
  end

  rebolito = Rebolito::Interpreter.new
    
  if source
    puts "==> #{ rebolito.eval_string(source) }"
  else
    ## REPL mode
    puts "REBOLito version #{ $__rebolito_version }"

    input = nil
    while true
      if input
        print '.. '
      else
        print '>> '
      end

      input = "#{input} #{gets.chomp}"
      
      begin
        puts "==> #{ rebolito.eval_string(input) }"
        input = nil
      rescue Rebolito::SourceNotCompleteException
        # nothing  
      rescue Exception => e
        #raise
        raise if e.class == SystemExit
        input = nil
        puts "** #{ e }"
      end
    end
  end

end
