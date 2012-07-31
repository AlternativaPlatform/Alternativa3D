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
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.SpotLight;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Texture material with dynamic vertex lightning. The material is able to draw skin
	 * with the number of bones in surface no more than 41. To reduce the number of bones in surface can break
	 * the skin for more surface with fewer bones. Use the method Skin.divide(). To be drawn with this material, geometry should have UV coordinates and vertex normals​​.
	 *
	 * @see alternativa.engine3d.objects.Skin#divide()
	 * @see alternativa.engine3d.core.VertexAttributes#TEXCOORDS
	 * @see alternativa.engine3d.core.VertexAttributes#NORMAL
	 */
	public class VertexLightTextureMaterial extends TextureMaterial {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;

		private static const _passLightingProcedure:Procedure = new Procedure(["#v0=vLightColor","mov v0, i0"], "passLightingProcedure");
		private static const _ambientLightProcedure:Procedure = new Procedure(["mov o0, i0"], "ambientLightProcedure");
		private static const _mulLightingProcedure:Procedure = new Procedure(["#v0=vLightColor","mul o0, i0, v0"], "mulLightingProcedure");
		private static const _directionalLightCode:Array = [
			"dp3 t0.x,i0,c0",
			"sat t0.x,t0.x",
			"mul t0, c1, t0.xxxx",
			"add o0, o0, t0"
		];

		private static const _omniLightCode:Array = [
			"sub t0, c0, i1", // L = pos - lightPos
			"dp3 t0.w, t0, t0", // lenSqr
			"nrm t0.xyz,t0.xyz", // L = normalize(L)
			"dp3 t0.x,t0,i0", // dot = dot(normal, L)
			"sqt t0.w,t0.w", // len = sqt(lensqr)
			"sub t0.w, t0.w, c2.z", // len = len - atenuationBegin
			"div t0.y, t0.w, c2.y", // att = len/radius
			"sub t0.w, c2.x, t0.y", // att = 1 - len/radius
			"sat t0.xw,t0.xw", // t = sat(t)
			"mul t0.xyz,c1.xyz,t0.xxx", // t = color*t
			"mul t0.xyz, t0.xyz, t0.www",
			"add o0.xyz, o0.xyz, t0.xyz"
		];

		private static const _spotLightCode:Array = [
			"sub t0, c0, i1", // L = pos - lightPos
			"dp3 t0.w, t0, t0", // lenSqr

			"nrm t0.xyz,t0.xyz", // L = normalize(L)

			"dp3 t1.x, t0.xyz, c3.xyz", //axisDirDot
			"dp3 t0.x,t0,i0", // dot = dot(normal, L)

			"sqt t0.w,t0.w", // len = sqt(lensqr)
			"sub t0.w, t0.w, c2.y", // len = len - atenuationBegin
			"div t0.y, t0.w, c2.x", // att = len/radius
			"sub t0.w, c0.w, t0.y", // att = 1 - len/radius
			"sub t0.y, t1.x, c2.w",
			"div t0.y, t0.y, c2.z",
			"sat t0.xyw,t0.xyw", // t = sat(t)
			"mul t1.xyz,c1.xyz,t0.xxx", // t = color*t
			"mul t1.xyz,t1.xyz,t0.yyy", //
			"mul t1.xyz, t1.xyz, t0.www",
			"add o0.xyz, o0.xyz, t1.xyz"
		];

		private static const _lightsProcedures:Dictionary = new Dictionary(true);

		/**
		 * @private
		 */
		alternativa3d static var fallbackMaterial:TextureMaterial = new TextureMaterial();

		/**
		 * Creates a new VertexLightTextureMaterial instance.
		 *
		 * @param diffuse Diffuse map.
		 * @param alpha Transparency.
		 */
		public function VertexLightTextureMaterial(diffuse:TextureResource = null, opacityMap:TextureResource = null, alpha:Number = 1) {
			super(diffuse, opacityMap, alpha);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:VertexLightTextureMaterial = new VertexLightTextureMaterial(diffuseMap, opacityMap, alpha);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @param object
		 * @param materialKey
		 * @param opacityMap
		 * @param alphaTest - 0:disabled 1:alpha-test 2:contours
		 * @param lights
		 * @param directionalLight
		 * @param lightsLength
		 */
		private function getProgram(object:Object3D, programs:Dictionary, camera:Camera3D, materialKey:String, opacityMap:TextureResource, alphaTest:int, lights:Vector.<Light3D>, lightsLength:int):VertexLightTextureMaterialProgram {
			var key:String = materialKey + (opacityMap != null ? "O" : "o") + alphaTest.toString();
			var program:VertexLightTextureMaterialProgram = programs[key];
			if (program == null) {
				var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
				vertexLinker.declareVariable("tTotalLight");
				vertexLinker.declareVariable("aNormal", VariableType.ATTRIBUTE);
				vertexLinker.declareVariable("cAmbientColor", VariableType.CONSTANT);
				vertexLinker.addProcedure(_passUVProcedure);
				var positionVar:String = "aPosition";
				vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
				if (object.transformProcedure != null) {
					positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
				}
				vertexLinker.addProcedure(_projectProcedure);
				vertexLinker.setInputParams(_projectProcedure, positionVar);
				vertexLinker.addProcedure(_ambientLightProcedure);
				vertexLinker.setInputParams(_ambientLightProcedure, "cAmbientColor");
				vertexLinker.setOutputParams(_ambientLightProcedure, "tTotalLight");
				if (lightsLength > 0) {
					var normalVar:String = "aNormal";
					if (object.deltaTransformProcedure != null) {
						vertexLinker.declareVariable("tTransformedNormal");
						vertexLinker.addProcedure(object.deltaTransformProcedure);
						vertexLinker.setInputParams(object.deltaTransformProcedure, "aNormal");
						vertexLinker.setOutputParams(object.deltaTransformProcedure, "tTransformedNormal");
						normalVar = "tTransformedNormal";
					}
					for (var i:uint = 0; i < lightsLength; i++) {
						var light:Light3D = lights[i];
						var lightProcedure:Procedure = _lightsProcedures[light];
						if (lightProcedure == null) {
							lightProcedure = new Procedure();
							if (light is DirectionalLight) {
								lightProcedure.compileFromArray(_directionalLightCode);
								lightProcedure.assignVariableName(VariableType.CONSTANT, 0, "c" + light.name + "Direction");
								lightProcedure.name = "Directional" + i.toString();
							} else if (light is OmniLight) {
								lightProcedure.compileFromArray(_omniLightCode);
								lightProcedure.assignVariableName(VariableType.CONSTANT, 0, "c" + light.name + "Position");
								lightProcedure.assignVariableName(VariableType.CONSTANT, 2, "c" + light.name + "Radius");
								lightProcedure.name = "Omni" + i.toString();
							} else if (light is SpotLight) {
								lightProcedure.compileFromArray(_spotLightCode);
								lightProcedure.assignVariableName(VariableType.CONSTANT, 0, "c" + light.name + "Position");
								lightProcedure.assignVariableName(VariableType.CONSTANT, 2, "c" + light.name + "Radius");
								lightProcedure.assignVariableName(VariableType.CONSTANT, 3, "c" + light.name + "Axis");
								lightProcedure.name = "Spot" + i.toString();
							}
							lightProcedure.assignVariableName(VariableType.CONSTANT, 1, "c" + light.name + "Color");
							_lightsProcedures[light] = lightProcedure;
						}
						vertexLinker.addProcedure(lightProcedure);
						vertexLinker.setInputParams(lightProcedure, normalVar, positionVar);
						vertexLinker.setOutputParams(lightProcedure, "tTotalLight");
					}
				}
				vertexLinker.addProcedure(_passLightingProcedure);
				vertexLinker.setInputParams(_passLightingProcedure, "tTotalLight");

				var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
				fragmentLinker.declareVariable("tColor");
				var outputProcedure:Procedure = opacityMap != null ? getDiffuseOpacityProcedure : getDiffuseProcedure;
				fragmentLinker.addProcedure(outputProcedure);
				fragmentLinker.setOutputParams(outputProcedure, "tColor");

				if (alphaTest > 0) {
					outputProcedure = alphaTest == 1 ? thresholdOpaqueAlphaProcedure : thresholdTransparentAlphaProcedure;
					fragmentLinker.addProcedure(outputProcedure, "tColor");
					fragmentLinker.setOutputParams(outputProcedure, "tColor");
				}
				fragmentLinker.addProcedure(_mulLightingProcedure, "tColor");

				fragmentLinker.varyings = vertexLinker.varyings;
				program = new VertexLightTextureMaterialProgram(vertexLinker, fragmentLinker);

				program.upload(camera.context3D);
				programs[key] = program;
			}
			return program;
		}

		private function getDrawUnit(program:VertexLightTextureMaterialProgram, camera:Camera3D, surface:Surface, geometry:Geometry, opacityMap:TextureResource, lights:Vector.<Light3D>, lightsLength:int):DrawUnit {
			// Buffers
			var object:Object3D = surface.object;

			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);

			// Draw call
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

			// Streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);

			// Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);
			drawUnit.setVertexConstantsFromVector(program.cAmbientColor, camera.ambient, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.cThresholdAlpha, alphaThreshold, 0, 0, alpha);

			if (lightsLength > 0) {
				drawUnit.setVertexBufferAt(program.aNormal, normalsBuffer, geometry._attributesOffsets[VertexAttributes.NORMAL], VertexAttributes.FORMATS[VertexAttributes.NORMAL]);

				var i:int;
				var light:Light3D;

				var transform:Transform3D;
				var rScale:Number;
				for (i = 0; i < lightsLength; i++) {
					light = lights[i];
					transform = light.lightToObjectTransform;
					var len:Number = Math.sqrt(transform.c*transform.c + transform.g*transform.g + transform.k*transform.k);
					if (light is DirectionalLight) {
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Direction"), -transform.c/len, -transform.g/len, -transform.k/len);
					} else if (light is OmniLight) {
						var omni:OmniLight = light as OmniLight;
						rScale = Math.sqrt(transform.a*transform.a + transform.e*transform.e + transform.i*transform.i);
						rScale += Math.sqrt(transform.b*transform.b + transform.f*transform.f + transform.j*transform.j);
						rScale += len;
						rScale /= 3;
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Position"), transform.d, transform.h, transform.l);
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Radius"), 1, omni.attenuationEnd*rScale - omni.attenuationBegin*rScale, omni.attenuationBegin*rScale);
					} else if (light is SpotLight) {
						var spot:SpotLight = light as SpotLight;
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Position"), transform.d, transform.h, transform.l);
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Axis"), -transform.c/len, -transform.g/len, -transform.k/len);
						rScale = Math.sqrt(transform.a*transform.a + transform.e*transform.e + transform.i*transform.i);
						rScale += Math.sqrt(transform.b*transform.b + transform.f*transform.f + transform.j*transform.j);
						rScale += len;
						rScale /= 3;

						var falloff:Number = Math.cos(spot.falloff*0.5);
						var hotspot:Number = Math.cos(spot.hotspot*0.5);
						drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Radius"), spot.attenuationEnd*rScale - spot.attenuationBegin*rScale, spot.attenuationBegin*rScale, hotspot == falloff ? 0.000001 : hotspot - falloff, falloff);
					}
					drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("c" + light.name + "Color"), light.red, light.green, light.blue);
				}
			}

			// Textures
			drawUnit.setTextureAt(program.sDiffuse, diffuseMap._texture);
			if (opacityMap != null) {
				drawUnit.setTextureAt(program.sOpacity, opacityMap._texture);
			}
			return drawUnit;
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			if (diffuseMap == null || diffuseMap._texture == null || opacityMap != null && opacityMap._texture == null) return;

			if (camera.context3DProperties.isConstrained) {
				// fallback to texture material
				fallbackMaterial.diffuseMap = diffuseMap;
				fallbackMaterial.opacityMap = opacityMap;
				fallbackMaterial.alphaThreshold = alphaThreshold;
				fallbackMaterial.alpha = alpha;
				fallbackMaterial.opaquePass = opaquePass;
				fallbackMaterial.transparentPass = transparentPass;
				fallbackMaterial.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, objectRenderPriority);
				return;
			}

			var object:Object3D = surface.object;

			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);

			if (positionBuffer == null || uvBuffer == null || normalsBuffer == null) return;

			// Program
			var light:Light3D;
			var materialKey:String = "";
			// TODO: Form key by each light types count, not id
			for (var i:int = 0; i < lightsLength; i++) {
				light = lights[i];
				materialKey += light.lightID;
			}

			// Refresh programs for this context.
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Dictionary();
					caches[cachedContext3D] = programsCache;
				}
			}

			var optionsPrograms:Dictionary = programsCache[object.transformProcedure];
			if (optionsPrograms == null) {
				optionsPrograms = new Dictionary(false);
				programsCache[object.transformProcedure] = optionsPrograms;
			}

			var program:VertexLightTextureMaterialProgram;
			var drawUnit:DrawUnit;
			// Opaque passOpaque pass
			if (opaquePass && alphaThreshold <= alpha) {
				if (alphaThreshold > 0) {
					// Alpha test
					// use opacityMap if it is presented
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 1, lights, lightsLength);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength);
				} else {
					// do not use opacityMap at all
					program = getProgram(object, optionsPrograms, camera, materialKey, null, 0, lights, lightsLength);
					drawUnit = getDrawUnit(program, camera, surface, geometry, null, lights, lightsLength);
				}
				// Use z-buffer within DrawCall, draws without blending
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
			// Transparent pass
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				// use opacityMap if it is presented
				if (alphaThreshold <= alpha && !opaquePass) {
					// Alpha threshold
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 2, lights, lightsLength);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength);
				} else {
					// There is no Alpha threshold or check z-buffer by previous pass
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 0, lights, lightsLength);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength);
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

class VertexLightTextureMaterialProgram extends ShaderProgram {

	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var aNormal:int = -1;
	public var cProjMatrix:int = -1;
	public var cAmbientColor:int = -1;
	public var cThresholdAlpha:int = -1;
	public var sDiffuse:int = -1;
	public var sOpacity:int = -1;

	public function VertexLightTextureMaterialProgram(vertex:Linker, fragment:Linker) {
		super(vertex, fragment);
	}

	override public function upload(context3D:Context3D):void {
		super.upload(context3D);

		aPosition = vertexShader.findVariable("aPosition");
		aUV = vertexShader.findVariable("aUV");
		aNormal = vertexShader.findVariable("aNormal");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		cAmbientColor = vertexShader.findVariable("cAmbientColor");
		cThresholdAlpha = fragmentShader.findVariable("cThresholdAlpha");
		sDiffuse = fragmentShader.findVariable("sDiffuse");
		sOpacity = fragmentShader.findVariable("sOpacity");
	}

}
