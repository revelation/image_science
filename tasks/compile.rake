EXT_DIR = File.dirname(__FILE__) + "/../ext"

# for development
desc "compile the extension"
task :compile do
  Dir.chdir(EXT_DIR)
  system("/usr/bin/env ruby extconf.rb")
  system("make")
end
