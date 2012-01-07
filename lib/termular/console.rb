module Termular
  module Console    
    def self.init
      Ncurses.initscr
      Ncurses.raw
      Ncurses.noecho
      Ncurses.keypad Ncurses.stdscr, true
      Ncurses.refresh
      at_exit { Ncurses.endwin }
    end
    
    def self.move(x, y)
      "\e[#{y.to_i};#{x.to_i}H"
    end
    
    def self.clear
      "\e[H\e[2J"
    end
    
    def self.clear_line
      "\e[0G\e[2K"
    end
    
    def self.color(*col)
      Paint["|", *col].split("|").first
    end
    
    def self.reset
      "\e[m"
    end
    
    def self.cols
      Ncurses.getmaxx Ncurses.stdscr
    end

    def self.rows
      Ncurses.getmaxy Ncurses.stdscr
    end

    def self.buffered_print
      buff = ""
      yield buff
      print buff
    end
  end
end