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
		static private const point:Point = new Point();
		/**
		 * BitmapData
		 */
		public var data:BitmapData;

        /**
         * Uploads textures from <code>BitmapData</code> to GPU.
         */
		public function BitmapTextureResource(data:BitmapData) {
			this.data = data;
		}

		/**
		 * @inheritDoc 
		 */
		override public function upload(context3D:Context3D):void {
			if (_texture != null) _texture.dispose();
			if (data != null) {
				_texture = context3D.createTexture(data.width, data.height, Context3DTextureFormat.BGRA, false);
				filter.preserveAlpha = !data.transparent;
				Texture(_texture).uploadFromBitmapData(data, 0);
				var level:int = 1;
				var bmp:BitmapData = new BitmapData(data.width, data.height, data.transparent);
				var current:BitmapData = data;
				rect.width = data.width;
				rect.height = data.height;
				while (rect.width%2 == 0 || rect.height%2 == 0) {
					bmp.applyFilter(current, rect, point, filter);
					rect.width >>= 1;
					rect.height >>= 1;
					if (rect.width == 0) rect.width = 1;
					if (rect.height == 0) rect.height = 1;
					if (current != data) current.dispose();
					current = new BitmapData(rect.width, rect.height, data.transparent, 0);
					current.draw(bmp, matrix, null, null, null, false);
					Texture(_texture).uploadFromBitmapData(current, level++);
				}
				if (current != data) current.dispose();
				bmp.dispose();
			} else {
				_texture = null;
				throw new Error("Cannot upload without data");
			}
		}

		/**
		 * @private
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
