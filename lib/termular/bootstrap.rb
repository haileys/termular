require "termular/parser"
require "termular/context"
require "termular/console"
require "termular/graph"
require "termular/ui"
require "ncurses"
require "paint"

Termular::Console.init
ui = Termular::UI.new
ui.render

trap("WINCH") { Ncurses.endwin; Ncurses.refresh; ui.tick }

loop do
  c = nil
  if ui.needs_tick?
    hack = Thread.new { c = STDIN.getc }
    hack.join 0.1
    hack.kill
    if c.nil?
      ui.tick
      next
    end
  else
    c = STDIN.getc
  end
  if c.ord == 27
    hack = Thread.new { c << STDIN.getc; c << STDIN.getc; c << STDIN.getc }
    hack.join 0.001
    hack.kill
  end
  ui.dispatch_keypress c
  ui.render
end