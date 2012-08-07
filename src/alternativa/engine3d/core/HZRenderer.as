package alternativa.engine3d.core {

	import flash.display.BitmapData;

	public class HZRenderer {

		public var bitmapData:BitmapData;

		public var width:int;
		public var height:int;

		public var data:Vector.<Number>;

		public function HZRenderer(width:int, height:int) {
			this.width = width;
			this.height = height;

			data = new Vector.<Number>(width*height, true);
			bitmapData = new BitmapData(width, height, false, 0);

			// draw occluders (boxes)
			// test by occluded image
		}

		public function clear():void {
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

		public function checkOcclusion(x:Number, y:Number, width:Number, height:Number):Boolean {
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
