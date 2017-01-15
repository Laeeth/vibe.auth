module vibeauth.challenges.imagegenerator;

import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.path;

import vibe.http.router;
import vibe.stream.memory;
import vibe.http.router;

extern(C) {
	enum MagickBooleanType { MagickFalse = 0, MagickTrue = 1 }
	enum MagickPathExtent = 4096;

	alias MagickSizeType = size_t;
	alias Image = void;
	alias ImageInfo = void;
	alias ExceptionInfo = void;

	struct MagickWand {
		size_t id;
		char[MagickPathExtent] name;
		Image *images;
		ImageInfo *image_info;
		ExceptionInfo *exception;
		MagickBooleanType insert_before;
		MagickBooleanType image_pending;
		MagickBooleanType _debug;
		size_t signature;
	}

	struct PixelWand {
		size_t id;
		char[MagickPathExtent] name;
		ExceptionInfo* exception;
		PixelInfo pixel;
		size_t count;
		MagickBooleanType _debug;
		size_t signature;
	}

	struct PixelInfo { }
	struct DrawingWand { }

	void MagickWandGenesis();
	MagickWand *NewMagickWand();
	MagickWand *DestroyMagickWand(MagickWand *wand);
	void MagickWandTerminus();

	PixelWand *NewPixelWand();
	MagickBooleanType MagickNewImage(MagickWand *wand, const size_t columns, const size_t rows, const PixelWand *background);

	MagickBooleanType MagickWriteImage(MagickWand *wand, const char *filename);

	ubyte *MagickGetImageBlob(MagickWand *wand, size_t *length);
	void MagickResetIterator(MagickWand *wand);

	void *MagickRelinquishMemory(void *resource);

	MagickBooleanType MagickSetImageFormat(MagickWand *wand, const char *format);
	MagickBooleanType MagickGetImageLength(MagickWand *wand, MagickSizeType *length);
	MagickBooleanType PixelSetColor(PixelWand *wand, const char *color);

	void DrawSetTextAntialias(DrawingWand *wand, const MagickBooleanType text_antialias);
	DrawingWand *NewDrawingWand();
	void DrawSetStrokeColor(DrawingWand *wand, const PixelWand *stroke_wand);

	void DrawAnnotation(DrawingWand *wand ,const double x, const double y, const char *text);

	MagickBooleanType MagickDrawImage(MagickWand *wand, const DrawingWand *drawing_wand);
  void DrawSetFillColor(DrawingWand *wand, const PixelWand *fill_wand);
  MagickBooleanType DrawSetFont(DrawingWand *wand, const char *font_name);
  void DrawSetFontSize(DrawingWand *wand, const double pointsize);
  MagickBooleanType MagickTrimImage(MagickWand *wand,const double fuzz);
}

struct ImageGenerator {
  private {
    MagickWand *mw;
    PixelWand *p_wand;
    DrawingWand *d_wand;
  }

  this(size_t width, size_t height) {
		MagickWandGenesis();

    mw = NewMagickWand;
    p_wand = NewPixelWand;
    d_wand = NewDrawingWand;

    PixelSetColor(p_wand, "white");
		MagickNewImage(mw, width, height, p_wand);
  }

  void setText(string text) {
		PixelSetColor(p_wand, "black");
		DrawSetFillColor(d_wand,p_wand);
		DrawSetFont(d_wand, buildNormalizedPath(getcwd, "fonts/warpstorm/WarpStorm.otf").toStringz) ;
		DrawSetFontSize(d_wand, 15);

    writeln("??", buildNormalizedPath(getcwd, "fonts/warpstorm/WarpStorm.otf"));

		// Turn antialias on - not sure this makes a difference
		DrawSetTextAntialias(d_wand, MagickBooleanType.MagickTrue);

		// Now draw the text
		DrawAnnotation(d_wand, 25, 65, text.toStringz);

		// Draw the image on to the magick_wand
		MagickDrawImage(mw, d_wand);
  }

	void flush(HTTPServerResponse res) {
		scope(exit) {
			if(mw !is null) mw = DestroyMagickWand(mw);
			MagickWandTerminus();
		}

    MagickTrimImage(mw, 0);

		MagickResetIterator(mw);
		MagickSetImageFormat(mw, "jpeg");
		MagickSizeType length;

		MagickGetImageLength(mw, &length);

		auto blob = MagickGetImageBlob(mw, &length);

		ubyte[] data = blob[0..length];
		RandomAccessStream stream = new MemoryStream(data, false, length);

		MagickRelinquishMemory(blob);

		writeln("image size: ", length, " []", blob, "]");

		res.contentType = "image/jpeg";
		res.headers["Content-Length"] = length.to!string;

		res.writeRawBody(stream, 200);
	}
}
