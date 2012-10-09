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
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 *  Sprite3D is a flat <code>Object3D</code> always turned in to the camera.
	 */
	public class Sprite3D extends Object3D {
		static private const geometries:Dictionary = new Dictionary();

		static private var transformProcedureStatic:Procedure = new Procedure([
			// Pivot
			"sub t0.z, i0.x, c3.x",
			"sub t0.w, i0.y, c3.y",
			// Width and height
			"mul t0.z, t0.z, c3.z",
			"mul t0.w, t0.w, c3.w",
			// Rotation
			"mov t1.z, c4.w",
			"sin t1.x, t1.z", // sin
			"cos t1.y, t1.z", // cos
			"mul t1.z, t0.z, t1.y", // x*cos
			"mul t1.w, t0.w, t1.x", // y*sin
			"sub t0.x, t1.z, t1.w", // X
			"mul t1.z, t0.z, t1.x", // x*sin
			"mul t1.w, t0.w, t1.y", // y*cos
			"add t0.y, t1.z, t1.w", // Y
			// Offset
			"add t0.x, t0.x, c4.x",
			"add t0.y, t0.y, c4.y",
			"add t0.z, i0.z, c4.z",
			"mov t0.w, i0.w",
			// Transform to local coordinates
			"dp4 o0.x, t0, c0",
			"dp4 o0.y, t0, c1",
			"dp4 o0.z, t0, c2",
			"mov o0.w, t0.w",
			// Declaration
			"#c0=trans1",
			"#c1=trans2",
			"#c2=trans3",
			"#c3=size", // originX, originY, width, height
			"#c4=coords", // x, y, z, rotation
		]);

		static private var deltaTransformProcedureStatic:Procedure = new Procedure([
			// Rotation
			"mov t1.z, c4.w",
			"sin t1.x, t1.z", // sin
			"cos t1.y, t1.z", // cos
			"mul t1.z, i0.x, t1.y", // x*cos
			"mul t1.w, i0.y, t1.x", // y*sin
			"sub t0.x, t1.z, t1.w", // X
			"mul t1.z, i0.x, t1.x", // x*sin
			"mul t1.w, i0.y, t1.y", // y*cos
			"add t0.y, t1.z, t1.w", // Y
			"mov t0.z, i0.z",
			"mov t0.w, i0.w",
			// Transform to local coordinates
			"dp3 o0.x, t0, c0",
			"dp3 o0.y, t0, c1",
			"dp3 o0.z, t0, c2",
			// Declaration
			"#c0=trans1",
			"#c1=trans2",
			"#c2=trans3",
			"#c3=size", // originX, originY, width, height
			"#c4=coords" // x, y, z, rotation
		]);

		/**
		 * Horizontal coordinate in the Sprite3D plane which defines what part of the plane will placed in x = 0 of  the  Sprite3D object. The dimension considered with UV-coordinates.
		 * Thus, if <code>originX = 0</code>, image will drawn from 0 to the right, if <code>originX = -1</code> – to the left.
		 * And image will drawn in the center of the <code>Sprite3D</code>, if <code>originX = 0.5</code>.
		 */
		public var originX:Number = 0.5;

		/**
		 * Vertical coordinate in the Sprite3D plane which defines what part of the plane will placed in y = 0 of  the  Sprite3D object. The dimension considered with UV-coordinates.
		 * Thus, if <code>originY = 0</code>, image will drawn from 0 to the bottom, if <code>originY = -1</code> – to the top.
		 * And image will drawn in the center of the <code>Sprite3D</code>, if <code>originY = 0.5</code>.
		 */
		public var originY:Number = 0.5;
		/**
		 * Rotation in the screen plane, defines in radians.
		 */
		public var rotation:Number = 0;

		/**
		 * Width.
		 */
		public var width:Number;
		/**
		 * Height.
		 */
		public var height:Number;

		/**
		 * If <code>true</code>, screen size of a Sprite3D will have perspective correction according to distance to a camera. Otherwise Sprite3D will have fixed size with no dependence on point of view.
		 */
		public var perspectiveScale:Boolean = true;

		/**
		 * If <code>true</code>, Sprite3D will drawn over all the rest objects which uses z-buffer sorting.
		 */
		public var alwaysOnTop:Boolean = false;

		/**
		 * @private
		 */
		alternativa3d var surface:Surface;

		/**
		 * Creates a new Sprite3D instance.
		 * @param width Width.
		 * @param height Height
		 * @param material Material.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function Sprite3D(width:Number, height:Number, material:Material = null) {
			this.width = width;
			this.height = height;
			surface = new Surface();
			surface.object = this;
			this.material = material;
			surface.indexBegin = 0;
			surface.numTriangles = 2;
			// Transform to the local space
			transformProcedure = transformProcedureStatic;
			// Transformation of the vector to the local space.
			deltaTransformProcedure = deltaTransformProcedureStatic;
		}

		/**
		 * Material of the Sprite3D.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function get material():Material {
			return surface.material;
		}

		/**
		 * @private
		 */
		public function set material(value:Material):void {
			surface.material = value;
		}

		/**
		 * @private
		 */
		alternativa3d override function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (surface.material != null) surface.material.fillResources(resources, resourceType);
			super.fillResources(resources, hierarchy, resourceType);
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			var geometry:Geometry = getGeometry(camera.context3D);
			if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, alwaysOnTop ? Renderer.NEXT_LAYER : -1);
			// Mouse events.
			if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
		}

		/**
		 * @private
		 */
		override alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			// Average size
			var scale:Number = Math.sqrt(localToCameraTransform.a*localToCameraTransform.a + localToCameraTransform.e*localToCameraTransform.e + localToCameraTransform.i*localToCameraTransform.i);
			scale += Math.sqrt(localToCameraTransform.b*localToCameraTransform.b + localToCameraTransform.f*localToCameraTransform.f + localToCameraTransform.j*localToCameraTransform.j);
			scale += Math.sqrt(localToCameraTransform.c*localToCameraTransform.c + localToCameraTransform.g*localToCameraTransform.g + localToCameraTransform.k*localToCameraTransform.k);
			scale /= 3;
			// Distance dependence
			if (!perspectiveScale && !camera.orthographic) scale *= localToCameraTransform.l/camera.focalLength;
			// Set the constants
			drawUnit.setVertexConstantsFromTransform(0, cameraToLocalTransform);
			drawUnit.setVertexConstantsFromNumbers(3, originX, originY, width*scale, height*scale);
			drawUnit.setVertexConstantsFromNumbers(4, localToCameraTransform.d, localToCameraTransform.h, localToCameraTransform.l, rotation);
		}

		/**
		 * @private
		 */
		alternativa3d function getGeometry(context:Context3D):Geometry {
			var geometry:Geometry = geometries[context];
			if (geometry == null) {
				geometry = new Geometry(4);

				var attributes:Array = [];
				attributes[0] = VertexAttributes.POSITION;
				attributes[1] = VertexAttributes.POSITION;
				attributes[2] = VertexAttributes.POSITION;
				attributes[3] = VertexAttributes.NORMAL;
				attributes[4] = VertexAttributes.NORMAL;
				attributes[5] = VertexAttributes.NORMAL;
				attributes[6] = VertexAttributes.TEXCOORDS[0];
				attributes[7] = VertexAttributes.TEXCOORDS[0];
				attributes[8] = VertexAttributes.TEXCOORDS[1];
				attributes[9] = VertexAttributes.TEXCOORDS[1];
				attributes[10] = VertexAttributes.TEXCOORDS[2];
				attributes[11] = VertexAttributes.TEXCOORDS[2];
				attributes[12] = VertexAttributes.TEXCOORDS[3];
				attributes[13] = VertexAttributes.TEXCOORDS[3];
				attributes[14] = VertexAttributes.TEXCOORDS[4];
				attributes[15] = VertexAttributes.TEXCOORDS[4];
				attributes[16] = VertexAttributes.TEXCOORDS[5];
				attributes[17] = VertexAttributes.TEXCOORDS[5];
				attributes[18] = VertexAttributes.TEXCOORDS[6];
				attributes[19] = VertexAttributes.TEXCOORDS[6];
				attributes[20] = VertexAttributes.TEXCOORDS[7];
				attributes[21] = VertexAttributes.TEXCOORDS[7];
				attributes[22] = VertexAttributes.TANGENT4;
				attributes[23] = VertexAttributes.TANGENT4;
				attributes[24] = VertexAttributes.TANGENT4;
				attributes[25] = VertexAttributes.TANGENT4;
				geometry.addVertexStream(attributes);

				geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0]));
				geometry.setAttributeValues(VertexAttributes.NORMAL, Vector.<Number>([0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[1], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[2], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[3], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[4], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[5], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[6], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				geometry.setAttributeValues(VertexAttributes.TEXCOORDS[7], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));

				geometry.indices = Vector.<uint>([0, 1, 3, 2, 3, 1]);

				geometry.upload(context);
				geometries[context] = geometry;
			}
			return geometry;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Sprite3D = new Sprite3D(width, height);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Sprite3D = source as Sprite3D;
			width = src.width;
			height = src.height;
			// autoSize = src.autoSize;
			material = src.material;
			originX = src.originX;
			originY = src.originY;
			rotation = src.rotation;
			perspectiveScale = src.perspectiveScale;
			alwaysOnTop = src.alwaysOnTop;
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			var ww:Number = width;
			var hh:Number = height;
			// Calculate local radius.
			var w:Number = ((originX >= 0.5) ? originX : (1 - originX))*ww;
			var h:Number = ((originY >= 0.5) ? originY : (1 - originY))*hh;
			var radius:Number = Math.sqrt(w*w + h*h);
			var cx:Number = 0;
			var cy:Number = 0;
			var cz:Number = 0;
			if (transform != null) {
				// Find average size
				var ax:Number = transform.a;
				var ay:Number = transform.e;
				var az:Number = transform.i;
				var size:Number = Math.sqrt(ax*ax + ay*ay + az*az);
				ax = transform.b;
				ay = transform.f;
				az = transform.j;
				size += Math.sqrt(ax*ax + ay*ay + az*az);
				ax = transform.c;
				ay = transform.g;
				az = transform.k;
				size += Math.sqrt(ax*ax + ay*ay + az*az);
				radius *= size/3;
				cx = transform.d;
				cy = transform.h;
				cz = transform.l;
			}
			if (cx - radius < boundBox.minX) boundBox.minX = cx - radius;
			if (cx + radius > boundBox.maxX) boundBox.maxX = cx + radius;
			if (cy - radius < boundBox.minY) boundBox.minY = cy - radius;
			if (cy + radius > boundBox.maxY) boundBox.maxY = cy + radius;
			if (cz - radius < boundBox.minZ) boundBox.minZ = cz - radius;
			if (cz + radius > boundBox.maxZ) boundBox.maxZ = cz + radius;
		}
	}
}
