/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;

	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * @private 
	 */
	public class TransformKey extends Keyframe {

		/**
		 * @private 
		 */
		alternativa3d var x:Number = 0;
		/**
		 * @private 
		 */
		alternativa3d var y:Number = 0;
		/**
		 * @private 
		 */
		alternativa3d var z:Number = 0;
		/**
		 * @private 
		 */
		alternativa3d var rotation:Vector3D = new Vector3D(0, 0, 0, 1);
		/**
		 * @private 
		 */
		alternativa3d var scaleX:Number = 1;
		/**
		 * @private 
		 */
		alternativa3d var scaleY:Number = 1;
		/**
		 * @private 
		 */
		alternativa3d var scaleZ:Number = 1;

		/**
		 * @private 
		 */
		alternativa3d var next:TransformKey;

		/**
		 * Creates a TransformKey object.
		 */
		public function TransformKey() {
		}

		/**
		 * @inheritDoc 
		 */
		override public function get value():Object {
			var m:Matrix3D = new Matrix3D();
			m.recompose(Vector.<Vector3D>([new Vector3D(x, y, z), rotation, new Vector3D(scaleX, scaleY, scaleZ)]), Orientation3D.QUATERNION);
			return m;
		}

		/**
		 * @inheritDoc 
		 */
		override public function set value(v:Object):void {
			var m:Matrix3D = Matrix3D(v);
			var components:Vector.<Vector3D> = m.decompose(Orientation3D.QUATERNION);
			x = components[0].x;
			y = components[0].y;
			z = components[0].z;
			rotation = components[1];
			scaleX = components[2].x;
			scaleY = components[2].y;
			scaleZ = components[2].z;
		}

		/**
		 * Sets interpolated value.
		 */
		public function interpolate(a:TransformKey, b:TransformKey, c:Number):void {
			var c2:Number = 1 - c;
			x = c2*a.x + c*b.x;
			y = c2*a.y + c*b.y;
			z = c2*a.z + c*b.z;
			slerp(a.rotation, b.rotation, c, rotation);
			scaleX = c2*a.scaleX + c*b.scaleX;
			scaleY = c2*a.scaleY + c*b.scaleY;
			scaleZ = c2*a.scaleZ + c*b.scaleZ;
		}
		
		/**
		 * @private
		 *
		 * Performs spherical interpolation between two given quaternions by min distance
		 *
		 * @param a first quaternion.
		 * @param b second quaternion.
		 * @param t interpolation parameter, usually  defines in [0, 1] range.
		 * @return this
		 */
		private function slerp(a:Vector3D, b:Vector3D, t:Number, result:Vector3D):void {
			var flip:Number = 1;
			// Since one orientation represents by two values q and -q, we should invert the sign of one of quaternions
			// in case of negative value of the dot product. Otherwise the interpolation results by max distance.
			var cosine:Number = a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
			if (cosine < 0)	{ 
				cosine = -cosine; 
				flip = -1; 
			}
			if ((1 - cosine) < 0.001) {
				// Linear interpolation used near zero
				var k1:Number = 1 - t;
				var k2:Number = t*flip;
				result.w = a.w*k1 + b.w*k2;
				result.x = a.x*k1 + b.x*k2;
				result.y = a.y*k1 + b.y*k2;
				result.z = a.z*k1 + b.z*k2;
				var d:Number = result.w*result.w + result.x*result.x + result.y*result.y + result.z*result.z;
				if (d == 0) {
					result.w = 1;
				} else {
					result.scaleBy(1/Math.sqrt(d));
				}
			} else {
				var theta:Number = Math.acos(cosine); 
				var sine:Number = Math.sin(theta); 
				var beta:Number = Math.sin((1 - t)*theta)/sine; 
				var alpha:Number = Math.sin(t*theta)/sine*flip;
				result.w = a.w*beta + b.w*alpha;
				result.x = a.x*beta + b.x*alpha;
				result.y = a.y*beta + b.y*alpha;
				result.z = a.z*beta + b.z*alpha;
			}
		}

		/**
		 * @inheritDoc 
		 */
		override alternativa3d function get nextKeyFrame():Keyframe {
			return next;
		}
		
		/**
		 * @inheritDoc 
		 */
		override alternativa3d function set nextKeyFrame(value:Keyframe):void {
			next = TransformKey(value);
		}

	}
}
