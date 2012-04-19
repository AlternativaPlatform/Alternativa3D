package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: A layer can contain one or more of the following layer elements:
	 * Normals
	 * Binormals
	 * Tangents
	 * Materials
	 * Polygon Groups
	 * UVs
	 * Vertex Colors
	 * Smoothing informations
	 * Vertex Creases
	 * Edge Creases
	 * Custom User Data
	 * Visibilities
	 * Textures (diffuse, ambient, specular, etc.) (deprecated)
	 * A typical layer for a Mesh contains Normals, UVs and Materials. A typical layer for NURBS contains only Materials. In the case of the NURBS, the NURBS' parameterization is used for the UVs; no UVs should be specified.
	 * In most cases, you only need a single layer to describe a geometry. Many applications only support what is defined on the first layer. Take this into account when you fill the layer. For example, it is legal to define the Layer 0 with the UVs and then define the model's Normals on layer 1. However if you construct a file this way, it may not be imported correctly in other applications. Store the Normals in Layer 0 to avoid problems.
	 */
	public class KFbxLayer {
		public var elements:Vector.<KFbxLayerElement> = new Vector.<KFbxLayerElement>();

		public function getLayerElement(type:Class, stringProperty:String = null,
				value:String = null):KFbxLayerElement {
			for (var i:int = 0; i < elements.length; i++) {
				var e:KFbxLayerElement = elements [i];
				if (e is type) {
					if (stringProperty == null) {
						return e;
					} else {
						if (e [stringProperty] == value) {
							return e;
						}
					}
				}
			}
			return null;
		}
	}
}
