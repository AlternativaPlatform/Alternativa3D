package alternativa.engine3d.resources {
	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.events.Event;
	import flash.utils.ByteArray;

	use namespace alternativa3d;
	/**
	 * @author Gonchar
	 */
	public class ATFCubeTextureResource extends TextureResource {
		/**
		 * <code>ByteArray</code>, that will be used as left face.
		 */
		public var data : ByteArray;

		private var uploadCallback : Function = null;

		public function ATFCubeTextureResource(data : ByteArray) {
			this.data = data;
		}

		/**
		 * @inheritDoc
		 */
		override public function upload(context3D : Context3D) : void {
			uploadInternal(context3D);
		}

		public function uploadAsync(context3D : Context3D, callback : Function) : void {
			uploadInternal(context3D, true, callback);
		}

		private function uploadInternal(context3D : Context3D, async : Boolean = false, callback : Function = null) : void {
			if (_texture != null) _texture.dispose();

			data.position = 6;
			var type : uint = data.readByte();
			var format : String;
			switch (type & 0x7F) {
				case 0:
					format = Context3DTextureFormat.BGRA;
					break;
				case 1:
					format = Context3DTextureFormat.BGRA;
					break;
				case 2:
				case 3:
					format = Context3DTextureFormat.COMPRESSED;
					break;
			}

			_texture = context3D.createCubeTexture(1 << data.readByte(), format, false);
			if (async) {
				uploadCallback = callback;
				_texture.addEventListener("textureReady", onTextureReady);
			}
			CubeTexture(_texture).uploadCompressedTextureFromByteArray(data, 0, async);
		}

		private function onTextureReady(e : Event) : void {
			if (uploadCallback != null) {
				uploadCallback(this);
				uploadCallback = null;
			}
		}
	}
}
