package alternativa.engine3d.materials {
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	use namespace alternativa3d;
	/**
	 * GroundMaterial use second vertex UV for opacity map 
	 */
	public class GroundMaterial extends StandardMaterial {
		private static const UV2 : String = "aUV2";

		private static const passTwoUVProcedure : Procedure = new Procedure([//
		"#v0=vUV",// 
		"#v1=vUV2",// 
		"#a0=aUV",// 
		"#a1=aUV2",// 
		"mov v0, a0",// 
		"mov v1, a1"//
		], "passUVProcedure");

		private static const diffuseOpacityProcedure : Procedure = new Procedure([//
		"#v0=vUV",// 
		"#v1=vUV2",// 
		"#s0=sDiffuse", // 
		"#s1=sOpacity", // 
		"#c0=cThresholdAlpha",// 
		"tex t0, v0, s0 <2d,linear,repeat,miplinear>", // 
		"tex t1, v1, s1 <2d,linear,repeat,miplinear>", // 
		"mul t0.w, t1.x, c0.w", // 
		"mov o0, t0"//
		], "diffuseOpacityProcedure");

		public function GroundMaterial(diffuseMap : TextureResource = null, normalMap : TextureResource = null, specularMap : TextureResource = null, glossinessMap : TextureResource = null, opacityMap : TextureResource = null) {
			super(diffuseMap, normalMap, specularMap, glossinessMap, opacityMap);
		}

		/**
		 * @private
		 */
		override alternativa3d function getPassUVProcedure() : Procedure {
			return passTwoUVProcedure;
		}

		override alternativa3d function getDiffuseOpacityProcedure() : Procedure {
			return diffuseOpacityProcedure;
		}

		/**
		 * @private
		 */
		override alternativa3d function setVertexBuffers(destination : DrawUnit, geometry : Geometry, vertexLinker : Linker) : void {
			destination.setVertexBufferAt(vertexLinker.getVariableIndex(UV2), geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[1]), geometry._attributesOffsets[VertexAttributes.TEXCOORDS[1]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[1]]);
		}

		override alternativa3d function getUniqueMaterialKey(startOffset : int) : int {
			return 2 << startOffset;
		}

		override alternativa3d function collectDraws(camera : Camera3D, surface : Surface, geometry : Geometry, lights : Vector.<Light3D>, lightsLength : int, useShadow : Boolean, objectRenderPriority : int = -1) : void {
			if (transparentPass && alphaThreshold > 0 && alpha > 0) {
				super.alternativa3d::collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, Renderer.PRE_TRANSPARENT_SORT);
				return;
			}
			super.alternativa3d::collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, objectRenderPriority);
		}
	}
}
