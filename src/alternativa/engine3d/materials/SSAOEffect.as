package alternativa.engine3d.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	public class SSAOEffect {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Vector.<DepthMaterialProgram>;

		public var depthTexture:Texture;
		private var rotationTexture:Texture;

		private var quadGeometry:Geometry;

		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		public var width:Number = 0;
		public var height:Number = 0;

		public var size:Number = 1;
		public var softness:Number = 1;

		public function SSAOEffect() {
			quadGeometry = new Geometry();
			quadGeometry.addVertexStream([VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0]]);
			quadGeometry.numVertices = 4;
			quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([-1, 1, 0, 1, 1, 0, 1, -1, 0, -1, -1, 0]));
			//quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 0, 1, 0, 0, 1, -1, 0, 0, -1, 0]));
			quadGeometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1]));
			quadGeometry._indices = Vector.<uint>([0, 3, 2, 0, 2, 1]);
		}

		private function setupProgram():DepthMaterialProgram {
			// project vector in camera
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			vertexLinker.addProcedure(new Procedure([
				"#a0=aPosition",
				"#a1=aUV",
				"#v0=vUV",
				"#c0=cScale",
				"mul v0, a1.xyxy, c0.xyzw",
				"mov o0, a0"
			], "vertexProcedure"));

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);

			var line:int;
			var ssao:Array = [
				"#v0=vUV",
				"#c0=cDecDepth",	// decode const (1, 1/255, 1)
				"#c1=cOffset0",		// .w = (far - near)
				"#c2=cOffset1",		// .w = 5.3
				"#c3=cOffset2",		// .w = 8
				"#c4=cOffset3",		// .w = 2/(far - near)
				"#c5=cOffset4",		// .w = 64
				"#c6=cOffset5",		// .w = 1/4
				"#c7=cOffset6",		// .w = -0.075
				"#c8=cOffset7",		// .w = 2*scale
				"#c9=cConstants",	// .x = -0.85*(far-near), 2, 0.55, 1
				"#s0=sDepth",
				"#s1=sRotation",
				// unpack depth
				"tex t0, v0, s0 <2d, clamp, nearest, mipnone>",
				"dp3 t0.w, t0, c0",
				// calculate world z = z*(far-near)
//				"mul t0.z, t0.w, c1.w",

				// scale = 2*sat(w_d/5.3)*(1 + w_d/8)
//				"div t1.x, t0.w, c2.w",
//				"sat t1.x, t1.x",
//				"div t1.y, t0.w, c3.w",
//				"add t1.y, t1.y, c9.w",
//				"mul t1.w, t1.x, t1.y",
//				"mul t1.xyz, t1.w, c8.w",
//				"div t1.xyz, t1.xyz, t0.w",
				// calc range_scale in t0.z = -0.85*(far - near)/scale.z
//				"div t0.z, c9.x, t1.z",
				// scale.z = 2*(z/4 + 2)/(far-near)
//				"mul t1.z, t1.z, c4.w",
				// calculate diff_scale = 64/scale.z
//				"div t1.w, c5.w, t1.z",

//				"mov t1, c1",
				"mov t1, c8.w",
//				"div t1, c8.w, t0.w",
				// z unchanged
//				"mov t1.z, c9.w",
				// sample mirror plane
				"tex t5, v0.zw, s1 <2d, repeat, nearest, mipnone>",
				"add t5, t5, t5",
				"sub t5, t5, c9.w",
			];
			// t0.w - depth [0..1]
			// t0.z - range_scale
			// t1.xyz - scale
			// t1.w = diff_scale
			// t5 = mirror plane

			const components:Array = [".x", ".y", ".z", ".w"];
			line = ssao.length;
			for (var pass:int = 0; pass < 2; pass++) {
				for (var i:int = 0; i < 4; i++) {
					// scale vector
					ssao[int(line++)] = "mul t2, c" + (4*pass + i + 1) + ", t1";
					// mirror by plane t2 = t2 - 2*dp3(t2, t5)
					ssao[int(line++)] = "dp3 t2.w, t2, t5";
					ssao[int(line++)] = "add t2.w, t2.w, t2.w";
					ssao[int(line++)] = "sub t2.xyz, t2.xyz, t2.w";
					// calc uv and sample
					ssao[int(line++)] = "add t2.xy, v0.xy, t2.xy";
					ssao[int(line++)] = "tex t2.xy, t2, s0 <2d, clamp, nearest, mipnone>";
//					ssao[int(line++)] = "tex t2.xy, v0, s0 <2d, clamp, nearest, mipnone>";
					// TODO: add threshold
					// unpack and add t2.z
					ssao[int(line++)] = "dp3 t3" + components[i] + ", t2, c0";
				}
				// diff = depths - center_z
				ssao[int(line++)] = "sub t3, t3, t0.w";

//				// calc occlusion quality. q = (sat(abs(vDist*range_sc)) + sat(vDist*range_sc))/2
//				ssao[int(line++)] = "mul t6, t3, t0.z";
//				ssao[int(line++)] = "abs t7, t6";
//				ssao[int(line++)] = "sat t6, t6";
//				ssao[int(line++)] = "sat t7, t7";
//				ssao[int(line++)] = "add t6, t6, t7";
//				ssao[int(line++)] = "div t6, t6, c9.y";
				// mul by diff_scale
//				ssao[int(line++)] = "mul t3, t3, t1.w";

				// apply fallof by distance
				ssao[int(line++)] = "mul t6, t3, c9.y";
				ssao[int(line++)] = "sat t6, t6";
				ssao[int(line++)] = "mul t3, t3, c9.x";
				ssao[int(line++)] = "sat t3, t3";
				ssao[int(line++)] = "add t3, t3, t6";
				if (pass == 0) {
					ssao[int(line++)] = "sat t4, t3";
				} else {
					ssao[int(line++)] = "sat t7, t3";
//					ssao[int(line++)] = "add t4, t4, t3";
				}

//				ssao[int(line++)] = "sat t3, t3";
//				// interpolate value by occlusion quality. t3 = 0.55*t6 + t3*(1 - t6)
//				ssao[int(line++)] = "mul t7, c9.z, t6";
//				ssao[int(line++)] = "sub t6, c9.w, t6";
//				ssao[int(line++)] = "mul t3, t3, t6";
				if (pass == 0) {
//					ssao[int(line++)] = "add t4, t3, t7";
				} else {
//					ssao[int(line++)] = "add t3, t3, t7";
//					ssao[int(line++)] = "add t4, t4, t3";
				}
			}
			// weighted sum and output
//			ssao[int(line++)] =	"dp4 t4.x, t4, c6.w";  	// 1/4
//			ssao[int(line++)] =	"add t4.x, t4.x, c7.w"; // -0.075

			ssao[int(line++)] =	"add t4, t4, t7";
			// TODO: fix dp4
			ssao[int(line++)] =	"add t4.x, t4.x, t4.y";
			ssao[int(line++)] =	"add t4.x, t4.x, t4.z";
			ssao[int(line++)] =	"add t4.x, t4.x, t4.w";
			ssao[int(line++)] =	"mul t4.x, t4.x, c6.w";
			ssao[int(line++)] =	"pow t4.x, t4.x, c9.z";
			ssao[int(line++)] =	"mov o0, t4.x";

//			ssao[int(line++)] =	"mov o0, t4.x";

			var ssaoProcedure:Procedure = new Procedure(ssao, "SSAOProcedure");
			fragmentLinker.addProcedure(ssaoProcedure);

			trace(A3DUtils.disassemble(ssaoProcedure.getByteCode(Context3DProgramType.FRAGMENT)));

			fragmentLinker.varyings = vertexLinker.varyings;
			return new DepthMaterialProgram(vertexLinker, fragmentLinker);
		}

		private static const offsets:Vector.<Number> = initOffsets();

		private static function initOffsets():Vector.<Number> {
			var result:Vector.<Number> = new Vector.<Number>(32);
//			for (var i:int = 0; i < 32; i+=4) {
//				var x:Number = (i == 0 || i >= 5*4) ? 1 : -1;
//				var y:Number = (i == 0 || i == 3*4 || i == 4*4 || i == 7*4) ? 1 : -1;
//				var z:Number = ((i/4) % 2 == 0) ? 1 : -1;
////				var step:Number = (i/4 + 1)*(1 - 1/8);
////				var scale:Number = 0.025*step/Math.sqrt(x*x + y*y + z*z);
//				var scale:Number = 1/Math.sqrt(x*x + y*y + z*z);
//				result[i] = scale*x;
//				result[i + 1] = scale*y;
//				result[i + 2] = scale*z;
//			}

			result[0] = 1;
			result[1] = -1;
//			result[2] = 1;
			result[4] = -1;
			result[5] = -1;
//			result[6] = 1;
			result[8] = 1;
			result[9] = 1;
//			result[10] = 1;
			result[12] = -1;
			result[13] = 1;
//			result[14] = 1;
			for (var i:int = 0; i < 4; i++) {
				var index:int = int(4*i);
				var x:Number = result[index];
				var y:Number = result[int(index + 1)];
//				var z:Number = result[int(index + 2)];
				var z:Number = 1 + 0.001;
				var invLen:Number = 1/Math.sqrt(x*x + y*y + z*z);
				result[index] = x*invLen;
				result[int(index + 1)] = y*invLen;
				result[int(index + 2)] = z*invLen;
				// bottom
				index = index + 16;
				result[index] = x*invLen;
				result[int(index + 1)] = y*invLen;
				result[int(index + 2)] = -z*invLen;
			}

			return result;
		}

		public function collectQuadDraw(camera:Camera3D):void {
			// Check validity
			if (depthTexture == null) return;

			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				quadGeometry.upload(camera.context3D);

//				var bmd:BitmapData = new BitmapData(4, 4, false, 0x3653dd);
				var bmd:BitmapData = new BitmapData(4, 4, false, 0x7F7F7F);
				bmd.setPixel(0, 0, 0x967bfe);
				bmd.setPixel(1, 0, 0x7f0361);
				bmd.setPixel(2, 0, 0xa4f663);
				bmd.setPixel(3, 0, 0x9bb10e);
				bmd.setPixel(0, 1, 0x3653dd);
				bmd.setPixel(1, 1, 0x028e8f);
				bmd.setPixel(2, 1, 0x20394f);
				bmd.setPixel(3, 1, 0x31a020);
				bmd.setPixel(0, 2, 0x39e873);
				bmd.setPixel(1, 2, 0xb2d8cb);
				bmd.setPixel(2, 2, 0x46c4da);
				bmd.setPixel(3, 2, 0xf1a452);
				bmd.setPixel(0, 3, 0xe13855);
				bmd.setPixel(1, 3, 0xe958bd);
				bmd.setPixel(2, 3, 0x9019cb);
				bmd.setPixel(3, 3, 0x75490c);
				rotationTexture = camera.context3D.createTexture(4, 4, Context3DTextureFormat.BGRA, false);
				rotationTexture.uploadFromBitmapData(bmd);

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
			drawUnit.setVertexConstantsFromNumbers(program.cScale, scaleX, scaleY, width*scaleX/4, height*scaleY/4);

			const dist:Number = camera.farClipping - camera.nearClipping;

			//			drawUnit.setFragmentConstantsFromNumbers(program.cDecDepth, 1, 1/255, 1, 0);
			drawUnit.setFragmentConstantsFromNumbers(program.cDecDepth, dist, dist/255, dist*0.5, 0);
//			drawUnit.setFragmentConstantsFromNumbers(program.cDecDepth, dist, dist/255, -1, 0);

//			const sc:Number = 2*size;
//			offsets[3] = dist;
//			offsets[4 + 3] = 0.1;
//			offsets[8 + 3] = 4;
//			offsets[12 + 3] = 2/dist;
//			offsets[16 + 3] = 64;
//			offsets[20 + 3] = 1/4;
//			offsets[24 + 3] = -0.075;
//			offsets[28 + 3] = sc;

			offsets[20 + 3] = 1/4;
//			offsets[24 + 3] = 0.5;
			offsets[24 + 3] = 0;
			offsets[28 + 3] = size;
//			offsets[28 + 3] = dist*size;

			drawUnit.setFragmentConstantsFromVector(program.cOffset0, offsets, 8);
//			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, -0.85*dist*softness, 2, 0.55, 1);
//			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, 65000, -1/(100*softness), 0.55, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, 65000, -1/(100*softness), 100, 1);
			drawUnit.setTextureAt(program.sDepth, depthTexture);
			drawUnit.setTextureAt(program.sRotation, rotationTexture);
			// Send to render
			camera.renderer.addDrawUnit(drawUnit, Renderer.OPAQUE);
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class DepthMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var cScale:int = -1;
	public var cDecDepth:int = -1;
	public var cOffset0:int = -1;
	public var cConstants:int = -1;
	public var sDepth:int = -1;
	public var sRotation:int = -1;

	public function DepthMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aUV =  vertexShader.findVariable("aUV");
		cScale = vertexShader.findVariable("cScale");
		cDecDepth = fragmentShader.findVariable("cDecDepth");
		cOffset0 = fragmentShader.findVariable("cOffset0");
		cConstants = fragmentShader.findVariable("cConstants");
		sDepth = fragmentShader.findVariable("sDepth");
		sRotation = fragmentShader.findVariable("sRotation");
	}

}
