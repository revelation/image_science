require File.dirname(__FILE__) + '/../ext/image_science_ext'

class ImageScience

  VERSION = "1.1.1"

  ##
  # Returns the type of the image.

  def self.image_type(path)
    file_types = %W{BMP ICO JPEG JNG KOALA IFF MNG PBM PBMRAW PCD PCX PGM
                    PGMRAW PNG PPM PPMRAW RAS TARGA TIFF WBMP PSD CUT XBM
                    XPM DDS GIF HDR FAXG3 SGI EXR J2K JP2}
    type = file_type(path)
    file_types[type]
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

  ##
  # Creates a proportional thumbnail of the image scaled so its longest
  # edge is resized to +size+ and yields the new image.

  def thumbnail(size) # :yields: image
    w, h = width, height
    scale = size.to_f / (w > h ? w : h)

    self.resize((w * scale).to_i, (h * scale).to_i) do |image|
      yield image
    end
  end

  ##
  # Creates a square thumbnail of the image cropping the longest edge
  # to match the shortest edge, resizes to +size+, and yields the new
  # image.

  def cropped_thumbnail(size) # :yields: image
    w, h = width, height
    l, t, r, b, half = 0, 0, w, h, (w - h).abs / 2

    l, r = half, half + h if w > h
    t, b = half, half + w if h > w

    with_crop(l, t, r, b) do |img|
      img.thumbnail(size) do |thumb|
        yield thumb
      end
    end
  end

end
