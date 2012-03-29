/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Resource;
	
	import flash.display3D.textures.TextureBase;

	use namespace alternativa3d;
	
	/**
	 * Base resource for texture resources, that can be uploaded into the video memory.
	 * <code>BitmapTextureResource</code> and <code>ATFTextureResource</code> allows user
	 * to upload textures  into the video memory from <code>BitmapData</code> and ATF format accordingly.
	 * <code>ExternalTextureResource</code> should be used with <code>TexturesLoader</code>,
	 * that uploads textures from files and automatically puts them into the video memory.
     * Size of texture must be power of two (e.g., 256х256, 128*512, 256* 32).
	 * @see alternativa.engine3d.resources.BitmapTextureResource
	 * @see alternativa.engine3d.resources.ATFTextureResource
	 * @see alternativa.engine3d.resources.ExternalTextureResource
	 */
	public class TextureResource extends Resource {
		
		/**
		 * @private 
		 */
		alternativa3d var _texture:TextureBase;

		/**
		 * @inheritDoc
		 */
		override public function get isUploaded():Boolean {
			return _texture != null;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void {
			if (_texture != null) {
				_texture.dispose();
				_texture = null;
			}
		}

	}
}
