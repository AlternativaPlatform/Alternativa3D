/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3D;

	use namespace alternativa3d;

	/**
	 * Base class for GPU data. GPU data can be divided in 2 groups: geometry data and texture data.
	 * The type of resources for uploading geometry data in GPU is Geometry.
	 * <code>BitmapTextureResource</code> allows to use textures of  type is <code>BitmapData</code> and <code>ATFTextureResource</code> deals with <code>ByteArray</code> consists of ATF data,
	 * <code>ExternalTextureResource</code> should be used with <code>TexturesLoader</code>, which loads textures from files and automatically uploads in GPU.
	 *
	*
 	* @see alternativa.engine3d.resources.Geometry
	* @see alternativa.engine3d.resources.TextureResource
	* @see alternativa.engine3d.resources.BitmapTextureResource
	* @see alternativa.engine3d.resources.ATFTextureResource
	* @see alternativa.engine3d.resources.ExternalTextureResource
	*/
	public class Resource {
		
		/**
		 * Defines if this resource is uploaded inti a <code>Context3D</code>.
		 */
		public function get isUploaded():Boolean {
			return false;
		}
		
		/**
		 * Uploads resource into given <code>Context3D</code>.
		 *  
		 * @param context3D <code>Context3D</code> to which resource will uploaded.
		 */
		public function upload(context3D:Context3D):void {
			throw new Error("Cannot upload without data");
		}
		
		/**
		 * Removes this resource from <code>Context3D</code> to which it was uploaded.
		 */
		public function dispose():void {
		}

	}
}
