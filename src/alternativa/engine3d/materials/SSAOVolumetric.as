/**
 * Created with IntelliJ IDEA.
 * User: gaev
 * Date: 25.06.12
 * Time: 20:06
 * To change this template use File | Settings | File Templates.
 */
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
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	public class SSAOVolumetric {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Vector.<DepthMaterialProgram>;

		public var depthTexture:Texture;

		private var quadGeometry:Geometry;

		public var scaleX:Number = 1;
		public var scaleY:Number = 1;

		public var width:int = 1024;
		public var height:int = 1024;
		public var offset:int = 6;
		public var bias:Number = 0;
		public var intensity:Number = 1;
		public var multiplier:Number = 1;
		public var maxR:Number = 5;
		public var threshold:Number = 10;

		public function SSAOVolumetric() {
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
				"mul v0, a1, c0",
				"mov o0, a0"
			], "vertexProcedure"));

			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			var ssaoArray:Array = [
				"#v0=vUV",
				"#c0=cConstants",	// camLength, camLength/255, 0, threshold
				"#c1=cOffset",		// offset/width, offset/height, -offset/width, -offset/height
				"#c2=cCoeff",		// maxR, intensity, 1/9, 1
				"#c3=cBias",		// bias, multiplier, 0, 0
				"#s0=sDepth"
			];

			var index:int = 6;
			// v0 - current point
			// t0 - texture value
			// t1 - coordinates

			// t2.x - P depth
			// t2.y - B depth
			// t2.z - C (Current point depth)
			// t2.w - T - B
			// c2.x - l
			// c0.w - t

			// t3.x = C - B
			// t3.y - g(C) = sat[(C - B)/(T - B)]
			// t3.z - f(C) = sat[(C - B)/(P - B)]
			// t3.w - sum

			// init
			ssaoArray[index++] = "mov t1.x, c2.w";
			ssaoArray[index++] = "sub t1, t1.x, t1.x";	// t1 = 0
			ssaoArray[index++] = "mov t3.w, t1.x";		// t3.w = 0
			ssaoArray[index++] = "mov t0.z, t1.x";		// t0.w = 0

			// 0 segment
			// -------------
			ssaoArray[index++] = "tex t0.xy, v0, s0 <2d, clamp, nearest, mipnone>";
			ssaoArray[index++] = "dp3 t2.x, t0.xyz, c0.xyz";								// decode value
			// -------------
			ssaoArray[index++] = "sub t2.y, t2.x, c2.x";									// calculate B
//			ssaoArray[index++] = "mov t4, c1";												// calculate Offsets
			ssaoArray[index++] = "div t4.xyzw, c1.xyzw, t2.x";								// calculate Offsets
			ssaoArray[index++] = "sub t2.w, t2.x, c0.w";									// T
			ssaoArray[index++] = "sub t2.w, t2.w, t2.y";									// T - B

			ssaoArray[index++] = "add t3.w, t3.w, c2.w";


			function getDepthValue(ssaoArray:Array):void{
				ssaoArray[index++] = "tex t0.xy, t1.xy, s0 <2d, clamp, nearest, mipnone>";
				ssaoArray[index++] = "dp3 t2.z, t0.xyz, c0.xyz";
			}
			function calculateSegment(ssaoArray:Array):void{
				ssaoArray[index++] = "sub t3.x, t2.z, t2.y";									// calculate Δz = C-B
				ssaoArray[index++] = "div t3.z, t3.x, c2.x";									// (C-B)/l
				ssaoArray[index++] = "sat t3.z, t3.z";											// f(C)

				ssaoArray[index++] = "div t3.y, t3.x, t2.w";									// (C - B)/(T - B)
				ssaoArray[index++] = "sat t3.y, t3.y";											// g(C)

				ssaoArray[index++] = "add t3.w, t3.w, t3.z";									// calculate sum of f(C) + g(C)
				ssaoArray[index++] = "add t3.w, t3.w, t3.y";									//
			}


			// 1 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.x";									// calculate coordinates
			ssaoArray[index++] = "mov t1.y, v0.y";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 2 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.z";
			ssaoArray[index++] = "mov t1.y, v0.y";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 3 segment
			ssaoArray[index++] = "mov t1.x, v0.x";
			ssaoArray[index++] = "add t1.y, v0.y, t4.y";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 4 segment
			ssaoArray[index++] = "mov t1.x, v0.x";
			ssaoArray[index++] = "add t1.y, v0.y, t4.w";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 5 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.z";
			ssaoArray[index++] = "add t1.y, v0.y, t4.y";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 6 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.x";
			ssaoArray[index++] = "add t1.y, v0.y, t4.y";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 7 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.z";
			ssaoArray[index++] = "add t1.y, v0.y, t4.w";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// 8 segment
			ssaoArray[index++] = "add t1.x, v0.x, t4.x";
			ssaoArray[index++] = "add t1.y, v0.y, t4.w";
			getDepthValue(ssaoArray);
			calculateSegment(ssaoArray);

			// ------------

			ssaoArray[index++] = "mul t3.w, t3.w, c2.z";		// * 1/9
			ssaoArray[index++] = "add t3.w, t3.w, c3.x";		// + bias
			ssaoArray[index++] = "mul t3.w, t3.w, c3.y";		// * multiplier
			ssaoArray[index++] = "sat t3.w, t3.w";


			ssaoArray[index++] = "sub t3.w, c2.w, t3.w";		// 1 - sum of Δz
			ssaoArray[index++] = "mul t3.w, t3.w, c2.y";		// multiply on intensity
			ssaoArray[index++] = "sub t3.w, c2.w, t3.w";		// 1 - sum of Δz

			ssaoArray[index++] = "mov o0, t3.w";


			var ssaoProcedure:Procedure = Procedure.compileFromArray(ssaoArray, "SSAOProcedure");
			fragmentLinker.addProcedure(ssaoProcedure);
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
					programsCache = new Vector.<DepthMaterialProgram>(1);
					programsCache[0] = setupProgram();
					programsCache[0].upload(camera.context3D);
					caches[cachedContext3D] = programsCache;
				}
			}
			// Strams
			var positionBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = quadGeometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);

			var program:DepthMaterialProgram = programsCache[0];
			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(null, program.program, quadGeometry._indexBuffer, 0, 2, program);
			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, quadGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, quadGeometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			// Constants
			var camLength:Number = camera.farClipping - camera.nearClipping;
			drawUnit.setVertexConstantsFromNumbers(program.cScale, scaleX, scaleY, 0);

			drawUnit.setFragmentConstantsFromNumbers(program.cConstants, camLength, camLength/255, 0, threshold);
			drawUnit.setFragmentConstantsFromNumbers(program.cOffset, offset*camLength/width, offset*camLength/height, -offset*camLength/width, -offset*camLength/height);
			drawUnit.setFragmentConstantsFromNumbers(program.cCoeff,  maxR, intensity, 1/9, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.cBias,   bias, multiplier, 0, 0);

			drawUnit.setTextureAt(program.sDepth, depthTexture);
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
	public var cConstants:int = -1;
	public var cOffset:int = -1;
	public var cCoeff:int = -1;
	public var cBias:int = -1;
	public var sDepth:int = -1;

	public function DepthMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition =  vertexShader.findVariable("aPosition");
		aUV =  vertexShader.findVariable("aUV");
		cScale = vertexShader.findVariable("cScale");
		cConstants = fragmentShader.findVariable("cConstants");
		cOffset = fragmentShader.findVariable("cOffset");
		cCoeff = fragmentShader.findVariable("cCoeff");
		cBias = fragmentShader.findVariable("cBias");
		sDepth = fragmentShader.findVariable("sDepth");
	}

}
