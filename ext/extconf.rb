require 'mkmf'

dir_config('freeimage')

have_header('FreeImage.h') &&
  have_library('freeimage', 'FreeImage_Load') &&
  create_makefile("image_science")
