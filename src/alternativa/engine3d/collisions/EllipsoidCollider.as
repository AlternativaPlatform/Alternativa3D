/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.collisions {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.resources.Geometry;

	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	
	/**
	 * The class implements the algorithm of the continuous collision of an ellipsoid with the faces.
	 */
	public class EllipsoidCollider {
		
		/**
		 * Ellipsoid radius along X axis.
		 */
		public var radiusX:Number;
		
		/**
		 * Ellipsoid radius along Y axis.
		 */
		public var radiusY:Number;
		
		/**
		 * Ellipsoid radius along Z axis.
		 */
		public var radiusZ:Number;
		
		/**
		 * Geometric error. Minimum absolute difference between two values
		 * when they are considered to be different. Default value is 0.001.
		 */
		public var threshold:Number = 0.001;
		
		private var matrix:Transform3D = new Transform3D();
		private var inverseMatrix:Transform3D = new Transform3D();
		
		/**
		 * @private 
		 */
		alternativa3d var geometries:Vector.<Geometry> = new Vector.<Geometry>();
		/**
		 * @private 
		 */
		alternativa3d var transforms:Vector.<Transform3D> = new Vector.<Transform3D>();
		
		private var vertices:Vector.<Number> = new Vector.<Number>();
		private var normals:Vector.<Number> = new Vector.<Number>();
		private var indices:Vector.<int> = new Vector.<int>();
		private var numTriangles:int;
		
		private var radius:Number;
		private var src:Vector3D = new Vector3D();
		private var displ:Vector3D = new Vector3D();
		private var dest:Vector3D = new Vector3D();
		
		private var collisionPoint:Vector3D = new Vector3D();
		private var collisionPlane:Vector3D = new Vector3D();
		
		/**
		 * @private 
		 */
		alternativa3d var sphere:Vector3D = new Vector3D();
		private var cornerA:Vector3D = new Vector3D();
		private var cornerB:Vector3D = new Vector3D();
		private var cornerC:Vector3D = new Vector3D();
		private var cornerD:Vector3D = new Vector3D();
		
		/**
		 * Creates a EllipsoidCollider object.
		 *
		 *  @param radiusX Ellipsoid radius along X axis.
		 * @param radiusY Ellipsoid radius along Y axis.
		 * @param radiusZ Ellipsoid radius along Z axis.
		 */
		public function EllipsoidCollider(radiusX:Number, radiusY:Number, radiusZ:Number) {
			this.radiusX = radiusX;
			this.radiusY = radiusY;
			this.radiusZ = radiusZ;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function calculateSphere(transform:Transform3D):void {
			sphere.x = transform.d;
			sphere.y = transform.h;
			sphere.z = transform.l; 
			var sax:Number = transform.a*cornerA.x + transform.b*cornerA.y + transform.c*cornerA.z + transform.d;
			var say:Number = transform.e*cornerA.x + transform.f*cornerA.y + transform.g*cornerA.z + transform.h;
			var saz:Number = transform.i*cornerA.x + transform.j*cornerA.y + transform.k*cornerA.z + transform.l; 
			var sbx:Number = transform.a*cornerB.x + transform.b*cornerB.y + transform.c*cornerB.z + transform.d;
			var sby:Number = transform.e*cornerB.x + transform.f*cornerB.y + transform.g*cornerB.z + transform.h;
			var sbz:Number = transform.i*cornerB.x + transform.j*cornerB.y + transform.k*cornerB.z + transform.l; 
			var scx:Number = transform.a*cornerC.x + transform.b*cornerC.y + transform.c*cornerC.z + transform.d;
			var scy:Number = transform.e*cornerC.x + transform.f*cornerC.y + transform.g*cornerC.z + transform.h;
			var scz:Number = transform.i*cornerC.x + transform.j*cornerC.y + transform.k*cornerC.z + transform.l; 
			var sdx:Number = transform.a*cornerD.x + transform.b*cornerD.y + transform.c*cornerD.z + transform.d;
			var sdy:Number = transform.e*cornerD.x + transform.f*cornerD.y + transform.g*cornerD.z + transform.h;
			var sdz:Number = transform.i*cornerD.x + transform.j*cornerD.y + transform.k*cornerD.z + transform.l;
			var dx:Number = sax - sphere.x;
			var dy:Number = say - sphere.y;
			var dz:Number = saz - sphere.z;
			sphere.w = dx*dx + dy*dy + dz*dz;
			dx = sbx - sphere.x;
			dy = sby - sphere.y;
			dz = sbz - sphere.z;
			var dxyz:Number = dx*dx + dy*dy + dz*dz;
			if (dxyz > sphere.w) sphere.w = dxyz;
			dx = scx - sphere.x;
			dy = scy - sphere.y;
			dz = scz - sphere.z;
			dxyz = dx*dx + dy*dy + dz*dz;
			if (dxyz > sphere.w) sphere.w = dxyz;
			dx = sdx - sphere.x;
			dy = sdy - sphere.y;
			dz = sdz - sphere.z;
			dxyz = dx*dx + dy*dy + dz*dz;
			if (dxyz > sphere.w) sphere.w = dxyz;
			sphere.w = Math.sqrt(sphere.w);
		}
		
		private function prepare(source:Vector3D, displacement:Vector3D, object:Object3D, excludedObjects:Dictionary):void {
			
			// Radius of the sphere
			radius = radiusX;
			if (radiusY > radius) radius = radiusY;
			if (radiusZ > radius) radius = radiusZ;
			
			// The matrix of the collider
			matrix.compose(source.x, source.y, source.z, 0, 0, 0, radiusX/radius, radiusY/radius, radiusZ/radius);
			inverseMatrix.copy(matrix);
			inverseMatrix.invert();
			
			// Local coordinates
			src.x = 0;
			src.y = 0;
			src.z = 0;
			// Local offset
			displ.x = inverseMatrix.a*displacement.x + inverseMatrix.b*displacement.y + inverseMatrix.c*displacement.z;
			displ.y = inverseMatrix.e*displacement.x + inverseMatrix.f*displacement.y + inverseMatrix.g*displacement.z;
			displ.z = inverseMatrix.i*displacement.x + inverseMatrix.j*displacement.y + inverseMatrix.k*displacement.z;
			// Local destination point
			dest.x = src.x + displ.x;
			dest.y = src.y + displ.y;
			dest.z = src.z + displ.z;
			
			// Bound defined by movement of the sphere
			var rad:Number = radius + displ.length;
			cornerA.x = -rad;
			cornerA.y = -rad;
			cornerA.z = -rad;
			cornerB.x = rad;
			cornerB.y = -rad;
			cornerB.z = -rad;
			cornerC.x = rad;
			cornerC.y = rad;
			cornerC.z = -rad;
			cornerD.x = -rad;
			cornerD.y = rad;
			cornerD.z = -rad;

			// Gathering the faces which with collision can occur
			if (excludedObjects == null || !excludedObjects[object]) {
				if (object.transformChanged) object.composeTransforms();
				object.globalToLocalTransform.combine(object.inverseTransform, matrix);
				// Check collision with the bound
				var intersects:Boolean = true;
				if (object.boundBox != null) {
					calculateSphere(object.globalToLocalTransform);
					intersects = object.boundBox.checkSphere(sphere);
				}
				if (intersects) {
					object.localToGlobalTransform.combine(inverseMatrix, object.transform);
					object.collectGeometry(this, excludedObjects);
				}
				// Check children
				if (object.childrenList != null) object.collectChildrenGeometry(this, excludedObjects);
			}
			
			numTriangles = 0;
			var indicesLength:int = 0;
			var normalsLength:int = 0;
			
			// Loop geometries
			var j:int;
			var mapOffset:int = 0;
			var verticesLength:int = 0;
			var geometriesLength:int = geometries.length;
			for (var i:int = 0; i < geometriesLength; i++) {
				var geometry:Geometry = geometries[i];
				var transform:Transform3D = transforms[i];
				var geometryIndicesLength:int = geometry._indices.length;
				if (geometry._numVertices == 0 || geometryIndicesLength == 0) continue;
				// Transform vertices
				var vBuffer:VertexStream = (VertexAttributes.POSITION < geometry._attributesStreams.length) ? geometry._attributesStreams[VertexAttributes.POSITION] : null;
				if (vBuffer != null) {
					var attributesOffset:int = geometry._attributesOffsets[VertexAttributes.POSITION];
					var numMappings:int = vBuffer.attributes.length;
					var data:ByteArray = vBuffer.data;
					for (j = 0; j < geometry._numVertices; j++) {
						data.position = 4*(numMappings*j + attributesOffset);
						var vx:Number = data.readFloat();
						var vy:Number = data.readFloat();
						var vz:Number = data.readFloat();
						vertices[verticesLength] = transform.a*vx + transform.b*vy + transform.c*vz + transform.d; verticesLength++;
						vertices[verticesLength] = transform.e*vx + transform.f*vy + transform.g*vz + transform.h; verticesLength++;
						vertices[verticesLength] = transform.i*vx + transform.j*vy + transform.k*vz + transform.l; verticesLength++;
					}
				}
				// Loop triangles
				var geometryIndices:Vector.<uint> = geometry._indices;
				for (j = 0; j < geometryIndicesLength;) {
					var a:int = geometryIndices[j] + mapOffset; j++;
					var index:int = a*3;
					var ax:Number = vertices[index]; index++;
					var ay:Number = vertices[index]; index++;
					var az:Number = vertices[index];
					var b:int = geometryIndices[j] + mapOffset; j++;
					index = b*3;
					var bx:Number = vertices[index]; index++;
					var by:Number = vertices[index]; index++;
					var bz:Number = vertices[index];
					var c:int = geometryIndices[j] + mapOffset; j++;
					index = c*3;
					var cx:Number = vertices[index]; index++;
					var cy:Number = vertices[index]; index++;
					var cz:Number = vertices[index];
					// Exclusion by bound
					if (ax > rad && bx > rad && cx > rad || ax < -rad && bx < -rad && cx < -rad) continue;
					if (ay > rad && by > rad && cy > rad || ay < -rad && by < -rad && cy < -rad) continue;
					if (az > rad && bz > rad && cz > rad || az < -rad && bz < -rad && cz < -rad) continue;
					// The normal
					var abx:Number = bx - ax;
					var aby:Number = by - ay;
					var abz:Number = bz - az;
					var acx:Number = cx - ax;
					var acy:Number = cy - ay;
					var acz:Number = cz - az;
					var normalX:Number = acz*aby - acy*abz;
					var normalY:Number = acx*abz - acz*abx;
					var normalZ:Number = acy*abx - acx*aby;
					var len:Number = normalX*normalX + normalY*normalY + normalZ*normalZ;
					if (len < 0.001) continue;
					len = 1/Math.sqrt(len);
					normalX *= len;
					normalY *= len;
					normalZ *= len;
					var offset:Number = ax*normalX + ay*normalY + az*normalZ;
					if (offset > rad || offset < -rad) continue;
					indices[indicesLength] = a; indicesLength++;
					indices[indicesLength] = b; indicesLength++;
					indices[indicesLength] = c; indicesLength++;
					normals[normalsLength] = normalX; normalsLength++;
					normals[normalsLength] = normalY; normalsLength++;
					normals[normalsLength] = normalZ; normalsLength++;
					normals[normalsLength] = offset; normalsLength++;
					numTriangles++;
				}
				// Offset by nomber of vertices
				mapOffset += geometry._numVertices;
			}
			geometries.length = 0;
			transforms.length = 0;
		}
		
		/**
		 * Calculates destination point from given start position and displacement vector.
		 * @param source Starting point.
		 * @param displacement Displacement vector.
		 * @param object An object at crossing which will be checked. If this is a container, the application will participate and its child objects
		 * @param excludedObjects An associative array whose keys are instances of <code>Object3D</code> and its children.
		 * The objects that are keys of this dictionary will be excluded from intersection test.
		 * @return Destination point.
		 */
		public function calculateDestination(source:Vector3D, displacement:Vector3D, object:Object3D, excludedObjects:Dictionary = null):Vector3D {
			
			if (displacement.length <= threshold) return source.clone();
			
			prepare(source, displacement, object, excludedObjects);
			
			if (numTriangles > 0) {
				var limit:int = 50;
				for (var i:int = 0; i < limit; i++) {
					if (checkCollision()) {
						// Offset destination point from behind collision plane by radius of the sphere over plane, along the normal
						var offset:Number = radius + threshold + collisionPlane.w - dest.x*collisionPlane.x - dest.y*collisionPlane.y - dest.z*collisionPlane.z;
						dest.x += collisionPlane.x*offset;
						dest.y += collisionPlane.y*offset;
						dest.z += collisionPlane.z*offset;
						// Fixing up the current sphere coordinates for the next iteration
						src.x = collisionPoint.x + collisionPlane.x*(radius + threshold);
						src.y = collisionPoint.y + collisionPlane.y*(radius + threshold);
						src.z = collisionPoint.z + collisionPlane.z*(radius + threshold);
						// Fixing up velocity vector. The result ordered along plane of collision.
						displ.x = dest.x - src.x;
						displ.y = dest.y - src.y;
						displ.z = dest.z - src.z;
						if (displ.length < threshold) break;
					} else break;
				}
				// Setting the coordinates
				return new Vector3D(matrix.a*dest.x + matrix.b*dest.y + matrix.c*dest.z + matrix.d, matrix.e*dest.x + matrix.f*dest.y + matrix.g*dest.z + matrix.h, matrix.i*dest.x + matrix.j*dest.y + matrix.k*dest.z + matrix.l);
			} else {
				return new Vector3D(source.x + displacement.x, source.y + displacement.y, source.z + displacement.z);
			}
		}
		
		/**
		 * Finds first collision from given starting point aling displacement vector.
		 * @param source Starting point.
		 * @param displacement Displacement vector.
		 * @param resCollisionPoint Collision point will be written into this variable.
		 * @param resCollisionPlane Collision plane (defines by normal) parameters will be written into this variable.
		 * @param object The object to use in collision detection. If a container is specified, all its children will be tested for collison with ellipsoid.
		 * @param excludedObjects An associative array whose keys are instances of <code>Object3D</code> and its children.
		 * @return <code>true</code> if collision detected and <code>false</code> otherwise.
		 */
		public function getCollision(source:Vector3D, displacement:Vector3D, resCollisionPoint:Vector3D, resCollisionPlane:Vector3D, object:Object3D, excludedObjects:Dictionary = null):Boolean {
			
			if (displacement.length <= threshold) return false;
			
			prepare(source, displacement, object, excludedObjects);
			
			if (numTriangles > 0) {
				if (checkCollision()) {
					
					// Transform the point to the global space
					resCollisionPoint.x = matrix.a*collisionPoint.x + matrix.b*collisionPoint.y + matrix.c*collisionPoint.z + matrix.d;
					resCollisionPoint.y = matrix.e*collisionPoint.x + matrix.f*collisionPoint.y + matrix.g*collisionPoint.z + matrix.h;
					resCollisionPoint.z = matrix.i*collisionPoint.x + matrix.j*collisionPoint.y + matrix.k*collisionPoint.z + matrix.l;
					
					// Transform the plane to the global space
					var abx:Number;
					var aby:Number;
					var abz:Number;
					if (collisionPlane.x < collisionPlane.y) {
						if (collisionPlane.x < collisionPlane.z) {
							abx = 0;
							aby = -collisionPlane.z;
							abz = collisionPlane.y;
						} else {
							abx = -collisionPlane.y;
							aby = collisionPlane.x;
							abz = 0;
						}
					} else {
						if (collisionPlane.y < collisionPlane.z) {
							abx = collisionPlane.z;
							aby = 0;
							abz = -collisionPlane.x;
						} else {
							abx = -collisionPlane.y;
							aby = collisionPlane.x;
							abz = 0;
						}
					}
					var acx:Number = collisionPlane.z*aby - collisionPlane.y*abz;
					var acy:Number = collisionPlane.x*abz - collisionPlane.z*abx;
					var acz:Number = collisionPlane.y*abx - collisionPlane.x*aby;
					
					var abx2:Number = matrix.a*abx + matrix.b*aby + matrix.c*abz;
					var aby2:Number = matrix.e*abx + matrix.f*aby + matrix.g*abz;
					var abz2:Number = matrix.i*abx + matrix.j*aby + matrix.k*abz;
					var acx2:Number = matrix.a*acx + matrix.b*acy + matrix.c*acz;
					var acy2:Number = matrix.e*acx + matrix.f*acy + matrix.g*acz;
					var acz2:Number = matrix.i*acx + matrix.j*acy + matrix.k*acz;
					
					resCollisionPlane.x = abz2*acy2 - aby2*acz2;
					resCollisionPlane.y = abx2*acz2 - abz2*acx2;
					resCollisionPlane.z = aby2*acx2 - abx2*acy2;
					resCollisionPlane.normalize();
					resCollisionPlane.w = resCollisionPoint.x*resCollisionPlane.x + resCollisionPoint.y*resCollisionPlane.y + resCollisionPoint.z*resCollisionPlane.z;
					
					return true;
				} else {
					return false;
				}
			}
			return false;
		}
		
		private function checkCollision():Boolean {
			var minTime:Number = 1;
			var displacementLength:Number = displ.length;
			// Loop triangles
			var indicesLength:int = numTriangles*3;
			for (var i:int = 0, j:int = 0; i < indicesLength;) {
				// Points
				var index:int = indices[i]*3; i++;
				var ax:Number = vertices[index]; index++;
				var ay:Number = vertices[index]; index++;
				var az:Number = vertices[index];
				index = indices[i]*3; i++;
				var bx:Number = vertices[index]; index++;
				var by:Number = vertices[index]; index++;
				var bz:Number = vertices[index];
				index = indices[i]*3; i++;
				var cx:Number = vertices[index]; index++;
				var cy:Number = vertices[index]; index++;
				var cz:Number = vertices[index];
				// Normal
				var normalX:Number = normals[j]; j++;
				var normalY:Number = normals[j]; j++;
				var normalZ:Number = normals[j]; j++;
				var offset:Number = normals[j]; j++;
				var distance:Number = src.x*normalX + src.y*normalY + src.z*normalZ - offset;
				// The intersection of plane and sphere
				var pointX:Number;
				var pointY:Number;
				var pointZ:Number;
				if (distance < radius) {
					pointX = src.x - normalX*distance;
					pointY = src.y - normalY*distance;
					pointZ = src.z - normalZ*distance;
				} else {
					var t:Number = (distance - radius)/(distance - dest.x*normalX - dest.y*normalY - dest.z*normalZ + offset);
					pointX = src.x + displ.x*t - normalX*radius;
					pointY = src.y + displ.y*t - normalY*radius;
					pointZ = src.z + displ.z*t - normalZ*radius;
				}
				// Closest polygon vertex
				var faceX:Number;
				var faceY:Number;
				var faceZ:Number;
				var min:Number = 1e+22;
				// Loop edges
				var inside:Boolean = true;
				for (var k:int = 0; k < 3; k++) {
					var p1x:Number;
					var p1y:Number;
					var p1z:Number;
					var p2x:Number;
					var p2y:Number;
					var p2z:Number;
					if (k == 0) {
						p1x = ax;
						p1y = ay;
						p1z = az;
						p2x = bx;
						p2y = by;
						p2z = bz;
					} else if (k == 1) {
						p1x = bx;
						p1y = by;
						p1z = bz;
						p2x = cx;
						p2y = cy;
						p2z = cz;
					} else {
						p1x = cx;
						p1y = cy;
						p1z = cz;
						p2x = ax;
						p2y = ay;
						p2z = az;
					}
					var abx:Number = p2x - p1x;
					var aby:Number = p2y - p1y;
					var abz:Number = p2z - p1z;
					var acx:Number = pointX - p1x;
					var acy:Number = pointY - p1y;
					var acz:Number = pointZ - p1z;
					var crx:Number = acz*aby - acy*abz;
					var cry:Number = acx*abz - acz*abx;
					var crz:Number = acy*abx - acx*aby;
					// Case of the point is outside of the polygon
					if (crx*normalX + cry*normalY + crz*normalZ < 0) {
						var edgeLength:Number = abx*abx + aby*aby + abz*abz;
						var edgeDistanceSqr:Number = (crx*crx + cry*cry + crz*crz)/edgeLength;
						if (edgeDistanceSqr < min) {
							// Edge normalization
							edgeLength = Math.sqrt(edgeLength);
							abx /= edgeLength;
							aby /= edgeLength;
							abz /= edgeLength;
							// Distance to intersecion of normal along theedge
							t = abx*acx + aby*acy + abz*acz;
							var acLen:Number;
							if (t < 0) {
								// Closest point is the first one
								acLen = acx*acx + acy*acy + acz*acz;
								if (acLen < min) {
									min = acLen;
									faceX = p1x;
									faceY = p1y;
									faceZ = p1z;
								}
							} else if (t > edgeLength) {
								// Closest point is the second one
								acx = pointX - p2x;
								acy = pointY - p2y;
								acz = pointZ - p2z;
								acLen = acx*acx + acy*acy + acz*acz;
								if (acLen < min) {
									min = acLen;
									faceX = p2x;
									faceY = p2y;
									faceZ = p2z;
								}
							} else {
								// Closest point is on edge
								min = edgeDistanceSqr;
								faceX = p1x + abx*t;
								faceY = p1y + aby*t;
								faceZ = p1z + abz*t;
							}
						}
						inside = false;
					}
				}
				// Case of point is inside polygon
				if (inside) {
					faceX = pointX;
					faceY = pointY;
					faceZ = pointZ;
				}
				// Vector pointed from closest point to the center of sphere
				var deltaX:Number = src.x - faceX;
				var deltaY:Number = src.y - faceY; 
				var deltaZ:Number = src.z - faceZ;
				// If movement directed to point
				if (deltaX*displ.x + deltaY*displ.y + deltaZ*displ.z <= 0) {
					// reversed vector
					var backX:Number = -displ.x/displacementLength;
					var backY:Number = -displ.y/displacementLength;
					var backZ:Number = -displ.z/displacementLength;
					// Length of Vector pointed from closest point to the center of sphere
					var deltaLength:Number = deltaX*deltaX + deltaY*deltaY + deltaZ*deltaZ;
					// Projection Vector pointed from closest point to the center of sphere  on reversed vector
					var projectionLength:Number = deltaX*backX + deltaY*backY + deltaZ*backZ;
					var projectionInsideLength:Number = radius*radius - deltaLength + projectionLength*projectionLength;
					if (projectionInsideLength > 0) {
						// Time of the intersection
						var time:Number = (projectionLength - Math.sqrt(projectionInsideLength))/displacementLength;
						// Collision with closest point occurs
						if (time < minTime) {
							minTime = time;
							collisionPoint.x = faceX;
							collisionPoint.y = faceY;
							collisionPoint.z = faceZ;
							if (inside) {
								collisionPlane.x = normalX;
								collisionPlane.y = normalY;
								collisionPlane.z = normalZ;
								collisionPlane.w = offset;
							} else {
								deltaLength = Math.sqrt(deltaLength);
								collisionPlane.x = deltaX/deltaLength;
								collisionPlane.y = deltaY/deltaLength;
								collisionPlane.z = deltaZ/deltaLength;
								collisionPlane.w = collisionPoint.x*collisionPlane.x + collisionPoint.y*collisionPlane.y + collisionPoint.z*collisionPlane.z;
							}
						}
					}
				}
			}
			return minTime < 1;
		}
		
	}
}
