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
	import flash.display3D.textures.CubeTexture;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	use namespace alternativa3d;

	/**
	 * Resource of cube texture.
	 * 
	 * Allows user to upload cube texture, that consists of six <code>BitmapData</code> images to GPU.
	 * Size of texture must be power of two (e.g., 256х256, 128*512, 256* 32).
	 * @see alternativa.engine3d.resources.TextureResource
	 * @see alternativa.engine3d.resources.ATFTextureResource
	 * @see alternativa.engine3d.resources.ExternalTextureResource
	 */
	public class BitmapCubeTextureResource extends TextureResource {

		static private const filter:ConvolutionFilter = new ConvolutionFilter(2, 2, [1, 1, 1, 1], 4, 0, false, true);

		static private var temporaryBitmapData:BitmapData;
		static private const rect:Rectangle = new Rectangle();
		static private const point:Point = new Point();
		static private const matrix:Matrix = new Matrix(0.5, 0, 0, 0.5);

		/**
		 * <code>BitmapData</code>, that will be used as left face.
		 */
		public var left:BitmapData;
		/**
		 * <code>BitmapData</code>, that will be used as right face.
		 */
		public var right:BitmapData;
		/**
		 * <code>BitmapData</code>, that will be used as top face.
		 */
		public var top:BitmapData;
		/**
		 * <code>BitmapData</code>, that will be used as bottom face.
		 */
		public var bottom:BitmapData;
		/**
		 * <code>BitmapData</code>, that will be used as front face.
		 */
		public var front:BitmapData;
		/**
		 * <code>BitmapData</code>, that will be used as back face.
		 */
		public var back:BitmapData;
		/**
		 * Property, that define the choice of type of coordinate system: left-side or right-side.
		 * If axis Y is directed to up, and axis X - to front, then if you use right-side coordinate
		 * system, axis Z is directed to right. But if you use right-side coordinate system, then
		 * axis Z is directed to left.
		 */
		public var leftHanded:Boolean;

		/**
		 * Creates a new instance of BitmapCubeTextureResource.
		 * @param left  <code>BitmapData</code>, that will be used as left face.
		 * @param right <code>BitmapData</code>, that will be used as right face.
		 * @param bottom <code>BitmapData</code>, that will be used as bottom face.
		 * @param top <code>BitmapData</code>, that will be used as top face.
		 * @param back <code>BitmapData</code>, that will be used as back face.
		 * @param front <code>BitmapData</code>, that will be used as front face.
		 * @param leftHanded Property, that define the choice of type of coordinate system: left-side or right-side.
		 */
		public function BitmapCubeTextureResource(left:BitmapData, right:BitmapData, back:BitmapData, front:BitmapData, bottom:BitmapData, top:BitmapData, leftHanded:Boolean = false) {
			this.left = left;
			this.right = right;
			this.bottom = bottom;
			this.top = top;
			this.back = back;
			this.front = front;
			this.leftHanded = leftHanded;
		}

		/**
		 *  @inheritDoc
		 */
		override public function upload(context3D:Context3D):void {
			if (_texture != null) _texture.dispose();
			_texture = context3D.createCubeTexture(left.width, Context3DTextureFormat.BGRA, false);
			var cubeTexture:CubeTexture = CubeTexture(_texture);
			filter.preserveAlpha = !left.transparent;
			var bmp:BitmapData = (temporaryBitmapData != null) ? temporaryBitmapData : new BitmapData(left.width, left.height, left.transparent);

			var level:int = 0;



			var current:BitmapData;

			if (leftHanded) {
				current = left;
			} else {
				current = new BitmapData(left.width, left.height, left.transparent);
				current.draw(left, new Matrix(0, -1, -1, 0, left.width, left.height));
			}
			cubeTexture.uploadFromBitmapData(current, 1, level++);

			rect.width = left.width;
			rect.height = left.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != left) current.dispose();
				current = new BitmapData(rect.width, rect.height, left.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 1, level++);
			}

			level = 0;
			if (leftHanded) {
				current = right;
			} else {
				current = new BitmapData(right.width, right.height, right.transparent);
				current.draw(right, new Matrix(0, 1, 1, 0));
			}

			cubeTexture.uploadFromBitmapData(current, 0, level++);
			rect.width = right.width;
			rect.height = right.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != right) current.dispose();
				current = new BitmapData(rect.width, rect.height, right.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 0, level++);
			}

			level = 0;


			if (leftHanded) {
				current = back;
			} else {
				current = new BitmapData(back.width, back.height, back.transparent);
				current.draw(back, new Matrix(-1, 0, 0, 1, back.width, 0));
			}

			cubeTexture.uploadFromBitmapData(current, 3, level++);

			rect.width = back.width;
			rect.height = back.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != back) current.dispose();
				current = new BitmapData(rect.width, rect.height, back.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 3, level++);
			}

			level = 0;
			if (leftHanded) {
				current = front;
			} else {
				current = new BitmapData(front.width, front.height, front.transparent);
				current.draw(front, new Matrix(1, 0, 0, -1, 0, front.height));
			}
			cubeTexture.uploadFromBitmapData(current, 2, level++);

			rect.width = front.width;
			rect.height = front.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != front) current.dispose();
				current = new BitmapData(rect.width, rect.height, front.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 2, level++);
			}

			level = 0;
			if (leftHanded) {
				current = bottom;
			} else {
				current = new BitmapData(bottom.width, bottom.height, bottom.transparent);
				current.draw(bottom, new Matrix(-1, 0, 0, 1, bottom.width, 0));
			}
			cubeTexture.uploadFromBitmapData(current, 5, level++);

			rect.width = bottom.width;
			rect.height = bottom.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != bottom) current.dispose();
				current = new BitmapData(rect.width, rect.height, bottom.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 5, level++);
			}

			level = 0;
			if (leftHanded) {
				current = top;
			} else {
				current = new BitmapData(top.width, top.height, top.transparent);
				current.draw(top, new Matrix(1, 0, 0, -1, 0, top.height));
			}
			cubeTexture.uploadFromBitmapData(current, 4, level++);

			rect.width = top.width;
			rect.height = top.height;
			while (rect.width%2 == 0 || rect.height%2 == 0) {
				bmp.applyFilter(current, rect, point, filter);
				rect.width >>= 1;
				rect.height >>= 1;
				if (rect.width == 0) rect.width = 1;
				if (rect.height == 0) rect.height = 1;
				if (current != top) current.dispose();
				current = new BitmapData(rect.width, rect.height, top.transparent, 0);
				current.draw(bmp, matrix, null, null, null, false);
				cubeTexture.uploadFromBitmapData(current, 4, level++);
			}
			if (temporaryBitmapData == null) bmp.dispose();
		}

	}
}
