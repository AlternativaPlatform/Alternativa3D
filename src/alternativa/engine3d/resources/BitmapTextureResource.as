/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	use namespace alternativa3d;

	/**
	 * Texture resource, that allows user to upload textures from <code>BitmapData</code> to GPU.
	 * Size of texture must be power of two (e.g., 256х256, 128*512, 256* 32).
	 * @see alternativa.engine3d.resources.TextureResource
	 * @see alternativa.engine3d.resources.ATFTextureResource
	 * @see alternativa.engine3d.resources.ExternalTextureResource
	 */
	public class BitmapTextureResource extends TextureResource {

		static private const rect:Rectangle = new Rectangle();
		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);
		static private const matrix:Matrix = new Matrix(0.5, 0, 0, 0.5);
		static private const resizeMatrix:Matrix = new Matrix(1, 0, 0, 1);
		static private const point:Point = new Point();
		/**
		 * BitmapData
		 */
		public var data:BitmapData;

		public var resizeForGPU:Boolean = false;

        /**
         * Uploads textures from <code>BitmapData</code> to GPU.
         */
		public function BitmapTextureResource(data:BitmapData, resizeForGPU:Boolean = false) {
			this.data = data;
			this.resizeForGPU = resizeForGPU;
		}

		/**
		 * @inheritDoc 
		 */
		override public function upload(context3D:Context3D):void {
			if (_texture != null) _texture.dispose();
			if (data != null) {
				var source:BitmapData = data;
				if (resizeForGPU) {
					var wLog2Num:Number = Math.log(data.width)/Math.LN2;
					var hLog2Num:Number = Math.log(data.height)/Math.LN2;
					var wLog2:int = Math.ceil(wLog2Num);
					var hLog2:int = Math.ceil(hLog2Num);
					if (wLog2 != wLog2Num || hLog2 != hLog2Num || wLog2 > 11 || hLog2 > 11) {
						// Resize bitmap
						wLog2 = (wLog2 > 11) ? 11 : wLog2;
						hLog2 = (hLog2 > 11) ? 11 : hLog2;
						source = new BitmapData(1 << wLog2, 1 << hLog2, data.transparent, 0x0);
						resizeMatrix.a = (1 << wLog2)/data.width;
						resizeMatrix.d = (1 << hLog2)/data.height;
						source.draw(data, resizeMatrix, null, null, null, true);
					}
				}
				_texture = context3D.createTexture(source.width, source.height, Context3DTextureFormat.BGRA, false);
				Texture(_texture).uploadFromBitmapData(source, 0);
				filter.preserveAlpha = !source.transparent;
				var level:int = 1;
				var bmp:BitmapData = new BitmapData(source.width, source.height, source.transparent);
				var current:BitmapData = source;
				rect.width = source.width;
				rect.height = source.height;
				while (rect.width%2 == 0 || rect.height%2 == 0) {
					bmp.applyFilter(current, rect, point, filter);
					rect.width >>= 1;
					rect.height >>= 1;
					if (rect.width == 0) rect.width = 1;
					if (rect.height == 0) rect.height = 1;
					if (current != source) current.dispose();
					current = new BitmapData(rect.width, rect.height, source.transparent, 0);
					current.draw(bmp, matrix, null, null, null, false);
					Texture(_texture).uploadFromBitmapData(current, level++);
				}
				if (current != source) current.dispose();
				bmp.dispose();
			} else {
				_texture = null;
				throw new Error("Cannot upload without data");
			}
		}

		/**
		 * @private
		 * TODO: remove repeated method.
		 */
		alternativa3d function createMips(texture:Texture, bitmapData:BitmapData):void {
			rect.width = bitmapData.width;
			rect.height = bitmapData.height;
			var level:int = 1;
			var bmp:BitmapData = new BitmapData(rect.width, rect.height, bitmapData.transparent);
			var current:BitmapData = bitmapData;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != bitmapData) current.dispose();
				current = new BitmapData(rect.width, rect.height, bitmapData.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				texture.uploadFromBitmapData(current, level++);
			}
			if (current != bitmapData) current.dispose();
			bmp.dispose();
		}

		/**
		 * @private 
		 */
		static alternativa3d function createMips(texture:Texture, bitmapData:BitmapData):void {
			rect.width = bitmapData.width;
			rect.height = bitmapData.height;
			var level:int = 1;
			var bmp:BitmapData = new BitmapData(rect.width, rect.height, bitmapData.transparent);
			var current:BitmapData = bitmapData;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != bitmapData) current.dispose();
				current = new BitmapData(rect.width, rect.height, bitmapData.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				texture.uploadFromBitmapData(current, level++);
			}
			if (current != bitmapData) current.dispose();
			bmp.dispose();
		}

	}
}
