/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.shadows.Shadow;

	use namespace alternativa3d;

	/**
	 * Base class for light sources. Light sources are involved in the hierarchy of 3d objects,
	 * have transformation and bounding boxes (<code>BoundBox</code>).
	 * Light source influences on objects, boundboxes of which  intersect with boundbox of the given light source.
	 *
	 * Light3D does not meant for instantiating, use subclasses instead.
	 *
	 * @see alternativa.engine3d.core.BoundBox
	 */
	public class Light3D extends Object3D {

		/**
		 * @private
		 */
		alternativa3d static const AMBIENT:int = 1;
		/**
		 * @private
		 */
		alternativa3d static const DIRECTIONAL:int = 2;
		/**
		 * @private
		 */
		alternativa3d static const OMNI:int = 3;
		/**
		 * @private
		 */
		alternativa3d static const SPOT:int = 4;
		/**
		 * @private
		 */
		alternativa3d static const SHADOW_BIT:int = 0x100;

		/**
		 * @private
		 */
		alternativa3d var type:int = 0;

		/**
		 * @private
		 */
		alternativa3d var _shadow:Shadow;

		/**
		 * Color of the light.
		 */
		public var color:uint;

		/**
		 * Intensity.
		 */
		public var intensity:Number = 1;

		/**
		 * @private 
		 */
		alternativa3d var lightToObjectTransform:Transform3D = new Transform3D();

		/**
		 * @private 
		 */
		alternativa3d var lightID:String;
		/**
		 * @private 
		 */
		alternativa3d var red:Number;
		/**
		 * @private 
		 */
		alternativa3d var green:Number;
		/**
		 * @private 
		 */
		alternativa3d var blue:Number;

		/**
		 * @private
		 */
		private static var lastLightNumber:uint = 0;
		/**
		 * @private
		 */
		public function Light3D() {
			lightID = "l" + lastLightNumber.toString(16);
			name = "L" + (lastLightNumber++).toString();
		}

		/**
		 * @private 
		 */
		override alternativa3d function calculateVisibility(camera:Camera3D):void {
			if (intensity != 0 && color > 0) {
				camera.lights[camera.lightsLength] = this;
				camera.lightsLength++;
			}
		}
		
		/**
		 * @private
		 * Check if given object placed in field of influence of the light.
		 * @param targetObject  Object for checking.
		 * @return True
		 */
		alternativa3d function checkBound(targetObject:Object3D):Boolean {
			// this check is implemented in subclasses
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Light3D = new Light3D();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Light3D = source as Light3D;
			color = src.color;
			intensity = src.intensity;
		}

		public function get shadow():Shadow {
			return _shadow;
		}

		/**
		 * @private
		 */
		public function set shadow(value:Shadow):void {
			if (_shadow != null) _shadow._light = null;
			_shadow = value;
			if (value != null) value._light = this;
			type = (value != null) ? type | SHADOW_BIT : type & ~SHADOW_BIT;
		}
	}
}
