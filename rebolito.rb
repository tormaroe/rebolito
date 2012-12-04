
module Rebolito

  ## ------------------------------------------ BASE CLASS OF ALL TYPES
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
      super( eval token )
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

  ## ---------------------------------------------------- THE TOKENIZER
  module Tokenizer
    def self.parse source
      @@rules = {
        /^\s+/ => :whitespace,
        /^\"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\"/ => Proc.new {|s| String.new s },
        /^(?:\-){0,1}\d+(?:\.\d+){0,1}/ => Proc.new {|s| Number.new s },
        /^[A-Za-z]+[A-Za-z0-9\-_\?\<\>\!\@\#\&\/\=\+\.]*/ => Proc.new {|s| Symbol.new s }
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
            @@tokens << factory.call(match[0])
          end
          return index + match[0].length
        end
      end
      raise "TOKENIZER NO MATCH"
    end
  end
end
