# -*- ruby -*-

##
# we are using the hotelicopter_gemcutter hoe plugin to publish to gemcutter
# so we want to make sure we disable rubyforge and the regular gemcutter
#

require 'rubygems'
require 'hoe'

Hoe.plugin :doofus, :git, :inline, :telicopter

Hoe.plugins.delete :rubyforge
Hoe.plugins.delete :gemcutter

Hoe.spec 'image_science' do

  developer "jim nist", "jim@hotelicopter.com"

  extra_deps << %w(hoe >=2.5.0)
  extra_deps << %w(gemcutter >=0.3.0)
  extra_dev_deps << %w(hoe-doofus >=1.0.0)
  extra_dev_deps << %w(hoe-git >=1.3.0)
  
  clean_globs << 'blah*png' << 'images/*_thumb.*'

  email_to << 'jim@hotelicopter.com'

  # this can be set in ~/.hoerc or overridden here
  prefix < 'g1nn13-'
end

# vim: syntax=Ruby
