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
	 * AxisAlignedSprite is a flat image which keeps vertical orientation but able to revolve on its own z-axis. Z-rotation defines by relative position of  a sprite and a camera.
	 * AxisAlignedSprite can look to the camera as well as keep the same direction with it. In the first case normal of  the sprite point to the camera,
	 * and normal is  parallel with z-axis of the camera in second case.  Set <code>alignToView</code> to <code>true</code> for the second case and <code>false</code> otherwise.
	 *  Please note,  if z-axis of the AxisAlignedSprite point to the camera, you will not able see it.
	 */
	public class AxisAlignedSprite extends Object3D {

		static private const geometries:Dictionary = new Dictionary();

		static private var transformProcedureStatic:Procedure = new Procedure([
			// Pivot
			"sub t0.x, i0.x, c0.x",
			"add t0.z, i0.z, c0.y",
			// Width and height
			"mul t0.x, t0.x, c0.z",
			"mul o0.z, t0.z, c0.w",
			// Rotation
			"mov t1.z, c1.x",
			"sin t1.x, t1.z", // sin
			"cos t1.y, t1.z", // cos
			"mul o0.x, t0.x, t1.y", // x*cos
			"mul o0.y, t0.x, t1.x", // x*sin
			"mov o0.w, i0.w",
			// Declaration
			"#c0=size", // originX, originY, width, height
			"#c1=rotation", // angle, 0, 0, 1
		]);

		static private var deltaTransformProcedureStatic:Procedure = new Procedure([
			// Rotation
			"mov t1.z, c1.x",
			"sin t1.x, t1.z", // sin
			"neg t1.x, t1.x",
			"cos t1.y, t1.z", // cos
			"mul o0.x, i0.y, t1.x", // y*sin
			"mul o0.y, i0.y, t1.y", // y*cos
			"mov o0.z, i0.z",
			"mov o0.w, i0.w",
			// Declaration
			"#c0=size", // originX, originY, width, height
			"#c1=rotation", // angle, 0, 0, 1
		]);

		/**
		 * Horizontal coordinate in the AxisAlignedSprite plane which defines what part of the plane will placed in x = 0 of  the  AxisAlignedSprite object. The dimension considered with UV-coordinates.
		 * Thus, if <code>originX = 0</code>, image will drawn from 0 to the right, if <code>originX = -1</code> – to the left.
		 * And image will drawn in the center of the <code>AxisAlignedSprite</code>, if <code>originX = 0.5</code>.
		 */
		public var originX:Number = 0.5;

		/**
		 * Vertical coordinate in the AxisAlignedSprite plane which defines what part of the plane will placed in y = 0 of  the  AxisAlignedSprite object. The dimension considered with UV-coordinates.
		 * Thus, if <code>originY = 0</code>, image will drawn from 0 to the bottom, if <code>originY = -1</code> – to the top.
		 * And image will drawn in the center of the <code>AxisAlignedSprite</code>, if <code>originY = 0.5</code>.
		 */
		public var originY:Number = 0.5;

		/**
		 * Width
		 */
		public var width:Number;

		/**
		 * Height
		 */
		public var height:Number;

		/**
		 * If <code>true</code>, the normal of the  AxisAlignedSprite will be parallel to z-axis of the camera, otherwise the normal will point to the camera.
		 */
		public var alignToView:Boolean = true;

		/**
		 * @private
		 */
		alternativa3d var surface:Surface;

		/**
		 * Creates a new AxisAlignedSprite instance.
		 * @param width Width
		 * @param height Height
		 * @param material The material.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function AxisAlignedSprite(width:Number, height:Number, material:Material = null) {
			this.width = width;
			this.height = height;
			surface = new Surface();
			surface.object = this;
			this.material = material;
			surface.indexBegin = 0;
			surface.numTriangles = 2;
			// Transform position to the local space
			transformProcedure = transformProcedureStatic;
			// Transform vector to the local space
			deltaTransformProcedure = deltaTransformProcedureStatic;
		}

		/**
		 * Material of a sprite.
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
			if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, -1);
			// Mouse events
			if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
		}

		/**
		 * @private
		 */
		override alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			// Set constants
			drawUnit.setVertexConstantsFromNumbers(0, originX, originY, width, height);
			if (alignToView || camera.orthographic) {
				drawUnit.setVertexConstantsFromNumbers(1, Math.PI - Math.atan2(-cameraToLocalTransform.c, -cameraToLocalTransform.g), 0, 0, 1);
			} else {
				drawUnit.setVertexConstantsFromNumbers(1, Math.PI - Math.atan2(cameraToLocalTransform.d, cameraToLocalTransform.h), 0, 0, 1);
			}
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

				geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 0, 0, 0, -1, 1, 0, -1, 1, 0, 0]));
				geometry.setAttributeValues(VertexAttributes.NORMAL, Vector.<Number>([0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0]));
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
			var res:AxisAlignedSprite = new AxisAlignedSprite(width, height);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:AxisAlignedSprite = source as AxisAlignedSprite;
			width = src.width;
			height = src.height;
			material = src.material;
			originX = src.originX;
			originY = src.originY;
			alignToView = src.alignToView;
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (transform != null) {
				// TODO:
			}
			var radius:Number = ((originX >= 0.5) ? originX : (1 - originX))*width;
			var top:Number = originY*height;
			var bottom:Number = (originY - 1)*height;
			if (-radius < boundBox.minX) boundBox.minX = -radius;
			if (radius > boundBox.maxX) boundBox.maxX = radius;
			if (-radius < boundBox.minY) boundBox.minY = -radius;
			if (radius > boundBox.maxY) boundBox.maxY = radius;
			if (bottom < boundBox.minZ) boundBox.minZ = bottom;
			if (top > boundBox.maxZ) boundBox.maxZ = top;
		}
	}
}
