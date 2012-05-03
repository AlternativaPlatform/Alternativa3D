/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;

	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * Class stores object's bounding box object's local space. Generally, position of child objects isn't considered at BoundBox calculation.
	 * Ray intersection always made  boundBox check at first, but it's possible to check on crossing  boundBox  only.
	 *
	 */
	public class BoundBox {
		/**
		 * Left face.
		 */
		public var minX:Number = 1e+22;
		/**
		 * Back face.
		 */
		public var minY:Number = 1e+22;
		/**
		 *  Bottom face.
		 */
		public var minZ:Number = 1e+22;
		/**
		 *   Right face.
		 */
		public var maxX:Number = -1e+22;
		/**
		 *  Ftont face.
		 */
		public var maxY:Number = -1e+22;
		/**
		 *  Top face.
		 */
		public var maxZ:Number = -1e+22;


		/**
		 * Resets all bounds values to its initial state.
		 */
		public function reset():void {
			minX = 1e+22;
			minY = 1e+22;
			minZ = 1e+22;
			maxX = -1e+22;
			maxY = -1e+22;
			maxZ = -1e+22;
		}

		/**
		 * @private
		 */
		alternativa3d function checkFrustumCulling(frustum:CullingPlane, culling:int):int {
			var side:int = 1;
			for (var plane:CullingPlane = frustum; plane != null; plane = plane.next) {
				if (culling & side) {
					if (plane.x >= 0)
						if (plane.y >= 0)
							if (plane.z >= 0) {
								if (maxX*plane.x + maxY*plane.y + maxZ*plane.z <= plane.offset) return -1;
								if (minX*plane.x + minY*plane.y + minZ*plane.z > plane.offset) culling &= (63 & ~side);
							} else {
								if (maxX*plane.x + maxY*plane.y + minZ*plane.z <= plane.offset) return -1;
								if (minX*plane.x + minY*plane.y + maxZ*plane.z > plane.offset) culling &= (63 & ~side);
							}
						else
							if (plane.z >= 0) {
								if (maxX*plane.x + minY*plane.y + maxZ*plane.z <= plane.offset) return -1;
								if (minX*plane.x + maxY*plane.y + minZ*plane.z > plane.offset) culling &= (63 & ~side);
							} else {
								if (maxX*plane.x + minY*plane.y + minZ*plane.z <= plane.offset) return -1;
								if (minX*plane.x + maxY*plane.y + maxZ*plane.z > plane.offset) culling &= (63 & ~side);
							}
					else if (plane.y >= 0)
						if (plane.z >= 0) {
							if (minX*plane.x + maxY*plane.y + maxZ*plane.z <= plane.offset) return -1;
							if (maxX*plane.x + minY*plane.y + minZ*plane.z > plane.offset) culling &= (63 & ~side);
						} else {
							if (minX*plane.x + maxY*plane.y + minZ*plane.z <= plane.offset) return -1;
							if (maxX*plane.x + minY*plane.y + maxZ*plane.z > plane.offset) culling &= (63 & ~side);
						}
					else if (plane.z >= 0) {
						if (minX*plane.x + minY*plane.y + maxZ*plane.z <= plane.offset) return -1;
						if (maxX*plane.x + maxY*plane.y + minZ*plane.z > plane.offset) culling &= (63 & ~side);
					} else {
						if (minX*plane.x + minY*plane.y + minZ*plane.z <= plane.offset) return -1;
						if (maxX*plane.x + maxY*plane.y + maxZ*plane.z > plane.offset) culling &= (63 & ~side);
					}
				}
				side <<= 1;
			}
			return culling;
		}

		/**
		 * @private
		 */
		alternativa3d function checkOcclusion(occluders:Vector.<Occluder>, occludersLength:int, transform:Transform3D):Boolean {
			var ax:Number = transform.a*minX + transform.b*minY + transform.c*minZ + transform.d;
			var ay:Number = transform.e*minX + transform.f*minY + transform.g*minZ + transform.h;
			var az:Number = transform.i*minX + transform.j*minY + transform.k*minZ + transform.l;
			var bx:Number = transform.a*maxX + transform.b*minY + transform.c*minZ + transform.d;
			var by:Number = transform.e*maxX + transform.f*minY + transform.g*minZ + transform.h;
			var bz:Number = transform.i*maxX + transform.j*minY + transform.k*minZ + transform.l;
			var cx:Number = transform.a*minX + transform.b*maxY + transform.c*minZ + transform.d;
			var cy:Number = transform.e*minX + transform.f*maxY + transform.g*minZ + transform.h;
			var cz:Number = transform.i*minX + transform.j*maxY + transform.k*minZ + transform.l;
			var dx:Number = transform.a*maxX + transform.b*maxY + transform.c*minZ + transform.d;
			var dy:Number = transform.e*maxX + transform.f*maxY + transform.g*minZ + transform.h;
			var dz:Number = transform.i*maxX + transform.j*maxY + transform.k*minZ + transform.l;
			var ex:Number = transform.a*minX + transform.b*minY + transform.c*maxZ + transform.d;
			var ey:Number = transform.e*minX + transform.f*minY + transform.g*maxZ + transform.h;
			var ez:Number = transform.i*minX + transform.j*minY + transform.k*maxZ + transform.l;
			var fx:Number = transform.a*maxX + transform.b*minY + transform.c*maxZ + transform.d;
			var fy:Number = transform.e*maxX + transform.f*minY + transform.g*maxZ + transform.h;
			var fz:Number = transform.i*maxX + transform.j*minY + transform.k*maxZ + transform.l;
			var gx:Number = transform.a*minX + transform.b*maxY + transform.c*maxZ + transform.d;
			var gy:Number = transform.e*minX + transform.f*maxY + transform.g*maxZ + transform.h;
			var gz:Number = transform.i*minX + transform.j*maxY + transform.k*maxZ + transform.l;
			var hx:Number = transform.a*maxX + transform.b*maxY + transform.c*maxZ + transform.d;
			var hy:Number = transform.e*maxX + transform.f*maxY + transform.g*maxZ + transform.h;
			var hz:Number = transform.i*maxX + transform.j*maxY + transform.k*maxZ + transform.l;
			for (var i:int = 0; i < occludersLength; i++) {
				var occluder:Occluder = occluders[i];
				for (var plane:CullingPlane = occluder.planeList; plane != null; plane = plane.next) {
					if (plane.x*ax + plane.y*ay + plane.z*az > plane.offset ||
						plane.x*bx + plane.y*by + plane.z*bz > plane.offset ||
						plane.x*cx + plane.y*cy + plane.z*cz > plane.offset ||
						plane.x*dx + plane.y*dy + plane.z*dz > plane.offset ||
						plane.x*ex + plane.y*ey + plane.z*ez > plane.offset ||
						plane.x*fx + plane.y*fy + plane.z*fz > plane.offset ||
						plane.x*gx + plane.y*gy + plane.z*gz > plane.offset ||
						plane.x*hx + plane.y*hy + plane.z*hz > plane.offset) break;
				}
				if (plane == null) return true;
			}
			return false;
		}

		/**
		 * @private
		 */
		alternativa3d function checkRays(origins:Vector.<Vector3D>, directions:Vector.<Vector3D>, raysLength:int):Boolean {
			for (var i:int = 0; i < raysLength; i++) {
				var origin:Vector3D = origins[i];
				var direction:Vector3D = directions[i];
				if (origin.x >= minX && origin.x <= maxX && origin.y >= minY && origin.y <= maxY && origin.z >= minZ && origin.z <= maxZ) return true;
				if (origin.x < minX && direction.x <= 0 || origin.x > maxX && direction.x >= 0 || origin.y < minY && direction.y <= 0 || origin.y > maxY && direction.y >= 0 || origin.z < minZ && direction.z <= 0 || origin.z > maxZ && direction.z >= 0) continue;
				var a:Number;
				var b:Number;
				var c:Number;
				var d:Number;
				var threshold:Number = 0.000001;
				// Intersection of X and Y projection
				if (direction.x > threshold) {
					a = (minX - origin.x)/direction.x;
					b = (maxX - origin.x)/direction.x;
				} else if (direction.x < -threshold) {
					a = (maxX - origin.x)/direction.x;
					b = (minX - origin.x)/direction.x;
				} else {
					a = 0;
					b = 1e+22;
				}
				if (direction.y > threshold) {
					c = (minY - origin.y)/direction.y;
					d = (maxY - origin.y)/direction.y;
				} else if (direction.y < -threshold) {
					c = (maxY - origin.y)/direction.y;
					d = (minY - origin.y)/direction.y;
				} else {
					c = 0;
					d = 1e+22;
				}
				if (c >= b || d <= a) continue;
				if (c < a) {
					if (d < b) b = d;
				} else {
					a = c;
					if (d < b) b = d;
				}
				// Intersection of XY and Z projections
				if (direction.z > threshold) {
					c = (minZ - origin.z)/direction.z;
					d = (maxZ - origin.z)/direction.z;
				} else if (direction.z < -threshold) {
					c = (maxZ - origin.z)/direction.z;
					d = (minZ - origin.z)/direction.z;
				} else {
					c = 0;
					d = 1e+22;
				}
				if (c >= b || d <= a) continue;
				return true;
			}
			return false;
		}

		/**
		 * @private
		 */
		alternativa3d function checkSphere(sphere:Vector3D):Boolean {
			return sphere.x + sphere.w > minX && sphere.x - sphere.w < maxX && sphere.y + sphere.w > minY && sphere.y - sphere.w < maxY && sphere.z + sphere.w > minZ && sphere.z - sphere.w < maxZ;
		}

		/**
		 * Checks if the ray crosses the <code>BoundBox</code>.
		 *
		 * @param origin Ray origin.
		 * @param direction Ray direction.
		 * @return <code>true</code> if intersection was found and <code>false</code> otherwise.
		 */
		public function intersectRay(origin:Vector3D, direction:Vector3D):Boolean {
			if (origin.x >= minX && origin.x <= maxX && origin.y >= minY && origin.y <= maxY && origin.z >= minZ && origin.z <= maxZ) return true;
			if (origin.x < minX && direction.x <= 0) return false;
			if (origin.x > maxX && direction.x >= 0) return false;
			if (origin.y < minY && direction.y <= 0) return false;
			if (origin.y > maxY && direction.y >= 0) return false;
			if (origin.z < minZ && direction.z <= 0) return false;
			if (origin.z > maxZ && direction.z >= 0) return false;
			var a:Number;
			var b:Number;
			var c:Number;
			var d:Number;
			var threshold:Number = 0.000001;
			// Intersection of X and Y projection
			if (direction.x > threshold) {
				a = (minX - origin.x) / direction.x;
				b = (maxX - origin.x) / direction.x;
			} else if (direction.x < -threshold) {
				a = (maxX - origin.x) / direction.x;
				b = (minX - origin.x) / direction.x;
			} else {
				a = -1e+22;
				b = 1e+22;
			}
			if (direction.y > threshold) {
				c = (minY - origin.y) / direction.y;
				d = (maxY - origin.y) / direction.y;
			} else if (direction.y < -threshold) {
				c = (maxY - origin.y) / direction.y;
				d = (minY - origin.y) / direction.y;
			} else {
				c = -1e+22;
				d = 1e+22;
			}
			if (c >= b || d <= a) return false;
			if (c < a) {
				if (d < b) b = d;
			} else {
				a = c;
				if (d < b) b = d;
			}
			// Intersection of XY and Z projections
			if (direction.z > threshold) {
				c = (minZ - origin.z) / direction.z;
				d = (maxZ - origin.z) / direction.z;
			} else if (direction.z < -threshold) {
				c = (maxZ - origin.z) / direction.z;
				d = (minZ - origin.z) / direction.z;
			} else {
				c = -1e+22;
				d = 1e+22;
			}
			if (c >= b || d <= a) return false;
			return true;
		}

		/**
		 * Duplicates an instance of  <code>BoundBox</code>.
		 * @return  New <code>BoundBox</code> instance with same set of properties.
		 */
		public function clone():BoundBox {
			var res:BoundBox = new BoundBox();
			res.minX = minX;
			res.minY = minY;
			res.minZ = minZ;
			res.maxX = maxX;
			res.maxY = maxY;
			res.maxZ = maxZ;
			return res;
		}

		/**
		 * Returns a string representation of <code>BoundBox</code>.
		 * @return A string representation of <code>BoundBox</code>.
		 */
		public function toString():String {
			return "[BoundBox " + "X:[" + minX.toFixed(2) + ", " + maxX.toFixed(2) + "] Y:[" + minY.toFixed(2) + ", " + maxY.toFixed(2) +  "] Z:[" + minZ.toFixed(2) + ", " + maxZ.toFixed(2) + "]]";
		}

	}
}
