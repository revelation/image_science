/*
 * Provides a clean and simple API to generate thumbnails using
 * FreeImage as the underlying mechanism.
 *
 * For more information or if you have build issues with FreeImage, see
 * http://seattlerb.rubyforge.org/ImageScience.html
 *
 */

#include "ruby.h"
#include "FreeImage.h"

#define GET_BITMAP(name) Data_Get_Struct(self, FIBITMAP, (name)); if (!(name)) rb_raise(rb_eTypeError, "Bitmap has already been freed");

VALUE isc;  /* ImageScience class */

static VALUE unload(VALUE self) {
  FIBITMAP *bitmap;
  GET_BITMAP(bitmap);

  FreeImage_Unload(bitmap);
  DATA_PTR(self) = NULL;
  return Qnil;
}

static VALUE wrap_and_yield(FIBITMAP *image, VALUE self, FREE_IMAGE_FORMAT fif) {
  unsigned int self_is_class = rb_type(self) == T_CLASS;
  VALUE klass = self_is_class ? self         : CLASS_OF(self);
  VALUE type  = self_is_class ? INT2FIX(fif) : rb_iv_get(self, "@file_type");
  VALUE obj = Data_Wrap_Struct(klass, NULL, NULL, image);
  rb_iv_set(obj, "@file_type", type);
  return rb_ensure(rb_yield, obj, unload, obj);
}

static void copy_icc_profile(VALUE self, FIBITMAP *from, FIBITMAP *to) {
  FREE_IMAGE_FORMAT fif = FIX2INT(rb_iv_get(self, "@file_type"));
  if (fif != FIF_PNG && FreeImage_FIFSupportsICCProfiles(fif)) {
    FIICCPROFILE *profile = FreeImage_GetICCProfile(from);
    if (profile && profile->data) {
      FreeImage_CreateICCProfile(to, profile->data, profile->size);
    }
  }
}

static void FreeImageErrorHandler(FREE_IMAGE_FORMAT fif, const char *message) {
  rb_raise(rb_eRuntimeError,
	   "FreeImage exception for type %s: %s",
	   (fif == FIF_UNKNOWN) ? "???" : FreeImage_GetFormatFromFIF(fif),
	   message);
}

/****** Class methods ******/

/*
 * The top-level image loader opens +path+ and then yields the image.
 */
static VALUE with_image(VALUE klass, VALUE filename) {
  FREE_IMAGE_FORMAT fif = FIF_UNKNOWN;
  int flags;
  char *input = RSTRING(filename)->ptr;

  fif = FreeImage_GetFileType(input, 0);
  if (fif == FIF_UNKNOWN) fif = FreeImage_GetFIFFromFilename(input);
  if ((fif != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(fif)) {
    FIBITMAP *bitmap;
    VALUE result = Qnil;
    flags = fif == FIF_JPEG ? JPEG_ACCURATE : 0;
    bitmap = FreeImage_Load(fif, input, flags);
    if (bitmap) {
      FITAG *tagValue = NULL;
      FreeImage_GetMetadata(FIMD_EXIF_MAIN, bitmap, "Orientation", &tagValue); 
      switch (tagValue == NULL ? 0 : *((short *) FreeImage_GetTagValue(tagValue))) {
      case 6:
	bitmap = FreeImage_RotateClassic(bitmap, 270);
	break;
      case 3:
	bitmap = FreeImage_RotateClassic(bitmap, 180);
	break;
      case 8:
	bitmap = FreeImage_RotateClassic(bitmap, 90);
	break;
      default:
	break;
      }

      result = wrap_and_yield(bitmap, klass, fif);
    }
    return result;
  }
  rb_raise(rb_eTypeError, "Unknown file format");
}

/*
 * The top-level image loader, opens an image from the string +data+
 * and then yields the image.
 */
static VALUE with_image_from_memory(VALUE klass, VALUE image_data) {
  FREE_IMAGE_FORMAT fif = FIF_UNKNOWN;

  Check_Type(image_data, T_STRING);
  BYTE *image_data_ptr    = (BYTE*)RSTRING_PTR(image_data);
  DWORD image_data_length = RSTRING_LEN(image_data);
  FIMEMORY *stream = FreeImage_OpenMemory(image_data_ptr, image_data_length);

  if (NULL == stream) {
    rb_raise(rb_eTypeError, "Unable to open image_data");
  }

  fif = FreeImage_GetFileTypeFromMemory(stream, 0);
  if ((fif == FIF_UNKNOWN) || !FreeImage_FIFSupportsReading(fif)) {
    rb_raise(rb_eTypeError, "Unknown file format");
  }

  FIBITMAP *bitmap = NULL;
  VALUE result = Qnil;
  int flags = fif == FIF_JPEG ? JPEG_ACCURATE : 0;
  bitmap = FreeImage_LoadFromMemory(fif, stream, flags);
  FreeImage_CloseMemory(stream);
  if (bitmap) {
    result = wrap_and_yield(bitmap, klass, fif);
  }
  return result;
}

/*
 * get FreeImage library version
 */
static VALUE get_version(VALUE self) {
  const char *version = FreeImage_GetVersion();
  return rb_str_new2(version);
}

static VALUE file_type(VALUE self, VALUE filename) {
  char * input = RSTRING(filename)->ptr;
  FREE_IMAGE_FORMAT fif = FIF_UNKNOWN; 

  fif = FreeImage_GetFileType(input, 0); 
  if (fif == FIF_UNKNOWN) fif = FreeImage_GetFIFFromFilename(input); 
  return (fif == FIF_UNKNOWN) ? Qnil : INT2FIX(fif);
}

/*********** Instance methods ***********/

/*
 * Crops an image to +left+, +top+, +right+, and +bottom+ and then
 * yields the new image.
 */
static VALUE with_crop(VALUE self, VALUE lv, VALUE tv, VALUE rv, VALUE bv) {
  FIBITMAP *copy, *bitmap;
  VALUE result = Qnil;
  GET_BITMAP(bitmap);

  copy = FreeImage_Copy(bitmap, NUM2INT(lv), NUM2INT(tv),
			NUM2INT(rv), NUM2INT(bv));
  if (copy) {
    copy_icc_profile(self, bitmap, copy);
    result = wrap_and_yield(copy, self, 0);
  }
  return result;
}

/*
 * Returns the height of the image, in pixels.
 */
static VALUE height(VALUE self) {
  FIBITMAP *bitmap;
  GET_BITMAP(bitmap);
  int height = FreeImage_GetHeight(bitmap);
  return INT2FIX(height);
}

/*
 * Returns the width of the image, in pixels.
 */
static VALUE width(VALUE self) {
  FIBITMAP *bitmap;
  GET_BITMAP(bitmap);
  int width = FreeImage_GetWidth(bitmap);
  return INT2FIX(width);
}

/*
 * Returns an array representing the color of the given pixel (blue,green,red)
 */
static VALUE get_pixel_color(VALUE self, VALUE xval, VALUE yval) {
  FIBITMAP *bitmap;
  RGBQUAD rgb;
  RGBQUAD *pal;
  BYTE rgb_index;
  GET_BITMAP(bitmap);
  FREE_IMAGE_COLOR_TYPE ctype;
  VALUE out_ary = rb_ary_new2(3);
  int x = NUM2INT(xval);
  int y = NUM2INT(yval);
  int success = 0;

  ctype = FreeImage_GetColorType(bitmap);

  if(ctype == FIC_PALETTE) {
    if(FreeImage_GetPixelIndex(bitmap, x, y, &rgb_index)) {
      pal = FreeImage_GetPalette(bitmap);
      if(pal) {
	rgb = pal[rgb_index];
	success = 1;
      }
    }
  } else {
    success = FreeImage_GetPixelColor(bitmap, x, y, &rgb);
  }

  if(success) {
    rb_ary_store(out_ary, 0, INT2FIX(rgb.rgbRed));
    rb_ary_store(out_ary, 1, INT2FIX(rgb.rgbGreen));
    rb_ary_store(out_ary, 2, INT2FIX(rgb.rgbBlue));
  }

  return out_ary;
}

/***
 * Resizes the image to +width+ and +height+ using a cubic-bspline
 * filter and yields the new image.
 */
static VALUE resize(VALUE self, VALUE width, VALUE height) {
  FIBITMAP *bitmap, *image;
  int w = NUM2INT(width);
  int h = NUM2INT(height);

  if (w <= 0) rb_raise(rb_eArgError, "Width <= 0");
  if (h <= 0) rb_raise(rb_eArgError, "Height <= 0");
  GET_BITMAP(bitmap);
  image = FreeImage_Rescale(bitmap, w, h, FILTER_CATMULLROM);
  if (image) {
    copy_icc_profile(self, bitmap, image);
    return wrap_and_yield(image, self, 0);
  }
  return Qnil;
}

/*
 * Saves the image out to +path+. Changing the file extension will
 * convert the file type to the appropriate format.
 */
static VALUE save(VALUE self, VALUE filename) {
  int flags;
  char * output = RSTRING(filename)->ptr;
  FIBITMAP *bitmap;
  FREE_IMAGE_FORMAT fif = FreeImage_GetFIFFromFilename(output);
  if (fif == FIF_UNKNOWN) fif = FIX2INT(rb_iv_get(self, "@file_type"));
  if ((fif != FIF_UNKNOWN) && FreeImage_FIFSupportsWriting(fif)) {
    GET_BITMAP(bitmap);
    flags = fif == FIF_JPEG ? JPEG_QUALITYSUPERB : 0;
    BOOL result = 0, unload = 0;
    
    if (fif == FIF_PNG) FreeImage_DestroyICCProfile(bitmap);
    if (fif == FIF_JPEG && FreeImage_GetBPP(bitmap) != 24) {
      bitmap = FreeImage_ConvertTo24Bits(bitmap);
      unload = 1; // sue me
    }
    result = FreeImage_Save(fif, bitmap, output, flags);
    
    if (unload) FreeImage_Unload(bitmap);

    return result ? Qtrue : Qfalse;
  }
  rb_raise(rb_eTypeError, "Unknown file format");
}

static VALUE colortype(VALUE self) {
  FIBITMAP *bitmap;
  GET_BITMAP(bitmap);

  return INT2FIX(FreeImage_GetColorType(bitmap));
}

static VALUE depth(VALUE self) {
  FIBITMAP *bitmap;
  GET_BITMAP(bitmap);

  return INT2FIX(FreeImage_GetBPP(bitmap));
}

/* -- initialiser ---- */

void Init_image_science_ext(void)
{
  isc = rb_define_class("ImageScience", rb_cObject);
  rb_define_singleton_method(isc, "with_image", with_image, 1);
  rb_define_singleton_method(isc, "with_image_from_memory",
			     with_image_from_memory, 1);
  rb_define_singleton_method(isc, "get_version", get_version, 0);
  rb_define_singleton_method(isc, "file_type", file_type, 1);

  //rb_define_method(isc, "initialize", t_init, 0);
  rb_define_method(isc, "width", width, 0);
  rb_define_method(isc, "height", height, 0);
  rb_define_method(isc, "resize", resize, 2);
  rb_define_method(isc, "save", save, 1);
  rb_define_method(isc, "with_crop", with_crop, 4);
  rb_define_method(isc, "get_pixel_color", get_pixel_color, 2);
  rb_define_method(isc, "colortype", colortype, 0);
  rb_define_method(isc, "depth", depth, 0);

  FreeImage_SetOutputMessage(FreeImageErrorHandler);
}
