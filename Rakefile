require 'rubygems'
require 'hoe'

Hoe.spec 'sobakasu-image_science' do
  @version = "1.1.0" # keep this up to date with image_science.c VERSION
  developer 'Andrew Williams', 'sobakasu@gmail.com'
  clean_globs << 'blah*png' << 'images/*_thumb.*'
  spec_extras[:extensions] = "ext/extconf.rb"
end
