/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.A3DUtils;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.WireGeometry;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	use namespace alternativa3d;

	/**
	 * Wireframe is an <code>Object3D</code> which consists of solid lines. Line draws  with z-buffer but has no perspective correction, so it has fixed thickness.
	 * Wireframe can be built on <code>Mesh</code> geometry as well as on sequence of points.
	 */
	public class WireFrame extends Object3D {

		private static const cachedPrograms:Dictionary = new Dictionary(true);
		/**
		 * @private
		 */
		alternativa3d var shaderProgram:ShaderProgram;
		private var cachedContext3D:Context3D;

		private static function initProgram():ShaderProgram {
			var vertexShader:Linker = new Linker(Context3DProgramType.VERTEX);
			var transform:Procedure = new Procedure();
			transform.compileFromArray([
				"mov t0, a0", // it is because  a0.w holds offset direction
				"mov t0.w, c0.y", // replace w with 1
				"m34 t0.xyz, t0, c2", // Transform  p0 to the camera coordinates
				"m34 t1.xyz, a1, c2", //  Transform  p1 to the camera coordinates
				"sub t2, t1.xyz, t0.xyz", // L = p1 - p0
				 // if point places behind the camera, it need to be cut to point lies in the nearClipping plane
				"slt t5.x, t0.z, c1.z",	// behind = (Q0.z < Camera.near) ? 1 : 0
				"sub t5.y, c0.y, t5.x",	// !behind = 1 - behind
				//find intersection point of section and nearClipping plane
				"add t4.x, t0.z, c0.z", // p0.z + Camera.nearCliping
				"sub t4.y, t0.z, t1.z", // p0.z - p1.z
				"add t4.y, t4.y, c0.w", // Add some small value for cases of Q0.z = Q1.z
				"div t4.z, t4.x, t4.y", // t = ( p0.z - near ) / ( p0.z - p1.z )
				"mul t4.xyz, t4.zzz, t2.xyz", // t(L)
				"add t3.xyz, t0.xyz, t4.xyz", // pClipped = p0 + t(L)
				// Clip p0
				"mul t0, t0, t5.y", // !behind * p0
				"mul t3.xyz, t3.xyz, t5.x", // behind * pClipped
				"add t0, t0, t3.xyz", // newp0 = p0 + pClipped
				// Calculate vector of thickness direction
				"sub t2, t1.xyz, t0.xyz", // L = p1 - p0
				"crs t3.xyz, t2, t0",	// S = L x D
				"nrm t3.xyz, t3.xyz",	// normalize( S )
				"mul t3.xyz, t3.xyz, a0.w",	// Direction correction
				"mul t3.xyz, t3.xyz, c1.w", // S *= weight
				// Scale vector depends on distance to the camera
				"mul t4.x, t0.z, c1.x", // distance *= vpsod
				"mul t3.xyz, t3.xyz, t4.xxx",	// S.xyz *= pixelScaleFactor
				"add t0.xyz, t0.xyz, t3.xyz",	// p0 + S
				"m44 o0, t0, c5"	// projection
			]);
			transform.assignVariableName(VariableType.ATTRIBUTE, 0, "pos1");
			transform.assignVariableName(VariableType.ATTRIBUTE, 1, "pos2");
			transform.assignVariableName(VariableType.CONSTANT, 0, "ZERO");
			transform.assignVariableName(VariableType.CONSTANT, 1, "consts");
			transform.assignVariableName(VariableType.CONSTANT, 2, "worldView", 3);
			transform.assignVariableName(VariableType.CONSTANT, 5, "proj", 4);
			vertexShader.addProcedure(transform);
			vertexShader.link();

			var fragmentShader:Linker = new Linker(Context3DProgramType.FRAGMENT);
			var fp:Procedure = new Procedure();
			fp.compileFromArray(["mov o0, c0"]);
			fp.assignVariableName(VariableType.CONSTANT, 0, "color");
			fragmentShader.addProcedure(fp);
			fragmentShader.link();
			
			return new ShaderProgram(vertexShader, fragmentShader);
		}

		/**
		 * Thickness.
		 */
		public var thickness:Number = 1;

		/**
		 * @private 
		 */
		alternativa3d var _colorVec:Vector.<Number> = new Vector.<Number>(4, true);
		/**
		 * @private 
		 */
		alternativa3d var geometry:WireGeometry;

		/**
		 * The constructor did not make any geometry, so if you need class instance - use static methods  <code>createLinesList()</code>,
		 * <code>createLineStrip()</code> and <code>createEdges()</code> which return one.
		 *
		 * @see #createLinesList()
		 * @see #createLineStrip()
		 * @see #createEdges()
		 */
		public function WireFrame(color:uint = 0, alpha:Number = 1, thickness:Number = 0.5) {
			this.color = color;
			this.alpha = alpha;
			this.thickness = thickness;
			geometry = new WireGeometry();
		}

		/**
		 * Transparency.
		 */
		public function get alpha():Number {
			return _colorVec[3];
		}

		/**
		 * @private
		 */
		public function set alpha(value:Number):void {
			_colorVec[3] = value;
		}

		/**
		 * Color
		 */
		public function get color():uint {
			return (_colorVec[0]*255 << 16) | (_colorVec[1]*255 << 8) | (_colorVec[2]*255);
		}

		/**
		 * @private
		 */
		public function set color(value:uint):void {
			_colorVec[0] = ((value >> 16) & 0xff)/255;
			_colorVec[1] = ((value >> 8) & 0xff)/255;
			_colorVec[2] = (value & 0xff)/255;

		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (geometry != null) {
				geometry.updateBoundBox(boundBox, transform);
			}
		}

		/**
		 * @private 
		 */
		alternativa3d override function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				shaderProgram = cachedPrograms[cachedContext3D];
				if (shaderProgram == null) {
					shaderProgram = initProgram();
					shaderProgram.upload(cachedContext3D);
					cachedPrograms[cachedContext3D] = shaderProgram;
				}
			}
			geometry.getDrawUnits(camera, _colorVec, thickness, this, shaderProgram);
		}

		/**
		 * @private 
		 */
		alternativa3d override function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			super.fillResources(resources, hierarchy, resourceType);
			if (A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(geometry)) as Class, resourceType)) {
				resources[geometry] = true;
			}
		}

		/**
		 * Creates and returns a new WireFrame instance consists of segments for each couple of points in the given array.
		 *
		 * @param points Set of point couples. One point of couple defines start of line segment and another one - end of the line.
		 * @param color  Color of the line.
		 * @param alpha Transparency.
		 * @param thickness Thickness.
		 * @return A new WireFrame instance.
		 */
		public static function createLinesList(points:Vector.<Vector3D>, color:uint = 0, alpha:Number = 1, thickness:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var p0:Vector3D;
			var p1:Vector3D;
			var geometry:WireGeometry = result.geometry;
			for (var i:uint = 0, count:uint = points.length - 1; i < count; i += 2) {
				p0 = points[i];
				p1 = points[i + 1];
				geometry.addLine(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z);
			}
			result.calculateBoundBox();
			return result;
		}

		/**
		 * Creates  and returns a new WireFrame instance of solid line built on point sequence.
		 *
		 * @param points   Point sequence.
		 * @param color  Color of the line.
		 * @param alpha Transparency.
		 * @param thickness Thickness.
		 * @return A new WireFrame instance.
		 */
		public static function createLineStrip(points:Vector.<Vector3D>, color:uint = 0, alpha:Number = 1, thickness:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var p0:Vector3D;
			var p1:Vector3D;
			var geometry:WireGeometry = result.geometry;
			for (var i:uint = 0, count:uint = points.length - 1; i < count; i++) {
				// TODO : don't get vector value twice
				p0 = points[i];
				p1 = points[i + 1];
				geometry.addLine(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z);
			}
			result.calculateBoundBox();
			return result;
		}

		/**
		 * Creates  and returns a new WireFrame instance built on edges of given <code>Mesh</code>.
		 * 
		 * @param mesh Source of geometry.
		 * @param color  Color of the line.
		 * @param alpha Transparency.
		 * @param thickness Thickness.
		 * @return A new WireFrame instance.
		 */
		public static function createEdges(mesh:Mesh, color:uint = 0, alpha:Number = 1, thickness:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var geometry:Geometry = mesh.geometry;
			var resultGeometry:WireGeometry = result.geometry;
			var edges:Dictionary = new Dictionary();
			var indices:Vector.<uint> = geometry.indices;
			var vertices:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.POSITION);
			// Loop over all the faces of mesh, create lines like 0-1-2-0
			for (var i:int = 0, count:int = indices.length; i < count; i += 3) {
				var index:uint = indices[i]*3;
				var v1x:Number = vertices[index];
				index++;
				var v1y:Number = vertices[index];
				index++;
				var v1z:Number = vertices[index];
				index = indices[int(i + 1)]*3;
				var v2x:Number = vertices[index];
				index++;
				var v2y:Number = vertices[index];
				index++;
				var v2z:Number = vertices[index];
				index = indices[int(i + 2)]*3;
				var v3x:Number = vertices[index];
				index++;
				var v3y:Number = vertices[index];
				index++;
				var v3z:Number = vertices[index];
				if (checkEdge(edges, v1x, v1y, v1z, v2x, v2y, v2z)) {
					resultGeometry.addLine(v1x, v1y, v1z, v2x, v2y, v2z);
				}
				if (checkEdge(edges, v2x, v2y, v2z, v3x, v3y, v3z)) {
					resultGeometry.addLine(v2x, v2y, v2z, v3x, v3y, v3z);
				}
				if (checkEdge(edges, v1x, v1y, v1z, v3x, v3y, v3z)) {
					resultGeometry.addLine(v1x, v1y, v1z, v3x, v3y, v3z);
				}
			}
			result.calculateBoundBox();
			result._x = mesh._x;
			result._y = mesh._y;
			result._z = mesh._z;
			result._rotationX = mesh._rotationX;
			result._rotationY = mesh._rotationY;
			result._rotationZ = mesh._rotationZ;
			result._scaleX = mesh._scaleX;
			result._scaleY = mesh._scaleY;
			result._scaleZ = mesh._scaleZ;
			return result;
		}
        /**
         * @private
         */
		alternativa3d static function createNormals(mesh:Mesh, color:uint = 0, alpha:Number = 1, thickness:Number = 1, length:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var geometry:Geometry = mesh.geometry;
			var resultGeometry:WireGeometry = result.geometry;
			var vertices:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.POSITION);
			var normals:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.NORMAL);
			var numVertices:uint = geometry._numVertices;
			for (var i:int = 0; i < numVertices; i++) {
				var index:uint = i*3;
				resultGeometry.addLine(
						vertices[index], vertices[int(index + 1)], vertices[int(index + 2)],
						vertices[index] + normals[index]*length, vertices[int(index + 1)] + normals[int(index + 1)]*length, vertices[int(index + 2)] + normals[int(index + 2)]*length);
			}
			result.calculateBoundBox();
			result._x = mesh._x;
			result._y = mesh._y;
			result._z = mesh._z;
			result._rotationX = mesh._rotationX;
			result._rotationY = mesh._rotationY;
			result._rotationZ = mesh._rotationZ;
			result._scaleX = mesh._scaleX;
			result._scaleY = mesh._scaleY;
			result._scaleZ = mesh._scaleZ;
			return result;
		}

		/**
		 * @private
		 */
		alternativa3d static function createTangents(mesh:Mesh, color:uint = 0, alpha:Number = 1, thickness:Number = 1, length:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var geometry:Geometry = mesh.geometry;
			var resultGeometry:WireGeometry = result.geometry;
			var vertices:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.POSITION);
			var tangents:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.TANGENT4);
			var numVertices:uint = geometry._numVertices;
			for (var i:int = 0; i < numVertices; i++) {
				var index:uint = i*3;
				resultGeometry.addLine(
						vertices[index], vertices[int(index + 1)], vertices[int(index + 2)],
						vertices[index] + tangents[int(i*4)]*length, vertices[int(index + 1)] + tangents[int(i*4 + 1)]*length, vertices[int(index + 2)] + tangents[int(i*4 + 2)]*length);
			}
			result.calculateBoundBox();
			result._x = mesh._x;
			result._y = mesh._y;
			result._z = mesh._z;
			result._rotationX = mesh._rotationX;
			result._rotationY = mesh._rotationY;
			result._rotationZ = mesh._rotationZ;
			result._scaleX = mesh._scaleX;
			result._scaleY = mesh._scaleY;
			result._scaleZ = mesh._scaleZ;
			return result;
		}

		/**
		 * @private
		 */
		alternativa3d static function createBinormals(mesh:Mesh, color:uint = 0, alpha:Number = 1, thickness:Number = 1, length:Number = 1):WireFrame {
			var result:WireFrame = new WireFrame(color, alpha, thickness);
			var geometry:Geometry = mesh.geometry;
			var resultGeometry:WireGeometry = result.geometry;
			var vertices:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.POSITION);
			var tangents:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.TANGENT4);
			var normals:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.NORMAL);
			var numVertices:uint = geometry._numVertices;
			for (var i:int = 0; i < numVertices; i++) {
				var index:uint = i*3;
				var normal:Vector3D = new Vector3D(normals[index], normals[int(index + 1)], normals[int(index + 2)]);
				var tangent:Vector3D = new Vector3D(tangents[int(i*4)], tangents[int(i*4 + 1)], tangents[int(i*4 + 2)]);
				var binormal:Vector3D = normal.crossProduct(tangent);

				binormal.scaleBy(tangents[int(i*4 + 3)]);
				binormal.normalize();
				resultGeometry.addLine(
						vertices[index], vertices[int(index + 1)], vertices[int(index + 2)],
						vertices[index] + binormal.x*length, vertices[int(index + 1)] + binormal.y*length, vertices[int(index + 2)] + binormal.z*length);
			}
			result.calculateBoundBox();
			result._x = mesh._x;
			result._y = mesh._y;
			result._z = mesh._z;
			result._rotationX = mesh._rotationX;
			result._rotationY = mesh._rotationY;
			result._rotationZ = mesh._rotationZ;
			result._scaleX = mesh._scaleX;
			result._scaleY = mesh._scaleY;
			result._scaleZ = mesh._scaleZ;
			return result;
		}

		private static function checkEdge(edges:Dictionary, v1x:Number, v1y:Number, v1z:Number, v2x:Number, v2y:Number, v2z:Number):Boolean {
			var str:String;
			if (v1x*v1x + v1y*v1y + v1z*v1z < v2x*v2x + v2y*v2y + v2z*v2z) {
				str = v1x.toString() + v1y.toString() + v1z.toString() + v2x.toString() + v2y.toString() + v2z.toString();
			} else {
				str = v2x.toString() + v2y.toString() + v2z.toString() + v1x.toString() + v1y.toString() + v1z.toString();
			}
			if (edges[str]) return false;
			edges[str] = true;
			return true;
		}
		
	}
}
