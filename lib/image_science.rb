require File.dirname(__FILE__) + '/../ext/image_science_ext'

class ImageScience

  VERSION = "1.1.1"

  ##
  # Returns the type of the image as a string.

  def self.image_type(path)
    fif_to_string(file_type(path))
  end

  ##
  # Returns the type of the image as a string.

  def image_type
    ImageScience.fif_to_string(@file_type)
  end

  ##
  # Returns the colorspace of the image as a string

  def colorspace
    case colortype
      when 0 then depth == 1 ? 'InvertedMonochrome' : 'InvertedGrayscale'
      when 1 then depth == 1 ? 'Monochrome' : 'Grayscale'
      when 2 then 'RGB'
      when 3 then 'Indexed'
      when 4 then 'RGBA'
      when 5 then 'CMYK'
    end
  end
  
  def colourspace # :nodoc:
    colorspace
  end

  ##
  # call-seq:
  #   thumbnail(size)
  #   thumbnail(size) { |image| ... }
  # 
  # Creates a proportional thumbnail of the image scaled so its
  # longest edge is resized to +size+.  If a block is given, yields
  # the new image, else returns true on success.

  def thumbnail(size)
    w, h = width, height
    scale = size.to_f / (w > h ? w : h)
    w = (w * scale).to_i
    h = (h * scale).to_i

    if block_given?
      self.resize(w, h) do |image|
        yield image
      end
    else
      self.resize(w, h)
    end
  end

  ##
  # call-seq:
  #   cropped_thumbnail(size)
  #   cropped_thumbnail(size) { |image| ... }
  #
  # Creates a square thumbnail of the image cropping the longest edge
  # to match the shortest edge, resizes to +size+.  If a block is given,
  # yields the new image, else returns true on success.

  def cropped_thumbnail(size) # :yields: image
    w, h = width, height
    l, t, r, b, half = 0, 0, w, h, (w - h).abs / 2

    l, r = half, half + h if w > h
    t, b = half, half + w if h > w

    if block_given?
      with_crop(l, t, r, b) do |img|
        img.thumbnail(size) do |thumb|
          yield thumb
        end
      end
    else
      crop(l, t, r, b) && thumbnail(size)
    end
  end

  private

  def self.fif_to_string(fif)
    file_types = %W{BMP ICO JPEG JNG KOALA IFF MNG PBM PBMRAW PCD PCX PGM
                    PGMRAW PNG PPM PPMRAW RAS TARGA TIFF WBMP PSD CUT XBM
                    XPM DDS GIF HDR FAXG3 SGI EXR J2K JP2}
    file_types[fif]
  end

end
