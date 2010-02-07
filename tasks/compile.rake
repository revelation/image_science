EXT_DIR = File.dirname(__FILE__) + "/../ext"

# for development
desc "compile the extension"
task :compile do
  Dir.chdir(EXT_DIR)
  #require 'extconf'  # creates a Makefile with the wrong target...
  system("ruby extconf.rb")
  system("make")
  Dir.chdir("..")
end
