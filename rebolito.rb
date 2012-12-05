
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

  class Block < Type
    attr_accessor :closed
    def initialize
      @closed = false
      super []
    end
  end

  ## ---------------------------------------------------- THE TOKENIZER
  module Tokenizer
    def self.parse source
      @@rules = {
        /^\"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\"/ => Proc.new {|s| String.new s },
        /^\[/ => Proc.new {|s| Block.new },
        /^\]/ => :block_end,
        /^(?:\-){0,1}\d+(?:\.\d+){0,1}/ => Proc.new {|s| Number.new s },
        /^[A-Za-z]+[A-Za-z0-9\-_\?\<\>\!\@\#\&\/\=\+\.]*\:/ => Proc.new {|s| Assignment.new s },
        /^[A-Za-z]+[A-Za-z0-9\-_\?\<\>\!\@\#\&\/\=\+\.]*/ => Proc.new {|s| Symbol.new s },
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
              @@tokens[-1].value << factory.call(match[0])
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
    end
    def add_binding symbol, value
      if symbol.class == ::String
        @symbols[symbol] = value
      else
        @symbols[symbol.value] = value
      end
    end
    def resolve symbol
      @symbols[symbol]
    end
  end

  ## --------------------------------------------------- INTERPRETER

  class Interpreter
    attr_accessor :global
    def initialize
      @global = Scope.new nil
    end
    def eval_string source # UNFORTUNATE NAME!!!
      self.eval(Tokenizer.parse(source))
    end
    def eval ast
      #return @global.add_binding "foo", Number.new("10")

      while ast.size > 0
        if ast[0].class == Rebolito::Assignment
          eval_assignment ast
        end
      end
    end

    def eval_assignment ast
      @global.add_binding ast.shift.value, ast.shift
    end
  end
end
