module Termular  
  class Context
    def self.global
      @@global ||= begin
        ctx = Context.new
        %w( acos acosh asin asinh atan atan2 atanh cbrt cos cosh erf erfc exp
            log log10 log2 sin sinh sqrt tan tanh ).each do |m|
          ctx[m] = Math.method m
        end
        %w( PI E ).each do |c|
          ctx[c.downcase] = Math.const_get c
        end
        ctx["ln"]     = ctx["log"]
        ctx["abs"]    = ->x { x.abs }
        ctx["arg"]    = ->x { x.arg }
        ctx["ceil"]   = ->x { x.ceil }
        ctx["floor"]  = ->x { x.floor }
        ctx["int"]    = ->x { x.to_i }
        ctx["mod"]    = ->a,b { a % b }
        ctx
      end
    end
    
    attr_accessor :vars, :parent
    
    def initialize(parent = nil)
      @vars, @parent = {}, parent
    end
    
    def [](var)
      if vars.key? var
        vars[var]
      elsif parent
        parent[var]
      else
        raise "undefined variable '#{var}'"
      end        
    end
    
    def []=(var, val)
      if vars.key? var
        vars[var] = val
      elsif parent and parent.has? val
        parent[var] = val
      else
        vars[var] = val
      end
    end
    
    def has?(var)
      vars.key?(var) or parent && parent.has?(var)
    end
  end
end