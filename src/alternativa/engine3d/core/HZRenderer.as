package alternativa.engine3d.core {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public class HZRenderer {

		public var projectionX:Number;
		public var projectionY:Number;

		public var smWidth:int;
		public var smHeight:int;

		public var data:Vector.<HZPixel>;

		public var debugCanvas:Sprite = new Sprite();
		private var bitmapData:BitmapData;

		private var debugCheckedQuads:Array = [];
		private var checkedQuadsGfx:Graphics;
		private var numDebugCheckedQuads:int;

		public function HZRenderer(width:int, height:int) {
			// TODO: work by highresolution grid
			this.smWidth = width >> 1;
			this.smHeight = height >> 1;

			data = new Vector.<HZPixel>(smWidth*smHeight, true);
			for (var i:int = 0; i < data.length; i++) {
				data[i] = new HZPixel();
			}
			bitmapData = new BitmapData(width, height, false, 0);

			debugCanvas.mouseEnabled = false;
			debugCanvas.mouseChildren = false;
			debugCanvas.tabEnabled = false;
			debugCanvas.tabChildren = false;
			debugCanvas.addChild(new Bitmap(bitmapData));
			var checkedQuads:Shape = new Shape();
			checkedQuads.scaleX = 2;
			checkedQuads.scaleY = 2;
			checkedQuadsGfx = checkedQuads.graphics;
			debugCanvas.addChild(checkedQuads);
		}

		public function configure(viewWidth:Number, viewHeight:Number, focalLength:Number):void {
			this.projectionX = focalLength*smWidth/viewWidth;
			this.projectionY = focalLength*smHeight/viewHeight;
			for (var i:int = 0; i < data.length; i++) {
				data[i].filled = 0;
			}
			numDebugCheckedQuads = 0;
		}

/*
		public function drawTriangle(triangle:HZTriangle):void {
			// Bounding rectangle
			var minx:int = int(Math.min(triangle.x1, triangle.x2, triangle.x3));
			var maxx:int = int(Math.max(triangle.x1, triangle.x2, triangle.x3));
			var miny:int = int(Math.min(triangle.y1, triangle.y2, triangle.y3));
			var maxy:int = int(Math.max(triangle.y1, triangle.y2, triangle.y3));

			// Deltas
			var dx12:Number = triangle.x1 - triangle.x2;
			var dx23:Number = triangle.x2 - triangle.x3;
			var dx31:Number = triangle.x3 - triangle.x1;

			var dy12:Number = triangle.y1 - triangle.y2;
			var dy23:Number = triangle.y2 - triangle.y3;
			var dy31:Number = triangle.y3 - triangle.y1;

			// Constant part of half-edge functions
			var cy1:Number = dy12*triangle.x1 - dx12*triangle.y1 + dx12*miny - dy12*minx;
			var cy2:Number = dy23*triangle.x2 - dx23*triangle.y2 + dx23*miny - dy23*minx;
			var cy3:Number = dy31*triangle.x3 - dx31*triangle.y3 + dx31*miny - dy31*minx;

			// Scan through bounding rectangle
			for (var y:int = miny; y < maxy; y++) {
				// Start value for horizontal scan
				var cx1:Number = cy1;
				var cx2:Number = cy2;
				var cx3:Number = cy3;
				for (var x:int = minx; x < maxx; x++) {
					if(cx1 > 0 && cx2 > 0 && cx3 > 0) {
						data[int(y*smWidth + x)] = 1;
					}
					cx1 -= dy12;
					cx2 -= dy23;
					cx3 -= dy31;
				}
				cy1 += dx12;
				cy2 += dx23;
				cy3 += dx31;
			}
		}
*/

		public function checkBoundBox(bb:BoundBox, transform:Transform3D):Boolean {
			var ax:Number = transform.a*bb.minX + transform.b*bb.minY + transform.c*bb.minZ + transform.d;
			var ay:Number = transform.e*bb.minX + transform.f*bb.minY + transform.g*bb.minZ + transform.h;
			var az:Number = transform.i*bb.minX + transform.j*bb.minY + transform.k*bb.minZ + transform.l;
			var bx:Number = transform.a*bb.maxX + transform.b*bb.minY + transform.c*bb.minZ + transform.d;
			var by:Number = transform.e*bb.maxX + transform.f*bb.minY + transform.g*bb.minZ + transform.h;
			var bz:Number = transform.i*bb.maxX + transform.j*bb.minY + transform.k*bb.minZ + transform.l;
			var cx:Number = transform.a*bb.minX + transform.b*bb.maxY + transform.c*bb.minZ + transform.d;
			var cy:Number = transform.e*bb.minX + transform.f*bb.maxY + transform.g*bb.minZ + transform.h;
			var cz:Number = transform.i*bb.minX + transform.j*bb.maxY + transform.k*bb.minZ + transform.l;
			var dx:Number = transform.a*bb.maxX + transform.b*bb.maxY + transform.c*bb.minZ + transform.d;
			var dy:Number = transform.e*bb.maxX + transform.f*bb.maxY + transform.g*bb.minZ + transform.h;
			var dz:Number = transform.i*bb.maxX + transform.j*bb.maxY + transform.k*bb.minZ + transform.l;
			var ex:Number = transform.a*bb.minX + transform.b*bb.minY + transform.c*bb.maxZ + transform.d;
			var ey:Number = transform.e*bb.minX + transform.f*bb.minY + transform.g*bb.maxZ + transform.h;
			var ez:Number = transform.i*bb.minX + transform.j*bb.minY + transform.k*bb.maxZ + transform.l;
			var fx:Number = transform.a*bb.maxX + transform.b*bb.minY + transform.c*bb.maxZ + transform.d;
			var fy:Number = transform.e*bb.maxX + transform.f*bb.minY + transform.g*bb.maxZ + transform.h;
			var fz:Number = transform.i*bb.maxX + transform.j*bb.minY + transform.k*bb.maxZ + transform.l;
			var gx:Number = transform.a*bb.minX + transform.b*bb.maxY + transform.c*bb.maxZ + transform.d;
			var gy:Number = transform.e*bb.minX + transform.f*bb.maxY + transform.g*bb.maxZ + transform.h;
			var gz:Number = transform.i*bb.minX + transform.j*bb.maxY + transform.k*bb.maxZ + transform.l;
			var hx:Number = transform.a*bb.maxX + transform.b*bb.maxY + transform.c*bb.maxZ + transform.d;
			var hy:Number = transform.e*bb.maxX + transform.f*bb.maxY + transform.g*bb.maxZ + transform.h;
			var hz:Number = transform.i*bb.maxX + transform.j*bb.maxY + transform.k*bb.maxZ + transform.l;
			if (az <= 0 || bz <= 0 || cz <= 0 || dz <= 0 || ez <= 0 || fz <= 0 || gz <= 0 || hz <= 0) return false;
			// calculate min, max projected
			var x:Number, y:Number;
			var halfW:Number = 0.5*smWidth;
			var halfH:Number = 0.5*smHeight;
			var minX:Number = 10000;
			var minY:Number = 10000;
			var maxX:Number = -10000;
			var maxY:Number = -10000;
			x = projectionX*ax/az + halfW;
			y = projectionY*ay/az + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*bx/bz + halfW;
			y = projectionY*by/bz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*cx/cz + halfW;
			y = projectionY*cy/cz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*dx/dz + halfW;
			y = projectionY*dy/dz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*ex/ez + halfW;
			y = projectionY*ey/ez + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*fx/fz + halfW;
			y = projectionY*fy/fz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*gx/gz + halfW;
			y = projectionY*gy/gz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			x = projectionX*hx/hz + halfW;
			y = projectionY*hy/hz + halfH;
			if (x < minX) minX = x;
			if (x > maxX) maxX = x;
			if (y < minY) minY = y;
			if (y > maxY) maxY = y;
			return checkRectangle(minX, minY, maxX, maxY);
		}

		public function checkRectangle(minX:Number, minY:Number, maxX:Number, maxY:Number):Boolean {
			// Check if area of the rect is not positive
			if (maxX <= minX || maxY <= minY) return false;
			// Check if boundbox is out of the screen
			if (maxX <= 0 || minX >= smWidth) return false;
			if (maxY <= 0 || minY >= smHeight) return false;

			minX = minX <= 0 ? 0 : minX;
			minY = minY <= 0 ? 0 : minY;
			maxX = maxX > smWidth ? smWidth : maxX;
			maxY = maxY > smHeight ? smHeight : maxY;

			var index:int;
			// minXi - left bound by lowres grid
			// minYi - top bound by lowres grid
			// maxXi - right bound by lowres grid
			// maxYi - bottom bound by lowres grid
			var minXi:int = minX;
			var maxXi:int = Math.ceil(maxX);
			var minYi:int = minY;
			var maxYi:int = Math.ceil(maxY);

			if (((maxXi - minXi) <= 1) || ((maxYi - minYi) <= 1)) {
				// fast checking
				if (data[int(minYi*smWidth + minXi)].filled == 0xF) {
					return true;
				}
				// TODO: check other situations
			}

			var subMinX:Boolean = (minX - minXi) >= 0.5;
			var subMaxX:Boolean = (maxXi - maxX) >= 0.5;
			var subMinY:Boolean = (minY - minYi) >= 0.5;
			var subMaxY:Boolean = (maxYi - maxY) >= 0.5;
			if (subMinX) minXi++;
			if (subMinY) minYi++;
			if (subMaxX) maxXi--;
			if (subMaxY) maxYi--;

			// Check inner blocks
			var px:int, py:int;
			for (py = minYi; py < maxYi; py++) {
				for (px = minXi; px < maxXi; px++) {
					index = py*smWidth + px;
					if (data[index].filled < 0xF) {
						return false;
					}
				}
			}
			// Check sides subpixels
			if (subMinX) {
				for (py = minYi; py < maxYi; py++) {
					index = py*smWidth + minXi - 1;
					if ((data[index].filled & 0xA) != 0xA) return false;
				}
			}
			if (subMinY) {
				var cI:int = (minYi - 1)*smWidth;
				for (px = minXi; px < maxXi; px++) {
					index = cI + px;
					if ((data[index].filled & 0xC) != 0xC) return false;
				}
			}
			if (subMaxX) {
				for (py = minYi; py < maxYi; py++) {
					index = py*smWidth + maxXi;
					if ((data[index].filled & 0x5) != 0x5) return false;
				}
			}
			if (subMaxY) {
				for (px = minXi; px < maxXi; px++) {
					index = maxYi*smWidth + px;
					if ((data[index].filled & 0x3) != 0x3) return false;
				}
			}
			// Check corners
			if (subMinX && subMinY) {
				index = (minYi - 1)*smWidth + (minXi - 1);
				if ((data[index].filled & 0x8) != 0x8) return false;
			}
			if (subMinX && subMaxY) {
				index = maxYi*smWidth + (minXi - 1);
				if ((data[index].filled & 0x2) != 0x2) return false;
			}
			if (subMaxX && subMinY) {
				index = (minYi - 1)*smWidth + maxXi;
				if ((data[index].filled & 0x4) != 0x4) return false;
			}
			if (subMaxX && subMaxY) {
				index = maxYi*smWidth + maxXi;
				if ((data[index].filled & 0x1) != 0x1) return false;
			}
			var quad:Rectangle = debugCheckedQuads[numDebugCheckedQuads++];
			if (quad == null) {
				quad = new Rectangle();
				debugCheckedQuads[int(numDebugCheckedQuads - 1)] = quad;
			}
			quad.x = minX;
			quad.y = minY;
			quad.width = maxX - minX;
			quad.height = maxY - minY;

			return true;
		}

		public function updateDebug(width:Number, height:Number):void {
			bitmapData.fillRect(bitmapData.rect, 0x0);
			// iterate through pixels, mark subpixels
			for (var i:int = 0; i < data.length; i++) {
				var x:int = (i%smWidth) << 1;
				var y:int = (i/smWidth) << 1;
				var filled:uint = data[i].filled;
				if (filled != 0) {
					if (filled == 0xF) {
						if ((filled & 1) != 0) {
							bitmapData.setPixel32(x, y, 0xFFFFFF);
						}
						if ((filled & 2) != 0) {
							bitmapData.setPixel32(x + 1, y, 0xFFFFFF);
						}
						if ((filled & 4) != 0) {
							bitmapData.setPixel32(x, y + 1, 0xFFFFFF);
						}
						if ((filled & 8) != 0) {
							bitmapData.setPixel32(x + 1, y + 1, 0xFFFFFF);
						}
					} else {
						if ((filled & 1) != 0) {
							bitmapData.setPixel32(x, y, 0xFFFFFF);
						}
						if ((filled & 2) != 0) {
							bitmapData.setPixel32(x + 1, y, 0xFFFFFF);
						}
						if ((filled & 4) != 0) {
							bitmapData.setPixel32(x, y + 1, 0xFFFFFF);
						}
						if ((filled & 8) != 0) {
							bitmapData.setPixel32(x + 1, y + 1, 0xFFFFFF);
						}
					}
				}
			}
			debugCanvas.scaleX = width/bitmapData.width;
			debugCanvas.scaleY = height/bitmapData.height;

			checkedQuadsGfx.clear();
			for (i = 0; i < numDebugCheckedQuads; i++) {
				var quad:Rectangle = debugCheckedQuads[i];
				checkedQuadsGfx.lineStyle(0, 0xFF00);
				checkedQuadsGfx.drawRect(quad.x, quad.y, quad.width, quad.height);
			}
		}

	}
}
