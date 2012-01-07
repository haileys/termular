module Termular
  class UI
    attr_accessor :current_graph, :current_command, :insert_mode, :expression, :cursor_offset, :invalidate_next
    
    def draw_status_line
      Console.buffered_print do |s|
        s <<  Console.move(0, Console.rows) <<
              Console.clear_line <<
              Console.color(:black, :white) <<
              (" " * Console.cols) <<
              Console.move(0, Console.rows) <<
              expression
        if insert_mode
          msg = "--INSERT--"
          s <<  Console.move(Console.cols - msg.length + 1, Console.rows) << 
                Console.color(:black, :white) << msg <<
                Console.move(cursor_offset + 1, Console.rows)
        else
          s << Console.move(Console.cols, Console.rows)
        end
        s << Console.reset
      end
    end
    
    def dispatch_keypress(k)
      if invalidate_next
        current_graph and current_graph.invalidate
        @invalidate_next = false
      end
      return dispatch_insert_keypress k if insert_mode
      case k[0]
      when "h" # move left
        current_graph.pan -0.2, 0
      when "H"
        current_graph.pan -0.05, 0
      when "l" # move right
        current_graph.pan 0.2, 0
      when "L"
        current_graph.pan 0.05, 0
      when "j" # move down
        current_graph.pan 0, -0.2
      when "J"
        current_graph.pan 0, -0.05
      when "k" # move up
        current_graph.pan 0, 0.2
      when "K"
        current_graph.pan 0, 0.05
      when " " # center
        current_graph.center
      when "]" # zoom in
        current_graph.zoom 2
      when "[" # zoom out
        current_graph.zoom 0.5
      when "i"
        @insert_mode = true
      when ":"
        @insert_mode = true
        @expression = ":"
        @cursor_offset = 1
      when "o"
        @insert_mode = true
        @expression = ""
        @cursor_offset = 0
      else
        print Console.move 0, 0
        print k.ord
      end

      #print Termular::Console.move 0, Termular::Console.rows
      #print c.ord
      exit if k[0] == "\3"
    end
    
    def dispatch_insert_keypress(k)
      case k[0].ord
      when 127 # backspace
        unless cursor_offset.zero?
          @cursor_offset -= 1
          expression[cursor_offset..cursor_offset] = ""
        end
      when 10 # enter
        begin
          @current_command = Parser.parse! expression
          if current_command.is_a? AST::CartesianCommand
            @current_graph = Graph::Cartesian.new current_command.expression
            @needs_tick = expression =~ /time/
          elsif current_command.is_a? AST::PolarCommand
            @current_graph = Graph::Polar.new current_command.expression
            @needs_tick = expression =~ /time/
          elsif current_command.is_a? AST::OptionCommand
            if current_graph
              current_graph.options[current_command.option] = current_command.expression.eval(Context.global)
              current_graph.invalidate
            end
          elsif current_command.is_a? AST::QuitCommand
            exit
          end
        rescue => e
          show_exception "#{e.class.name} #{e.message}"
        end
      when 27 # special key
        if k == "\e"
          # legit escape
          @insert_mode = false
          return
        end
        case k[1..-1]
        when "OH" # home
          @cursor_offset = 0
        when "OF" # end
          @cursor_offset = expression.length
        when "OD" # arrow left
          @cursor_offset -= 1 unless cursor_offset.zero?
        when "OC" # arrow right
          @cursor_offset += 1 unless cursor_offset == expression.length
        when "[3~"  
          expression[cursor_offset..cursor_offset] = ""
        else
#          print k.each_byte.to_a.join ","
#          raise k[1..-1]#k.each_byte.to_a.join ","
        end
      when 0x20..0x7E
#        expression << k.ord.to_s << " "
        expression[cursor_offset, 0] = k
        @cursor_offset += 1
      end
    end
    
    def show_exception(msg)
      Console.buffered_print do |s|
        s <<  Console.move(0, Console.rows - 1) <<
              Console.color(:bright, :white, :red) <<
              msg <<
              Console.reset
      end
      # this writes over where the graph goes, so invalidate it
      # however if we invalidate it now, it gets immediately dismissed, so set
      # a special flag
      @invalidate_next = true
    end
    
    def render
      Console.clear
      begin
        current_graph.render if current_graph and current_graph.needs_redraw
      rescue => e
        show_exception e.message
      end
      draw_status_line
    end
    
    def tick
      current_graph and current_graph.invalidate
      render
    end
    
    def needs_tick?
      @needs_tick
    end
    
    def initialize
      @cursor_offset = 0
      @expression = ""
    end
  end
end