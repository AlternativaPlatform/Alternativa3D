/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.primitives {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;

	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * A spherical primitive consists of set of equal triangles.
	 */
	public class GeoSphere extends Mesh {

		/**
		 * Creates a new GeoSphere instance.
		 *
		 * @param radius Radius of a sphere. Can't be less than 0.
		 * @param segments Level of subdivision.
		 * @param reverse If <code>true</code>, face normals will turned inside, so the sphere will be visible from inside only. Otherwise, the normals will turned outside.
		 * @param material Material. If you use   <code>TextureMaterial</code>, it is need to set <code>repeat</code> property to <code>true</code>.
		 */
		public function GeoSphere(radius:Number = 100, segments:uint = 2, reverse:Boolean = false, material:Material = null) {
			if (segments == 0) return;
			radius = (radius < 0) ? 0 : radius;
			var indices:Vector.<uint> = new Vector.<uint>();
			var sections:uint = 20;
			var deg180:Number = Math.PI;
			var deg360:Number = Math.PI*2;
			var vertices:Vector.<Vector3D> = new Vector.<Vector3D>();
			var uvs:Vector.<Number> = new Vector.<Number>();
			var i:uint;
			var f:uint;
			var theta:Number;
			var sin:Number;
			var cos:Number;
			// distance along z-axis to the top and bottom pole hats
			var subz:Number = 4.472136E-001*radius;
			//radius along subz distance.
			var subrad:Number = 2*subz;
			vertices.push(new Vector3D(0, 0, radius, -1));
			uvs.length += 2;
			// Make vertices of  the top pole hats
			for (i = 0; i < 5; i++) {
				theta = deg360*i/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices.push(new Vector3D(subrad*cos, subrad*sin, subz, -1));
				uvs.length += 2;
			}
			// Make vertices of  the bottom pole hats
			for (i = 0; i < 5; i++) {
				theta = deg180*((i << 1) + 1)/5;
				sin = Math.sin(theta);
				cos = Math.cos(theta);
				vertices.push(new Vector3D(subrad*cos, subrad*sin, -subz, -1));
				uvs.length += 2;
			}
			vertices.push(new Vector3D(0, 0, -radius, -1));
			uvs.length += 2;
			for (i = 1; i < 6; i++) {
				interpolate(0, i, segments, vertices, uvs);

			}
			for (i = 1; i < 6; i++) {
				interpolate(i, i%5 + 1, segments, vertices, uvs);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i, i + 5, segments, vertices, uvs);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i, (i + 3)%5 + 6, segments, vertices, uvs);
			}
			for (i = 1; i < 6; i++) {
				interpolate(i + 5, i%5 + 6, segments, vertices, uvs);
			}
			for (i = 6; i < 11; i++) {
				interpolate(11, i, segments, vertices, uvs);
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + f*(segments - 1) + i, 12 + (f + 1)%5*(segments - 1) + i, i + 1, vertices, uvs);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + (f + 15)*(segments - 1) + i, 12 + (f + 10)*(segments - 1) + i, i + 1, vertices, uvs);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + ((f + 1)%5 + 15)*(segments - 1) + segments - 2 - i, 12 + (f + 10)*(segments - 1) + segments - 2 - i, i + 1, vertices, uvs);
				}
			}
			for (f = 0; f < 5; f++) {
				for (i = 1; i <= segments - 2; i++) {
					interpolate(12 + ((f + 1)%5 + 25)*(segments - 1) + i, 12 + (f + 25)*(segments - 1) + i, i + 1, vertices, uvs);
				}
			}
			// Make faces
			for (f = 0; f < sections; f++) {
				for (var row:uint = 0; row < segments; row++) {
					for (var column:uint = 0; column <= row; column++) {
						var aIndex:uint = findVertices(segments, f, row, column);
						var bIndex:uint = findVertices(segments, f, row + 1, column);
						var cIndex:uint = findVertices(segments, f, row + 1, column + 1);
						var a:Vector3D = vertices[aIndex];
						var b:Vector3D = vertices[bIndex];
						var c:Vector3D = vertices[cIndex];
						var au:Number;
						var av:Number;
						var bu:Number;
						var bv:Number;
						var cu:Number;
						var cv:Number;
						if (a.y >= 0 && (a.x < 0) && (b.y < 0 || c.y < 0)) {
							au = Math.atan2(a.y, a.x)/deg360 - 0.5;
						} else {
							au = Math.atan2(a.y, a.x)/deg360 + 0.5;
						}
						av = -Math.asin(a.z/radius)/deg180 + 0.5;
						if (b.y >= 0 && (b.x < 0) && (a.y < 0 || c.y < 0)) {
							bu = Math.atan2(b.y, b.x)/deg360 - 0.5;
						} else {
							bu = Math.atan2(b.y, b.x)/deg360 + 0.5;
						}
						bv = -Math.asin(b.z/radius)/deg180 + 0.5;
						if (c.y >= 0 && (c.x < 0) && (a.y < 0 || b.y < 0)) {
							cu = Math.atan2(c.y, c.x)/deg360 - 0.5;
						} else {
							cu = Math.atan2(c.y, c.x)/deg360 + 0.5;
						}
						cv = -Math.asin(c.z/radius)/deg180 + 0.5;
						// Pole
						if (aIndex == 0 || aIndex == 11) {
							au = bu + (cu - bu)*0.5;
						}
						if (bIndex == 0 || bIndex == 11) {
							bu = au + (cu - au)*0.5;
						}
						if (cIndex == 0 || cIndex == 11) {
							cu = au + (bu - au)*0.5;
						}
						// Duplication
						if (a.w > 0 && uvs[aIndex*2] != au) {
							a = createVertex(a.x, a.y, a.z);
							aIndex = vertices.push(a) - 1;

						}
						uvs[aIndex*2] = au;
						uvs[aIndex*2 + 1] = av;
						a.w = 1;
						if (b.w > 0 && uvs[bIndex*2] != bu) {
							b = createVertex(b.x, b.y, b.z);
							bIndex = vertices.push(b) - 1;
						}
						uvs[bIndex*2] = bu;
						uvs[bIndex*2 + 1] = bv;
						b.w = 1;
						if (c.w > 0 && uvs[cIndex*2] != cu) {
							c = createVertex(c.x, c.y, c.z);
							cIndex = vertices.push(c) - 1;
						}
						uvs[cIndex*2] = cu;
						uvs[cIndex*2 + 1] = cv;
						c.w = 1;
						if (reverse) {
							indices.push(aIndex, cIndex, bIndex);
						} else {
							indices.push(aIndex, bIndex, cIndex);
						}
						if (column < row) {
							bIndex = findVertices(segments, f, row, column + 1);
							b = vertices[bIndex];
							if (a.y >= 0 && (a.x < 0) && (b.y < 0 || c.y < 0)) {
								au = Math.atan2(a.y, a.x)/deg360 - 0.5;
							} else {
								au = Math.atan2(a.y, a.x)/deg360 + 0.5;
							}
							av = -Math.asin(a.z/radius)/deg180 + 0.5;
							if (b.y >= 0 && (b.x < 0) && (a.y < 0 || c.y < 0)) {
								bu = Math.atan2(b.y, b.x)/deg360 - 0.5;
							} else {
								bu = Math.atan2(b.y, b.x)/deg360 + 0.5;
							}
							bv = -Math.asin(b.z/radius)/deg180 + 0.5;
							if (c.y >= 0 && (c.x < 0) && (a.y < 0 || b.y < 0)) {
								cu = Math.atan2(c.y, c.x)/deg360 - 0.5;
							} else {
								cu = Math.atan2(c.y, c.x)/deg360 + 0.5;
							}
							cv = -Math.asin(c.z/radius)/deg180 + 0.5;
							if (aIndex == 0 || aIndex == 11) {
								au = bu + (cu - bu)*0.5;
							}
							if (bIndex == 0 || bIndex == 11) {
								bu = au + (cu - au)*0.5;
							}
							if (cIndex == 0 || cIndex == 11) {
								cu = au + (bu - au)*0.5;
							}
							// Duplication
							if (a.w > 0 && uvs[aIndex*2] != au) {
								a = createVertex(a.x, a.y, a.z);
								aIndex = vertices.push(a) - 1;
							}
							uvs[aIndex*2] = au;
							uvs[aIndex*2 + 1] = av;
							a.w = 1;
							if (b.w > 0 && uvs[bIndex*2] != bu) {
								b = createVertex(b.x, b.y, b.z);
								bIndex = vertices.push(b) - 1;
							}
							uvs[bIndex*2] = bu;
							uvs[bIndex*2 + 1] = bv;
							b.w = 1;
							if (c.w > 0 && uvs[cIndex*2] != cu) {
								c = createVertex(c.x, c.y, c.z);
								cIndex = vertices.push(c) - 1;
							}
							uvs[cIndex*2] = cu;
							uvs[cIndex*2 + 1] = cv;
							c.w = 1;
							if (reverse) {
								indices.push(aIndex, bIndex, cIndex);
							} else {
								indices.push(aIndex, cIndex, bIndex);
							}
						}
					}
				}
			}

			var byteArray:ByteArray = new ByteArray();
			byteArray.endian = Endian.LITTLE_ENDIAN;
			for (i = 0; i < vertices.length; i++) {
				var v:Vector3D = vertices[i];
				byteArray.writeFloat(v.x);
				byteArray.writeFloat(v.y);
				byteArray.writeFloat(v.z);
				byteArray.writeFloat(uvs[i*2]);
				byteArray.writeFloat(uvs[i*2 + 1]);
				byteArray.writeFloat(v.x / radius);
				byteArray.writeFloat(v.y / radius);
				byteArray.writeFloat(v.z / radius);

				var longitude:Number = deg360 * uvs[i*2];
				byteArray.writeFloat( +Math.sin (longitude));
				byteArray.writeFloat( -Math.cos (longitude));
				byteArray.writeFloat(0.0);
				byteArray.writeFloat(-1.0);
			}

			geometry = new Geometry();
			geometry._indices = indices;
			var attributes:Array = [];
			attributes[0] = VertexAttributes.POSITION;
			attributes[1] = VertexAttributes.POSITION;
			attributes[2] = VertexAttributes.POSITION;
			attributes[3] = VertexAttributes.TEXCOORDS[0];
			attributes[4] = VertexAttributes.TEXCOORDS[0];
			attributes[5] = VertexAttributes.NORMAL;
			attributes[6] = VertexAttributes.NORMAL;
			attributes[7] = VertexAttributes.NORMAL;
			attributes[8] = VertexAttributes.TANGENT4;
			attributes[9] = VertexAttributes.TANGENT4;
			attributes[10] = VertexAttributes.TANGENT4;
			attributes[11] = VertexAttributes.TANGENT4;
			
			geometry.addVertexStream(attributes);
			geometry._vertexStreams[0].data = byteArray;
			geometry._numVertices = byteArray.length/48;

//			this.geometry.calculateFacesNormals();
			addSurface(material, 0, indices.length/3);
			calculateBoundBox();
		}

		private function createVertex(x:Number, y:Number, z:Number):Vector3D {
			var vertex:Vector3D = new Vector3D();
			vertex.x = x;
			vertex.y = y;
			vertex.z = z;
			vertex.w = -1;
			return vertex;
		}

		private function interpolate(v1:uint, v2:uint, num:uint, vertices:Vector.<Vector3D>, uvs:Vector.<Number>):void {
			if (num < 2) {
				return;
			}
			var a:Vector3D = vertices[v1];
			var b:Vector3D = vertices[v2];
			var cos:Number = (a.x*b.x + a.y*b.y + a.z*b.z)/(a.x*a.x + a.y*a.y + a.z*a.z);
			cos = (cos < -1) ? -1 : ((cos > 1) ? 1 : cos);
			var theta:Number = Math.acos(cos);
			var sin:Number = Math.sin(theta);
			for (var e:uint = 1; e < num; e++) {
				var theta1:Number = theta*e/num;
				var theta2:Number = theta*(num - e)/num;
				var st1:Number = Math.sin(theta1);
				var st2:Number = Math.sin(theta2);
				vertices.push(new Vector3D((a.x*st2 + b.x*st1)/sin, (a.y*st2 + b.y*st1)/sin, (a.z*st2 + b.z*st1)/sin, -1));
				uvs.length += 2;
			}
		}

		private function findVertices(segments:uint, section:uint, row:uint, column:uint):uint {
			if (row == 0) {
				if (section < 5) {
					return (0);
				}
				if (section > 14) {
					return (11);
				}
				return (section - 4);
			}
			if (row == segments && column == 0) {
				if (section < 5) {
					return (section + 1);
				}
				if (section < 10) {
					return ((section + 4)%5 + 6);
				}
				if (section < 15) {
					return ((section + 1)%5 + 1);
				}
				return ((section + 1)%5 + 6);
			}
			if (row == segments && column == segments) {
				if (section < 5) {
					return ((section + 1)%5 + 1);
				}
				if (section < 10) {
					return (section + 1);
				}
				if (section < 15) {
					return (section - 9);
				}
				return (section - 9);
			}
			if (row == segments) {
				if (section < 5) {
					return (12 + (5 + section)*(segments - 1) + column - 1);
				}
				if (section < 10) {
					return (12 + (20 + (section + 4)%5)*(segments - 1) + column - 1);
				}
				if (section < 15) {
					return (12 + (section - 5)*(segments - 1) + segments - 1 - column);
				}
				return (12 + (5 + section)*(segments - 1) + segments - 1 - column);
			}
			if (column == 0) {
				if (section < 5) {
					return (12 + section*(segments - 1) + row - 1);
				}
				if (section < 10) {
					return (12 + (section%5 + 15)*(segments - 1) + row - 1);
				}
				if (section < 15) {
					return (12 + ((section + 1)%5 + 15)*(segments - 1) + segments - 1 - row);
				}
				return (12 + ((section + 1)%5 + 25)*(segments - 1) + row - 1);
			}
			if (column == row) {
				if (section < 5) {
					return (12 + (section + 1)%5*(segments - 1) + row - 1);
				}
				if (section < 10) {
					return (12 + (section%5 + 10)*(segments - 1) + row - 1);
				}
				if (section < 15) {
					return (12 + (section%5 + 10)*(segments - 1) + segments - row - 1);
				}
				return (12 + (section%5 + 25)*(segments - 1) + row - 1);
			}
			return (12 + 30*(segments - 1) + section*(segments - 1)*(segments - 2)/2 + (row - 1)*(row - 2)/2 + column - 1);
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Object3D {
			var res:GeoSphere = new GeoSphere(1, 0);
			res.clonePropertiesFrom(this);
			return res;
		}
	}

}
