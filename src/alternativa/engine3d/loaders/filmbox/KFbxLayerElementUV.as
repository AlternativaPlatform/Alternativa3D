package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: Layer element for mapping UVs to a geometry.
	 */
	public class KFbxLayerElementUV extends KFbxLayerElement {
		public var UV:Vector.<Number> = new Vector.<Number>();
		public var UVIndex:Vector.<Number> = new Vector.<Number>();

		public function KFbxLayerElementUV() {
			// v5 has MappingInformationType set to "ByPolygon" - how the fuck could UVs be by polygon?
			MappingInformationType = "ByPolygonVertex";
			ReferenceInformationType = "IndexToDirect";
		}

		static public function generateDefaultTextureMap(mesh:KFbxMesh):KFbxLayerElementUV {
			var uv:KFbxLayerElementUV = new KFbxLayerElementUV;
			var i:int, j:int;
			for (i = 0; i < mesh.PolygonVertexIndex.length; i++) {
				j = mesh.PolygonVertexIndex [i];
				if (j < 0) j = -j - 1;
				uv.UVIndex [i] = j;
			}
			for (i = 0; i < mesh.Vertices.length/3; i++) {
				j = i*3;
				var x:Number = mesh.Vertices [j++];
				var y:Number = mesh.Vertices [j++];
				var z:Number = mesh.Vertices [j++];
				var rxy:Number = 1e-5 + Math.sqrt(x*x + y*y);
				j = i*2;
				uv.UV [j++] = Math.atan2(rxy, z)*0.159154943 + 0.5;
				uv.UV [j++] = Math.atan2(y, x)*0.159154943 + 0.5;
			}
			return uv;
		}
	}
}
