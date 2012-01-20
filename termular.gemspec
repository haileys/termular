Gem::Specification.new do |s|
  s.name          = "termular"
  s.version       = "0.1.4"
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Charlie Somerville"]
  s.email         = ["charlie@charliesomerville.com"]
  s.homepage      = "http://github.com/charliesome/termular"
  s.summary       = "Simple terminal grapher with vim-like keybindings"
  s.description   = "Termular Grapher is a simple graphing program that's capable of cartesian and polar graphs"
  s.require_path  = "lib"
  s.files         = Dir["{bin,lib}/**/*"]
  s.executables   = ["termular"]
  
  s.add_dependency "ncurses-ruby"
  s.add_dependency "paint"
end
