require 'mkmf'

# expand comments in image_science_ext.c.in and generate image_science_ext.c.
# creates constant definitions (rb_define_const)
def expand_constants

  File.open("conftest.c", "w") { |f| f.puts "#include <FreeImage.h>" }
  cpp = cpp_command('')
  system "#{cpp} > confout"

  constants = {}
  headers = []

  config = File.readlines("confout")
  config.each do |include|
    next unless include.match(/"(.*?FreeImage.h)"/)
    filename = include.split('"')[1]
    headers << filename
  end
  
  headers.uniq!

  # add typedef constants
  config.each do |define|
    next unless define.match(/^\s*(\w+)\s*=\s*\d/)  # typedef
    name = $1
    next unless name.match(/^(FIT|FICC|FIC|FIF|FILTER)_/)
    constants[$1] ||= []
    constants[$1] << [name]
  end

  if RUBY_VERSION >= "1.9"
    raw_headers = headers.collect { |i| File.read(i, :encoding => "ISO-8859-1") }.join
  else
    raw_headers = headers.collect { |i| File.read(i) }.join
  end
  
  # add #defined constants (load/save flags)
  constants['FLAG'] ||= []
  flag_defines = raw_headers.scan(/(flag constants\s*---.*?)^\/\//m)
  flag_defines.each do |flag_data|
    flag_data[0].split(/\n/).each do |define|
      next unless define.match(/^\#define\s*(\w+)\s(.*?(\/\/.+)$)?/)  # #define
      constants['FLAG'] << [$1, $3]
    end
  end

  File.unlink("confout")

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
        const_list.each do |c, comment|
          if comment
            comment.sub!('//', '')
            comment.sub!(/[\r\n]+$/, '')
            comment.gsub!(/:/, '-')  # colons break rdoc..
            comment.strip!
            newf.puts %Q{  /* #{comment} */}
          end
          newf.puts %Q{  rb_define_const(#{klass_name}, "#{c}", INT2FIX(#{c}));}
        end
      else
        newf.puts l
      end
    end
  end

end

dir_config('freeimage', %W{/opt/local /usr/local /usr})

ok = have_header('FreeImage.h') &&
  have_library('stdc++') && # sometimes required on OSX
  have_library('freeimage', 'FreeImage_Load')

if(ok)
  have_func('FreeImage_Rotate')
  have_func('FreeImage_RotateClassic')
  expand_constants
  create_makefile("image_science_ext")
end
