package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: Layer element for mapping Textures to a geometry.
	 * Deprecated since FBX SDK 2011. Textures (KFbxTexture derived classes)
	 * should be connected to material properties.
	 */
	public class KFbxLayerElementTexture extends KFbxLayerElement {
		public var TextureId:Vector.<Number> = new Vector.<Number>();

		/**
		 * Канал для ParserMaterial. Сам MotionBuilder v6, похоже, умеет только
		 * diffuse текстуры, однако SDK предусматривает кучу типов. К сожалению,
		 * SDK v7 считает KFbxLayerElementTexture устаревшим и не описывает
		 * соответствующие токены (в примере файла найдены токены для specular и bump).
		 *
		 *
		 * В SDK каждый KFbxLayerElement имеет тип, и в зависимости от типа
		 * данные пишутся в конкретный класс-наследник; в KFbxLayerElementTexture
		 * пишутся данные для следующих типов:
		 * eDIFFUSE_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eEMISSIVE_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eEMISSIVE_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eAMBIENT_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eAMBIENT_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eDIFFUSE_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eSPECULAR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eNORMALMAP_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eSPECULAR_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eSHININESS_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eBUMP_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eTRANSPARENT_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eTRANSPARENCY_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eREFLECTION_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eREFLECTION_FACTOR_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eDISPLACEMENT_TEXTURES Layer Element of type KFbxLayerElementTexture,
		 * eVECTOR_DISPLACEMENT_TEXTURES Layer Element of type KFbxLayerElementTexture.
		 * @see http://download.autodesk.com/global/docs/fbxsdk2012/en_us/cpp_ref/class_k_fbx_layer_element.html#a6478dfad43def5e882aaf6607af3fdae
		 */
		public var renderChannel:String;

		public function KFbxLayerElementTexture(channel:String = "diffuse", values:Vector.<Number> = null,
				mapping:String = "ByPolygon", reference:String = "IndexToDirect") {
			if (channel != null) renderChannel = channel;
			if (values != null) TextureId = values;
			if (mapping != null) MappingInformationType = mapping;
			if (reference != null) ReferenceInformationType = reference;
		}
	}
}
