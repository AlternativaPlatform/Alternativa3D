/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.utils.ByteArray;

	use namespace alternativa3d;

	/**
	 * Allows to upload in textures of ATF format to GPU.
	 *
	 * @see alternativa.engine3d.resources.BitmapTextureResource
	 * @see alternativa.engine3d.resources.ExternalTextureResource
	 * @see alternativa.engine3d.resources.TextureResource
	 */
	public class ATFTextureResource extends TextureResource {
		/**
		 * ByteArray, that contains texture of ATF format.
		 */
		public var data:ByteArray;

		private var uploadCallback:Function = null;

		/**
		 * Create an instance of CompressedTextureResource.
		 * @param data  ByteArray, that contains ATF texture.
		 */
		public function ATFTextureResource(data:ByteArray) {
			this.data = data;
		}

		/**
		 * @inheritDoc
		 */
		override public function upload(context3D:Context3D):void {
			uploadInternal(context3D);
		}

		public function uploadAsync(context3D:Context3D, callback:Function):void {
			uploadInternal(context3D, true, callback);
		}

		private function uploadInternal(context3D:Context3D, async:Boolean = false, callback:Function = null):void {
			if (_texture != null) _texture.dispose();

			if (data != null) {
				data.position = 6;
				var type:uint = data.readByte();
				var format:String;
				switch (type & 0x7F) {
					case 0:
					case 1:
						format = Context3DTextureFormat.BGRA;
						break;
					case 2:
					case 3:
						format = Context3DTextureFormat.COMPRESSED;
						break;
					case 4:
					case 5:
						format = "compressedAlpha"; // Context3DTextureFormat.COMPRESSED_ALPHA
						break;
				}

				if ((type & ~0x7F) == 0) {
					_texture = context3D.createTexture(1 << data.readByte(), 1 << data.readByte(), format, false);
					if (async) {
						uploadCallback = callback;
						_texture.addEventListener("textureReady", onTextureReady);
					}
					Texture(_texture).uploadCompressedTextureFromByteArray(data, 0, async);

				} else {
					_texture = context3D.createCubeTexture(1 << data.readByte(), format, false);
					if (async) {
						uploadCallback = callback;
						_texture.addEventListener("textureReady", onTextureReady);
					}
					CubeTexture(_texture).uploadCompressedTextureFromByteArray(data, 0, async);
				}
			} else {
				_texture = null;
				throw new Error("Cannot upload without data");
			}
		}

		private function onTextureReady(e:Event):void {
			if (uploadCallback != null) {
				uploadCallback(this);
				uploadCallback = null;
			}
		}

	}
}
