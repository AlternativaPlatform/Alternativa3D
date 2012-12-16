package alternativa.engine3d.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	public class OutputEffect {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Vector.<DepthMaterialProgram>;

		public var depthTexture:Texture;

		private var quadGeometry:Geometry;

		public var scaleX:Number = 1;
		public var scaleY:Number = 1;

		// 0 - raw
		// 1 - depth
		// 2 - depth encoded
		// 3 - normals
		// 4 - raw smoothed
		public var mode:int = 0;
		public var multiplyBlend:Boolean = false;

		public function OutputEffect() {
			quadGeometry = new Geometry();
			quadGeometry.addVertexStream([VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0]]);
			quadGeometry.numVertices = 4;
			quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([-1, 1, 0, 1, 1, 0, 1, -1, 0, -1, -1, 0]));
//			quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 0, 1, 0, 0, 1, -1, 0, 0, -1, 0]));
			quadGeometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1]));
			quadGeometry._indices = Vector.<uint>([0, 3, 2, 0, 2, 1]);
		}

		private function setupProgram(mode:int):DepthMaterialProgram {
			// project vector in camera
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			vertexLinker.addProcedure(new Procedure([
				"#a0=aPosition",
				"#a1=aUV",
				"#v0=vUV",
				"#c0=cScale",
				"mul v0, a1, c0",
				"mov o0, a0"
			], "vertexProcedure"));

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);

			var outputProcedure:Procedure;
			outputProcedure = new Procedure([
				"#v0=vUV",
				"#s0=sTexture",
				mode == 4 ? "tex t0, v0, s0 <2d, clamp, linear, mipnone>" : "tex t0, v0, s0 <2d, clamp, nearest, mipnone>",
				"mov o0, t0"
			], "DepthFragment");
			fragmentLinker.addProcedure(outputProcedure);

			if (mode == 1) {
				fragmentLinker.declareVariable("tOutput");
				fragmentLinker.setOutputParams(outputProcedure, "tOutput");
				fragmentLinker.addProcedure(new Procedure([
					"#c0=cConstants",
					"mov i0.zw, c0.z",
					"mov o0, i0"
				], "DepthProcedure"), "tOutput");
			}
			if (mode == 2) {
				fragmentLinker.declareVariable("tOutput");
				fragmentLinker.setOutputParams(outputProcedure, "tOutput");
				fragmentLinker.addProcedure(new Procedure([
					"#c0=cDecodeDepth",
					"dp3 t0, i0, c0",
					"mov o0, t0"
				], "EncodeProcedure"), "tOutput");
			}
			if (mode == 3) {
				// encode normal
				fragmentLinker.declareVariable("tOutput");
				fragmentLinker.setOutputParams(outputProcedure, "tOutput");
				fragmentLinker.addProcedure(new Procedure([
					"#c0=cConstants",	// PI, -, 0, 1
//					"add i0.xy, i0.zw, i0.zw",
//					// doubled and sub 1
//					"sub i0.xy, i0.xy, c0.x",
//					// restore z = Math.sqrt(1 - x*x - y*y)
//					"mul t0.xy, i0.xy, i0.xy",
//					"add t0.w, t0.x, t0.y",
//					"sub t0.w, c0.x, t0.w",
//					"sqt i0.z, t0.w",
					// restore z = t0.z*2 - 1
					// restore angle = Math.PI*(i0.w*2 - 1)
					"add i0.zw, i0.zwzw, i0.zwzw",
					"sub i0.zw, i0.zwzw, c0.w",
					"mul i0.w, i0.w, c0.x",
					// restore r = sqt(1 - z^2)
					"mul t0.w, i0.z, i0.z",
					"sub t0.w, c0.w, t0.w",
					"sqt t0.w, t0.w",
					"cos t0.x, i0.w",
					"sin t0.y, i0.w",
					"mul t0.xy, t0.xy, t0.w",
					"neg t0.z, i0.z",
					"mov t0.w, c0.w",
					"mov o0, t0"
				], "NormalsProcedure"), "tOutput");
			}

			fragmentLinker.varyings = vertexLinker.varyings;
			return new DepthMaterialProgram(vertexLinker, fragmentLinker);
		}

		public function collectQuadDraw(camera:Camera3D):void {
			// Check validity
			if (depthTexture == null) return;

			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				quadGeometry.upload(camera.context3D);
				if (programsCache == null) {
					programsCache = new Vector.<DepthMaterialProgram>(5, true);
					for (var i:int = 0; i < 5; i++) {
						programsCache[i] = setupProgram(i);
						programsCache[i].upload(camera.context3D);
					}
					caches[cachedContext3D] = programsCache;
				}
			}
			// Strams
			var positionBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);

			var program:DepthMaterialProgram = programsCache[mode];
			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(null, program.program, quadGeometry._indexBuffer, 0, 2, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, quadGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, quadGeometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			// Constants
			drawUnit.setVertexConstantsFromNumbers(program.cScale, scaleX, scaleY, 0);
			if (program.cDecodeDepth >= 0) drawUnit.setFragmentConstantsFromNumbers(program.cDecodeDepth, 1, 1/255, 0, 0);
			if (program.cConstants >= 0) drawUnit.setFragmentConstantsFromNumbers(program.cConstants, Math.PI, 0, 0, 1);
			drawUnit.setTextureAt(program.sTexture, depthTexture);
			// Send to render
			drawUnit.culling = Context3DTriangleFace.NONE;
			if (multiplyBlend) {
				drawUnit.blendSource = Context3DBlendFactor.ZERO;
				drawUnit.blendDestination = Context3DBlendFactor.SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, Renderer.TRANSPARENT_SORT);
			} else {
				camera.renderer.addDrawUnit(drawUnit, Renderer.BACKGROUND);
			}
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class DepthMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var cConstants:int = -1;
	public var cDecodeDepth:int = -1;
	public var cScale:int = -1;
	public var sTexture:int = -1;

	public function DepthMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aUV =  vertexShader.findVariable("aUV");
		cScale = vertexShader.findVariable("cScale");
		cConstants = fragmentShader.findVariable("cConstants");
		cDecodeDepth = fragmentShader.findVariable("cDecodeDepth");
		sTexture = fragmentShader.findVariable("sTexture");
	}

}
