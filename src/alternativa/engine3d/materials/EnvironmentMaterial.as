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
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.CubeTexture;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;

	/**
	 * The material which reflects the environment given with cube texture.
	 *
	 * @see   alternativa.engine3d.resources.BitmapCubeTextureResource
	 * @see   alternativa.engine3d.resources.ExternalTextureResource
	 */
	public class EnvironmentMaterial extends TextureMaterial {

		private static var caches:Dictionary = new Dictionary(true);
		private var cachedContext3D:Context3D;
		private var programsCache:Array;

		/**
		 * @private
		 */
		alternativa3d static var fogMode:int = FogMode.DISABLED;
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

		/**
		 * @private
		 */
		static alternativa3d const _passReflectionProcedure:Procedure = new Procedure([
			// i0 = position, i1 = normal
			"#v1=vNormal",
			"#v0=vPosition",
			"mov v0, i0",
			"mov v1, i1"
		], "passReflectionProcedure");

		/**
		 * @private
		 */
		static alternativa3d const _applyReflectionProcedure:Procedure = getApplyReflectionProcedure();

		private static function getApplyReflectionProcedure():Procedure {
			var result:Procedure = new Procedure([
				"#v1=vNormal",
				"#v0=vPosition",
				"#s0=sCubeMap",
				"#c0=cCamera",
				"sub t0, v0, c0",
				"dp3 t1.x, v1, t0",
				"add t1.x, t1.x, t1.x",
				"mul t1, v1, t1.x",
				"sub t1, t0, t1",
				"nrm t1.xyz, t1.xyz",
				"m33 t1.xyz, t1.xyz, c1",
				"nrm t1.xyz, t1.xyz",
				"tex o0, t1, s0 <cube,clamp,linear,nomip>"
			], "applyReflectionProcedure");
			result.assignVariableName(VariableType.CONSTANT, 1, "cLocalToGlobal", 3);
			return result;
		}

		/**
		 * @private
		 */
		static alternativa3d const _applyReflectionNormalMapProcedure:Procedure = getApplyReflectionNormalMapProcedure();

		private static function getApplyReflectionNormalMapProcedure():Procedure {
			var result:Procedure = new Procedure([
				"#s0=sCubeMap",
				"#c0=cCamera",
				"#v0=vPosition",
				"sub t0, v0, c0",
				"dp3 t1.x, i0.xyz, t0",
				"add t1.x, t1.x, t1.x",
				"mul t1, i0.xyz, t1.x",
				"sub t1, t0, t1",
				"nrm t1.xyz, t1.xyz",
				"m33 t1.xyz, t1.xyz, c1",
				"nrm t1.xyz, t1.xyz",
				"tex o0, t1, s0 <cube,clamp,linear,nomip>"
			], "applyReflectionNormalMapProcedure");
			result.assignVariableName(VariableType.CONSTANT, 1, "cLocalToGlobal", 3);
			return result;
		}

		/**
		 * @private
		 */
		static alternativa3d const _blendReflection:Procedure = new Procedure([
			"#c0=cAlpha",
			"mul t1.xyz, i0.xyz, c0.y",
			"mul t0.xyz, i1, c0.z",
			"add t0.xyz, t1.xyz, t0",
			"mov t0.w, i0.w",
			"mov o0, t0"
		], "blendReflection");

		/**
		 * @private
		 */
		static alternativa3d const _blendReflectionMap:Procedure = new Procedure([
			"#c0=cCamera",
			"#c1=cAlpha",
			"#s0=sReflection",
			"#v0=vUV",
			"tex t0, v0, s0 <2d,repeat,linear,miplinear>",
			"mul t0, t0, c1.z",
			"mul t1.xyz, i1, t0",
			"sub t0, c0.www, t0",
			"mul t2, i0, t0",
			"add t0.xyz, t1, t2",
			"mov t0.w, i0.w",
			"mov o0, t0"
		], "blendReflectionMap");

		// inputs : tangent, normal
		private static const _passTBNRightProcedure:Procedure = getPassTBNProcedure(true);
		private static const _passTBNLeftProcedure:Procedure = getPassTBNProcedure(false);

		private static function getPassTBNProcedure(right:Boolean):Procedure {
			var crsInSpace:String = (right) ? "crs t1.xyz, i0, i1" : "crs t1.xyz, i1, i0";
			return new Procedure([
				"#v0=vTangent",
				"#v1=vBinormal",
				"#v2=vNormal",
				// Calculates binormal
				crsInSpace,
				"mul t1.xyz, t1.xyz, i0.w",
				//  Transpose normal matrix
				// TODO: can be optimized like in StandardMaterial
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

		// outputs : normal, viewVector
		private static const _getNormalTangentProcedure:Procedure = new Procedure([
			"#v0=vTangent",
			"#v1=vBinormal",
			"#v2=vNormal",
			"#v3=vUV",
			"#c0=cCamera",
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
			// Normalization after transform
			"nrm o0.xyz, o0.xyz"
		], "getNormalTangentProcedure");
		// outputs : normal, viewVector
		private static const _getNormalObjectProcedure:Procedure = new Procedure([
			"#v3=vUV",
			"#c0=cCamera",
			"#s0=sBump",
			// Extract normal from the texture
			"tex t0, v3, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"sub t0.xyz, t0.xyz, c0.www",
			// Normalization
			"nrm o0.xyz, t0.xyz"
		], "getNormalObjectProcedure");

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
			"tex t1, t1, s0 <2d,repeat,linear,miplinear>",
			"mul t0.xyz, t1.xyz, t0.x",
			"add i0.xyz, i0.xyz, t0.xyz",
			"mov o0, i0"
		], "outputWithAdvancedFog");

		private static const _applyLightMapProcedure:Procedure = new Procedure([
			"#v0=vUV1",
			"#s0=sLightMap",
			"tex t0, v0, s0 <2d,repeat,linear,miplinear>",
			"add t0, t0, t0",
			"mul o0.xyz, i0.xyz, t0.xyz"
		], "applyLightMapProcedure");

		private static const _passLightMapUVProcedure:Procedure = new Procedure([
			"#a0=aUV1",
			"#v0=vUV1",
			"mov v0, a0"
		], "passLightMapUVProcedure");

		/**
		 * @private
		 */
		alternativa3d static var fallbackTextureMaterial:TextureMaterial = new TextureMaterial();
		/**
		 * @private
		 */
		alternativa3d static var fallbackLightMapMaterial:LightMapMaterial = new LightMapMaterial();

		private var _normalMapSpace:int = NormalMapSpace.TANGENT_RIGHT_HANDED;

		/**
		 * Type of the normal map. Should be defined by constants of   <code>NormalMapSpace</code> class.
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
			dirty();
		}

		/**
		 * Normal map.
		 */
		public function get normalMap():TextureResource {
			return _normalMap;
		}

		/**
		 * @private
		 */
		public function set normalMap(value:TextureResource):void {
			_normalMap = value;
			dirty();
		}

		/**
		 * Reflection texture. Should be <code>BitmapCubeTextureResource</code> or  <code>ExternalTextureResource</code> with CubeTexture data.
		 */
		public function get environmentMap():TextureResource {
			return _environmentMap;
		}

		/**
		 * @private
		 */
		public function set environmentMap(value:TextureResource):void {
			_environmentMap = value;
			dirty();
		}

		/**
		 * Reflectivity map.
		 */
		public function get reflectionMap():TextureResource {
			return _reflectionMap;
		}

		/**
		 * @private
		 */
		public function set reflectionMap(value:TextureResource):void {
			_reflectionMap = value;
			dirty();
		}

		/**
		 * Light map.
		 */
		public function get lightMap():TextureResource {
			return _lightMap;
		}

		/**
		 * @private
		 */
		public function set lightMap(value:TextureResource):void {
			_lightMap = value;
			dirty();
		}

		/**
		 *  Reflectivity.
		 */
		public var reflection:Number = 1;

		/**
		 * Number of the UV-channel for light map.
		 */
		public var lightMapChannel:uint = 1;

		/**
		 * @private
		 */
		alternativa3d var _normalMap:TextureResource;

		/**
		 * @private
		 */
		alternativa3d var _environmentMap:TextureResource;

		/**
		 * @private
		 */
		alternativa3d var _reflectionMap:TextureResource;

		/**
		 * @private
		 */
		alternativa3d var _lightMap:TextureResource;

		private var localToGlobalTransform:Transform3D = new Transform3D();

		/**
		 *  Creates a new EnvironmentMaterial instance.
		 * @param diffuseMap
		 * @param environmentMap
		 * @param normalMap
		 * @param reflectionMap
		 * @param lightMap
		 * @param opacityMap
		 * @param alpha
		 */
		public function EnvironmentMaterial(diffuseMap:TextureResource = null, environmentMap:TextureResource = null, normalMap:TextureResource = null, reflectionMap:TextureResource = null, lightMap:TextureResource = null, opacityMap:TextureResource = null, alpha:Number = 1) {
			super(diffuseMap, opacityMap, alpha);
			this._environmentMap = environmentMap;
			this._normalMap = normalMap;
			this._reflectionMap = reflectionMap;
			this._lightMap = lightMap;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Material {
			var res:EnvironmentMaterial = new EnvironmentMaterial(diffuseMap, _environmentMap, _normalMap, _reflectionMap, _lightMap, opacityMap, alpha);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Material):void {
			super.clonePropertiesFrom(source);
			var eMaterial:EnvironmentMaterial = EnvironmentMaterial(source);
			reflection = eMaterial.reflection;
			lightMapChannel = eMaterial.lightMapChannel;
			_normalMapSpace = eMaterial._normalMapSpace;
		}

		/**
		 * @private
		 */
		alternativa3d override function fillResources(resources:Dictionary, resourceType:Class):void {
			super.alternativa3d::fillResources(resources, resourceType);
			if (_environmentMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(_environmentMap)) as Class, resourceType)) {
				resources[_environmentMap] = true;
			}
			if (_normalMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(_normalMap)) as Class, resourceType)) {
				resources[_normalMap] = true;
			}
			if (_reflectionMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(_reflectionMap)) as Class, resourceType)) {
				resources[_reflectionMap] = true;
			}
			if (_lightMap != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(_lightMap)) as Class, resourceType)) {
				resources[_lightMap] = true;
			}
		}

		private function setupProgram(targetObject:Object3D, opacityMap:TextureResource, alphaTest:int):EnvironmentMaterialShaderProgram {
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			var positionVar:String = "aPosition";
			var normalVar:String = "aNormal";
			var tangentVar:String = "aTangent";
			vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
			vertexLinker.declareVariable(normalVar, VariableType.ATTRIBUTE);
			if (targetObject.transformProcedure != null) {
				positionVar = appendPositionTransformProcedure(targetObject.transformProcedure, vertexLinker);
			}
			var procedure:Procedure;
			if (targetObject.deltaTransformProcedure != null) {
				vertexLinker.declareVariable("tTransformedNormal");
				procedure = targetObject.deltaTransformProcedure.newInstance();
				vertexLinker.addProcedure(procedure);
				vertexLinker.setInputParams(procedure, normalVar);
				vertexLinker.setOutputParams(procedure, "tTransformedNormal");
				normalVar = "tTransformedNormal";

				if ((_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) && _normalMap != null) {
					vertexLinker.declareVariable(tangentVar, VariableType.ATTRIBUTE);
					vertexLinker.declareVariable("tTransformedTangent");
					procedure = targetObject.deltaTransformProcedure.newInstance();
					vertexLinker.addProcedure(procedure);
					vertexLinker.setInputParams(procedure, tangentVar);
					vertexLinker.setOutputParams(procedure, "tTransformedTangent");
					tangentVar = "tTransformedTangent";
				}

			} else {
				if ((_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) && _normalMap != null) {
					vertexLinker.declareVariable(tangentVar, VariableType.ATTRIBUTE);
				}
			}
			if (_lightMap != null) {
				vertexLinker.addProcedure(_passLightMapUVProcedure);
			}

			vertexLinker.addProcedure(_passReflectionProcedure);
			vertexLinker.setInputParams(_passReflectionProcedure, positionVar, normalVar);
			vertexLinker.addProcedure(_projectProcedure);
			vertexLinker.setInputParams(_projectProcedure, positionVar);
			vertexLinker.addProcedure(_passUVProcedure);
			if (_normalMap != null) {
				fragmentLinker.declareVariable("tNormal");
				if (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) {
					var nrmProcedure:Procedure = (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED) ? _passTBNRightProcedure : _passTBNLeftProcedure;
					vertexLinker.addProcedure(nrmProcedure);
					vertexLinker.setInputParams(nrmProcedure, tangentVar, normalVar);
					fragmentLinker.addProcedure(_getNormalTangentProcedure);
					fragmentLinker.setOutputParams(_getNormalTangentProcedure, "tNormal");
				} else {
					fragmentLinker.addProcedure(_getNormalObjectProcedure);
					fragmentLinker.setOutputParams(_getNormalObjectProcedure, "tNormal");
				}
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

			fragmentLinker.declareVariable("tReflection");
			if (_normalMap != null) {
				fragmentLinker.addProcedure(_applyReflectionNormalMapProcedure);
				fragmentLinker.setInputParams(_applyReflectionNormalMapProcedure, "tNormal");
				fragmentLinker.setOutputParams(_applyReflectionNormalMapProcedure, "tReflection");
			} else {
				fragmentLinker.addProcedure(_applyReflectionProcedure);
				fragmentLinker.setOutputParams(_applyReflectionProcedure, "tReflection");
			}
			if (_lightMap != null) {
				fragmentLinker.addProcedure(_applyLightMapProcedure);
				fragmentLinker.setInputParams(_applyLightMapProcedure, "tColor");
				fragmentLinker.setOutputParams(_applyLightMapProcedure, "tColor");
			}

			var outputProcedure:Procedure;
			if (_reflectionMap != null) {
				fragmentLinker.addProcedure(_blendReflectionMap);
				fragmentLinker.setInputParams(_blendReflectionMap, "tColor", "tReflection");
				outputProcedure = _blendReflectionMap;
			} else {
				fragmentLinker.addProcedure(_blendReflection);
				fragmentLinker.setInputParams(_blendReflection, "tColor", "tReflection");
				outputProcedure = _blendReflection;
			}

			if (fogMode == FogMode.SIMPLE || fogMode == FogMode.ADVANCED) {
				fragmentLinker.setOutputParams(outputProcedure, "tColor");
			}
			if (fogMode == FogMode.SIMPLE) {
				vertexLinker.addProcedure(passSimpleFogConstProcedure);
				vertexLinker.setInputParams(passSimpleFogConstProcedure, positionVar);
				fragmentLinker.addProcedure(outputWithSimpleFogProcedure);
				fragmentLinker.setInputParams(outputWithSimpleFogProcedure, "tColor");
			} else if (fogMode == FogMode.ADVANCED) {
				vertexLinker.declareVariable("tProjected");
				vertexLinker.setOutputParams(_projectProcedure, "tProjected");
				vertexLinker.addProcedure(postPassAdvancedFogConstProcedure);
				vertexLinker.setInputParams(postPassAdvancedFogConstProcedure, positionVar, "tProjected");
				fragmentLinker.addProcedure(outputWithAdvancedFogProcedure);
				fragmentLinker.setInputParams(outputWithAdvancedFogProcedure, "tColor");
			}

			fragmentLinker.varyings = vertexLinker.varyings;
			return new EnvironmentMaterialShaderProgram(vertexLinker, fragmentLinker);
		}

		/**
		 * @private
		 */
		alternativa3d function getProceduresCRC32(targetObject:Object3D, opacityMap:TextureResource, alphaTest:int):uint {
			var crc:uint = 0xFFFFFFFF;
			var procedureCRC:uint;
			var crc32Table:Vector.<uint> = Procedure.crc32Table;
			if (targetObject.transformProcedure != null) {
				procedureCRC = targetObject.transformProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (targetObject.deltaTransformProcedure != null) {
				procedureCRC = targetObject.deltaTransformProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				if ((_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) && _normalMap != null) {
					crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				}

			}
			if (_lightMap != null) {
				procedureCRC = _passLightMapUVProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (_normalMap != null) {
				if (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) {
					procedureCRC = (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED) ? _passTBNRightProcedure.crc32 : _passTBNLeftProcedure.crc32;
					crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);

					procedureCRC = _getNormalTangentProcedure.crc32;
					crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				} else {
					procedureCRC = _getNormalObjectProcedure.crc32;
					crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				}
			}
			procedureCRC = opacityMap != null ? getDiffuseOpacityProcedure.crc32 : getDiffuseProcedure.crc32;
			crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			if (alphaTest > 0) {
				procedureCRC = alphaTest == 1 ? thresholdOpaqueAlphaProcedure.crc32 : thresholdTransparentAlphaProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (_normalMap != null) {
				procedureCRC = _applyReflectionNormalMapProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			} else {
				procedureCRC = _applyReflectionProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (_lightMap != null) {
				procedureCRC = _applyLightMapProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (_reflectionMap != null) {
				procedureCRC = _blendReflectionMap.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			} else {
				procedureCRC = _blendReflection.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			if (fogMode == FogMode.SIMPLE) {
				procedureCRC = passSimpleFogConstProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				procedureCRC = outputWithSimpleFogProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			} else if (fogMode == FogMode.ADVANCED) {
				procedureCRC = postPassAdvancedFogConstProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
				procedureCRC = outputWithAdvancedFogProcedure.crc32;
				crc = crc32Table[(crc ^ procedureCRC) & 0xFF] ^ (crc >> 8);
			}
			return crc ^ 0xFFFFFFFF;
		}

		private function getDrawUnit(program:EnvironmentMaterialShaderProgram, camera:Camera3D, surface:Surface, geometry:Geometry, opacityMap:TextureResource):DrawUnit {
			// Buffers
			var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			var uvBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
			var normalsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.NORMAL);
			var tangentsBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.TANGENT4);
			if (positionBuffer == null || uvBuffer == null || normalsBuffer == null) return null;
			var i:int;
			var object:Object3D = surface.object;

			if (program.sBump >= 0 && (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED)) {
				if (tangentsBuffer == null) return null;
			}

			// Draw call
			var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cThresholdAlpha"), alphaThreshold, 0, 0, alpha);
			// Set the textures
			if (program.sLightMap >= 0) {
				drawUnit.setTextureAt(program.sLightMap, _lightMap._texture);
				drawUnit.setVertexBufferAt(program.aUV1, uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[lightMapChannel]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[lightMapChannel]]);
			}

			if (program.sBump >= 0) {
				drawUnit.setTextureAt(program.sBump, _normalMap._texture);
				if (_normalMapSpace == NormalMapSpace.TANGENT_RIGHT_HANDED || _normalMapSpace == NormalMapSpace.TANGENT_LEFT_HANDED) {
					drawUnit.setVertexBufferAt(program.aTangent, tangentsBuffer, geometry._attributesOffsets[VertexAttributes.TANGENT4], VertexAttributes.FORMATS[VertexAttributes.TANGENT4]);
				}
			}

			if (program.sReflection >= 0) {
				drawUnit.setTextureAt(program.sReflection, _reflectionMap._texture);
			}

			if (program.sOpacity >= 0) {
				drawUnit.setTextureAt(program.sOpacity, opacityMap._texture);
			}

			// Set the streams
			drawUnit.setVertexBufferAt(program.aPosition, positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawUnit.setVertexBufferAt(program.aUV, uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
			drawUnit.setVertexBufferAt(program.aNormal, normalsBuffer, geometry._attributesOffsets[VertexAttributes.NORMAL], VertexAttributes.FORMATS[VertexAttributes.NORMAL]);

			// Set the constants
			object.setTransformConstants(drawUnit, surface, program.vertexShader, camera);
			drawUnit.setProjectionConstants(camera, program.cProjMatrix, object.localToCameraTransform);

			drawUnit.setTextureAt(program.sTexture, diffuseMap._texture);
			drawUnit.setTextureAt(program.sCubeMap, _environmentMap._texture);
			var cameraToLocalTransform:Transform3D = object.cameraToLocalTransform;
			drawUnit.setFragmentConstantsFromNumbers(program.cCamera, cameraToLocalTransform.d, cameraToLocalTransform.h, cameraToLocalTransform.l);
			drawUnit.setFragmentConstantsFromNumbers(program.cAlpha, 0, 1 - reflection, reflection, alpha);

			// Calculate local to global matrix
			localToGlobalTransform.combine(camera.localToGlobalTransform, object.localToCameraTransform);
			drawUnit.setFragmentConstantsFromTransform(program.cLocalToGlobal, localToGlobalTransform);
			if (fogMode == FogMode.SIMPLE || fogMode == FogMode.ADVANCED) {
				var lm:Transform3D = object.localToCameraTransform;
				var dist:Number = fogFar - fogNear;
				drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("cFogSpace"), lm.i/dist, lm.j/dist, lm.k/dist, (lm.l - fogNear)/dist);
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cFogRange"), fogMaxDensity, 1, 0, 1 - fogMaxDensity);
			}
			if (fogMode == FogMode.SIMPLE) {
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cFogColor"), fogColorR, fogColorG, fogColorB);
			}
			if (fogMode == FogMode.ADVANCED) {
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
				//   UV
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

		private function getProgram(targetObject:Object3D, camera:Camera3D, opacityMap:TextureResource, alphaTest:int):EnvironmentMaterialShaderProgram {
			// Renew program cache for this context
			if (camera.context3D != cachedContext3D) {
				cachedContext3D = camera.context3D;
				programsCache = caches[cachedContext3D];
				if (programsCache == null) {
					programsCache = new Array();
					caches[cachedContext3D] = programsCache;
				}
			}

			var key:uint;
			var program:EnvironmentMaterialShaderProgram;
			key = getProceduresCRC32(targetObject, opacityMap, alphaTest);
			program = programsCache[key];
			if (program == null) {
				program = programsCache[key] = setupProgram(targetObject, opacityMap, alphaTest);

				program.upload(camera.context3D);
			}
			return program;
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			if (diffuseMap == null || diffuseMap._texture == null) return;
			if (_environmentMap == null || _environmentMap._texture == null || !(_environmentMap._texture is CubeTexture)) return;
			if (opacityMap != null && opacityMap._texture == null) return;
			if (_normalMap != null && _normalMap._texture == null) return;
			if (_reflectionMap != null && _reflectionMap._texture == null) return;
			if (_lightMap != null && _lightMap._texture == null) return;

			if (camera.context3DProperties.isConstrained) {
				// fallback to simpler material
				if (lightMap == null) {
					fallbackTextureMaterial.diffuseMap = diffuseMap;
					fallbackTextureMaterial.opacityMap = opacityMap;
					fallbackTextureMaterial.alphaThreshold = alphaThreshold;
					fallbackTextureMaterial.alpha = alpha;
					fallbackTextureMaterial.opaquePass = opaquePass;
					fallbackTextureMaterial.transparentPass = transparentPass;
					fallbackTextureMaterial.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, objectRenderPriority);
				} else {
					fallbackLightMapMaterial.diffuseMap = diffuseMap;
					fallbackLightMapMaterial.lightMap = lightMap;
					fallbackLightMapMaterial.lightMapChannel = lightMapChannel;
					fallbackLightMapMaterial.opacityMap = opacityMap;
					fallbackLightMapMaterial.alphaThreshold = alphaThreshold;
					fallbackLightMapMaterial.alpha = alpha;
					fallbackLightMapMaterial.opaquePass = opaquePass;
					fallbackLightMapMaterial.transparentPass = transparentPass;
					fallbackLightMapMaterial.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, objectRenderPriority);
				}
				return;
			}

			var object:Object3D = surface.object;

			// Program
			var program:EnvironmentMaterialShaderProgram;
			var drawUnit:DrawUnit;
			// Opaque pass
			if (opaquePass && alphaThreshold <= alpha) {
				if (alphaThreshold > 0) {
					// Alpha test
					// use opacityMap if it is presented
					program = getProgram(object, camera, opacityMap, 1);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// do not use opacityMap at all
					program = getProgram(object, camera, null, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, null);
				}
				if (drawUnit == null) return;
				// Use z-buffer within DrawCall, draws without blending
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
			}
			// Transparent pass
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				// use opacityMap if it is presented
				if (alphaThreshold <= alpha && !opaquePass) {
					// Alpha threshold
					program = getProgram(object, camera, opacityMap, 2);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				} else {
					// There is no Alpha threshold or check z-buffer by previous pass
					program = getProgram(object, camera, opacityMap, 0);
					drawUnit = getDrawUnit(program, camera, surface, geometry, opacityMap);
				}
				if (drawUnit == null) return;
				// Do not use z-buffer, draws with blending
				drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
				drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
			}
		}

		/**
		 * @private
		 */
		alternativa3d function dirty():void {
			for each (var program:EnvironmentMaterialShaderProgram in programsCache) {
				program.dirty = true;
			}
		}

	}
}

import alternativa.engine3d.alternativa3d;
import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;

use namespace alternativa3d;

class EnvironmentMaterialShaderProgram extends ShaderProgram {

	public var aTangent:int = -1;
	public var aNormal:int = -1;
	public var aPosition:int = -1;
	public var aUV:int = -1;
	public var aUV1:int = -1;

	public var cCamera:int = -1;
	public var cLocalToGlobal:int = -1;
	public var cAlpha:int = -1;
	public var cProjMatrix:int = -1;

	public var sBump:int = -1;
	public var sTexture:int = -1;
	public var sOpacity:int = -1;
	public var sCubeMap:int = -1;
	public var sReflection:int = -1;
	public var sLightMap:int = -1;
	public var dirty:Boolean = false;

	public function EnvironmentMaterialShaderProgram(vertexShader:Linker, fragmentShader:Linker) {
		super(vertexShader, fragmentShader);
		fragmentShader.varyings = vertexShader.varyings;
		vertexShader.link();
		fragmentShader.link();
		aPosition = vertexShader.findVariable("aPosition");
		aNormal = vertexShader.findVariable("aNormal");
		aUV = vertexShader.findVariable("aUV");
		sBump = fragmentShader.findVariable("sBump");
		aTangent = vertexShader.findVariable("aTangent");
		sReflection = fragmentShader.findVariable("sReflection");
		sLightMap = fragmentShader.findVariable("sLightMap");
		aUV1 = vertexShader.findVariable("aUV1");
		cProjMatrix = vertexShader.findVariable("cProjMatrix");
		sTexture = fragmentShader.findVariable("sDiffuse");
		sCubeMap = fragmentShader.findVariable("sCubeMap");
		cCamera = fragmentShader.findVariable("cCamera");
		cLocalToGlobal = fragmentShader.findVariable("cLocalToGlobal");
		cAlpha = fragmentShader.findVariable("cAlpha");
		sOpacity = fragmentShader.findVariable("sOpacity");
	}

}
