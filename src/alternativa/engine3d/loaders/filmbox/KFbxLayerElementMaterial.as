package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: Layer element for mapping materials (KFbxSurfaceMaterial) to a geometry.
	 */
	public class KFbxLayerElementMaterial extends KFbxLayerElement {
		public var Materials:Vector.<Number> = new Vector.<Number>();

		public function KFbxLayerElementMaterial(values:Vector.<Number> = null, mapping:String = "ByPolygon",
				reference:String = "IndexToDirect") {
			if (values != null) Materials = values;
			if (mapping != null) MappingInformationType = mapping;
			if (reference != null) ReferenceInformationType = reference;
		}
	}
}
