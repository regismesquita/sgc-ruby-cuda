require 'mkmf'
if have_library("cuda") 
  create_makefile("rubycu")
else
  raise "Impossible to find cuda library"
end
