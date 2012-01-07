module Termular
  class Graph
    attr_accessor :expression, :max_x, :max_y, :min_x, :min_y, :needs_redraw, :start_time, :options
    
    def initialize(expression)
      @expression = expression
      @max_x = 10
      @min_x = -10
      factor = (Console.rows * 2.4 / Console.cols.to_f)
      @max_y = factor * @max_x
      @min_y = factor * @min_x
      @start_time = Time.now.to_f
      @options = {}
      invalidate
    end
    
    def invalidate
      @needs_redraw = true
    end
    
    def pan(fx, fy)
      x = (max_x - min_x) * fx
      y = (max_y - min_y) * fy
      @min_x += x
      @max_x += x
      @min_y += y
      @max_y += y
      invalidate
    end
    
    def center
      w = max_x - min_x
      h = max_y - min_y
      
      @max_x = w/2.0
      @min_x = -@max_x
      @max_y = h/2.0
      @min_y = -@max_y
      invalidate
    end
    
    def zoom(factor)
      w = max_x - min_x
      h = max_y - min_y
      
      cx = min_x + w/2.0
      cy = min_y + h/2.0
      
      w /= factor.to_f
      h /= factor.to_f
      
      @min_x = cx - w/2.0
      @max_x = cx + w/2.0
      @min_y = cy - h/2.0
      @max_y = cy + h/2.0
      invalidate
    end
    
    def point_to_screen(x, y)
      sw = Console.cols
      sh = Console.rows
      pw = max_x - min_x
      ph = max_y - min_y
      sx = (((x - min_x) / pw.to_f) * sw).round
      sy = sh - (((y - min_y) / ph.to_f) * sh).round
      [sx, sy]
    end
    
    def screen_to_point(x, y)
      sw = Console.cols
      sh = Console.rows
      pw = max_x - min_x
      ph = max_y - min_y
      sx = ((x / sw.to_f) * pw) + min_x
      sy = ((y / sh.to_f) * ph) + min_y
      [sx, sy]
    end
    
    def render_axes
      buff = Console.clear
      scr_origin = point_to_screen 0, 0
      buff << Console.color(:white)
      if scr_origin[0] >= 0 and scr_origin[0] <= Console.cols
        0.upto(Console.rows).each do |y|
          buff << Console.move(scr_origin[0], y)
          buff << "|"
        end
      end
      if scr_origin[1] >= 0 and scr_origin[1] <= Console.rows
        buff << Console.move(0, scr_origin[1])
        buff << "-" * Console.cols
        if scr_origin[0] >= 0 and scr_origin[0] <= Console.cols
          buff << Console.move(scr_origin[0], scr_origin[1])
          buff << "+"
        end
      end
      buff
    end
    
    class Cartesian < Graph
      def render
        @needs_redraw = false
        Console.buffered_print do |buff|
          buff << render_axes
          # render actual graph
          ctx = Context.new Context.global
          buff << Console.color(:green)
          ctx["time"] = Time.now.to_f - @start_time
          old_y = nil
          0.upto(Console.cols).map { |x| screen_to_point(x, 0)[0] }.each do |x|
            ctx["x"] = x
            py = expression.eval ctx
            next if py.is_a? Complex or (py.respond_to? :nan and py.nan?)
            scr_pt = point_to_screen(x, py)
            new_y = scr_pt[1]
            (old_y ? (old_y > new_y ? (old_y - 1).downto(new_y) : (old_y < new_y ? (old_y + 1).upto(new_y) : [new_y])) : [new_y]).each do |y|
              if scr_pt[0] >= 0 and scr_pt[0] <= Console.cols and y >= 0 and y <= Console.rows
                buff << Console.move(scr_pt[0], y)
                buff << "+"
              end
            end
            old_y = new_y
          end
          buff << Console.reset
        end
      end
    end
  
    class Polar < Graph
      def render
        @needs_redraw = false
        Console.buffered_print do |buff|
          buff << render_axes
          # render actual graph
          ctx = Context.new Context.global
          buff << Console.color(:green)
          ctx["time"] = Time.now.to_f - @start_time
          old_y = nil
          (options["tmin"] || 0).upto(((options["tmax"] || 2 * Math::PI) * 100).round).map { |t| t / 100.0 }.each do |theta|
            ctx["t"] = theta
            radius = expression.eval ctx
            next if radius.is_a? Complex or (radius.respond_to? :nan and radius.nan?)
            scr_pt = point_to_screen(radius*Math.cos(theta), radius*Math.sin(theta))
            if scr_pt[0] >= 0 and scr_pt[0] <= Console.cols and scr_pt[1] >= 0 and scr_pt[1] <= Console.rows
              buff << Console.move(scr_pt[0], scr_pt[1])
              buff << "+"
            end
          end
          buff << Console.reset
        end
      end
    end
  end
end