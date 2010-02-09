require File.dirname(__FILE__) + '/../lib/image_science'

include ImageScience::ColorChannels
include ImageScience::ImageFilters
include ImageScience::ImageFormats

describe ImageScience do

  FILE_TYPES = %W{png jpg gif bmp tif xpm}

  before(:each) do
    @path = 'spec/fixtures'
    @h = @w = 50
  end

  after(:each) do
    FILE_TYPES.each do |ext|
      File.unlink tmp_image_path(ext) if File.exist? tmp_image_path(ext)
    end
  end

  describe "get_version" do
    it "should return the image science version" do
      ImageScience.get_version.should_not be_nil
    end
  end
  
  FILE_TYPES.each do |ext|

    describe "#{ext}" do

      describe "with_image" do
        it "should raise an error when a file does not exist" do
          lambda {
            ImageScience.with_image(image_path(ext) + "nope") {}
          }.should raise_error
        end

        it "should fetch image dimensions" do
          ImageScience.with_image image_path(ext) do |img|
            img.should be_kind_of(ImageScience)
            img.height.should == @h
            img.width.should == @w
          end
        end
      end

      describe "with_image_from_memory" do
        it "should raise an error when an empty string is given" do
          lambda {
            ImageScience.with_image_from_memory("") {}
          }.should raise_error
        end
      end

      describe "with_image_from_memory" do
        it "should fetch image dimensions" do
          data = File.new(image_path(ext)).binmode.read
          ImageScience.with_image_from_memory data do |img|
            img.should be_kind_of(ImageScience)
            img.height.should == @h
            img.width.should == @w
          end
        end
      end

      describe "save" do
        it "should save a new copy of an image" do
          ImageScience.with_image image_path(ext) do |img|
            img.save(tmp_image_path(ext)).should be_true
          end
          File.exists?(tmp_image_path(ext)).should be_true
          
          ImageScience.with_image tmp_image_path(ext) do |img|
            img.should be_kind_of(ImageScience)
            img.height.should == @h
            img.width.should == @w
          end
        end
      end

      describe "resize" do
    
        it "should resize an image" do
          ImageScience.with_image image_path(ext) do |img|
            img.resize(25, 25) do |thumb|
              thumb.save(tmp_image_path(ext)).should be_true
            end
          end

          File.exists?(tmp_image_path(ext)).should be_true

          ImageScience.with_image tmp_image_path(ext) do |img|
            img.should be_kind_of(ImageScience)
            img.height.should == 25
            img.width.should == 25
          end
        end
      
        it "should resize an image given floating point dimensions" do
          ImageScience.with_image image_path(ext) do |img|
            img.resize(25.2, 25.7) do |thumb|
              thumb.save(tmp_image_path(ext)).should be_true
            end
          end

          File.exists?(tmp_image_path(ext)).should be_true
        
          ImageScience.with_image tmp_image_path(ext) do |img|
            img.should be_kind_of(ImageScience)
            img.height.should == 25
            img.width.should == 25
          end
        end
      
        # do not accept negative or zero values for width/height
        it "should raise an error if given invalid width or height" do
          [ [0, 25], [25, 0], [-25, 25], [25, -25] ].each do |width, height|
            lambda {
              ImageScience.with_image image_path(ext) do |img|
                img.resize(width, height) do |thumb|
                  thumb.save(tmp_image_path(ext))
                end
              end
            }.should raise_error
            
            File.exists?(tmp_image_path(ext)).should be_false
          end
        end

        it "should resize the image in-place if no block given" do
          ImageScience.with_image image_path(ext) do |img|
            img.resize(20, 20).should be_true
            img.width.should == 20
            img.height.should == 20
          end
        end

        it "should resize the image with the given filter" do
          ImageScience.with_image image_path(ext) do |img|
            img.resize(20, 20, FILTER_BILINEAR).should be_true
            img.width.should == 20
            img.height.should == 20
          end
        end
        
      end

      describe "buffer" do
        it "should return image data" do
          ImageScience.with_image image_path(ext) do |img|
            expected = File.size(image_path(ext))
            tolerance = expected * 0.05

            data = img.buffer
            data.should_not be_nil
            #data.length.should be_close(expected, tolerance)
          end
        end

        it "should yield image data" do
          ImageScience.with_image image_path(ext) do |img|
            expected = File.size(image_path(ext))
            tolerance = expected * 0.05

            img.buffer do |data|
              data.should_not be_nil
              #data.length.should be_close(expected, tolerance)
            end
          end
        end

        it "should return image data in the given format" do
          ImageScience.with_image image_path(ext) do |img|
            [FIF_BMP, FIF_GIF, FIF_JPEG, FIF_PNG].each do |target_format|
              data = img.buffer(target_format)
              data.should_not be_nil
            end
          end
        end

        # TODO: convert to use constants
        it "should accept save flags" do
          ImageScience.with_image image_path(ext) do |img|
            jpg_large = img.buffer(FIF_JPEG, 0x80)  # jpeg quality superb
            jpg_small = img.buffer(FIF_JPEG, 0x08)  # jpeg quality bad
            jpg_small.length.should < jpg_large.length
          end
        end

      end

      describe "fit_within" do

        it "should resize image to fit within given dimensions (yield)" do
          # 50 x 50 image -> shrink to 20, 50 -> 20, 20
          ImageScience.with_image image_path(ext) do |img|
            img.fit_within(20, 50) do |thumb|
              thumb.width.should == 20
              thumb.height.should == 20
            end
          end
        end

        it "should resize image to fit within given dimensions (inline)" do
          # 50 x 50 image -> shrink to 20, 50 -> 20, 20
          ImageScience.with_image image_path(ext) do |img|
            img.fit_within(20, 50)
            img.width.should == 20
            img.height.should == 20
          end

          # 100 x 50 image -> shrink to 50, 100 -> 50, 25
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.fit_within(50, 100)
            img.width.should == 50
            img.height.should == 25
          end

          # 100 x 50 image -> shrink to 150, 25 -> 50, 25
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.fit_within(150, 25)
            img.width.should == 50
            img.height.should == 25
          end
        end

      end
      
      describe "get_pixel_color" do
        it "should get pixel color" do
          expected = {
            :jpg => [[62, 134, 122], [0, 14, 7]],
            :png => [[62, 134, 121], [1, 2, 2]],
            :gif => [[59, 135, 119], [0, 2, 0]],
            :bmp => [[62, 134, 121], [1, 2, 2]],
            :tif => [[62, 134, 121], [1, 2, 2]],
            :xpm => [[255, 255, 255], [0, 0, 0]]
          }

          ImageScience.with_image image_path(ext) do |img|
            rgb = img.get_pixel_color(10,7)
            rgb.should_not be_nil
            rgb.should == expected[ext.to_sym][0]
          
            rgb = img.get_pixel_color(24,0)
            rgb.should_not be_nil
            rgb.should == expected[ext.to_sym][1]
          end
        end
      end
      
      describe "thumbnail" do
        # Note: pix2 is 100x50
        it "should create a proportional thumbnail" do
          thumbnail_created = false
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.thumbnail(30) do |thumb|
              thumb.should_not be_nil
              thumb.width.should  == 30
              thumb.height.should == thumb.width / 2 # half of width
              thumbnail_created = true
            end
          end
          thumbnail_created.should be_true
        end

        it "should create a proportional thumbnail in-place if no block given" do
          thumbnail_created = false
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.thumbnail(30)
            img.width.should  == 30
            img.height.should == img.width / 2 # half of width
            thumbnail_created = true
          end
          thumbnail_created.should be_true
        end
      end
      
      describe "cropped_thumbnail" do
        # Note: pix2 is 100x50
        it "should create a square thumbnail" do
          thumbnail_created = false
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.cropped_thumbnail(30) do |thumb|
              thumb.should_not be_nil
              thumb.width.should == 30
              thumb.height.should == 30   # same as width
              thumbnail_created = true
            end
          end
          thumbnail_created.should be_true
        end

        it "should create a square thumbnail in-place if no block given" do
          thumbnail_created = false
          ImageScience.with_image image_path(ext, "pix2") do |img|
            img.cropped_thumbnail(30)
            img.width.should == 30
            img.height.should == 30   # same as width
            thumbnail_created = true
          end
          thumbnail_created.should be_true
        end
      end

      describe "crop" do
        it "should crop the image in-place if no block given" do
          ImageScience.with_image image_path(ext) do |img|
            img.crop(0, 0, 25, 20).should be_true
            img.width.should == 25
            img.height.should == 20
          end
        end
      end

      # image_type calls ImageScience.file_type, converts to string.
      # allow calling as a class or instance method
      describe "image_type" do
        expected = {
          'gif' => 'GIF',
          'jpg' => 'JPEG',
          'png' => 'PNG',
          'bmp' => 'BMP',
          'tif' => 'TIFF',
          'xpm' => 'XPM'
        }
        it "should return the image type (class method)" do
          ImageScience.image_type(image_path(ext)).should == expected[ext]
        end

        it "should return the image type (instance method)" do
          ImageScience.with_image image_path(ext) do |img|
            img.image_type.should == expected[ext]
          end
        end
      end

      # colorspace calls img.colortype & img.depth, converts to string
      describe "colorspace" do
        it "should return the color space" do
          expected = {
            'gif' => 'Indexed',
            'jpg' => 'RGB',
            'png' => 'RGB',
            'bmp' => 'RGB',
            'tif' => 'RGB',
            'xpm' => 'Indexed'
          }
          ImageScience.with_image image_path(ext) do |img|
            img.colorspace.should == expected[ext]
          end
        end
      end

      describe "depth" do
        it "should return the BPP of the image" do
          expected = {
            'gif' => 8,
            'jpg' => 24,
            'png' => 24,
            'bmp' => 24,
            'tif' => 24,
            'xpm' => 8
          }
          ImageScience.with_image image_path(ext) do |img|
            img.depth.should == expected[ext]
          end
        end
      end

      describe "adjust_gamma" do
        it "should perform gamma correction" do
          ImageScience.with_image image_path(ext) do |img|
            # darken image
            img.adjust_gamma(0.5).should be_true
          end
        end
      end

      describe "adjust_brightness" do
        it "should adjust brightness" do
          ImageScience.with_image image_path(ext) do |img|
            # 50% brighter
            img.adjust_brightness(50).should be_true
          end
        end
      end

      describe "adjust_contrast" do
        it "should adjust contrast" do
          ImageScience.with_image image_path(ext) do |img|
            # 50% less contrast
            img.adjust_contrast(-50).should be_true
          end
        end
      end

      describe "invert" do
        it "should invert pixel data" do
          ImageScience.with_image image_path(ext) do |img|
            # 50% less contrast
            img.invert.should be_true
          end
        end
      end

      describe "histogram" do
        it "should compute the image histogram" do
          ImageScience.with_image image_path(ext) do |img|
            h = img.histogram
            h.should be_kind_of(Array)
            h.length.should == 256
          end
        end

        it "should compute the image histogram for a given channel" do
          ImageScience.with_image image_path(ext) do |img|
            [FICC_RED, FICC_GREEN, FICC_BLUE].each do |channel|
              h = img.histogram(channel)
              h.should be_kind_of(Array)
              h.length.should == 256
            end
          end
        end
      end

      describe "rotate" do

        # test Rotate
        it "should rotate the image 90 degrees" do
          ImageScience.with_image image_path(ext, "pix2") do |img|
            w, h = img.width, img.height
            img.rotate(90)
            # width & height reversed
            img.width.should == h
            img.height.should == w
          end
        end

        # test RotateEx
        it "should rotate the image 120 degrees about an origin" do
          ImageScience.with_image image_path(ext, "pix2") do |img|
            w, h = img.width, img.height
            img.rotate(120, 0, 0, 20, 20)
            # width & height unchanged
            img.width.should == w
            img.height.should == h
          end          
        end

      end

      describe "flip_horizontal" do
        it "should flip the image horizontally" do
          ImageScience.with_image image_path(ext) do |img|          
            img.flip_horizontal.should be_true
          end
        end
      end

      describe "flip_vertical" do
        it "should flip the image vertically" do
          ImageScience.with_image image_path(ext) do |img|          
            img.flip_vertical.should be_true
          end
        end
      end

    end
  end

  private

  def image_path(extension, basename = "pix")
    raise "extension required" unless extension
    File.join(@path, "#{basename}.#{extension}")
  end

  def tmp_image_path(extension, basename = "pix")
    raise "extension required" unless extension
    File.join(@path, "#{basename}-tmp.#{extension}")
  end

end

