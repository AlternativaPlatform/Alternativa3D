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
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	public class EncodeDepthMaterial extends Material {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;

		public var useNormals:Boolean = false;
		public var outputScaleX:Number = 1;
		public var outputScaleY:Number = 1;
		public var outputOffsetX:Number = 0;
		public var outputOffsetY:Number = 0;

		public function EncodeDepthMaterial() {
		}

		private function setupProgram(object:Object3D, useNormals:Boolean):DepthMaterialProgram {
			// project vector in camera
			// transfer v0.z = z * 255 / farClipping

			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			var positionVar:String = "aPosition";
			vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
			if (object.transformProcedure != null) {
				positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
			}
			vertexLinker.addProcedure(_projectProcedure);

			vertexLinker.declareVariable("tProjected");
			vertexLinker.setInputParams(_projectProcedure, positionVar);
			vertexLinker.setOutputParams(_projectProcedure, "tProjected");

			if (useNormals) {
				vertexLinker.addProcedure(new Procedure([
					"#a0=aNormal",
					"#v0=vNormal",
					"mov v0, a0"
				], "passNormal"));
			}

			var vertexProcedure:Procedure = new Procedure([
				"#v0=vDistance",
				"#c0=cScale",
				"#c1=cOutput",
				"mul v0, i0.z, c0.x",
				"mul i0.xy, i0.xy, c1.xy",
				"mul t0.xy, c1.zwzw, i0.w",
				"add i0.xy, i0.xy, t0.xy",
				"mov o0, i0"
			], "DepthVertex");
			vertexLinker.addProcedure(vertexProcedure, "tProjected");

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			var outputProcedure:Procedure = new Procedure([
				"#v0=vDistance",
				"#c0=cConstants",
				"frc t0.y, v0.z",
				"sub t0.x, v0.z, t0.y",
				"mul t0.x, t0.x, c0.x",
				"mov t0.zw, c0.zwzw",
				"mov o0, t0"
			], "DepthFragment");
			fragmentLinker.addProcedure(outputProcedure);

			if (useNormals) {
				// Transform normal in camera
				// Multiply by transpose(invert(object->camera))
				fragmentLinker.declareVariable("tColor");
				fragmentLinker.setOutputParams(outputProcedure, "tColor");
				fragmentLinker.addProcedure(new Procedure([
					"#v0=vNormal",
					"#c0=cTransformRow1",	// .w = 0.5
					"#c1=cTransformRow2",
					"#c2=cTransformRow3",
					"dp3 t0.x, v0, c0",
					"dp3 t0.y, v0, c1",
					"dp3 t0.z, v0, c2",
					"nrm t0.xyz, t0.xyz",
					// mul by 0.5 and add 0.5
					"mul t0.xy, t0.xy, c0.w",
					"add t0.xy, t0.xy, c0.w",
					"mov i0.zw, t0.xyxy",
					"mov o0, i0"
				], "decNormal"), "tColor");
			}

			fragmentLinker.varyings = vertexLinker.varyings;
			return new DepthMaterialProgram(vertexLinker, fragmentLinker);
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			var object:Object3D = surface.object;
			// Strams
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);
			// Check validity
			if (positionBuffer == null) return;
			if (useNormals && normalsBuffer == null) return;

			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Dictionary();
					caches[cachedContext3D] = programsCache;
				}
			}

			var programs:Array = programsCache[object.transformProcedure];
			if (programs == null) {
				programs = new Array(2);
				program = setupProgram(object, false);
				program.upload(camera.context3D);
				programs[0] = program;
				program = setupProgram(object, true);
				program.upload(camera.context3D);
				programs[1] = program;
				programsCache[object.transformProcedure] = programs;
			}
			var program:DepthMaterialProgram = programs[int(useNormals ? 1 : 0)];
			// Drawcall
			var drawUnit:DrawUnit = camera.depthRenderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			if (useNormals) drawUnit.setVertexBufferAt(program.aNormal, normalsBuffer, geometry._attributesOffsets[VertexAttributes.NORMAL], VertexAttributes.FORMATS[VertexAttributes.NORMAL]);
			// Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);
			drawUnit.setVertexConstantsFromNumbers(program.cScale, 255/camera.farClipping, 0, 0);
			drawUnit.setVertexConstantsFromNumbers(program.cOutput, outputScaleX, outputScaleY, outputOffsetX, outputOffsetY);
			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, 1/255, 0, 0);
			if (program.cTransformRow1 >= 0) drawUnit.setFragmentConstantsFromNumbers(program.cTransformRow1, object.localToCameraTransform.a, object.localToCameraTransform.b, object.localToCameraTransform.c, 0.5);
			if (program.cTransformRow2 >= 0) drawUnit.setFragmentConstantsFromNumbers(program.cTransformRow2, object.localToCameraTransform.e, object.localToCameraTransform.f, object.localToCameraTransform.g);
			if (program.cTransformRow3 >= 0) drawUnit.setFragmentConstantsFromNumbers(program.cTransformRow3, object.localToCameraTransform.i, object.localToCameraTransform.j, object.localToCameraTransform.k);
			// Send to render
			camera.depthRenderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:EncodeDepthMaterial = new EncodeDepthMaterial();
			res.outputScaleX = outputScaleX;
			res.outputScaleY = outputScaleY;
			res.outputOffsetX = outputOffsetX;
			res.outputOffsetY = outputOffsetY;
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class DepthMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aNormal:int = -1;
	public var cProjMatrix:int = -1;
	public var cScale:int = -1;
	public var cOutput:int = -1;
	public var cConstants:int = -1;
	public var cTransformRow1:int = -1;
	public var cTransformRow2:int = -1;
	public var cTransformRow3:int = -1;

	public function DepthMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aNormal =  vertexShader.findVariable("aNormal");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		cScale = vertexShader.findVariable("cScale");
		cOutput = vertexShader.findVariable("cOutput");
		cConstants = fragmentShader.findVariable("cConstants");
		cTransformRow1 = fragmentShader.findVariable("cTransformRow1");
		cTransformRow2 = fragmentShader.findVariable("cTransformRow2");
		cTransformRow3 = fragmentShader.findVariable("cTransformRow3");
	}

}
