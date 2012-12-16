package alternativa.engine3d.materials {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.TextureResource;

	use namespace alternativa3d;
	public class TrimMaterial extends StandardMaterial {
		/**
		 * @private
		 */
		private static const cSize : String = "cSize";
		/**
		 * @private
		 */
		private static const _passSizedUVProcedure : Procedure = new Procedure([//
		"#v0=vUV",// 
		"#a0=aUV",// 
		"#c0=cSize",// 
		"mul v0, a0.xy, c0.xy"//
		], "applySpecularProcedure");
		/**
		 * Width of trim material
		 */
		public var sizeU : Number = 1;
		/**
		 * Height of trim material
		 */
		public var sizeV : Number = 1;
		
		/**
		 * Description 
		 */
		public var trimName : String;
		 
		/**
		 * Material for trimming objects. 
		 * TODO: add rotation
		 */
		public function TrimMaterial(diffuseMap : TextureResource = null, normalMap : TextureResource = null, specularMap : TextureResource = null, glossinessMap : TextureResource = null, opacityMap : TextureResource = null) {
			super(diffuseMap, normalMap, specularMap, glossinessMap, opacityMap);
		}

		/**
		 * @private
		 */
		override alternativa3d function getPassUVProcedure() : Procedure {
			return _passSizedUVProcedure;
		}

		/**
		 * @private
		 */
		override alternativa3d function setPassUVProcedureConstants(destination : DrawUnit, vertexLinker : Linker) : void {
			var constantIndex : int = vertexLinker.findVariable(cSize);
			if (constantIndex == -1) return;
			destination.setVertexConstantsFromNumbers(constantIndex, 1 / sizeU, 1 / sizeV, 0);
		}

		override alternativa3d function getUniqueMaterialKey(startOffset : int) : int {
			return 1 << startOffset;
		}
	}
}
