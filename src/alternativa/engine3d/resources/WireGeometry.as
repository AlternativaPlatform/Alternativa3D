/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.materials.ShaderProgram;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class WireGeometry extends Resource {

		private const MAX_VERTICES_COUNT:uint = 65500;
		private const VERTEX_STRIDE:uint = 7;
        /**
         * @private
         */
		alternativa3d var vertexBuffers:Vector.<VertexBuffer3D>;
        /**
         * @private
         */
		alternativa3d var indexBuffers:Vector.<IndexBuffer3D>;
		private var nTriangles:Vector.<int>;
		private var vertices:Vector.<Vector.<Number>>;
		private var indices:Vector.<Vector.<uint>>;

		// Current set of pairs vertex-buffer + index-buffer, that has a place for writing.
		private var currentSetIndex:int = 0;
		private var currentSetVertexOffset:uint = 0;

		public function WireGeometry() {
			vertexBuffers = new Vector.<VertexBuffer3D>(1);
			indexBuffers = new Vector.<IndexBuffer3D>(1);
			clear();
		}

		override public function upload(context3D:Context3D):void {
			for (var i:int = 0; i <= currentSetIndex; i++) {
				if (vertexBuffers[i] != null) {
					vertexBuffers[i].dispose();
				}
				if (indexBuffers[i] != null) {
					indexBuffers[i].dispose();
				}
				if (nTriangles[i] > 0) {
					var verts:Vector.<Number> = vertices[i];
					var inds:Vector.<uint> = indices[i];
					var vBuffer:VertexBuffer3D = vertexBuffers[i] = context3D.createVertexBuffer(verts.length/VERTEX_STRIDE, VERTEX_STRIDE);
					vBuffer.uploadFromVector(verts, 0, verts.length/VERTEX_STRIDE);
					var iBuffer:IndexBuffer3D = indexBuffers[i] = context3D.createIndexBuffer(inds.length);
					iBuffer.uploadFromVector(inds, 0, inds.length);
				}
			}
		}

		override public function dispose():void {
			for (var i:int = 0; i <= currentSetIndex; i++) {
				if (vertexBuffers[i] != null) {
					vertexBuffers[i].dispose();
					vertexBuffers[i] = null;
				}
				if (indexBuffers[i] != null) {
					indexBuffers[i].dispose();
					indexBuffers[i] = null;
				}
			}
		}

		override public function get isUploaded():Boolean {
			for (var i:int = 0; i <= currentSetIndex; i++) {
				if (vertexBuffers[i] == null) {
					return false;
				}
				if (indexBuffers[i] == null) {
					return false;
				}
			}
			return true;
		}

		public function clear():void {
			dispose();
			vertices = new Vector.<Vector.<Number>>();
			indices = new Vector.<Vector.<uint>>();
			vertices[0] = new Vector.<Number>();
			indices[0] = new Vector.<uint>();
			nTriangles = new Vector.<int>(1);
			currentSetVertexOffset = 0;
		}
        /**
         * @private
         */
		alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			for (var i:int = 0, count:int = vertices.length; i < count; i++) {
				for (var j:int = 0, vcount:int = vertices[i].length; j < vcount; j += VERTEX_STRIDE) {
					var verts:Vector.<Number> = vertices[i];
					var vx:Number = verts[j];
					var vy:Number = verts[int(j + 1)];
					var vz:Number = verts[int(j + 2)];
					var x:Number, y:Number, z:Number;
					if (transform != null) {
						x = transform.a*vx + transform.b*vy + transform.c*vz + transform.d;
						y = transform.e*vx + transform.f*vy + transform.g*vz + transform.h;
						z = transform.i*vx + transform.j*vy + transform.k*vz + transform.l;
					} else {
						x = vx;
						y = vy;
						z = vz;
					}
					if (x < boundBox.minX) boundBox.minX = x;
					if (x > boundBox.maxX) boundBox.maxX = x;
					if (y < boundBox.minY) boundBox.minY = y;
					if (y > boundBox.maxY) boundBox.maxY = y;
					if (z < boundBox.minZ) boundBox.minZ = z;
					if (z > boundBox.maxZ) boundBox.maxZ = z;
				}
			}
		}
        /**
         * @private
         */
		alternativa3d function getDrawUnits(camera:Camera3D, color:Vector.<Number>, thickness:Number, object:Object3D, shader:ShaderProgram):void {
			for (var i:int = 0; i <= currentSetIndex; i++) {
				var iBuffer:IndexBuffer3D = indexBuffers[i];
				var vBuffer:VertexBuffer3D = vertexBuffers[i];
				if (iBuffer != null && vBuffer != null) {
					var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, shader.program, iBuffer, 0, nTriangles[i], shader);
					drawUnit.setVertexBufferAt(0, vBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
					drawUnit.setVertexBufferAt(1, vBuffer, 4, Context3DVertexBufferFormat.FLOAT_3);
					drawUnit.setVertexConstantsFromNumbers(0, 0, 1, -1, 0.000001);
					drawUnit.setVertexConstantsFromNumbers(1, -1/camera.focalLength, 0, camera.nearClipping, thickness);
					drawUnit.setVertexConstantsFromTransform(2, object.localToCameraTransform);
					drawUnit.setProjectionConstants(camera, 5);
					drawUnit.setFragmentConstantsFromNumbers(0, color[0], color[1], color[2], color[3]);
					if (color[3] < 1) {
						drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
						drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
						camera.renderer.addDrawUnit(drawUnit, Renderer.TRANSPARENT_SORT);
					} else {
						camera.renderer.addDrawUnit(drawUnit, Renderer.OPAQUE);
					}
				}
			}
		}

        /**
         * @private
         */
		alternativa3d function addLine(v1x:Number, v1y:Number, v1z:Number, v2x:Number, v2y:Number, v2z:Number):void {
			var currentVertices:Vector.<Number> = vertices[currentSetIndex];
			var currentIndices:Vector.<uint> = indices[currentSetIndex];
			var verticesCount:uint = currentVertices.length/VERTEX_STRIDE;
			
			if (verticesCount > (MAX_VERTICES_COUNT - 4)) {
				// Limit of vertices has been reached
				currentSetVertexOffset = 0;
				currentSetIndex++;
				nTriangles[currentSetIndex] = 0;
				currentVertices = vertices[currentSetIndex] = new Vector.<Number>();
				currentIndices = indices[currentSetIndex] = new Vector.<uint>();
				vertexBuffers.length = currentSetIndex + 1;
				indexBuffers.length = currentSetIndex + 1;
			} else {
				nTriangles[currentSetIndex] += 2;
			}
			currentVertices.push(
					v1x, v1y, v1z, 0.5, v2x, v2y, v2z,
					v2x, v2y, v2z, -0.5, v1x, v1y, v1z,
					v1x, v1y, v1z, -0.5, v2x, v2y, v2z,
					v2x, v2y, v2z, 0.5, v1x, v1y, v1z
					);
			currentIndices.push(currentSetVertexOffset, currentSetVertexOffset + 1, currentSetVertexOffset + 2,
					currentSetVertexOffset + 3, currentSetVertexOffset + 2, currentSetVertexOffset + 1);
			currentSetVertexOffset += 4;
		}

	}
}
