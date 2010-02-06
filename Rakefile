require 'rubygems'
gem 'hoe'
require 'hoe'

Hoe.spec 'sobakasu-image_science' do
  developer('Ryan Davis', 'ryand-ruby@zenspider.com')
  developer('Andrew Williams', 'sobakasu@gmail.com')
  clean_globs << 'blah*png' << 'images/*_thumb.*'
  spec_extras[:extensions] = "ext/extconf.rb"
end

Dir['tasks/**/*.rake'].each { |t| load t }
