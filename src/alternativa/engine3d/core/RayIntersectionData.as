/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.objects.Surface;

	import flash.geom.Point;
	import flash.geom.Vector3D;

	/**
	 * A result of searching for intersection of an Object3D and a ray with intersectRay() method of Object3D.
	 *
	 * @see Object3D#intersectRay()
	 */
	public class RayIntersectionData {

		/**
		 *  First object intersected by the ray.
		 */
		public var object:Object3D;

		/**
		 * The point of intersection il local coordinates of object.
		 */
		public var point:Vector3D;

		/**
		 * Surface of <code>object</code> on which intersection occurred.
		 */
		public var surface:Surface;

		/**
		 * Distance from ray's origin to intersection point expressed in length of <code>localDirection</code> vector.
		 */
		public var time:Number;

		/**
		 * Texture coordinates of intersection point.
		 */
		public var uv:Point;

		/**
		 * Returns the string representation of the specified object.
		 * @return The string representation of the specified object.
		 */
		public function toString():String {
			return "[RayIntersectionData " + object + ", " + point + ", " + uv + ", " + time + "]";
		}

	}
}
