package alternativa.engine3d.resources {
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import alternativa.engine3d.alternativa3d;
	import flash.geom.Matrix;
	use namespace alternativa3d;
	/**
	 * Use this when you need to upload the texture frequently.
	 * Does not create any mip levels other than 0.
	 * Size of texture must be power of two (e.g., 256х256, 128*512, 256* 32).
	 * @see alternativa.engine3d.resources.TextureResource
	 * @see alternativa.engine3d.resources.BitmapTextureResource
	 */
	public class BitmapTextureResourceLite extends TextureResource {
		/**
		 * BitmapData object.
		 */
		public var data:BitmapData;
		
		/**
		 * Uploads textures from <code>BitmapData</code> to GPU.
		 */
		public function BitmapTextureResourceLite (data:BitmapData) {
			this.data = data;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function upload(context3D:Context3D):void {
			if (_texture != null) _texture.dispose();
			if (data != null) {
				_texture = context3D.createTexture (data.width, data.height, Context3DTextureFormat.BGRA, false);
				(_texture as Texture).uploadFromBitmapData (data, 0);
			} else {
				_texture = null;
				throw new Error("Cannot upload without data");
			}
		}
		
		/**
		 * Reuploads the data to the same texture.
		 */
		public function reupload ():void {
			if (_texture && data) {
				(_texture as Texture).uploadFromBitmapData (data, 0);
			}
		}
	}
}