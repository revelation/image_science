# -*- ruby -*-

##
# we are using the Hoe::Telicopter hoe plugin to add some email functionality
#

require 'rubygems'
require 'hoe'

Hoe.plugins.delete :rubyforge

Hoe.plugin :doofus, :git, :inline, :telicopter

Hoe.spec 'g1nn13-image_science' do

  developer "jim nist", "jim@hotelicopter.com"

  extra_deps << %w(hoe >=2.5.0)
  extra_deps << %w(gemcutter >=0.3.0)
  extra_dev_deps << %w(hoe-doofus >=1.0.0)
  extra_dev_deps << %w(hoe-git >=1.3.0)
  
  clean_globs << 'blah*png' << 'images/*_thumb.*'

#  email_to << 'cthulu@hotelicopter.com'

end

# vim: syntax=Ruby
