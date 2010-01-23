# -*- ruby -*-

##
# we are using the hotelicopter_gemcutter hoe plugin to publish to gemcutter
# so we want to make sure we disable rubyforge and the regular gemcutter
#

require 'rubygems'
require 'hoe'

Hoe.plugin :git
Hoe.plugin :inline
Hoe.plugin :telicopter   # includes email and hotelicopter_gemcutter

Hoe.plugins.delete :rubyforge
Hoe.plugins.delete :gemcutter

Hoe.spec 'image_science' do

  developer "jim nist", "jim@hotelicopter.com"

  clean_globs << 'blah*png' << 'images/*_thumb.*'
end

# vim: syntax=Ruby
