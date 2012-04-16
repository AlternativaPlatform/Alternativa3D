package alternativa.engine3d.loaders.filmbox {

	import flash.geom.Vector3D;

	/**
	 * @private SDK: Layer to map Normals on a geometry.
	 */
	public class KFbxLayerElementNormal extends KFbxLayerElement {
		public var Normals:Vector.<Number> = new Vector.<Number>();

		public function KFbxLayerElementNormal(values:Vector.<Number> = null, mapping:String = "ByVertice"
			/* TODO "ByPolygonVertex" ?? */, reference:String = "Direct") {
			if (values != null) Normals = values;
			if (mapping != null) MappingInformationType = mapping;
			if (reference != null) ReferenceInformationType = reference;
		}

		static public function generateDefaultNormals(mesh:KFbxMesh):KFbxLayerElementNormal {
			var vertices:Vector.<Number> = mesh.Vertices, polyIndex:Vector.<Number> = mesh.PolygonVertexIndex;

			var vertexNormals:Vector.<Number> = new Vector.<Number>(vertices.length);

			var i:int = 0;
			var va:Vector3D = new Vector3D;
			var vb:Vector3D = new Vector3D;
			var vc:Vector3D = new Vector3D;
			var vn:Vector3D;
			while (i < polyIndex.length) {
				var a:int = polyIndex [i], a3:int = a*3;
				var b:int = polyIndex [i + 1], b3:int = b*3;
				var c:int = polyIndex [i + 2], c3:int;
				if (c < 0) c = -c - 1;
				c3 = c*3;
				va.x = vertices [a3];
				va.y = vertices [a3 + 1];
				va.z = vertices [a3 + 2];
				vb.x = vertices [b3];
				vb.y = vertices [b3 + 1];
				vb.z = vertices [b3 + 2];
				vc.x = vertices [c3];
				vc.y = vertices [c3 + 1];
				vc.z = vertices [c3 + 2];
				va.decrementBy(vc);
				vb.decrementBy(vc);
				vn = va.crossProduct(vb); //vn.normalize ();

				// TODO smoothing groups, "ByPolygonVertex"?
				do {
					c = polyIndex [i++];
					if (c < 0) c = -c - 1;
					c *= 3;
					vertexNormals [c] += vn.x;
					vertexNormals [c + 1] += vn.y;
					vertexNormals [c + 2] += vn.z;
				} while (polyIndex [i - 1] >= 0);
			}

			for (i = 0; i < vertexNormals.length; i += 3) {
				vn.x = 1e-9 + vertexNormals [i];
				vn.y = vertexNormals [i + 1];
				vn.z = vertexNormals [i + 2];
				vn.normalize();
				vertexNormals [i] = vn.x;
				vertexNormals [i + 1] = vn.y;
				vertexNormals [i + 2] = vn.z;
			}

			return new KFbxLayerElementNormal(vertexNormals, "ByVertice", "Direct");
		}
	}
}
