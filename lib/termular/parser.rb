module Termular
  class SyntaxError < StandardError; end
  
  module AST
    class Base
      def initialize(hash = {})
        hash.each { |k,v| send "#{k}=", v }
      end
    end
    
    class Binary < Base
      attr_accessor :left, :right
    end
    
    class Add < Binary;       def eval(ctx) left.eval(ctx) + right.eval(ctx) end end
    class Subtract < Binary;  def eval(ctx) left.eval(ctx) - right.eval(ctx) end end
    class Multiply < Binary;  def eval(ctx) left.eval(ctx) * right.eval(ctx) end end
    class Divide < Binary;    def eval(ctx) left.eval(ctx) / right.eval(ctx) end end
    class Power < Binary;     def eval(ctx) left.eval(ctx) ** right.eval(ctx) end end
    
    class Negate < Base
      attr_accessor :expression
      def eval(ctx)
        -expression.eval(ctx)
      end
    end
    
    class Variable < Base
      attr_accessor :name
      def eval(ctx)
        ctx[name]
      end
    end
    
    class Number < Base
      attr_accessor :number
      def eval(ctx)
        number
      end
    end
    
    class Call < Base
      attr_accessor :callee
      attr_accessor :args
      def eval(ctx)
        callee.eval(ctx).call *args.map { |a| a.eval(ctx) }
      end
    end
    
    class CartesianCommand < Base
      attr_accessor :expression
    end
    
    class PolarCommand < Base
      attr_accessor :expression
    end
    
    class OptionCommand < Base
      attr_accessor :option, :expression
    end
    
    class QuitCommand < Base; end
  end
  
  class Lexer
    TOKENS = [
        [ :WHITESPACE,    /\s+/ ],
        [ :NUMBER,        /\d+(\.\d+)?/, ->m { m[0].to_f } ],
        [ :BAREWORD,      /[a-z][a-z0-9]*/, ->m { m[0] } ],
        [ :PLUS,          /\+/ ],
        [ :MINUS,         /-/ ],
        [ :TIMES,         /\*/ ],
        [ :DOT,           /\./ ],
        [ :DIVIDE,        /\// ],
        [ :POWER,         /\^/ ],
        [ :OPEN_PAREN,    /\(/ ],
        [ :CLOSE_PAREN,   /\)/ ],
        [ :OPEN_BRACKET,  /\[/ ],
        [ :CLOSE_BRACKET, /\]/ ],
        [ :COMMA,         /\,/ ],
        [ :COMMAND,       /:([a-z][a-z0-9]*)/, ->m { m[1] } ]
      ].map { |a| [a[0], Regexp.new("\\A#{a[1].source}", Regexp::MULTILINE), a[2]] }
      
    def self.lex!(original_src)
      tokens = []
      offset = 0
      src = original_src
      until src.empty?
        match = nil
        tok, re, conv = TOKENS.find { |tok, re, conv| match = re.match(src, offset) }
        raise SyntaxError, "illegal character at position #{original_src.length - src.length}" unless match
        tokens << [tok, conv && conv[match]] unless tok == :WHITESPACE
        src = match.post_match
      end
      tokens << [:END]
    end
  end
  
  class Parser
    def self.parse!(src)
      Parser.new(src).parse
    end
    
    def initialize(src)
      @src = src
      @tokens = Lexer.lex! src
      @i = -1
    end
    
    def token
      @tokens[@i]
    end
    
    def peek_token
      @tokens[@i + 1]
    end
    
    def next_token
      @tokens[@i += 1]
    end
    
    def assert_type(token, *types)
      unless types.include? token[0]
        raise SyntaxError, "Expected one of #{types.join ", "}, found #{token[0]}"
      end
    end
    
    def parse
      cmd = if peek_token[0] == :COMMAND
              command
            else
              AST::CartesianCommand.new expression: expression
            end
      assert_type next_token, :END
      cmd
    end
    
    def command
      assert_type next_token, :COMMAND
      case token[1]
      when "q";   AST::QuitCommand.new
      when "c";   AST::CartesianCommand.new expression: expression
      when "p";   AST::PolarCommand.new expression: expression
      when "opt"; option_command
      end
    end
    
    def option_command
      assert_type next_token, :BAREWORD
      opt = token[1]
      AST::OptionCommand.new option: opt, expression: expression
    end
    
    def expression
      additive_expression
    end
    
    def additive_expression
      expr = multiplicative_expression
      while [:PLUS, :MINUS].include? peek_token[0]
        case next_token[0]
        when :PLUS;   expr = AST::Add.new       left: expr, right: multiplicative_expression
        when :MINUS;  expr = AST::Subtract.new  left: expr, right: multiplicative_expression
        end
      end
      expr
    end
    
    def multiplicative_expression
      expr = power_expression
      while [:TIMES, :DIVIDE].include? peek_token[0]
        case next_token[0]
        when :TIMES;  expr = AST::Multiply.new  left: expr, right: power_expression
        when :DIVIDE; expr = AST::Divide.new    left: expr, right: power_expression
        end
      end
      expr
    end
    
    def power_expression
      expr = call_expression
      if peek_token[0] == :POWER
        next_token
        expr = AST::Power.new left: expr, right: power_expression
      end
      expr
    end
    
    def call_expression
      expr = unary_expression
      while peek_token[0] == :OPEN_BRACKET
        next_token
        args = []
        args << expression
        while peek_token[0] == :COMMA
          next_token
          args << expression
        end
        expr = AST::Call.new callee: expr, args: args
        assert_type next_token, :CLOSE_BRACKET
      end
      expr
    end
    
    def unary_expression
      case next_token[0]
      when :MINUS;      AST::Negate.new expression: unary_expression
      when :BAREWORD;   AST::Variable.new name: token[1]
      when :NUMBER;     AST::Number.new number: token[1]
      when :OPEN_PAREN; expr = expression
                        assert_type next_token, :CLOSE_PAREN
                        expr
      else
        raise SyntaxError, "Unexpected #{token[0]}"
      end
    end
  end
end