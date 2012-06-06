/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.lights {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;

	use namespace alternativa3d;
	
	/**
	 * An ambient light source represents a fixed-intensity and fixed-color light source
	 * that affects all objects in the scene equally. Upon rendering, all objects in
	 * the scene are brightened with the specified intensity and color.
	 * This type of light source is mainly used to provide the scene with a basic view of the different objects in it.
	 *
	 * This description taken from http://en.wikipedia.org/wiki/Shading#Ambient_lighting
	 */
	public class AmbientLight extends Light3D {
		
		/**
		 * Creates a AmbientLight object.
		 * @param color Light color.
		 */
		public function AmbientLight(color:uint) {
			this.type = AMBIENT;
			this.color = color;
		}

		/**
		 * Does not do anything.
		 *
		 */
		override public function calculateBoundBox():void {
		}

		/**
		 * @private 
		 */
		override alternativa3d function calculateVisibility(camera:Camera3D):void {
			camera.ambient[0] += ((color >> 16) & 0xFF)*intensity/255;
			camera.ambient[1] += ((color >> 8) & 0xFF)*intensity/255;
			camera.ambient[2] += (color & 0xFF)*intensity/255;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:AmbientLight = new AmbientLight(color);
			res.clonePropertiesFrom(this);
			return res;
		}
		
	}
}
