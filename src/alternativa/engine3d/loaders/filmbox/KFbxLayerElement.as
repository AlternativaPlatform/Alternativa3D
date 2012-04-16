package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: A KFbxLayerElement contains Normals, UVs or other kind of information..
	 */
	public class KFbxLayerElement {
		/**
		 * Mapping.
		 * "NoMappingInformation"
		 * "ByVertice"
		 * "ByPolygon"
		 * "ByPolygonVertex"
		 * "ByFace"
		 * "ByEdge"
		 * "AllSame"
		 * "ByModel"
		 *
		 *	 {
		 *		 eNONE,
		 *		 eBY_CONTROL_POINT,
		 *		 eBY_POLYGON_VERTEX,
		 *		 eBY_POLYGON,
		 *		 eBY_EDGE,
		 *		 eALL_SAME
		 *	 } EMappingMode;
		 */
		public var MappingInformationType:String;
		/**
		 * Reference.
		 * "Direct" This indicates that the mapping information for the n'th element
		 * is found in the n'th place of KFbxLayerElementTemplate::mDirectArray.
		 * "Index" This symbol is kept for backward compatibility with FBX v5.0 files.
		 * In FBX v6.0 and higher, this symbol is replaced with "IndexToDirect".
		 * "IndexToDirect" This indicates that the KFbxLayerElementTemplate::mIndexArray
		 * contains, for the n'th element, an index in the KFbxLayerElementTemplate::mDirectArray
		 * array of mapping elements.
		 */
		public var ReferenceInformationType:String;
	}
}
