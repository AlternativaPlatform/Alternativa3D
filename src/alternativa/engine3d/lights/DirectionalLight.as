/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.lights {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;

	use namespace alternativa3d;

	/**
	 * A directional light source illuminates all objects equally from a given direction,
	 * like an area light of infinite size and infinite distance from the scene;
	 * there is shading, but cannot be any distance falloff.
	 *
	 * This description taken from http://en.wikipedia.org/wiki/Shading#Directional_lighting
	 *
	 * Lightning direction defines by z-axis of  DirectionalLight.
	 * You can use lookAt() to make DirectionalLight point at given coordinates.
	 */
	public class DirectionalLight extends Light3D {

		/**
		 * Creates a new instance.
		 * @param color Color of light source.
		 */
		public function DirectionalLight(color:uint) {
			this.type = DIRECTIONAL;
			this.color = color;
		}

		/**
		 * Sets direction of DirectionalLight to given coordinates.
		 */
		public function lookAt(x:Number, y:Number, z:Number):void {
			var dx:Number = x - this.x;
			var dy:Number = y - this.y;
			var dz:Number = z - this.z;
			rotationX = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy)) - Math.PI/2;
			rotationY = 0;
			rotationZ = -Math.atan2(dx, dy);
		}
		
		/**
		 * Does not do anything.
		 */
		override public function calculateBoundBox():void {
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:DirectionalLight = new DirectionalLight(color);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
