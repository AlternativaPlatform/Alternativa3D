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
	import alternativa.engine3d.resources.TextureResource;

	import avmplus.getQualifiedClassName;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;

	/**
	 * Texture material which supports light map.    Can draw a Skin with no more than 41 Joints per surface. See Skin.divide() for more details.
	 * To be drawn with this material, geometry should have UV coordinates. Different UV-channels can be used for diffuse texture and light map.
	 *
	 * @see alternativa.engine3d.objects.Skin#divide()
	 * @see alternativa.engine3d.core.VertexAttributes#TEXCOORDS
	 */
	public class LightMapMaterial extends TextureMaterial {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;

		// inputs: color
		private static const _applyLightMapProcedure:Procedure = new Procedure([
			"#v0=vUV1",
			"#s0=sLightMap",
			"tex t0, v0, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"mul i0.xyz, i0.xyz, t0.xyz",
			"mov o0, i0"
		], "applyLightMapProcedure");

		private static const _passLightMapUVProcedure:Procedure = new Procedure([
			"#a0=aUV1",
			"#v0=vUV1",
			"mov v0, a0"
		], "passLightMapUVProcedure");

		/**
		 * Light map.
		 */
		public var lightMap:TextureResource;
		/**
		 * Number of the UV-channel for light map.
		 */
		public var lightMapChannel:uint = 0;

		/**
		 * Creates a new LightMapMaterial instance.
		 * @param diffuseMap Diffuse texture.
		 * @param lightMap  Light map.
		 * @param lightMapChannel Number of the UV-channel for light map.
		 */
		public function LightMapMaterial(diffuseMap:TextureResource = null, lightMap:TextureResource = null, lightMapChannel:uint = 0, opacityMap:TextureResource = null) {
			super(diffuseMap, opacityMap);
			this.lightMap = lightMap;
			this.lightMapChannel = lightMapChannel;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:LightMapMaterial = new LightMapMaterial(diffuseMap, lightMap, lightMapChannel, opacityMap);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @private 
		 */
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void {
			super.fillResources(resources, resourceType);

			if (lightMap != null &&
					A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(lightMap)) as Class, resourceType)) {
				resources[lightMap] = true;
			}
		}

		/**
		 * @param object
		 * @param programs
		 * @param camera
		 * @param opacityMap
		 * @param alphaTest 0 - disabled, 1 - opaque, 2 - contours
		 * @return
		 */
		private function getProgram(object:Object3D, programs:Vector.<LightMapMaterialProgram>, camera:Camera3D, opacityMap:TextureResource, alphaTest:int):LightMapMaterialProgram {
			var key:int = (opacityMap != null ? 3 : 0) + alphaTest;
			var program:LightMapMaterialProgram = programs[key];
			if (program == null) {
				// Make program
				// Vertex shader
				var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);

				var positionVar:String = "aPosition";
				vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
				if (object.transformProcedure != null) {
					positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
				}
				vertexLinker.addProcedure(_projectProcedure);
				vertexLinker.setInputParams(_projectProcedure, positionVar);
				vertexLinker.addProcedure(_passUVProcedure);
				vertexLinker.addProcedure(_passLightMapUVProcedure);

				// Pixel shader
				var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
				fragmentLinker.declareVariable("tColor");
				var outProcedure:Procedure = (opacityMap != null ? getDiffuseOpacityProcedure : getDiffuseProcedure);
				fragmentLinker.addProcedure(outProcedure);
				fragmentLinker.setOutputParams(outProcedure, "tColor");

				if (alphaTest > 0) {
					outProcedure = alphaTest == 1 ? thresholdOpaqueAlphaProcedure : thresholdTransparentAlphaProcedure;
					fragmentLinker.addProcedure(outProcedure, "tColor");
					fragmentLinker.setOutputParams(outProcedure, "tColor");
				}

				fragmentLinker.addProcedure(_applyLightMapProcedure, "tColor");

				fragmentLinker.varyings = vertexLinker.varyings;

				program = new LightMapMaterialProgram(vertexLinker, fragmentLinker);

				program.upload(camera.context3D);
				programs[key] = program;
			}
			return program;
		}

		private function getDrawUnit(program:LightMapMaterialProgram, camera:Camera3D, surface:Surface, geometry:Geometry, opacityMap:TextureResource):DrawUnit {
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var lightMapUVBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[lightMapChannel]);

			var object:Object3D = surface.object;

			// Drawcall
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			drawUnit.setVertexBufferAt(program.aUV1, lightMapUVBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[lightMapChannel]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[lightMapChannel]]);
			// Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);
			drawUnit.setFragmentConstantsFromNumbers(program.cThresholdAlpha, alphaThreshold, 0, 0, alpha);
			// Textures
			drawUnit.setTextureAt(program.sDiffuse, diffuseMap._texture);
			drawUnit.setTextureAt(program.sLightMap, lightMap._texture);
			if (opacityMap != null) {
				drawUnit.setTextureAt(program.sOpacity, opacityMap._texture);
			}

			return drawUnit;
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			if (diffuseMap == null || lightMap == null || diffuseMap._texture == null || lightMap._texture == null) return;
			if (opacityMap != null && opacityMap._texture == null) return;

			var object:Object3D = surface.object;

			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var lightMapUVBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[lightMapChannel]);

			if (positionBuffer == null || uvBuffer == null || lightMapUVBuffer == null) return;

			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Dictionary();
					caches[cachedContext3D] = programsCache;
				}
			}

			var optionsPrograms:Vector.<LightMapMaterialProgram> = programsCache[object.transformProcedure];
			if(optionsPrograms == null) {
				optionsPrograms = new Vector.<LightMapMaterialProgram>(6, true);
				programsCache[object.transformProcedure] = optionsPrograms;
			}

			var program:LightMapMaterialProgram;
			var drawUnit:DrawUnit;
			// Opaque pass
			if (opaquePass && alphaThreshold <= alpha) {
				if (alphaThreshold > 0) {
					// Alpha test
					// use opacityMap if it is presented
					program = getProgram(object, optionsPrograms, camera, opacityMap, 1);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// do not use opacityMap at all
					program = getProgram(object, optionsPrograms, camera, null, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, null);
				}
				// Use z-buffer within DrawCall, draws without blending
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
			// Transparent pass
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				// use opacityMap if it is presented
				if (alphaThreshold <= alpha && !opaquePass) {
					// Alpha threshold
					program = getProgram(object, optionsPrograms, camera, opacityMap, 2);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// There is no Alpha threshold or check z-buffer by previous pass
					program = getProgram(object, optionsPrograms, camera, opacityMap, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				}
				// Do not use z-buffer, draws with blending
				drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
				drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
			}
		}

	}
}

import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

import flash.display3D.Context3D;

class LightMapMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var aUV1:int = -1;
	public var cProjMatrix:int = -1;
	public var cThresholdAlpha:int = -1;
	public var sDiffuse:int = -1;
	public var sLightMap:int = -1;
	public var sOpacity:int = -1;

	public function LightMapMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition = vertexShader.findVariable("aPosition");
		aUV = vertexShader.findVariable("aUV");
		aUV1 = vertexShader.findVariable("aUV1");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		cThresholdAlpha = fragmentShader.findVariable("cThresholdAlpha");
		sDiffuse = fragmentShader.findVariable("sDiffuse");
		sLightMap = fragmentShader.findVariable("sLightMap");
		sOpacity = fragmentShader.findVariable("sOpacity");
	}

}
