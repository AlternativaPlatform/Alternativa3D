/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * The materiall fills surface with solid color in light-independent manner. Can draw a Skin with no more than 41 Joints per surface. See Skin.divide() for more details.
	 *
	 * @see alternativa.engine3d.objects.Skin#divide()
	 */
	public class FillMaterial extends Material {
		
		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;

		private static var outColorProcedure:Procedure = new Procedure(["#c0=cColor", "mov o0, c0"], "outColorProcedure");

		/**
		 * Transparency
		 */
		public var alpha:Number = 1;
		
		private var red:Number;
		private var green:Number;
		private var blue:Number;
		
		/**
		 * Color.
		 */
		public function get color():uint {
			return (red*0xFF << 16) + (green*0xFF << 8) + blue*0xFF;
		}

		/**
		 * @private
		 */
		public function set color(value:uint):void {
			red = ((value >> 16) & 0xFF)/0xFF;
			green = ((value >> 8) & 0xFF)/0xFF;
			blue = (value & 0xff)/0xFF;
		}

		/**
		 * Creates a new FillMaterial instance.
		 * @param color Color .
		 * @param alpha Transparency.
		 */
		public function FillMaterial(color:uint = 0x7F7F7F, alpha:Number = 1) {
			this.color = color;
			this.alpha = alpha;
		}

		private function setupProgram(object:Object3D):FillMaterialProgram {
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			var positionVar:String = "aPosition";
			vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
			if (object.transformProcedure != null) {
				positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
			}
			vertexLinker.addProcedure(_projectProcedure);
			vertexLinker.setInputParams(_projectProcedure, positionVar);

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			fragmentLinker.addProcedure(outColorProcedure);
			fragmentLinker.varyings = vertexLinker.varyings;
			return new FillMaterialProgram(vertexLinker, fragmentLinker);
		}

		/**
		 * @private 
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			var object:Object3D = surface.object;
			// Strams
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			// Check validity
			if (positionBuffer == null) return;
			// Program

			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Dictionary();
					caches[cachedContext3D] = programsCache;
				}
			}

			var program:FillMaterialProgram = programsCache[object.transformProcedure];
			if (program == null) {
				program = setupProgram(object);
				program.upload(camera.context3D);
				programsCache[object.transformProcedure] = program;
			}
			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			// Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);
			drawUnit.setFragmentConstantsFromNumbers(program.cColor, red, green, blue, alpha);
			// Send to render
			if (alpha < 1) {
				drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
				drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
			} else {
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Material {
			var res:FillMaterial = new FillMaterial(color, alpha);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class FillMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var cProjMatrix:int = -1;
	public var cColor:int = -1;

	public function FillMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		cColor = fragmentShader.findVariable("cColor");
	}
}
