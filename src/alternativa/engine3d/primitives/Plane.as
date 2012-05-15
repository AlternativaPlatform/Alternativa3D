/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.primitives {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;

	use namespace alternativa3d;

	/**
	 * A plane primitive.
	 */
	public class Plane extends Mesh {

		/**
		 * Creates a new Plane instance.
		 * @param width Width. Can not be less than 0.
		 * @param length Length. Can not be less than 0.
		 * @param widthSegments Number of subdivisions along x-axis.
		 * @param lengthSegments Number of subdivisions along y-axis.
		 * @param twoSided If <code>true</code>, plane has surface for both sides: tob and bottom and only one otherwise.
		 * @param reverse If   <code>twoSided=false</code>, reverse parameter determines for which side surface will be created.
		 * @param bottom Material of the bottom surface.
		 * @param top Material of the top surface.
		 */
		public function Plane(width:Number = 100, length:Number = 100, widthSegments:uint = 1, lengthSegments:uint = 1, twoSided:Boolean = true, reverse:Boolean = false, bottom:Material = null, top:Material = null) {
			// TODO: optionally do not create normals, tangents
			if (widthSegments <= 0 || lengthSegments <= 0) return;
			var indices:Vector.<uint> = new Vector.<uint>();
			var x:int;
			var y:int;
			var wEdges:int = widthSegments + 1;
			var lEdges:int = lengthSegments + 1;
			var halfWidth:Number = width*0.5;
			var halfLength:Number = length*0.5;
			var segmentUSize:Number = 1/widthSegments;
			var segmentVSize:Number = 1/lengthSegments;
			var segmentWidth:Number = width/widthSegments;
			var segmentLength:Number = length/lengthSegments;

			geometry = new Geometry(twoSided ? 2*wEdges*lEdges : wEdges*lEdges);
			var attributes:Array = [
				VertexAttributes.POSITION,
				VertexAttributes.POSITION,
				VertexAttributes.POSITION,
				VertexAttributes.TEXCOORDS[0],
				VertexAttributes.TEXCOORDS[0],
				VertexAttributes.NORMAL,
				VertexAttributes.NORMAL,
				VertexAttributes.NORMAL,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4
			];
			geometry.addVertexStream(attributes);
			var positions:Vector.<Number> = geometry._attributesValues[VertexAttributes.POSITION];
			var uvs:Vector.<Number> = geometry._attributesValues[VertexAttributes.TEXCOORDS[0]];
			var normals:Vector.<Number> = geometry._attributesValues[VertexAttributes.NORMAL];
			var tangents:Vector.<Number> = geometry._attributesValues[VertexAttributes.TANGENT4];

			var index:int;
			var vertex:int = 0;

			// Top face.
			for (x = 0; x < wEdges; x++) {
				for (y = 0; y < lEdges; y++) {
					index = 3*vertex;
					positions[index] = x*segmentWidth - halfWidth;
					positions[int(index + 1)] = y*segmentLength - halfLength;
					index = vertex << 1;
					uvs[index] = x*segmentUSize;
					uvs[int(index + 1)] = (lengthSegments - y)*segmentVSize;
					vertex++;
				}
			}
			var face:int = 0;
			var a:int, b:int, c:int, d:int;
			for (x = 0; x < wEdges; x++) {
				for (y = 0; y < lEdges; y++) {
					if (x < widthSegments && y < lengthSegments) {
						a = x*lEdges + y;
						b = (x + 1)*lEdges + y;
						c = (x + 1)*lEdges + y + 1;
						d = x*lEdges + y + 1;

						if (reverse) {
							indices[int(face++)] = d;
							indices[int(face++)] = c;
							indices[int(face++)] = b;
							indices[int(face++)] = d;
							indices[int(face++)] = b;
							indices[int(face++)] = a;

							// a.nz, a.tx, a.tw
							normals[int(3*a + 2)] = -1;
							index = a << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = 1;
							// b.nz, b.tx, b.tw
							normals[int(3*b + 2)] = -1;
							index = b << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = 1;
							// c.nz, c.tx, c.tw
							normals[int(3*c + 2)] = -1;
							index = c << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = 1;
							// d.nz, d.tx, d.tw
							normals[int(3*d + 2)] = -1;
							index = d << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = 1;
						} else {
							indices[int(face++)] = a;
							indices[int(face++)] = b;
							indices[int(face++)] = c;
							indices[int(face++)] = a;
							indices[int(face++)] = c;
							indices[int(face++)] = d;

							// a.nz, a.tx, a.tw
							normals[int(3*a + 2)] = 1;
							index = a << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = -1;
							// b.nz, b.tx, b.tw
							normals[int(3*b + 2)] = 1;
							index = b << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = -1;
							// c.nz, c.tx, c.tw
							normals[int(3*c + 2)] = 1;
							index = c << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = -1;
							// d.nz, d.tx, d.tw
							normals[int(3*d + 2)] = 1;
							index = d << 2;
							tangents[index] = 1;
							tangents[int(index + 3)] = -1;
						}
					}
				}
			}

			if (twoSided) {
				// Bottom face.
				for (x = 0; x < wEdges; x++) {
					for (y = 0; y < lEdges; y++) {
						index = 3*vertex;
						positions[index] = x*segmentWidth - halfWidth;
						positions[int(index + 1)] = y*segmentLength - halfLength;
						index = vertex << 1;
						uvs[index] = (widthSegments - x)*segmentUSize;
						uvs[int(index + 1)] = (lengthSegments - y)*segmentVSize;
						vertex++;
					}
				}
				var baseIndex:uint = wEdges*lEdges;
				for (x = 0; x < wEdges; x++) {
					for (y = 0; y < lEdges; y++) {
						if (x < widthSegments && y < lengthSegments) {
							a = baseIndex + (x + 1)*lEdges + y + 1;
							b = baseIndex + (x + 1)*lEdges + y;
							c = baseIndex + x*lEdges + y;
							d = baseIndex + x*lEdges + y + 1;

							if (reverse) {
								indices[int(face++)] = d;
								indices[int(face++)] = c;
								indices[int(face++)] = b;
								indices[int(face++)] = d;
								indices[int(face++)] = b;
								indices[int(face++)] = a;

								// a.nz, a.tx, a.tw
								normals[int(3*a + 2)] = 1;
								index = a << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = 1;
								// b.nz, b.tx, b.tw
								normals[int(3*b + 2)] = 1;
								index = b << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = 1;
								// c.nz, c.tx, c.tw
								normals[int(3*c + 2)] = 1;
								index = c << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = 1;
								// d.nz, d.tx, d.tw
								normals[int(3*d + 2)] = 1;
								index = d << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = 1;
							} else {
								indices[int(face++)] = a;
								indices[int(face++)] = b;
								indices[int(face++)] = c;
								indices[int(face++)] = a;
								indices[int(face++)] = c;
								indices[int(face++)] = d;

								// a.nz, a.tx, a.tw
								normals[int(3*a + 2)] = -1;
								index = a << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = -1;
								// b.nz, b.tx, b.tw
								normals[int(3*b + 2)] = -1;
								index = b << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = -1;
								// c.nz, c.tx, c.tw
								normals[int(3*c + 2)] = -1;
								index = c << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = -1;
								// d.nz, d.tx, d.tw
								normals[int(3*d + 2)] = -1;
								index = d << 2;
								tangents[index] = -1;
								tangents[int(index + 3)] = -1;
							}
						}
					}
				}
			}

			geometry._indices = indices;
			if (!twoSided) {
				addSurface(top, 0, indices.length/3);
			} else {
				addSurface(top, 0, indices.length/6);
				addSurface(bottom,  indices.length/2  , indices.length/6);
			}

			boundBox = new BoundBox();
			boundBox.minX = -halfWidth;
			boundBox.minY = -halfLength;
			boundBox.minZ = 0;
			boundBox.maxX = halfWidth;
			boundBox.maxY = halfLength;
			boundBox.maxZ = 0;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Plane = new Plane(0, 0, 0, 0);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
