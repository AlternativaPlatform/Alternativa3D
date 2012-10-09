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

	import flash.utils.ByteArray;
	import flash.utils.Endian;

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

			var vertices:ByteArray = new ByteArray();
			vertices.endian = Endian.LITTLE_ENDIAN;
			var offsetAdditionalData:Number = 28;
			// Top face.
			for (x = 0; x < wEdges; x++) {
				for (y = 0; y < lEdges; y++) {
					vertices.writeFloat(x*segmentWidth - halfWidth);
					vertices.writeFloat(y*segmentLength - halfLength);
					vertices.writeFloat(0);
					vertices.writeFloat(x*segmentUSize);
					vertices.writeFloat((lengthSegments - y)*segmentVSize);
					vertices.length = vertices.position += offsetAdditionalData;
				}
			}
			var lastPosition:uint = vertices.position;
			for (x = 0; x < wEdges; x++) {
				for (y = 0; y < lEdges; y++) {
					if (x < widthSegments && y < lengthSegments) {
						createFace(indices, vertices, x*lEdges + y, (x + 1)*lEdges + y, (x + 1)*lEdges + y + 1, x*lEdges + y + 1, 0, 0, 1, 1, 0, 0, -1, reverse);
					}
				}
			}

			if (twoSided) {
				vertices.position = lastPosition;
				// Bottom face.
				for (x = 0; x < wEdges; x++) {
					for (y = 0; y < lEdges; y++) {
						vertices.writeFloat(x*segmentWidth - halfWidth);
						vertices.writeFloat(y*segmentLength - halfLength);
						vertices.writeFloat(0);
						vertices.writeFloat((widthSegments - x)*segmentUSize);
						vertices.writeFloat((lengthSegments - y)*segmentVSize);
						vertices.length = vertices.position += offsetAdditionalData;
					}
				}
				var baseIndex:uint = wEdges*lEdges;
				for (x = 0; x < wEdges; x++) {
					for (y = 0; y < lEdges; y++) {
						if (x < widthSegments && y < lengthSegments) {
							createFace(indices, vertices, baseIndex + (x + 1)*lEdges + y + 1, baseIndex + (x + 1)*lEdges + y, baseIndex + x*lEdges + y, baseIndex + x*lEdges + y + 1, 0, 0, -1, -1, 0, 0, -1, reverse);
						}
					}
				}
			}

			// Set bounds
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
			geometry._vertexStreams[0].data = vertices;
			geometry._numVertices = vertices.length/48;
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
		
		private function createFace(indices:Vector.<uint>, vertices:ByteArray, a:int, b:int, c:int, d:int, nx:Number, ny:Number, nz:Number, tx:Number, ty:Number, tz:Number, tw:Number, reverse:Boolean):void {
			var temp:int;
			if (reverse) {
				nx = -nx;
				ny = -ny;
				nz = -nz;
				tw = -tw;
				temp = a;
				a = d;
				d = temp;
				temp = b;
				b = c;
				c = temp;
			}
			indices.push(a);
			indices.push(b);
			indices.push(c);
			indices.push(a);
			indices.push(c);
			indices.push(d);
			vertices.position = a*48 + 20;
			vertices.writeFloat(nx);
			vertices.writeFloat(ny);
			vertices.writeFloat(nz);
			vertices.writeFloat(tx);
			vertices.writeFloat(ty);
			vertices.writeFloat(tz);
			vertices.writeFloat(tw);
			vertices.position = b*48 + 20;
			vertices.writeFloat(nx);
			vertices.writeFloat(ny);
			vertices.writeFloat(nz);
			vertices.writeFloat(tx);
			vertices.writeFloat(ty);
			vertices.writeFloat(tz);
			vertices.writeFloat(tw);
			vertices.position = c*48 + 20;
			vertices.writeFloat(nx);
			vertices.writeFloat(ny);
			vertices.writeFloat(nz);
			vertices.writeFloat(tx);
			vertices.writeFloat(ty);
			vertices.writeFloat(tz);
			vertices.writeFloat(tw);
			vertices.position = d*48 + 20;
			vertices.writeFloat(nx);
			vertices.writeFloat(ny);
			vertices.writeFloat(nz);
			vertices.writeFloat(tx);
			vertices.writeFloat(ty);
			vertices.writeFloat(tz);
			vertices.writeFloat(tw);
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
