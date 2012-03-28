package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Procedure;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.geom.Matrix3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class ShadowRenderer {
		
		alternativa3d var shaderKey:String;
		private static var counter:int = 0;
		
		public var active:Boolean = false;
		
		public function ShadowRenderer() {
			counter++;
			shaderKey = "M" + counter.toString();
		}

		alternativa3d function get needMultiplyBlend():Boolean {
			return false;
		}
		
		public function update():void {}

		// Нет входных, выходных параметров
		public function getVShader(index:int = 0):Procedure {return null}
		public function getFShader(index:int = 0):Procedure {return null}

		public function getFIntensityShader():Procedure { throw new Error("Not implemented") };

//		public function getMultVShader():Procedure {return null};
//		// i0 - input color
//		// o0 - shadowed result
//		public function getMultFShader():Procedure {return null};

		public function applyShader(destination:DrawUnit, program:ShaderProgram, object:Object3D, camera:Camera3D, index:int = 0):void {}
//		public function drawShadow(mesh:Mesh, camera:Camera3D, texture:Texture):void {}

//		public function getTextureIndex(fLinker:Linker):int {return 0};
		
		public function get debug():Boolean { return false }
		public function set debug(value:Boolean):void {  }
		
		alternativa3d function cullReciever(boundBox:BoundBox, object:Object3D):Boolean {
			return false;
		}

		protected function cleanContext(context:Context3D):void {
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setTextureAt(2, null);
			context.setTextureAt(3, null);
			context.setTextureAt(4, null);
			context.setTextureAt(5, null);
			context.setTextureAt(6, null);
			context.setTextureAt(7, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
			context.setVertexBufferAt(4, null);
			context.setVertexBufferAt(5, null);
			context.setVertexBufferAt(6, null);
			context.setVertexBufferAt(7, null);
			context.setDepthTest(true, Context3DCompareMode.LESS);
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		}

		static private const boundVertices:Vector.<Number> = new Vector.<Number>(24);
		alternativa3d function cullObjectImplementation(bounds:BoundBox, matrix:Matrix3D):Boolean {
			var i:int;
			var infront:Boolean;
			var behind:Boolean;
			// Заполнение
			boundVertices[0] = bounds.minX;
			boundVertices[1] = bounds.minY;
			boundVertices[2] = bounds.minZ;
			boundVertices[3] = bounds.maxX;
			boundVertices[4] = bounds.minY;
			boundVertices[5] = bounds.minZ;
			boundVertices[6] = bounds.minX;
			boundVertices[7] = bounds.maxY;
			boundVertices[8] = bounds.minZ;
			boundVertices[9] = bounds.maxX;
			boundVertices[10] = bounds.maxY;
			boundVertices[11] = bounds.minZ;
			boundVertices[12] = bounds.minX;
			boundVertices[13] = bounds.minY;
			boundVertices[14] = bounds.maxZ;
			boundVertices[15] = bounds.maxX;
			boundVertices[16] = bounds.minY;
			boundVertices[17] = bounds.maxZ;
			boundVertices[18] = bounds.minX;
			boundVertices[19] = bounds.maxY;
			boundVertices[20] = bounds.maxZ;
			boundVertices[21] = bounds.maxX;
			boundVertices[22] = bounds.maxY;
			boundVertices[23] = bounds.maxZ;
			
			// Трансформация в камеру
			matrix.transformVectors(boundVertices, boundVertices);
			// Куллинг
			for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
				if (boundVertices[i] > 0) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				if (!infront) return false;
			}
			// left
			for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
				if (boundVertices[i] > 0) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				if (!infront) return false;
			}
			// right
			for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
				if (boundVertices[i] < 1) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				if (!infront) return false;
			}
			// up
			for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
				if (boundVertices[i] > 0) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				if (!infront) return false;
			}
			// down
			for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
				if (boundVertices[i] < 1) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				if (!infront) return false;
			}
			return true; 
		}

	}
}
