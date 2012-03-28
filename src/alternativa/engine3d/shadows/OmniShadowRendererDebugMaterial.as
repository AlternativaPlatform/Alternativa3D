package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.CubeTexture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class OmniShadowRendererDebugMaterial extends Material {

		alternativa3d override function get canDrawInShadowMap():Boolean {
			return false;
		}
		
		static alternativa3d const _samplerSetProcedure:Procedure = new Procedure(
		[
			"#v0=vUV", 
			"#s0=sTexture", 
			"#c0=cAlpha", 
			"tex t0, v0, s0 <cube,clamp,near,nomip>",
			"mov t0.w, c0.w", 
			"mov o0, t0"
		]);
		
		static alternativa3d const _samplerSetProcedureDiffuseAlpha:Procedure = new Procedure(
		[
			"#v0=vUV", 
			"#s0=sTexture", 
			"#c0=cAlpha", 
			"tex t0, v0, s0 <cube,clamp,near,nomip>",
			"mul t0.w, t0.w, c0.w",   
			"mov o0, t0"
		]);
		
		static alternativa3d const _passUVProcedure:Procedure = new Procedure(["#v0=vUV", "#a0=aNORMAL", "mov v0, a0"]);
		private static var _programs:Dictionary = new Dictionary();
		/**
		 * Текстура
		 */
		public var texture:CubeTexture;
		/**
		 * Прозрачность
		 */
		public var alpha:Number = 1;
		/**
		 * Использование alpha канала текстуры
		 */
		public var useDiffuseAlphaChannel:Boolean = false;
		
		/**
		 * Создает экземпляр материала
		 * @param texture текстура
		 * @param alpha прозрачность
		 */
		public function OmniShadowRendererDebugMaterial(texture:CubeTexture = null, alpha:Number = 1) {
			this.texture = texture;
			this.alpha = alpha;
		}

		private function setupProgram(targetObject:Object3D):Vector.<ShaderProgram> {
			var optionsPrograms:Vector.<ShaderProgram> = new Vector.<ShaderProgram>();
			
			var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			var positionVar:String = "aPosition";
			vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);
			if (targetObject.transformProcedure != null) {
				positionVar = appendPositionTransformProcedure(targetObject.transformProcedure, vertexLinker);
			}			
			vertexLinker.addProcedure(_projectProcedure);
			vertexLinker.setInputParams(_projectProcedure, positionVar);
			vertexLinker.addProcedure(_passUVProcedure);
			vertexLinker.link();
			
			var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			fragmentLinker.addProcedure(_samplerSetProcedure);
			fragmentLinker.varyings = vertexLinker.varyings;
			optionsPrograms[optionsPrograms.length] = new ShaderProgram(vertexLinker, fragmentLinker);
			
			var fragmentLinkerDiffuseAlpha:Linker = new Linker(Context3DProgramType.FRAGMENT);
			fragmentLinkerDiffuseAlpha.addProcedure(_samplerSetProcedureDiffuseAlpha); 
			fragmentLinkerDiffuseAlpha.varyings = vertexLinker.varyings;
			optionsPrograms[optionsPrograms.length] = new ShaderProgram(vertexLinker, fragmentLinkerDiffuseAlpha);
			
//			trace(A3DUtils.disassemble(fragmentLinker.getByteCode()));

			_programs[targetObject.transformProcedure] = optionsPrograms;
			return optionsPrograms;
		}

		/**
		 * @private 
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, objectRenderPriority:int = -1):void {
			// TODO: repair
			/*
			destination.isValid = destination.isValid && texture != null;

			var optionsPrograms:Vector.<ShaderProgram> = _programs[transformHolder.transformProcedure];
			if(!optionsPrograms) optionsPrograms = setupProgram(transformHolder);
			var program:ShaderProgram;
			if(!useDiffuseAlphaChannel){
				program = optionsPrograms[0];
			}else  {
				program = optionsPrograms[1];
			}
			
			if (!destination.isValid) {
				return;
			}

			if (alpha < 1 || useDiffuseAlphaChannel) {
				destination.blendModeSource = Context3DBlendFactor.SOURCE_ALPHA;
				destination.blendModeDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				destination.renderPriority = Renderer.TRANSPARENT_SORT;
			} else {
				destination.blendModeSource = Context3DBlendFactor.ONE;
				destination.blendModeDestination = Context3DBlendFactor.ZERO;
				destination.renderPriority = Renderer.OPAQUE;
			}

			destination.program = program;
			geometry.setAttribute(destination, VertexAttributes.POSITION, program.vertexShader.getVariableIndex("aPosition"));
			geometry.setAttribute(destination, VertexAttributes.NORMAL, program.vertexShader.getVariableIndex("aNORMAL"));
			camera.composeProjectionMatrix(destination.constantSetVertexVectorValues, program.vertexShader.getVariableIndex("cProjMatrix") << 2, transformHolder.localToCameraTransform);
			destination.constantSetVertexRegistersCount = destination.constantSetVertexVectorValues.length >> 2;
			destination.addTextureSet(program.fragmentShader.getVariableIndex("sTexture"), texture);
			destination.addFragmentConstantVector(program.fragmentShader.getVariableIndex("cAlpha"), 0, 0, 0, alpha);
			destination.cullingMode = cullingMode;
			*/
		}

		/**
		 * @inheritDoc 
		 */
		override public function clone():Material {
			var res:OmniShadowRendererDebugMaterial = new OmniShadowRendererDebugMaterial(texture, alpha);
			res.clonePropertiesFrom(this);
			return res;
		}

		override protected function clonePropertiesFrom(source:Material):void {
			super.clonePropertiesFrom(source);
			var t:OmniShadowRendererDebugMaterial = OmniShadowRendererDebugMaterial(source);
			texture = t.texture;
			alpha = t.alpha;
		}
	}
}
