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
	public class SSAOAngular {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Vector.<SSAOAngularProgram>;

		public var depthNormalsTexture:Texture;
		private var rotationTexture:Texture;

		private var quadGeometry:Geometry;

		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		public var uToViewX:Number = 1;
		public var vToViewY:Number = 1;
		public var width:Number = 0;
		public var height:Number = 0;

		public var size:Number = 1;
		public var angleBias:Number = 0.1;
		public var intensity:Number = 1;
		public var maxDistance:Number = 10;
		public var falloff:Number = 0;

		public function SSAOAngular() {
			quadGeometry = new Geometry();
			quadGeometry.addVertexStream([VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0]]);
			quadGeometry.numVertices = 4;
			quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([-1, 1, 0, 1, 1, 0, 1, -1, 0, -1, -1, 0]));
			//quadGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 0, 1, 0, 0, 1, -1, 0, 0, -1, 0]));
			quadGeometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1]));
			quadGeometry._indices = Vector.<uint>([0, 3, 2, 0, 2, 1]);
		}

		private function setupProgram():SSAOAngularProgram {
			// TODO: order constants for better caching
			// TODO: quadratic falloff
			// TODO: improved random texture
			// TODO: use 2D rotation matrix for random texture (mul o0 t0.xyxy c0; add o0.xy o0.xz o0.yw)
			// TODO: optimize shader
			// TODO: try to decode normal from depth
			// TODO: add more samples
			// TODO: fix normals at extremal camera angles (negative from camera direction)
			// TODO: render with reduced textures sizes

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
			var ssao:Array;

			ssao = [
				"#v0=vUV",
				"#c0=cDecDepth",
				"#c1=cOffset0",
				"#c2=cOffset1",
				"#c3=cConstants",	// radius, intensity/numSamples, bias, 1
				"#c4=cUnproject1",	// uToViewX, uToViewY, width/2, height/2
				"#c5=cUnproject2",	// nearClipping, focalLength, max_distance, falloff
				"#s0=sDepth",
				"#s1=sRotation",
				// unpack depth
				"tex t1, v0, s0 <2d, clamp, nearest, mipnone>",
				"dp3 t0.z, t1, c0",
				// get 3D position
				// z = d + near
				"add t0.z, t0.z, c5.x",
				// dx = u*uToViewX - width/2, v = v*vToViewY - height/2
				// x = dx*z/focalLength
				// y = dy*z/focalLength
//				"mov t1, c5",
				"mul t0.xy, v0.xy, c4.xy",
				"sub t0.xy, t0.xy, c4.zw",
				"mul t0.xy, t0.xy, t0.z",
				"div t0.xy, t0.xy, c5.y",

				// unpack normal
				"add t1.xy, t1.zwzw, t1.zwzw",
				"sub t1.xy, t1.xy, c3.w",
				"mul t1.zw, t1.xyxy, t1.xyxy",
				"add t1.z, t1.z, t1.w",
				"sub t1.z, c3.w, t1.z",
				"sqt t1.z, t1.z",
				// negative z
				"neg t1.z, t1.z",

				// calculate radius
				"div t0.w, c3.x, t0.z",

				// sample mirror plane
				"tex t2, v0.zw, s1 <2d, repeat, nearest, mipnone>",
				"add t2, t2, t2",
				"sub t2, t2, c3.w",
				"mov t2.z, c0.w",
			];
			// t0 - position
			// t0.w - radius
			// t1 - normal
			// t2 - mirror plane

			// Do iterations
			const components:Array = [".x", ".y", ".z", ".w"];
			line = ssao.length;
			for (var i:int = 0; i < 4; i++) {
				// reflect and scale vector
				if ((i & 1) == 0) {
					ssao[int(line++)] = "mul t3, c" + (i/2 + 1) + ", t0.w";
				} else {
					ssao[int(line++)] = "mul t3.xy, c" + (int(i/2) + 1) + ".zw, t0.w";
				}
				// mirror by plane t2 = t2 - 2*dp3(t2, t5)
				ssao[int(line++)] = "dp3 t3.w, t3, t2";
				ssao[int(line++)] = "add t3.w, t3.w, t3.w";
				ssao[int(line++)] = "sub t3.xy, t3.xy, t3.w";
				ssao[int(line++)] = "add t3.xy, v0.xy, t3.xy";
				ssao[int(line++)] = "tex t4, t3, s0 <2d, clamp, nearest, mipnone>";
				ssao[int(line++)] = "dp3 t3.z, t4, c0";

				// get sample 3D position
				ssao[int(line++)] = "add t3.z, t3.z, c5.x";
				ssao[int(line++)] = "mul t3.xy, t3.xy, c4.xy";
				ssao[int(line++)] = "sub t3.xy, t3.xy, c4.zw";
				ssao[int(line++)] = "mul t3.xy, t3.xy, t3.z";
				ssao[int(line++)] = "div t3.xy, t3.xy, c5.y";

				// get direction
				ssao[int(line++)] = "sub t3, t3, t0";

				// calculate distance
				ssao[int(line++)] = "dp3 t3.w, t3, t3";
				ssao[int(line++)] = "sqt t3.w, t3.w";

				// calculate occlusion = (max(0, dot(normal, direction)/len(direction)) - bias)/(1 + distance)
				ssao[int(line++)] = "dp3 t3.x, t3, t1";
				ssao[int(line++)] = "div t3.x, t3.x, t3.w";
				ssao[int(line++)] = "sub t3.x, t3.x, c3.z";
				ssao[int(line++)] = "max t3.x, t3.x, c0.w";

//				ssao[int(line++)] = "add t3.w, t3.w, c3.w";
//				ssao[int(line++)] = "div t3.w, t3.x, t3.w";

				ssao[int(line++)] = "sub t3.w, t3.w, c5.z";
				ssao[int(line++)] = "mul t3.w, t3.w, c5.w";
				ssao[int(line++)] = "sat t3.w, t3.w";
				ssao[int(line++)] = "sub t3.w, c3.w, t3.w";
				ssao[int(line++)] = "mul t3.w, t3.w, t3.x";

				// rotate to second vector 45*
				// calc second occlusion

				// calculate occlusion sum
				if (i == 0) {
					ssao[int(line++)] = "mov t5, t3.w";
				} else {
					ssao[int(line++)] = "add t5, t5, t3.w";
				}
			}

			// weighted sum and output
//			ssao[int(line++)] =	"dp4 t4.x, t4, c6.w";  	// 1/4
//			ssao[int(line++)] =	"add t4.x, t4.x, c7.w"; // -0.075
//			ssao[int(line++)] =	"add t4, t4, t7";
			// TODO: fix dp4
//			ssao[int(line++)] =	"add t4.x, t4.x, t4.y";
//			ssao[int(line++)] =	"add t4.x, t4.x, t4.z";
//			ssao[int(line++)] =	"add t4.x, t4.x, t4.w";
//			ssao[int(line++)] =	"mul t4.x, t4.x, c6.w";
//			ssao[int(line++)] =	"pow t4.x, t4.x, c9.z";

			ssao[int(line++)] =	"mul t5.x, t5.x, c3.y";
			ssao[int(line++)] =	"sub o0, c3.w, t5.x";
//			ssao[int(line++)] =	"mul o0, t5.x, c3.y";

			var ssaoProcedure:Procedure = new Procedure(ssao, "SSAOProcedure");
			fragmentLinker.addProcedure(ssaoProcedure);

//			trace(A3DUtils.disassemble(ssaoProcedure.getByteCode(Context3DProgramType.FRAGMENT)));

			fragmentLinker.varyings = vertexLinker.varyings;
			return new SSAOAngularProgram(vertexLinker, fragmentLinker);
		}

		private static const offsets:Vector.<Number> = initOffsets();

		private static function initOffsets():Vector.<Number> {
			var result:Vector.<Number> = new Vector.<Number>(32);
			result[0] = 1;
			result[1] = -1;
			result[4] = -1;
			result[5] = -1;
			result[8] = 1;
			result[9] = 1;
			result[12] = -1;
			result[13] = 1;
			for (var i:int = 0; i < 4; i++) {
				var index:int = int(4*i);
				var x:Number = result[index];
				var y:Number = result[int(index + 1)];
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
			if (depthNormalsTexture == null) return;

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
					programsCache = new Vector.<SSAOAngularProgram>(1);
					programsCache[0] = setupProgram();
					programsCache[0].upload(camera.context3D);
					caches[cachedContext3D] = programsCache;
				}
			}
			// Streams
			var positionBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);

			var program:SSAOAngularProgram = programsCache[0];
			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(null, program.program, quadGeometry._indexBuffer, 0, 2, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, quadGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, quadGeometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			// Constants
			drawUnit.setVertexConstantsFromNumbers(program.cScale, scaleX, scaleY, width*scaleX/4, height*scaleY/4);

			const distance:Number = camera.farClipping - camera.nearClipping;
			drawUnit.setFragmentConstantsFromNumbers(program.cDecDepth, distance, distance/255, 0, 0);
			drawUnit.setFragmentConstantsFromNumbers(program.cOffset0, 0, -1, 0, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.cOffset1, 1, 0, -1, 0);
			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, size, intensity/4, angleBias, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.cUnproject1, uToViewX, vToViewY, camera.view._width/2, camera.view._height/2);
			drawUnit.setFragmentConstantsFromNumbers(program.cUnproject2, camera.nearClipping, camera.focalLength, maxDistance, 1/(falloff + 0.00001));
			drawUnit.setTextureAt(program.sDepth, depthNormalsTexture);
			drawUnit.setTextureAt(program.sRotation, rotationTexture);
			// Send to render
			camera.renderer.addDrawUnit(drawUnit, Renderer.OPAQUE);
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class SSAOAngularProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var cScale:int = -1;
	public var cDecDepth:int = -1;
	public var cOffset0:int = -1;
	public var cOffset1:int = -1;
	public var cConstants:int = -1;
	public var cUnproject1:int = -1;
	public var cUnproject2:int = -1;
	public var sDepth:int = -1;
	public var sRotation:int = -1;

	public function SSAOAngularProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aUV =  vertexShader.findVariable("aUV");
		cScale = vertexShader.findVariable("cScale");
		cDecDepth = fragmentShader.findVariable("cDecDepth");
		cOffset0 = fragmentShader.findVariable("cOffset0");
		cOffset1 = fragmentShader.findVariable("cOffset1");
		cConstants = fragmentShader.findVariable("cConstants");
		cUnproject1 = fragmentShader.findVariable("cUnproject1");
		cUnproject2 = fragmentShader.findVariable("cUnproject2");
		sDepth = fragmentShader.findVariable("sDepth");
		sRotation = fragmentShader.findVariable("sRotation");
	}

}
