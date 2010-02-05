$:.unshift(File.dirname(__FILE__) + '/..')

require 'ext/image_science'

describe ImageScience do

  FILE_TYPES = %W{png jpg gif}

  before(:each) do
    @path = 'spec/fixtures'
    @h = @w = 50
  end

  after(:each) do
    FILE_TYPES.each do |ext|
      File.unlink tmp_image_path(ext) if File.exist? tmp_image_path(ext)
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
        
      end
      
      describe "get_pixel_color" do
        it "should get pixel color" do
          expected = {
            :jpg => [[61, 134, 123], [0, 18, 13]],
            :png => [[62, 134, 121], [1, 2, 2]],
            :gif => [[59, 135, 119], [0, 2, 0]]
          }

          ImageScience.with_image image_path(ext) do |img|
            rgb = img.get_pixel_color(10,7)
            rgb.should == expected[ext.to_sym][0]
          
            rgb = img.get_pixel_color(24,0)
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

