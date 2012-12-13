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
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;

	use namespace alternativa3d;
	
	/**
	 * A polygonal box with faces turned inside. It did not cut on <code>farClipping</code>  distance and it is  difference with <code>Box</code>.
	 *
	 * @see alternativa.engine3d.core.Camera3D#farClipping
	 */
	public class SkyBox extends Mesh {
		
		/**
		 * Left side.
		 */
		static public const LEFT:String = "left";
		
		/**
		 * Right side.
		 */
		static public const RIGHT:String = "right";
		
		/**
		 * Back side.
		 */
		static public const BACK:String = "back";
		
		/**
		 * Front side.
		 */
		static public const FRONT:String = "front";
		
		/**
		 * Bottom side.
		 */
		static public const BOTTOM:String = "bottom";
		
		/**
		 * Top side..
		 */
		static public const TOP:String = "top";
		
		static private var transformProcedureStatic:Procedure  = new Procedure([
			// Offset
			"sub t0.xyz, i0.xyz, c0.xyz",
			// Scale
			"mul t0.x, t0.x, c0.w",
			"mul t0.y, t0.y, c0.w",
			"mul t0.z, t0.z, c0.w",
			// Back offset
			"add o0.xyz, t0.xyz, c0.xyz",
			"mov o0.w, i0.w",
			// Declaration
			"#c0=cTrans", // Camera position and scale
		]);

		private var leftSurface:Surface;
		private var rightSurface:Surface;
		private var backSurface:Surface;
		private var frontSurface:Surface;
		private var bottomSurface:Surface;
		private var topSurface:Surface;
		
		private var halfSize:Number;

		/**
		 * Creates a new SkyBox instance.
		 * @param size Length of each edge.
		 * @param left Material of the left side.
		 * @param right Material of the right side.
		 * @param back Material of the back side.
		 * @param front Material of the front side.
		 * @param bottom Material of the bottom side.
		 * @param top Material of the top side.
		 * @param uvPadding Texture padding in UV space.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function SkyBox(size:Number, left:Material = null, right:Material = null, back:Material = null, front:Material = null, bottom:Material = null, top:Material = null, uvPadding:Number = 0) {
			this.halfSize = size*0.5;

			geometry = new Geometry(24);

			var attributes:Array = [];
			attributes[0] = VertexAttributes.POSITION;
			attributes[1] = VertexAttributes.POSITION;
			attributes[2] = VertexAttributes.POSITION;
			attributes[6] = VertexAttributes.TEXCOORDS[0];
			attributes[7] = VertexAttributes.TEXCOORDS[0];
			geometry.addVertexStream(attributes);

			geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([
				-halfSize, -halfSize, halfSize,
				-halfSize, -halfSize, -halfSize,
				-halfSize, halfSize, -halfSize,
				-halfSize, halfSize, halfSize,

				halfSize, halfSize, halfSize,
				halfSize, halfSize, -halfSize,
				halfSize, -halfSize, -halfSize,
				halfSize, -halfSize, halfSize,

				halfSize, -halfSize, halfSize,
				halfSize, -halfSize, -halfSize,
				-halfSize, -halfSize, -halfSize,
				-halfSize, -halfSize, halfSize,
				
				-halfSize, halfSize, halfSize,
				-halfSize, halfSize, -halfSize,
				halfSize, halfSize, -halfSize,
				halfSize, halfSize, halfSize,
				
				-halfSize, halfSize, -halfSize,
				-halfSize, -halfSize, -halfSize,
				halfSize, -halfSize, -halfSize,
				halfSize, halfSize, -halfSize,
				
				-halfSize, -halfSize, halfSize,
				-halfSize, halfSize, halfSize,
				halfSize, halfSize, halfSize,
				halfSize, -halfSize, halfSize
			]));
			
			geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding,
				
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding,
				
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding,
				
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding,
				
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding,
				
				uvPadding, uvPadding,
				uvPadding, 1 - uvPadding,
				1 - uvPadding, 1 - uvPadding,
				1 - uvPadding, uvPadding
			]));

			geometry.indices = Vector.<uint>([
				0, 1, 3, 2, 3, 1,
				4, 5, 7, 6, 7, 5,
				8, 9, 11, 10, 11, 9,
				12, 13, 15, 14, 15, 13,
				16, 17, 19, 18, 19, 17,
				20, 21, 23, 22, 23, 21
			]);
			
			leftSurface = addSurface(left, 0, 2);
			rightSurface = addSurface(right, 6, 2);
			backSurface = addSurface(back, 12, 2);
			frontSurface = addSurface(front, 18, 2);
			bottomSurface = addSurface(bottom, 24, 2);
			topSurface = addSurface(top, 30, 2);

			transformProcedure = transformProcedureStatic;
		}
		
		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, Renderer.SKY);
				//Mouse events
				if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
			}
		}
		
		/**
		 * @private
		 */
		override alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			var max:Number = 0;
			var dx:Number;
			var dy:Number;
			var dz:Number;
			var len:Number;
			dx = -halfSize - cameraToLocalTransform.d;
			dy = -halfSize - cameraToLocalTransform.h;
			dz = -halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = halfSize - cameraToLocalTransform.d;
			dy = -halfSize - cameraToLocalTransform.h;
			dz = -halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = halfSize - cameraToLocalTransform.d;
			dy = halfSize - cameraToLocalTransform.h;
			dz = -halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = -halfSize - cameraToLocalTransform.d;
			dy = halfSize - cameraToLocalTransform.h;
			dz = -halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = -halfSize - cameraToLocalTransform.d;
			dy = -halfSize - cameraToLocalTransform.h;
			dz = halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = halfSize - cameraToLocalTransform.d;
			dy = -halfSize - cameraToLocalTransform.h;
			dz = halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = halfSize - cameraToLocalTransform.d;
			dy = halfSize - cameraToLocalTransform.h;
			dz = halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			dx = -halfSize - cameraToLocalTransform.d;
			dy = halfSize - cameraToLocalTransform.h;
			dz = halfSize - cameraToLocalTransform.l;
			len = dx*dx + dy*dy + dz*dz;
			if (len > max) max = len;
			drawUnit.setVertexConstantsFromNumbers(0, cameraToLocalTransform.d, cameraToLocalTransform.h, cameraToLocalTransform.l, camera.farClipping/Math.sqrt(max));
		}

		/**
		 * Returns a <code>Surface</code> by given alias.  You can use  <code>SkyBox</code> class constants as value of <code>side</code> parameter. They are following: <code>SkyBox.LEFT</code>, <code>SkyBox.RIGHT</code>, <code>SkyBox.BACK</code>, <code>SkyBox.FRONT</code>, <code>SkyBox.BOTTOM</code>, <code>SkyBox.TOP</code>.
		 * @param side Surface alias.
		 * @return Surface by given alias.
		 */
		public function getSide(side:String):Surface {
			switch (side) {
				case LEFT:
					return leftSurface;
					break;
				case RIGHT:
					return rightSurface;
					break;
				case BACK:
					return backSurface;
					break;
				case FRONT:
					return frontSurface;
					break;
				case BOTTOM:
					return bottomSurface;
					break;
				case TOP:
					return topSurface;
					break;
			}
			return null;
		}
		

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:SkyBox = new SkyBox(0);
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			// Clone marks
			var src:SkyBox = source as SkyBox;
			for (var i:int = 0; i < src._surfacesLength; i++) {
				var surface:Surface = src._surfaces[i];
				var newSurface:Surface = _surfaces[i];
				if (surface == src.leftSurface) {
					leftSurface = newSurface;
				} else if (surface == src.rightSurface) {
					rightSurface = newSurface;
				} else if (surface == src.backSurface) {
					backSurface = newSurface;
				} else if (surface == src.frontSurface) {
					frontSurface = newSurface;
				} else if (surface == src.bottomSurface) {
					bottomSurface = newSurface;
				} else if (surface == src.topSurface) {
					topSurface = newSurface;
				}
			}
		}
		
	}
}
