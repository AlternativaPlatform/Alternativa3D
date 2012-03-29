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
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	import avmplus.getQualifiedClassName;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;

	/**
	 * Material with diffuse, normal, opacity, specular maps and glossiness value. The material is able to draw skin
	 * with the number of bones in surface no more than 41. To reduce the number of bones in surface can break
	 * the skin for more surface with fewer bones. Use the method Skin.divide (). To be drawn with this material,
	 * geometry should have UV coordinates vertex normals and tangent and binormal values​​.
	 *
	 * @see alternativa.engine3d.core.VertexAttributes#TEXCOORDS
	 * @see alternativa.engine3d.core.VertexAttributes#NORMAL
	 * @see alternativa.engine3d.core.VertexAttributes#TANGENT4
	 * @see alternativa.engine3d.objects.Skin#divide()
	 */
	public class StandardMaterial extends TextureMaterial {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Dictionary;

		/**
		 * @private
		 */
		alternativa3d static const DISABLED:int = 0;
		/**
		 * @private
		 */
		alternativa3d static const SIMPLE:int = 1;
		/**
		 * @private
		 */
		alternativa3d static const ADVANCED:int = 2;

		/**
		 * @private
		 */
		alternativa3d static var fogMode:int = DISABLED;
		/**
		 * @private
		 */
		alternativa3d static var fogNear:Number = 1000;
		/**
		 * @private
		 */
		alternativa3d static var fogFar:Number = 5000;

		/**
		 * @private
		 */
		alternativa3d static var fogMaxDensity:Number = 1;

		/**
		 * @private
		 */
		alternativa3d static var fogColorR:Number = 0xC8/255;
		/**
		 * @private
		 */
		alternativa3d static var fogColorG:Number = 0xA2/255;
		/**
		 * @private
		 */
		alternativa3d static var fogColorB:Number = 0xC8/255;

		/**
		 * @private
		 */
		alternativa3d static var fogTexture:TextureResource;
		 //light procedure caching. The key is light3d instance.
		private static const _lightFragmentProcedures:Dictionary = new Dictionary();

		// inputs : position
		private static const _passVaryingsProcedure:Procedure = new Procedure([
			"#v0=vPosition",
			"#v1=vViewVector",
			"#c0=cCameraPosition",
			// Pass the position
			"mov v0, i0",
			// Vector  to Camera
			"sub t0, c0, i0",
			"mov v1.xyz, t0.xyz",
			"mov v1.w, c0.w"
		]);
		
		// inputs : tangent, normal
		private static const _passTBNRightProcedure:Procedure = getPassTBNProcedure(true);
		private static const _passTBNLeftProcedure:Procedure = getPassTBNProcedure(false);
		private static function getPassTBNProcedure(right:Boolean):Procedure {
			var crsInSpace:String = (right) ? "crs t1.xyz, i0, i1" : "crs t1.xyz, i1, i0";
			return new Procedure([
				"#v0=vTangent",
				"#v1=vBinormal",
				"#v2=vNormal",
				// Calculate binormal
				crsInSpace,
				"mul t1.xyz, t1.xyz, i0.w",
				// Transpose normal matrix
				"mov v0.x, i0.x",
				"mov v0.y, t1.x",
				"mov v0.z, i1.x",
				"mov v0.w, i1.w",
				"mov v1.x, i0.y",
				"mov v1.y, t1.y",
				"mov v1.z, i1.y",
				"mov v1.w, i1.w",
				"mov v2.x, i0.z",
				"mov v2.y, t1.z",
				"mov v2.z, i1.z",
				"mov v2.w, i1.w"
			], "passTBNProcedure");
		}

		// outputs : light, highlight
		private static const _ambientLightProcedure:Procedure = new Procedure([
			"#c0=cSurface",
			"mov o0, i0",
			"mov o1, c0.xxxx"
		], "ambientLightProcedure");

		// Set o.w to glossiness
		private static const _setGlossinessFromConstantProcedure:Procedure = new Procedure([
			"#c0=cSurface",
			"mov o0.w, c0.y"
		], "setGlossinessFromConstantProcedure");
		// Set o.w to glossiness from texture
		private static const _setGlossinessFromTextureProcedure:Procedure = new Procedure([
			"#v0=vUV",
			"#c0=cSurface",
			"#s0=sGlossiness",
			"tex t0, v0, s0 <2d, repeat, linear, miplinear>",
			"mul o0.w, t0.x, c0.y"
		], "setGlossinessFromTextureProcedure");

		// outputs : normal, viewVector
		private static const _getNormalAndViewTangentProcedure:Procedure = new Procedure([
			"#v0=vTangent",
			"#v1=vBinormal",
			"#v2=vNormal",
			"#v3=vUV",
			"#v4=vViewVector",
			"#c0=cAmbientColor",
			"#s0=sBump",
			// Extract normal from the texture
			"tex t0, v3, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"sub t0.xyz, t0.xyz, c0.www",
			// Transform the normal with TBN
			"nrm t1.xyz, v0.xyz",
			"dp3 o0.x, t0.xyz, t1.xyz",
			"nrm t1.xyz, v1.xyz",
			"dp3 o0.y, t0.xyz, t1.xyz",
			"nrm t1.xyz, v2.xyz",
			"dp3 o0.z, t0.xyz, t1.xyz",
			// Normalization
			"nrm o0.xyz, o0.xyz",
			// Returns normalized vector of view
			"nrm o1.xyz, v4"
		], "getNormalAndViewTangentProcedure");
		// outputs : normal, viewVector
		private static const _getNormalAndViewObjectProcedure:Procedure = new Procedure([
			"#v3=vUV",
			"#v4=vViewVector",
			"#c0=cAmbientColor",
			"#s0=sBump",
			// Extract normal from the texture
			"tex t0, v3, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"sub t0.xyz, t0.xyz, c0.www",
			// Normalization
			"nrm o0.xyz, t0.xyz",
			// Returns normalized vector of view
			"nrm o1.xyz, v4"
		], "getNormalAndViewObjectProcedure");

		// Apply specular map color to a flare
		private static const _applySpecularProcedure:Procedure = new Procedure([
			"#v0=vUV",
			"#s0=sSpecular",
			"tex t0, v0, s0 <2d, repeat,linear,miplinear>",
			"mul o0.xyz, o0.xyz, t0.xyz"
		], "applySpecularProcedure");

		//Apply light and flare to diffuse
		// inputs : "diffuse", "tTotalLight", "tTotalHighLight"
		private static const _mulLightingProcedure:Procedure = new Procedure([
			"#c0=cSurface",  // c0.z - specularPower
			"mul i0.xyz, i0.xyz, i1.xyz",
			"mul t1.xyz, i2.xyz, c0.z",
			"add i0.xyz, i0.xyz, t1.xyz",
			"mov o0, i0"
		], "mulLightingProcedure");

		// inputs : position
		private static const passSimpleFogConstProcedure:Procedure = new Procedure([
			"#v0=vZDistance",
			"#c0=cFogSpace",
			"dp4 t0.z, i0, c0",
			"mov v0, t0.zzzz",
			"sub v0.y, i0.w, t0.z"
		], "passSimpleFogConst");

		// inputs : color
		private static const outputWithSimpleFogProcedure:Procedure = new Procedure([
			"#v0=vZDistance",
			"#c0=cFogColor",
			"#c1=cFogRange",
			// Restrict fog factor with the range
			"min t0.xy, v0.xy, c1.xy",
			"max t0.xy, t0.xy, c1.zw",
			"mul i0.xyz, i0.xyz, t0.y",
			"mul t0.xyz, c0.xyz, t0.x",
			"add i0.xyz, i0.xyz, t0.xyz",
			"mov o0, i0"
		], "outputWithSimpleFog");

		// inputs : position, projected
		private static const postPassAdvancedFogConstProcedure:Procedure = new Procedure([
			"#v0=vZDistance",
			"#c0=cFogSpace",
			"dp4 t0.z, i0, c0",
			"mov v0, t0.zzzz",
			"sub v0.y, i0.w, t0.z",
			// Screen x coordinate
			"mov v0.zw, i1.xwxw",
			"mov o0, i1"
		], "postPassAdvancedFogConst");

		// inputs : color
		private static const outputWithAdvancedFogProcedure:Procedure = new Procedure([
			"#v0=vZDistance",
			"#c0=cFogConsts",
			"#c1=cFogRange",
			"#s0=sFogTexture",
			// Restrict fog factor with the range
			"min t0.xy, v0.xy, c1.xy",
			"max t0.xy, t0.xy, c1.zw",
			"mul i0.xyz, i0.xyz, t0.y",
			// Calculate fog color
			"mov t1.xyzw, c0.yyzw",
			"div t0.z, v0.z, v0.w",
			"mul t0.z, t0.z, c0.x",
			"add t1.x, t1.x, t0.z",
			"tex t1, t1, s0 <2d, repeat, linear, miplinear>",
			"mul t0.xyz, t1.xyz, t0.x",
			"add i0.xyz, i0.xyz, t0.xyz",
			"mov o0, i0"
		], "outputWithAdvancedFog");

		// Add lightmap value with light
		private static const _addLightMapProcedure:Procedure = new Procedure([
			"#v0=vUV1",
			"#s0=sLightMap",
			"tex t0, v0, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"add o0.xyz, i0.xyz, t0.xyz"
		], "applyLightMapProcedure");

		private static const _passLightMapUVProcedure:Procedure = new Procedure([
			"#a0=aUV1",
			"#v0=vUV1",
			"mov v0, a0"
		], "passLightMapUVProcedure");

		/**
		 * Normal map.
		 */
		public var normalMap:TextureResource;

		private var _normalMapSpace:int = NormalMapSpace.TANGENT_RIGHT_HANDED;
		/**
		 * Type of the normal map. Should be defined by constants of   <code>NormalMapSpace</code> class.
		 *
		 * @default NormalMapSpace.TANGENT
		 *
		 * @see NormalMapSpace
		 */
		public function get normalMapSpace():int {
			return _normalMapSpace;
		}

		/**
		 * @private
		 */
		public function set normalMapSpace(value:int):void {
			if (value != NormalMapSpace.TANGENT_RIGHT_HANDED && value != NormalMapSpace.TANGENT_LEFT_HANDED && value != NormalMapSpace.OBJECT) {
				throw new ArgumentError("Value must be a constant from the NormalMapSpace class");
			}
			_normalMapSpace = value;
		}

		/**
		 * Specular map.
		 */
		public var specularMap:TextureResource;
		/**
		 * Glossiness map.
		 */
		public var glossinessMap:TextureResource;

		/**
		 * Light map.
		 */
		public var lightMap:TextureResource;

		/**
		 * Number of the UV-channel for light map.
		 */
		public var lightMapChannel:uint = 0;
		/**
		 * Glossiness. Multiplies with  <code>glossinessMap</code> value.
		 */
		public var glossiness:Number = 100;

		/**
		 * Brightness of a flare. Multiplies with  <code>specularMap</code> value.
		 */
		public var specularPower:Number = 1;

		/**
		 * Creates a new StandardMaterial instance.
		 * @param diffuseMap Diffuse map.
		 * @param normalMap Normal map.
		 * @param specularMap Specular map.
		 * @param glossinessMap Glossiness map.
		 * @param opacityMap Opacity map.
		 */
		public function StandardMaterial(diffuseMap:TextureResource = null, normalMap:TextureResource = null, specularMap:TextureResource = null, glossinessMap:TextureResource = null, opacityMap:TextureResource = null) {
			super(diffuseMap, opacityMap);
			this.normalMap = normalMap;
			this.specularMap = specularMap;
			this.glossinessMap = glossinessMap;
		}

		/**
		 * @private
		 */
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void {
			super.fillResources(resources, resourceType);
			if (normalMap != null &&
					A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(normalMap)) as Class, resourceType)) {
				resources[normalMap] = true;
			}

			if (lightMap != null &&
					A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(lightMap)) as Class, resourceType)) {
				resources[lightMap] = true;
			}

			if (glossinessMap != null &&
					A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(glossinessMap)) as Class, resourceType)) {
				resources[glossinessMap] = true;
			}

			if (specularMap != null &&
					A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(specularMap)) as Class, resourceType)) {
				resources[specularMap] = true;
			}
		}

		/**
		 * @private
		 */
		alternativa3d function getPassUVProcedure():Procedure {
			return _passUVProcedure;
		}

		/**
		 * @private
		 */
		alternativa3d function setPassUVProcedureConstants(destination:DrawUnit, vertexLinker:Linker):void {
		}

		// inputs: tNormal", "tViewVector", "shadow", "cAmbientColor"
		// outputs : light, hightlight
		private function formDirectionalProcedure(procedure:Procedure, light:Light3D, useShadow:Boolean):void {
			var source:Array = [
				"#c0=c" + light.lightID + "Direction",
				"#c1=c" + light.lightID + "Color",
				// Calculate half-way vector
				"add t0.xyz, i1.xyz, c0.xyz",
				"mov t0.w, c0.w",
				"nrm t0.xyz,t0.xyz",
				// Calculate a flare
				"dp3 t0.w, t0.xyz, i0.xyz",
				"pow t0.w, t0.w, o1.w",
				// Calculate light
				"dp3 t0.x, i0.xyz, c0.xyz",
				"sat t0.x, t0.x",
			];
			if (useShadow) {
				source.push("mul t0.x, t0.x, i2.x");
				source.push("mul t0.xyz, c1.xyz, t0.xxx");
				source.push("add o0.xyz, t0.xyz, i3.xyz");
				source.push("mul t0.w, i2.x, t0.w");
				source.push("mul o1.xyz, c1.xyz, t0.www");
			} else {
				// Apply calculated values
				source.push("mul t0.xyz, c1.xyz, t0.xxxx");
				source.push("add o0, o0, t0.xyz");
				source.push("mul t0.xyz, c1.xyz, t0.w");
				source.push("add o1.xyz, o1.xyz, t0.xyz");
			}
			procedure.compileFromArray(source);
		}

		/**
		 * @param object
		 * @param materialKey
		 * @param opacityMap
		 * @param alphaTest 0:disabled 1:alpha-test 2:contours
		 * @param lights
		 * @param directionalLight
		 * @param lightsLength
		 */
		private function getProgram(object:Object3D, programs:Dictionary, camera:Camera3D, materialKey:String, opacityMap:TextureResource, alphaTest:int, lights:Vector.<Light3D>, lightsLength:int, shadowedLight:Light3D):ShaderProgram {
			var key:String = materialKey + (opacityMap != null ? "O" : "o") + alphaTest.toString();
			var program:ShaderProgram = programs[key];
			if (program == null) {
				var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
				var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
				var i:int;

				fragmentLinker.declareVariable("tTotalLight");
				fragmentLinker.declareVariable("tTotalHighLight");
				fragmentLinker.declareVariable("tNormal");
				fragmentLinker.declareVariable("cAmbientColor", VariableType.CONSTANT);
				fragmentLinker.addProcedure(_ambientLightProcedure);
				fragmentLinker.setInputParams(_ambientLightProcedure, "cAmbientColor");
				fragmentLinker.setOutputParams(_ambientLightProcedure, "tTotalLight", "tTotalHighLight");
				var positionVar:String = "aPosition";
				var normalVar:String = "aNormal";
				var tangentVar:String = "aTangent";
				vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
				vertexLinker.declareVariable(tangentVar, VariableType.ATTRIBUTE);
				vertexLinker.declareVariable(normalVar, VariableType.ATTRIBUTE);
				if (object.transformProcedure != null) {
					positionVar = appendPositionTransformProcedure(object.transformProcedure, vertexLinker);
				}

				vertexLinker.addProcedure(_projectProcedure);
				vertexLinker.setInputParams(_projectProcedure, positionVar);

				vertexLinker.addProcedure(getPassUVProcedure());

				if (glossinessMap != null) {
					fragmentLinker.addProcedure(_setGlossinessFromTextureProcedure);
					fragmentLinker.setOutputParams(_setGlossinessFromTextureProcedure, "tTotalHighLight");
				} else {
					fragmentLinker.addProcedure(_setGlossinessFromConstantProcedure);
					fragmentLinker.setOutputParams(_setGlossinessFromConstantProcedure, "tTotalHighLight");
				}
				if (lightsLength > 0) {
					var procedure:Procedure;
					if (object.deltaTransformProcedure != null) {
						vertexLinker.declareVariable("tTransformedNormal");
						procedure = object.deltaTransformProcedure.newInstance();
						vertexLinker.addProcedure(procedure);
						vertexLinker.setInputParams(procedure, normalVar);
						vertexLinker.setOutputParams(procedure, "tTransformedNormal");
						normalVar = "tTransformedNormal";

						vertexLinker.declareVariable("tTransformedTangent");
						procedure = object.deltaTransformProcedure.newInstance();
						vertexLinker.addProcedure(procedure);
						vertexLinker.setInputParams(procedure, tangentVar);
						vertexLinker.setOutputParams(procedure, "tTransformedTangent");
						tangentVar = "tTransformedTangent";
					}
					vertexLinker.addProcedure(_passVaryingsProcedure);
					vertexLinker.setInputParams(_passVaryingsProcedure, positionVar);
					fragmentLinker.declareVariable("tViewVector");

					if (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) {
						var nrmProcedure:Procedure = (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED) ? _passTBNRightProcedure : _passTBNLeftProcedure;
						vertexLinker.addProcedure(nrmProcedure);
						vertexLinker.setInputParams(nrmProcedure, tangentVar, normalVar);
						fragmentLinker.addProcedure(_getNormalAndViewTangentProcedure);
						fragmentLinker.setOutputParams(_getNormalAndViewTangentProcedure, "tNormal", "tViewVector");
					} else {
						fragmentLinker.addProcedure(_getNormalAndViewObjectProcedure);
						fragmentLinker.setOutputParams(_getNormalAndViewObjectProcedure, "tNormal", "tViewVector");
					}
					if (shadowedLight != null && shadowedLight is DirectionalLight) {
						vertexLinker.addProcedure(shadowedLight.shadow.vertexShadowProcedure, positionVar);
						var shadowProc:Procedure = shadowedLight.shadow.fragmentShadowProcedure;
						fragmentLinker.addProcedure(shadowProc);
						fragmentLinker.setOutputParams(shadowProc, "tTotalLight");

						var dirMulShadowProcedure:Procedure = _lightFragmentProcedures[shadowedLight.shadow];
						if (dirMulShadowProcedure == null) {
							dirMulShadowProcedure = new Procedure();
							formDirectionalProcedure(dirMulShadowProcedure, shadowedLight, true);
						}
						fragmentLinker.addProcedure(dirMulShadowProcedure);
						fragmentLinker.setInputParams(dirMulShadowProcedure, "tNormal", "tViewVector", "tTotalLight", "cAmbientColor");
						fragmentLinker.setOutputParams(dirMulShadowProcedure, "tTotalLight", "tTotalHighLight");
					}

					for (i = 0; i < lightsLength; i++) {
						var light:Light3D = lights[i];
						if (light == shadowedLight) continue;
						var lightFragmentProcedure:Procedure = _lightFragmentProcedures[light];
						if (lightFragmentProcedure == null) {
							lightFragmentProcedure = new Procedure();
							lightFragmentProcedure.name = "light" + i.toString();
							if (light is DirectionalLight) {
								formDirectionalProcedure(lightFragmentProcedure, light, false);
								lightFragmentProcedure.name += "Directional";
							} else if (light is OmniLight) {
								lightFragmentProcedure.compileFromArray([
									"#c0=c" + light.lightID + "Position",
									"#c1=c" + light.lightID + "Color",
									"#c2=c" + light.lightID + "Radius",
									"#v0=vPosition",
									// Calculate vector from the point to light
									"sub t0, c0, v0", // L = lightPos - PointPos
									"dp3 t0.w, t0.xyz, t0.xyz", // lenSqr
									"nrm t0.xyz, t0.xyz", // L = normalize(L)
									// Calculate half-way vector
									"add t1.xyz, i1.xyz, t0.xyz",
									"mov t1.w, c0.w",
									"nrm t1.xyz, t1.xyz",
									// Calculate a flare
									"dp3 t1.w, t1.xyz, i0.xyz",
									"pow t1.w, t1.w, o1.w",
									// Calculate distance to the light source
									"sqt t1.x, t0.w", // len = sqt(lensqr)
									// Calculate light
									"dp3 t0.w, t0.xyz, i0.xyz", // dot = dot(normal, L)
									// Calculate decay
									"sub t0.x, t1.x, c2.z", // len = len - atenuationBegin
									"div t0.y, t0.x, c2.y", // att = len/radius
									"sub t0.x, c2.x, t0.y", // att = 1 - len/radius
									"sat t0.xw, t0.xw", // t = max(t, 0)
									// Multiply light color with the decay value
									"mul t0.xyz, c1.xyz, t0.xxx", // t = color*t
									"mul t1.xyz, t0.xyz, t1.w",
									"add o1.xyz, o1.xyz, t1.xyz",
									"mul t0.xyz, t0.xyz, t0.www",
									"add o0.xyz, o0.xyz, t0.xyz"
								]);
								lightFragmentProcedure.name += "Omni";
							} else if (light is SpotLight) {
								lightFragmentProcedure.compileFromArray([
									"#c0=c" + light.lightID + "Position",
									"#c1=c" + light.lightID + "Color",
									"#c2=c" + light.lightID + "Radius",
									"#c3=c" + light.lightID + "Axis",
									"#v0=vPosition",
									// Calculate vector from the point to light
									"sub t0, c0, v0",// L = pos - lightPos
									"dp3 t0.w, t0, t0",// lenSqr
									"nrm t0.xyz,t0.xyz",// L = normalize(L)
									// Calculate half-way vector
									"add t2.xyz, i1.xyz, t0.xyz",
									"nrm t2.xyz, t2.xyz",
									//Calculate a flare
									"dp3 t2.x, t2.xyz, i0.xyz",
									"pow t2.x, t2.x, o1.w",
									"dp3 t1.x, t0.xyz, c3.xyz", //axisDirDot
									"dp3 t0.x, t0, i0.xyz",// dot = dot(normal, L)
									"sqt t0.w, t0.w",// len = sqt(lensqr)
									"sub t0.w, t0.w, c2.y",// len = len - atenuationBegin
									"div t0.y, t0.w, c2.x",// att = len/radius
									"sub t0.w, c0.w, t0.y",// att = 1 - len/radius
									"sub t0.y, t1.x, c2.w",
									"div t0.y, t0.y, c2.z",
									"sat t0.xyw,t0.xyw",// t = sat(t)
									"mul t1.xyz,c1.xyz,t0.yyy",// t = color*t
									"mul t1.xyz,t1.xyz,t0.www",//
									"mul t2.xyz, t2.x, t1.xyz",
									"add o1.xyz, o1.xyz, t2.xyz",
									"mul t1.xyz, t1.xyz, t0.xxx",

									"add o0.xyz, o0.xyz, t1.xyz"
								]);
								lightFragmentProcedure.name += "Spot";
							}
						}
						fragmentLinker.addProcedure(lightFragmentProcedure);
						fragmentLinker.setInputParams(lightFragmentProcedure, "tNormal", "tViewVector");
						fragmentLinker.setOutputParams(lightFragmentProcedure, "tTotalLight", "tTotalHighLight");
					}
				}

				var outputProcedure:Procedure;
				if (specularMap != null) {
					fragmentLinker.addProcedure(_applySpecularProcedure);
					fragmentLinker.setOutputParams(_applySpecularProcedure, "tTotalHighLight");
					outputProcedure = _applySpecularProcedure;
				}
				if (lightMap != null) {
					vertexLinker.addProcedure(_passLightMapUVProcedure);
					fragmentLinker.addProcedure(_addLightMapProcedure);
					fragmentLinker.setInputParams(_addLightMapProcedure, "tTotalLight");
					fragmentLinker.setOutputParams(_addLightMapProcedure, "tTotalLight");
				}
				
				fragmentLinker.declareVariable("tColor");
				outputProcedure = opacityMap != null ? getDiffuseOpacityProcedure : getDiffuseProcedure;
				fragmentLinker.addProcedure(outputProcedure);
				fragmentLinker.setOutputParams(outputProcedure, "tColor");

				if (alphaTest > 0) {
					outputProcedure = alphaTest == 1 ? thresholdOpaqueAlphaProcedure : thresholdTransparentAlphaProcedure;
					fragmentLinker.addProcedure(outputProcedure, "tColor");
					fragmentLinker.setOutputParams(outputProcedure, "tColor");
				}

				fragmentLinker.addProcedure(_mulLightingProcedure, "tColor", "tTotalLight", "tTotalHighLight");

				
				if (fogMode == SIMPLE || fogMode == ADVANCED) {
					fragmentLinker.setOutputParams(_mulLightingProcedure, "tColor");
				}
				if (fogMode == SIMPLE) {
					vertexLinker.addProcedure(passSimpleFogConstProcedure);
					vertexLinker.setInputParams(passSimpleFogConstProcedure, positionVar);
					fragmentLinker.addProcedure(outputWithSimpleFogProcedure);
					fragmentLinker.setInputParams(outputWithSimpleFogProcedure, "tColor");
					outputProcedure = outputWithSimpleFogProcedure;
				} else if (fogMode == ADVANCED) {
					vertexLinker.declareVariable("tProjected");
					vertexLinker.setOutputParams(_projectProcedure, "tProjected");
					vertexLinker.addProcedure(postPassAdvancedFogConstProcedure);
					vertexLinker.setInputParams(postPassAdvancedFogConstProcedure, positionVar, "tProjected");
					fragmentLinker.addProcedure(outputWithAdvancedFogProcedure);
					fragmentLinker.setInputParams(outputWithAdvancedFogProcedure, "tColor");
					outputProcedure = outputWithAdvancedFogProcedure;
				}

				fragmentLinker.varyings = vertexLinker.varyings;
				program = new ShaderProgram(vertexLinker, fragmentLinker);


				program.upload(camera.context3D);
				programs[key] = program;
			}
			return program;
		}

		private function getDrawUnit(program:ShaderProgram, camera:Camera3D, surface:Surface, geometry:Geometry, opacityMap:TextureResource, lights:Vector.<Light3D>, lightsLength:int, shadowedLight:Light3D):DrawUnit {
			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);
			var tangentsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TANGENT4);

			var object:Object3D = surface.object;

			// Draw call
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

			// Streams
			drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aPosition"), positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aUV"), uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);

			// Constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.vertexShader.getVariableIndex("cProjMatrix"), object.localToCameraTransform);
			 // Set options for a surface. X should be 0.
			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cSurface"), 0, glossiness, specularPower, 1);
			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cThresholdAlpha"), alphaThreshold, 0, 0, alpha);

			if (lightsLength > 0) {
				if (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) {
					drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aNormal"), normalsBuffer, geometry._attributesOffsets[VertexAttributes.NORMAL], VertexAttributes.FORMATS[VertexAttributes.NORMAL]);
					drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aTangent"), tangentsBuffer, geometry._attributesOffsets[VertexAttributes.TANGENT4], VertexAttributes.FORMATS[VertexAttributes.TANGENT4]);
				}
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sBump"), normalMap._texture);

				var camTransform:Transform3D = object.cameraToLocalTransform;
				drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("cCameraPosition"), camTransform.d, camTransform.h, camTransform.l);

				var transform:Transform3D;
				var rScale:Number;
				for (var i:int = 0; i < lightsLength; i++) {
					var light:Light3D = lights[i];
					if (light is DirectionalLight) {
						transform = light.lightToObjectTransform;
						var len:Number = Math.sqrt(transform.c*transform.c + transform.g*transform.g + transform.k*transform.k);

						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Direction"), -transform.c/len, -transform.g/len, -transform.k/len, 1);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Color"), light.red, light.green, light.blue);
					} else if (light is OmniLight) {
						var omni:OmniLight = light as OmniLight;
						transform = light.lightToObjectTransform;
						rScale = Math.sqrt(transform.a*transform.a + transform.e*transform.e + transform.i*transform.i);
						rScale += Math.sqrt(transform.b*transform.b + transform.f*transform.f + transform.j*transform.j);
						rScale += Math.sqrt(transform.c*transform.c + transform.g*transform.g + transform.k*transform.k);
						rScale /= 3;

						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Position"), transform.d, transform.h, transform.l);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Radius"), 1, omni.attenuationEnd*rScale - omni.attenuationBegin*rScale, omni.attenuationBegin*rScale);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Color"), light.red, light.green, light.blue);
					} else if (light is SpotLight) {
						var spot:SpotLight = light as SpotLight;
						transform = light.lightToObjectTransform;
						rScale = Math.sqrt(transform.a*transform.a + transform.e*transform.e + transform.i*transform.i);
						rScale += Math.sqrt(transform.b*transform.b + transform.f*transform.f + transform.j*transform.j);
						rScale += len = Math.sqrt(transform.c*transform.c + transform.g*transform.g + transform.k*transform.k);
						rScale /= 3;
						var falloff:Number = Math.cos(spot.falloff*0.5);
						var hotspot:Number = Math.cos(spot.hotspot*0.5);

						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Position"), transform.d, transform.h, transform.l);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Axis"), -transform.c/len, -transform.g/len, -transform.k/len);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Radius"), spot.attenuationEnd*rScale - spot.attenuationBegin*rScale, spot.attenuationBegin*rScale, hotspot == falloff ? 0.000001 : hotspot - falloff, falloff);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + light.lightID + "Color"), light.red, light.green, light.blue);
					}
				}
			}

			// Textures
			drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sDiffuse"), diffuseMap._texture);
			if (opacityMap != null) {
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sOpacity"), opacityMap._texture);
			}
			if (glossinessMap != null) {
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sGlossiness"), glossinessMap._texture);
			}
			if (specularMap != null) {
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sSpecular"), specularMap._texture);
			}

			if (lightMap != null) {
				drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aUV1"),
						geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[lightMapChannel]),
						geometry._attributesOffsets[VertexAttributes.TEXCOORDS[lightMapChannel]],
						Context3DVertexBufferFormat.FLOAT_2);
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cAmbientColor"), 0,0,0, 1);
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sLightMap"), lightMap._texture);
			} else {
				drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex("cAmbientColor"), camera.ambient, 1);
			}
			setPassUVProcedureConstants(drawUnit, program.vertexShader);

			if (shadowedLight != null && shadowedLight is DirectionalLight) {
				shadowedLight.shadow.setup(drawUnit, program.vertexShader, program.fragmentShader, surface);
			}

			if (fogMode == SIMPLE || fogMode == ADVANCED) {
				var lm:Transform3D = object.localToCameraTransform;
				var dist:Number = fogFar - fogNear;
				drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("cFogSpace"), lm.i/dist, lm.j/dist, lm.k/dist, (lm.l - fogNear)/dist);
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cFogRange"), fogMaxDensity, 1, 0, 1 - fogMaxDensity);
			}
			if (fogMode == SIMPLE) {
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cFogColor"), fogColorR, fogColorG, fogColorB);
			}
			if (fogMode == ADVANCED) {
				if (fogTexture == null) {
					var bmd:BitmapData = new BitmapData(32, 1, false, 0xFF0000);
					for (i = 0; i < 32; i++) {
						bmd.setPixel(i, 0, ((i/32)*255) << 16);
					}
					fogTexture = new BitmapTextureResource(bmd);
					fogTexture.upload(camera.context3D);
				}
				var cLocal:Transform3D = camera.localToGlobalTransform;
				var halfW:Number = camera.view.width/2;
				var leftX:Number = -halfW*cLocal.a + camera.focalLength*cLocal.c;
				var leftY:Number = -halfW*cLocal.e + camera.focalLength*cLocal.g;
				var rightX:Number = halfW*cLocal.a + camera.focalLength*cLocal.c;
				var rightY:Number = halfW*cLocal.e + camera.focalLength*cLocal.g;
				// Finding UV
				var angle:Number = (Math.atan2(leftY, leftX) - Math.PI/2);
				if (angle < 0) angle += Math.PI*2;
				var dx:Number = rightX - leftX;
				var dy:Number = rightY - leftY;
				var lens:Number = Math.sqrt(dx*dx + dy*dy);
				leftX /= lens;
				leftY /= lens;
				rightX /= lens;
				rightY /= lens;
				var uScale:Number = Math.acos(leftX*rightX + leftY*rightY)/Math.PI/2;
				var uRight:Number = angle/Math.PI/2;

				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cFogConsts"), 0.5*uScale, 0.5 - uRight, 0);
				drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sFogTexture"), fogTexture._texture);
			}
			return drawUnit;
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, objectRenderPriority:int = -1):void {
			if (diffuseMap == null || normalMap == null || diffuseMap._texture == null || normalMap._texture == null) return;
			// Check if textures uploaded in to the context.
			if (opacityMap != null && opacityMap._texture == null || glossinessMap != null && glossinessMap._texture == null || specularMap != null && specularMap._texture == null || lightMap != null && lightMap._texture == null) return;

			var object:Object3D = surface.object;

			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);
			var tangentsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TANGENT4);

			if (positionBuffer == null || uvBuffer == null) return;

			if (lightsLength > 0 && (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED)) {
				if (normalsBuffer == null || tangentsBuffer == null) return;
			}

			// Make shared part of the key.
			var materialKey:String = (fogMode.toString()) +
					((lightMap != null) ? "L" : "l") +
					(_normalMapSpace.toString()) +
					((glossinessMap != null) ? "G" : "g") +
					((specularMap != null) ? "S" : "s");
			var shadowedLight:Light3D;
			for (var i:int = 0; i < lightsLength; i++) {
				var light:Light3D = lights[i];
				if (light.shadow != null && shadowedLight == null) {
					shadowedLight = light;
					materialKey += light.shadow.type;
				}
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

			var program:ShaderProgram;
			var drawUnit:DrawUnit;
			// Opaque pass
			if (opaquePass && alphaThreshold <= alpha) {
				if (alphaThreshold > 0) {
					// Alpha test
					// use opacityMap if it is presented
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 1, lights, lightsLength, shadowedLight);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength, shadowedLight);
				} else {
					// do not use opacityMap at all
					program = getProgram(object, optionsPrograms, camera, materialKey, null, 0, lights, lightsLength, shadowedLight);
					drawUnit = getDrawUnit(program, camera, surface, geometry, null, lights, lightsLength, shadowedLight);
				}
				// Use z-buffer within DrawCall, draws without blending
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
			// Transparent pass
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				// use opacityMap if it is presented
				if (alphaThreshold <= alpha && !opaquePass) {
					// Alpha threshold
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 2, lights, lightsLength, shadowedLight);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength, shadowedLight);
				} else {
					// There is no Alpha threshold or check z-buffer by previous pass
					program = getProgram(object, optionsPrograms, camera, materialKey, opacityMap, 0, lights, lightsLength, shadowedLight);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap, lights, lightsLength, shadowedLight);
				}
				// Do not use z-buffer, draws with blending
				drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
				drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:StandardMaterial = new StandardMaterial(diffuseMap, normalMap, specularMap, glossinessMap, opacityMap);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Material):void {
			super.clonePropertiesFrom(source);
			var sMaterial:StandardMaterial = StandardMaterial(source);
			glossiness = sMaterial.glossiness;
			specularPower = sMaterial.specularPower;
			_normalMapSpace = sMaterial._normalMapSpace;
			lightMap = sMaterial.lightMap;
			lightMapChannel = sMaterial.lightMapChannel;
		}

	}
}
