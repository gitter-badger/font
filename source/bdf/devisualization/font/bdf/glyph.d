﻿/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Devisualization (Richard Andrew Cattermole)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module devisualization.font.bdf.glyph;
import devisualization.font;
import devisualization.font.bdf.font;
import devisualization.image;

class BDFGlyph : Glyph {
	private {
		BDFFont font;
		ushort originalWidth;
		ushort originalEncodedValue;
		
		uint[] lines;
		uint width_;
		uint height_;
		Color_RGBA brush;
		Color_RGBA brushBKGD;
		
		uint offsetX;
		uint offsetY;
		bool isBold;
		bool isItalic;
	}
	
	this(BDFFont font, ushort encoded, ushort width, uint[] lines) {
		this.font = font;
		this.originalEncodedValue = encoded;
		this.originalWidth = width;
		this.lines = lines;
		
		width_ = lines.length * 2;
		height_ = lines.length * 2;

		
		brush = new Color_RGBA(0, 0, 0, 1f);
		brushBKGD = new Color_RGBA(0, 0, 0, 0f);
	}
	
	GlyphModifiers modifiers() {
		class GlyphMod : GlyphModifiers {
			void italize() { // makes it italisized
				isItalic = true;
			}
			
			void bold() { // makes it boldenized
				isBold = true;
			}
			
			void width(uint width) { // scales
				width_ = width;
			}
			
			void kerning(ushort amount) { // adds width but doesn't scale
				width_ += amount;
				offsetX = amount;
			}
			
			void height(uint amount) { // scales
				height_ = amount;
			}
			
			void lineHeight(uint amount) { // adds height to glyph but doesn't scale
				height_ += amount;
				offsetY = amount;
			}
			
			void color(Color_RGBA primary, Color_RGBA background = null) {
				brush = primary;
				brushBKGD = background;
			}
			
			void reset() { // reload image for glyph
				offsetX = 0;
				offsetY = 0;
				
				isBold = false;
				isItalic = false;
				
				width_ = 8;
				height_ = 8;
				
				brush = new Color_RGBA(0, 0, 0, 1f);
				brushBKGD = new Color_RGBA(0, 0, 0, 0f);
			}
		}
		
		return new GlyphMod;
	}
	
	Image output() {
		import std.math : ceil;
		import devisualization.image.mutable;
		uint useWidth = cast(uint)ceil(width_ * (isBold ? 1.2f : 1f));
		
		MutableImage image = new MutableImage(useWidth, height_);
		auto i_ = image.rgba;

		size_t perLineAddOnX = cast(size_t)((height_ - offsetY));
		size_t count_X = cast(size_t)ceil((useWidth - offsetX) / originalWidth + 0f);
		size_t count_Y = cast(size_t)ceil((height_ - offsetY) / lines.length + 0f);
		
		size_t yy = offsetY;
		foreach(k, line; lines) {
			size_t xx;
			
			for (size_t i = 0; i < originalWidth; i++) {
				Color_RGBA brushToUse = (line & (1 << (originalWidth - (i + 1)))) ? brush : brushBKGD;
				
				size_t y = yy;
				foreach(_; 0 .. count_Y) {
					size_t x = xx;
					foreach(__; 0 .. count_X) {
						if (x >= useWidth || y >= height_)
							break;
						
						i_[i_.indexFromXY(x, y)] = brushToUse;
						
						x++;
					}
					
					y++;
				}
				
				xx += count_X;
			}
			
			yy += count_Y;
		}
		
		// strip out whitespace pixels
		size_t bkgdLast;
		size_t theY;
		bool stillBKGD = true;
		bool hitLast;
		
		image.applyByY((Color_RGBA color, size_t x, size_t y) {
			if (color == brush) {
				stillBKGD = false;
			}
			
			if (theY != y) {
				if (stillBKGD) {
					bkgdLast++;
				} else {
					bkgdLast = 0;
				}
				
				theY = y;
				stillBKGD = true;
				hitLast = true;
			} else {
				hitLast = false;
			}
		});
		
		if (!hitLast) {
			if (stillBKGD)
				bkgdLast++;
			else {
				bkgdLast = 0;
			}
		}

		if (bkgdLast > 0)
			image = image.resizeCrop(image.width - bkgdLast, image.height);

		if (isItalic) {
			image = image.skewHorizontal(23, brushBKGD);
		}

		return image;
	}
}