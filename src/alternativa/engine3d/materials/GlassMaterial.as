package alternativa.engine3d.materials {
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.TextureResource;

	use namespace alternativa3d;
	public class GlassMaterial extends EnvironmentMaterial {
		private static const cColor : String = "cColor";
		private static const _applyColorLerpProcedure : Procedure = new Procedure([//
		"#c0=cColor", // 
		"sub o0.xyz, i0.xyz, c0.xyz", // 
		"mul o0.xyz, o0.xyz, c0.www", // 
		"add o0.xyz, o0.xyz, c0.xyz"//
		], "applyColorLerpProcedure");
		private var _red : Number = 0;
		private var _green : Number = 0;
		private var _blue : Number = 0;
		private var _colorIntensity : Number = 0;

		public function GlassMaterial(diffuseMap : TextureResource = null, environmentMap : TextureResource = null, normalMap : TextureResource = null, reflectionMap : TextureResource = null, lightMap : TextureResource = null, opacityMap : TextureResource = null, alpha : Number = 1) {
			super(diffuseMap, environmentMap, normalMap, reflectionMap, lightMap, opacityMap, alpha);
		}

		override alternativa3d function processReflectionColor(fragmentLinker : Linker, variableName : String) : void {
			fragmentLinker.addProcedure(_applyColorLerpProcedure, variableName);
			fragmentLinker.setOutputParams(_applyColorLerpProcedure, variableName);
		}

		override alternativa3d function setFragmentConstants(drawUnit : DrawUnit, fragmentShader : Linker) : void {
			drawUnit.setFragmentConstantsFromNumbers(fragmentShader.findVariable(cColor), _red, _green, _blue, 1 - _colorIntensity);
		}

		public function get color() : Number {
			return (_red * 0xFF << 16) + (_green * 0xFF << 8) + _blue * 0xFF;
		}

		public function set color(value : Number) : void {
			_red = ((value >> 16) & 0xFF) / 0xFF;
			_green = ((value >> 8) & 0xFF) / 0xFF;
			_blue = (value & 0xff) / 0xFF;
		}

		public function get colorIntensity() : Number {
			return _colorIntensity;
		}

		public function set colorIntensity(value : Number) : void {
			_colorIntensity = value;
		}
	}
}
