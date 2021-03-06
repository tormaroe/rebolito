
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
    def to_s
      @value.to_s
    end
  end
  
  class Symbol < Type
    def initialize token
      super token
    end
    def to_s
      @value
    end
  end

  class String < Type
    def initialize token
      super token[1..-2]
    end
    def to_s
      %("#{@value}")
    end
  end

  class Assignment < Type
    def initialize token
      super Symbol.new(token[0..-2])
    end
    def to_s
      "#{@value}:"
    end
  end

  class RetrieveValue < Type
    def initialize token
      super Symbol.new(token[1..-1])
    end
    def to_s
      ":#{@value}"
    end
  end

  class Block < Type
    def initialize
      super []
    end
    def to_s
      "[" + @value.join(" ") + "]"
    end
  end

  class Function < Type
    attr_accessor :parameters, :body
    def initialize; end
    def to_s
      if @parameters and @body
        "fun #{@parameters} #{@body}"
      else
        "[built-in function]"
      end
    end
  end

  ## ---------------------------------------------------- THE TOKENIZER
  module Tokenizer
    def self.parse source
      @@rules = {
     #   /^\n/ => :whitespace,
        /^\"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\"/ => Proc.new {|s| String.new s },
        /^\[/ => :block_start,
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
     # puts "SOURCE:"
     # puts source
      @@source = source #.gsub /\n/, ' '
      @@tokens = []
      @@block_stack = []

      next_token while @@source.length > 0
     # puts "TOKENS"
     # p @@tokens
      return @@tokens
    end

    def self.next_token 
      @@rules.each do |re, factory|
        match = @@source.scan re
        if match.size > 0
          unless factory == :whitespace
            if factory == :block_end
              b = @@block_stack.pop
              if @@block_stack.size > 0
                @@block_stack.last.value << b
              else
                @@tokens << b
              end
            elsif factory == :block_start
              @@block_stack.push Block.new
            elsif @@block_stack.size > 0
              @@block_stack.last.value << factory.call(match[0])
            else
              @@tokens << factory.call(match[0])
            end
          end
          @@source = @@source[match[0].length..-1]
          return
        end
      end
      raise "TOKENIZER NO MATCH on '#{ @@source }'\nTOKENS: #{ @@tokens }"
    end
  end

  ## --------------------------------------------------- ENVIRONMENT
  
  module CoreBindings
    def self.add_bindings scope
      @@bindings ||= []
      scope.symbols.keys.each {|k| @@bindings << k }
    end
    def self.is_core? symbol
      @@bindings.include? (if symbol.class == ::String then symbol else symbol.value end)
    end
  end

  class Scope
    attr_reader :symbols
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
    #rescue
    #  p self
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

  class Block
    def clone
      c = Block.new
      @value.each do |v|
        c.value << v.clone
      end
      return c
    end
#    def evaluate ast, scope
#      result = ast.evaluate(scope) while ast.size > 0
#      return result
#    end
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
      function_ast = @body.clone
      result = function_ast.value.evaluate(function_scope) while function_ast.value.size > 0
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

  class ReplFunctionHelp < Function
    def invoke ast, scope
      puts " REPL COMMANDS"
      puts '-'*60
      puts " ?vars          Lists all symbols in scope"
      puts " ? <symbol>     Display information about symbol binding"
      puts " load <path>    Load Rebolito script"
      puts " save <path>    Save environment to file path"
      puts " quit           Exit REPL"
      puts '-'*60
    end
  end

  class ReplFunctionSymbolInfo < Function
    def invoke ast, scope
      sym = ast.shift
      binding = scope.resolve(sym.value)
      puts
      puts " SYMBOL : #{sym}"
      puts " TYPE   : #{binding.class}"
      puts " CORE   : #{CoreBindings.is_core?(sym)}"
      puts " VALUE  : #{binding}"
      puts
    end
  end

  class ReplFunctionVars < Function
    def invoke ast, scope
      puts "SYMBOLS IN CURRENT SCOPE:"
      puts
      scope.symbols.keys.sort.each_slice(3) do |keys|
        print_row keys
      end
      puts
      return nil
    end
    def print_row r
      r.each {|x| print " #{x}".ljust(25) }
      puts
    end
  end

  class ReplFunctionLoad < Function
    def initialize interpreter
      @interpreter = interpreter
    end
    def invoke ast, scope
      path = ast.evaluate(scope).value
      raise "'#{path}' is not a valid file path" unless File.exist? path

      source = File.readlines(path).join " "
      #puts source
      @interpreter.eval_string source
      puts "\n#{path} loaded!"
    end
  end

  class ReplFunctionSave < Function
    def invoke ast, scope
      path = ast.evaluate(scope).value
      source = ""
      scope.symbols.each do |key, binding|
        unless CoreBindings.is_core? key
          source += "#{key}: #{binding}\n\n"
        end
      end

      if source.length > 0
        source = %("
  Rebolito environment saved on #{Time.new}
  Rebolito version #{$__rebolito_version}
"\n\n) + source
        
        File.open(path, 'w') {|f| f.puts source }
        return RebolitoTRUE        
      else
        puts " << NOTHING TO SAVE HERE >> "
        return RebolitoFALSE
      end
    end
  end

  class Interpreter
    attr_accessor :global

    def initialize
      @global = Scope.new nil

      f = Function.new ; def f.invoke(ast, scope)
        abort "bye bye!"
      end ; @global.add_binding 'quit', f

      @global.add_binding "true", RebolitoTRUE
      @global.add_binding "false", RebolitoFALSE

      @global.add_binding 'help', ReplFunctionHelp.new
      @global.add_binding '?vars', ReplFunctionVars.new
      @global.add_binding 'load', ReplFunctionLoad.new(self)
      @global.add_binding 'save', ReplFunctionSave.new
      @global.add_binding '?', ReplFunctionSymbolInfo.new

      f = Function.new ; def f.invoke(ast, scope)
        args = ast.evaluate_n 2, scope
        return RebolitoTRUE if args[0] == args[1]
        return RebolitoFALSE
      end ; @global.add_binding '=', f

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
          puts arg.value.map{|v| v.value }.join("") # TODO: need to evaluate values...
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
        a: "hi"

        b: "Dette er en test"
 c: "Dette er en test"

        unless: fun [cond then else][
          if cond else then
        ]
        and: fun [a b][
          if a [
            temp: b
            if temp temp false
          ] [[]]
        ]
        not: fun [x][
          if x [false] [true]
        ]
        inc: fun [x][+ x 1]
        dec: fun [x][- x 1]
        zero?: fun [x][if = 0 x true [[]]]
        "map: fun [lst f][
          result: []
          inner: fun [lst2] [
            if lst2 [ 
              push result f head lst2
              inner tail lst2
            ] done
          ]
          inner lst
        ]"

      )


      CoreBindings.add_bindings @global
    end

    def eval_string source
      ast = Tokenizer.parse(source)
      result = ast.evaluate(@global) while ast.size > 0
      return "NIL" unless result
      return result
    end
  end

  class SourceNotCompleteException < Exception
  end

  RebolitoTRUE = Symbol.new "true"
  RebolitoFALSE = Block.new
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
      rescue Rebolito::SourceNotCompleteException # TODO: Make this work again
        # nothing  
#=begin
      rescue Exception => e
        #raise
        raise if e.class == SystemExit
        input = nil
        puts "** #{ e }"
#=end
      end
    end
  end

end
