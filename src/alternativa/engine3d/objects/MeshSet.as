/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexStream;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class MeshSet extends Mesh {
		private var root:Object3D;

		private static const ATTRIBUTE:uint = 20;

		private var surfaceMeshes:Vector.<Vector.<Mesh>> = new Vector.<Vector.<Mesh>>();

		public static const MESHES_PER_SURFACE:uint = 30;
		private var surfaceTransformProcedures:Vector.<Procedure> = new Vector.<Procedure>();
		private var surfaceDeltaTransformProcedures:Vector.<Procedure> = new Vector.<Procedure>();

		private static var _transformProcedures:Dictionary = new Dictionary();
		private static var _deltaTransformProcedures:Dictionary = new Dictionary();

		public function MeshSet(root:Object3D) {
			this.root = root;
			calculateGeometry();
		}
        /**
         * @private
         */
		alternativa3d override function calculateVisibility(camera:Camera3D):void {
			super.alternativa3d::calculateVisibility(camera);
			if (root.transformChanged) root.composeTransforms();
			root.localToGlobalTransform.copy(root.transform);
			calculateMeshesTransforms(root);
		}
        /**
         * @private
         */
		alternativa3d override function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			drawUnit.setVertexBufferAt(vertexShader.getVariableIndex("joint"), geometry.getVertexBuffer(ATTRIBUTE), geometry._attributesOffsets[ATTRIBUTE], Context3DVertexBufferFormat.FLOAT_1);
			var index:uint = _surfaces.indexOf(surface);
			var meshes:Vector.<Mesh> = surfaceMeshes[index];
			for (var i:int = 0, count:int = meshes.length; i < count; i++) {
				var mesh:Mesh = meshes[i];
				drawUnit.setVertexConstantsFromTransform(i*3, mesh.localToGlobalTransform);
			}
		}

		private function calculateMeshesTransforms(root:Object3D):void {
			for (var child:Object3D = root.childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				// Put skin transfer matrix to localToGlobalTransform
				child.localToGlobalTransform.combine(root.localToGlobalTransform, child.transform);
				calculateMeshesTransforms(child);
			}
		}
        /**
         * @private
         */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			if (geometry == null) return;
			// Calculation of joints matrices.
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				transformProcedure = surfaceTransformProcedures[i];
				deltaTransformProcedure = surfaceDeltaTransformProcedures[i];
				if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow);
				// Mouse events
				if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
			}
			// Debug
			if (camera.debug) {
				var debug:int = camera.checkInDebug(this);
				if ((debug & Debug.BOUNDS) && boundBox != null) Debug.drawBoundBox(camera, boundBox, localToCameraTransform);
			}
		}

		private function calculateGeometry():void {
			geometry = new Geometry(0);
			addSurface(null, 0, 0);
			var numAttributes:int = 32;
			var attributesDict:Vector.<int> = new Vector.<int>(numAttributes, true);
			var attributesLengths:Vector.<int> = new Vector.<int>(numAttributes, true);
			var numMeshes:Number = collectAttributes(root, attributesDict, attributesLengths);

			var attributes:Array = [];
			var i:int;

			for (i = 0; i < numAttributes; i++) {
				if (attributesDict[i] > 0) {
					attributesLengths[i] = attributesLengths[i]/attributesDict[i];
				}
			}
			for (i = 0; i < numAttributes; i++) {
				if (Number(attributesDict[i])/numMeshes == 1) {
					for (var j:int = 0; j < attributesLengths[i]; j++) {
						attributes.push(i);
					}

				}
			}
			attributes.push(ATTRIBUTE);
			geometry.addVertexStream(attributes);
			if (root is Mesh) appendMesh(root as Mesh);
			collectMeshes(root);
			var surfaceIndex:uint = _surfaces.length - 1;
			var meshes:Vector.<Mesh> = surfaceMeshes[surfaceIndex];
			surfaceTransformProcedures[surfaceIndex] = calculateTransformProcedure(meshes.length);
			surfaceDeltaTransformProcedures[surfaceIndex] = calculateDeltaTransformProcedure(meshes.length);
		}

		private function collectAttributes(root:Object3D, attributesDict:Vector.<int>, attributesLengths:Vector.<int>):int {
			var geom:Geometry;
			var numMeshes:int = 0;
			if (root is Mesh) {
				geom = Mesh(root).geometry;

				for each (var stream:VertexStream in geom._vertexStreams) {
					var prev:int = -1;
					var attributes:Array = stream.attributes;
					for each (var attr:int in attributes) {
						attributesLengths[attr]++;
						if (attr == prev) continue;
						attributesDict[attr]++;
						prev = attr;
					}
				}
				numMeshes++;
			}

			for (var child:Object3D = root.childrenList; child != null; child = child.next) {
				numMeshes += collectAttributes(child, attributesDict, attributesLengths);
			}
			return numMeshes;
		}

		override public function addSurface(material:Material, indexBegin:uint, numTriangles:uint):Surface {
			surfaceMeshes.push(new Vector.<Mesh>());
			return super.addSurface(material, indexBegin, numTriangles);
		}

		private function collectMeshes(root:Object3D):void {
			for (var child:Object3D = root.childrenList; child != null; child = child.next) {
				if (child is Mesh) {
					appendMesh(child as Mesh);
				}
				collectMeshes(child);
			}
		}

		private function appendGeometry(geom:Geometry, index:int):void {
			var stream:VertexStream;
			var i:int, j:int;
			var length:uint = geom._vertexStreams.length;
			var numVertices:int = geom._numVertices;
			for (i = 0; i < length; i++) {
				stream = geom._vertexStreams[i];
				var attributes:Array = geometry._vertexStreams[i].attributes;
				var attribtuesLength:int = attributes.length;
				var destStream:VertexStream = geometry._vertexStreams[i];
				var newOffset:int = destStream.data.length;
				destStream.data.position = newOffset;

				stream.data.position = 0;
				var stride:int = stream.attributes.length*4;
				var destStride:int = destStream.attributes.length*4;
				for (j = 0; j < numVertices; j++) {
					var prev:int = -1;
					for (var k:int = 0; k < attribtuesLength; k++) {
						var attr:int = attributes[k];
						if (attr == ATTRIBUTE) {
							destStream.data.writeFloat(index*3);
							continue;
						}
						if (attr != prev) {
							stream.data.position = geom._attributesOffsets[attr]*4 + stride*j;
							destStream.data.position = newOffset + geometry._attributesOffsets[attr]*4 + destStride*j;
						}
						destStream.data.writeFloat(stream.data.readFloat());
						prev = attr;
					}
				}

			}
			geometry._numVertices += geom._numVertices;

		}

		private function compareAttribtues(destStream:VertexStream, sourceStream:VertexStream):Boolean {
			if ((destStream.attributes.length - 1) != sourceStream.attributes.length) return false;
			var len:int = sourceStream.attributes.length;
			for (var i:int = 0; i < len; i++) {
				if (destStream.attributes[i] != sourceStream.attributes[i]) return false;
			}
			return true;
		}

		private function appendMesh(mesh:Mesh):void {
			var surfaceIndex:uint = _surfaces.length - 1;
			var destSurface:Surface = _surfaces[surfaceIndex];
			var meshes:Vector.<Mesh> = surfaceMeshes[surfaceIndex];
			if (meshes.length >= MESHES_PER_SURFACE) {
				surfaceTransformProcedures[surfaceIndex] = calculateTransformProcedure(meshes.length);
				surfaceDeltaTransformProcedures[surfaceIndex] = calculateDeltaTransformProcedure(meshes.length);
				addSurface(null, geometry._indices.length, 0);
				surfaceIndex++;
				destSurface = _surfaces[surfaceIndex];
				meshes = surfaceMeshes[surfaceIndex];
			}
			meshes.push(mesh);
			var geom:Geometry = mesh.geometry;
			var vertexOffset:uint;
			var i:int, j:int;
			vertexOffset = geometry._numVertices;
			appendGeometry(geom, meshes.length - 1);
			trace(surfaceIndex);
			// Copy indexes
			for (i = 0; i < mesh._surfacesLength; i++) {
				var surface:Surface = mesh._surfaces[i];
				var indexEnd:uint = surface.numTriangles*3 + surface.indexBegin;
				destSurface.numTriangles += surface.numTriangles;
				for (j = surface.indexBegin; j < indexEnd; j++) {
					geometry._indices.push(geom._indices[j] + vertexOffset);
				}
			}
		}

		private function calculateTransformProcedure(numMeshes:int):Procedure {
			var res:Procedure = _transformProcedures[numMeshes];
			if (res != null) return res;
			res = _transformProcedures[numMeshes] = new Procedure(null, "MeshSetTransformProcedure");
			res.compileFromArray(["#a0=joint", "m34 o0.xyz, i0, c[a0.x]", "mov o0.w, i0.w"]);
			res.assignConstantsArray(numMeshes*3);
			return res;
		}

		private function calculateDeltaTransformProcedure(numMeshes:int):Procedure {
			var res:Procedure = _deltaTransformProcedures[numMeshes];
			if (res != null) return res;
			res = _deltaTransformProcedures[numMeshes] = new Procedure(null, "MeshSetDeltaTransformProcedure");
			res.compileFromArray(["#a0=joint", "m33 o0.xyz, i0, c[a0.x]", "mov o0.w, i0.w"]);
			return res;
		}
	}
}
