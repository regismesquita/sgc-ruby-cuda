require 'mkmf'
COMPILE_CXX = '/opt/local/bin/g++ $(INCFLAGS) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG) $@ -c $<'
COMPILE_C = '/opt/local/bin/gcc $(INCFLAGS) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG) $@ -c $<'
CXX_EXT = %w[cu cc cxx cpp]
if have_library("cuda") 
  create_makefile("rubycu")
else
  raise "Impossible to find cuda library"
end
