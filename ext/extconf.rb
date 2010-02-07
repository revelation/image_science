require 'mkmf'

# expand comments in image_science_ext.c.in and generate image_science_ext.c.
# creates constant definitions (rb_define_const)
def expand_constants

  File.open("conftest.c", "w") { |f| f.puts "#include <FreeImage.h>" }
  cpp = cpp_command('')
  system "#{cpp} > confout"

  constants = {}

  File.foreach("confout") do |includes|
    next unless includes.match(/"(.*?FreeImage.h)"/)
    system "#{cpp} > confout2"
    File.foreach("confout2") do |define|
      next unless define.match(/^\s*(\w+)\s*=\s*\d/)  # typedef
      name = $1
      next unless name.match(/^(FIT|FICC|FIC|FIF|FILTER)_/)
      constants[$1] ||= []
      constants[$1] << name
    end
  end
  File.unlink("confout", "confout2")

  constants.keys.each { |i| constants[i].uniq! }

  File.open("image_science_ext.c", "w") do |newf|
    File.foreach("image_science_ext.c.in") do |l|
      if l.match(/\/\* expand FreeImage constants\s+(\w+)\s+(\w+)\s*\*\//)
        klass_name = $1
        const_type = $2
        const_list = constants[const_type]
        unless const_list
          puts "warning: no constants found matching #{const_type}"
          next
        end
        const_list.each do |c|
          newf.puts %Q{  rb_define_const(#{klass_name}, "#{c}", INT2FIX(#{c}));}
        end
      else
        newf.puts l
      end
    end
  end

end

dir_config('freeimage')

ok = have_header('FreeImage.h') &&
  have_library('stdc++')  # sometimes required on OSX
  have_library('freeimage', 'FreeImage_Load') &&

if(ok)
  expand_constants
  create_makefile("image_science_ext")
end
