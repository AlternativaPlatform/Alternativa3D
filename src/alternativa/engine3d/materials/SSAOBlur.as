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
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	public class SSAOBlur {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Vector.<DepthMaterialProgram>;

		public var ssaoTexture:Texture;
//		public var depthTexture:Texture;

		private var quadGeometry:Geometry;

		public var width:Number = 0;
		public var height:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var clipSizeX:Number = 0;
		/**
		 * @private
		 */
		alternativa3d var clipSizeY:Number = 0;

		public var size:int = 4;
		public var offset:int = 1;

		public function SSAOBlur() {
			quadGeometry = new Geometry();
			quadGeometry.addVertexStream([VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0]]);
			quadGeometry.numVertices = 4;
			quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([-1, 1, 0, 1, 1, 0, 1, -1, 0, -1, -1, 0]));
			quadGeometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1]));
			quadGeometry._indices = Vector.<uint>([0, 3, 2, 0, 2, 1]);
		}

		private function setupProgram():DepthMaterialProgram {
			// TODO: bug - white line on edges

			// project vector in camera
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			vertexLinker.addProcedure(new Procedure([
				"#a0=aPosition",
				"#a1=aUV",
				"#v0=vUV",
				"#c0=cUVScale",
				"#c1=cCoordsTransform",
				"mul v0, a1, c0",
				"mul t0.xy, a0.xy, c1.xy",
				"add t0.xy, t0.xy, c1.zwzw",
				"mov t0.zw, a0.zw",
				"mov o0, t0"
			], "vertexProcedure"));

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);

			var line:int = 0;
			var i:int;
			var j:int;
			var blurCode:Array = [
				"#v0=vUV",
//				"#s0=sDepth",
				"#s1=sSSAO",

				"#c0=cOffset",		// dw, dh, -dw, -dh
				"#c1=cDecDepth",	// 1, 1/255, 0, 0
				"#c2=cConstants"	// segmentCount, 1, 0, 0
			];

			// init
			line = blurCode.length;
			blurCode[int(line++)] = "mov t0, c0";
			blurCode[int(line++)] = "mov t0, c1";
			blurCode[int(line++)] = "mov t0, c2";
//			blurCode[int(line++)] = "tex t0, v0, s0 <2d, clamp, nearest, mipnone>";
			blurCode[int(line++)] = "tex t0, v0, s1 <2d, clamp, nearest, mipnone>";
			blurCode[int(line++)] = "mov t1, c1.w";
			blurCode[int(line++)] = "mov t2, c1.w";

			// t0 - sample coords
			// t1 - texture value
			// t2.x - depth of source point
			// t2.y - depth of current point
			// t3 - sum

//			// calculate first offset coords
//			blurCode[int(line++)] = "mov t0, v0";
//			for (i = 0; i < size; i++){
//				blurCode[int(line++)] = "add t0.xy, t0.xy, c0.zw";
//			}
//
//			// calculate offsets
//			for (j = 0; j < size * 2 + 1; j++){
//				calculateSample();
//				for (i = 0; i < size * 2; i++){
//					blurCode[int(line++)] = ((j&1) == 0) ? "add t0.x, t0.x, c0.x" : "add t0.x, t0.x, c0.z";
//					calculateSample();
//				}
//				if (j < size * 2) blurCode[int(line++)] = "add t0.y, t0.y, c0.y";
//			}

			// calculate first offset coords
			blurCode[int(line++)] = "mov t0, v0";
			for (i = 0; i < size / 2 - 1; i++) {
				blurCode[int(line++)] = "add t0.xy, t0.xy, c0.zw";
			}

			// calculate offsets
			for (j = 0; j < size; j++){
				calculateSample();
				for (i = 0; i < size-1; i++){
					blurCode[int(line++)] = ((j&1) == 0) ? "add t0.x, t0.x, c0.x" : "add t0.x, t0.x, c0.z";
					calculateSample();
				}
				if (j < size - 1)
					blurCode[int(line++)] = "add t0.y, t0.y, c0.y";
			}

			function calculateSample():void{
				blurCode[int(line++)] = "tex t1, t0.xy, s1 <2d, clamp, nearest, mipnone>";
				blurCode[int(line++)] = "add t2, t2, t1";
			}

			// calc out color
			blurCode[int(line++)] = "div t2, t2, c2.x";
			blurCode[int(line++)] = "mov o0, t2";


			var ssaoProcedure:Procedure = new Procedure(blurCode, "SSAOBlur");
			fragmentLinker.addProcedure(ssaoProcedure);
			fragmentLinker.varyings = vertexLinker.varyings;
			return new DepthMaterialProgram(vertexLinker, fragmentLinker);
		}

		public function collectQuadDraw(camera:Camera3D):void {
			// Check validity
//			if (depthTexture == null) return;

			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				quadGeometry.upload(camera.context3D);

				if (programsCache == null) {
					programsCache = new Vector.<DepthMaterialProgram>(1);
					programsCache[0] = setupProgram();
					programsCache[0].upload(camera.context3D);
					caches[cachedContext3D] = programsCache;
				}
			}
			// Streams
			var positionBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var program:DepthMaterialProgram = programsCache[0];

			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(null, program.program, quadGeometry._indexBuffer, 0, 2, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, quadGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, quadGeometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			// Constants

			drawUnit.setVertexConstantsFromNumbers(program.cUVScale, clipSizeX, clipSizeY, 1, 1);
			drawUnit.setVertexConstantsFromNumbers(program.cCoordsTransform, clipSizeX, clipSizeY, clipSizeX - 1, 1 - clipSizeY);

			var dw:Number = offset/width;
			var dh:Number = offset/height;
//			var segmentCount:int = (size*2+1)*(size*2+1);
			var segmentCount:int = size*size;
			drawUnit.setFragmentConstantsFromNumbers(program.cOffset, dw, dh, -dw, -dh);
			drawUnit.setFragmentConstantsFromNumbers(program.cDecDepth, 1, 1/255, 0, 0);
			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, segmentCount, 1, 0, 0);
//			drawUnit.setTextureAt(program.sDepth, depthTexture);
			drawUnit.setTextureAt(program.sSSAO, ssaoTexture);
			drawUnit.culling = Context3DTriangleFace.NONE;
			// Send to render
			camera.renderer.addDrawUnit(drawUnit, Renderer.BACKGROUND);
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class DepthMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var cUVScale:int = -1;
	public var cCoordsTransform:int = -1;
	public var cOffset:int = -1;
	public var cDecDepth:int = -1;
	public var cConstants:int = -1;
//	public var sDepth:int = -1;
	public var sSSAO:int = -1;

	public function DepthMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aUV =  vertexShader.findVariable("aUV");
		cUVScale = vertexShader.findVariable("cUVScale");
		cCoordsTransform = vertexShader.findVariable("cCoordsTransform");

		cOffset = fragmentShader.findVariable("cOffset");
		cDecDepth = fragmentShader.findVariable("cDecDepth");
		cConstants = fragmentShader.findVariable("cConstants");

//		sDepth = fragmentShader.findVariable("sDepth");
		sSSAO = fragmentShader.findVariable("sSSAO");
	}

}
