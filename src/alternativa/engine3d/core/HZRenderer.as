package alternativa.engine3d.core {

	import flash.display.BitmapData;

	public class HZRenderer {

		public var bitmapData:BitmapData;

		private var projectionX:Number;
		private var projectionY:Number;

		public var width:int;
		public var height:int;

		public var data:Vector.<Number>;

		public function HZRenderer(width:int, height:int) {
			this.width = width;
			this.height = height;

			data = new Vector.<Number>(width*height, true);
			bitmapData = new BitmapData(width, height, false, 0);
		}

		public function configure(viewWidth:Number, viewHeight:Number, focalLength:Number):void {
			this.projectionX = focalLength*width/viewWidth;
			this.projectionY = focalLength*height/viewHeight;
			for (var i:int = 0; i < data.length; i++) {
				data[i] = 0;
			}
		}

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
						data[int(y*width + x)] = 1;
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

		public function checkOcclusion(bb:BoundBox, transform:Transform3D):Boolean {
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
			var halfW:Number = 0.5*width;
			var halfH:Number = 0.5*height;
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
			minX = minX <= 0 ? 0 : minX;
			minY = minY <= 0 ? 0 : minY;
			maxX = maxX > width ? width : maxX;
			maxY = maxY > height ? height : maxY;
			// check all pixels
			for (var py:int = minY; py < maxY; py++) {
				for (var px:int = minX; px < maxX; px++) {
					if (data[int(py*width + px)] == 0) {
						return false;
					}
				}
			}
			return true;
		}

		public function updateBitmapData():void {
			for (var i:int = 0; i < data.length; i++) {
				if (data[i] > 0) {
					bitmapData.setPixel32(i % width, i/width, 0xFFFFFF);
				} else {
					bitmapData.setPixel32(i % width, i/width, 0x0);
				}
			}
		}

	}
}
