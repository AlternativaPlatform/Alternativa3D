package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.*;
	import alternativa.engine3d.loaders.filmbox.readers.*;

	/** @private */
	public class V5 extends VCommon implements IVersion {
		public function parseCurrentRecord(reader:IReader, stack:Array, heap:Object):void {

			var data:RecordData, node:KFbxNode, object:Object;

			var recordName:String = reader.getRecordName();
			switch (recordName) {
				case "AmbientRenderSettings":
					stack.push(null);
					reader.stepIn();
					break;

				case "AmbientLightColor":
					parseAmbientLight(reader.getRecordData(), heap);
					reader.stepOver();
					break;


				// 3D объекты
				case "Model":
					data = reader.getRecordData();
					parseModelRecord(data, stack, heap);
					reader.stepIn();
					break;


				// разная хрень из Mesh
				case "Vertices":
				case "PolygonVertexIndex":
					setMeshNumericProperty(reader, stack, recordName);
					reader.stepOver();
					break;
				case "Normals":
					addMeshLayerElement(null, stack, new KFbxLayerElementNormal(reader.getRecordData().numbers), 0,
							false);
					reader.stepOver();
					break;
				case "Meterials":
					addMeshLayerElement(null, stack, new KFbxLayerElementMaterial(reader.getRecordData().numbers), 0,
							false);
					reader.stepOver();
					break;
				case "TextureId":
					addMeshLayerElement(null, stack,
							new KFbxLayerElementTexture("diffuse", reader.getRecordData().numbers), 0, false);
					reader.stepOver();
					break;
				case "GeometryUVInfo":
					addMeshLayerElement(null, stack, new KFbxLayerElementUV, 0);
					reader.stepIn();
					break;


				// поля слоёв
				case "TextureUV":
					setPredefinedProperty(reader, stack, "UV");
					reader.stepOver();
					break;
				case "TextureUVVerticeIndex":
					setPredefinedProperty(reader, stack, "UVIndex");
					reader.stepOver();
					break;
				// поля текстур
				case "Media":
					setPredefinedProperty(reader, stack, "RelativeFilename");
					reader.stepOver();
					break;
				case "ModelUVTranslation":
				case "ModelUVScaling":
				// иерархия по версии 5
				case "Children":
					setPredefinedProperty(reader, stack, recordName);
					reader.stepOver();
					break;

				case "Material":
					node = stack [stack.length - 1] as KFbxNode;
					node.materials.push(object = new KFbxSurfaceMaterial);
					stack.push(object);
					reader.stepIn();
					break;

				case "Texture":
					node = stack [stack.length - 1] as KFbxNode;
					node.textures.push(object = new KFbxTexture);
					stack.push(object);
					reader.stepIn();
					break;

				case "Takes":
					// all nodes were parsed by now
					buildHierarchy(heap);
					reader.stepOver();
					break;

				default:
					reader.stepOver();
					break;
			}
		}

		private function parseModelRecord(data:RecordData, stack:Array, heap:Object):void {
			var node:KFbxNode = new KFbxNode;
			// can't determine attribute yet :(
			stack.push(heap [data.strings [0]] = node);
		}

		private function buildHierarchy(heap:Object):void {
			for (var key:String in heap) {
				var node:KFbxNode = heap [key] as KFbxNode;
				if (node) {
					for (var i:int = 0; i < node.Children.length; i++) {
						var child:KFbxNode = heap [node.Children [i]] as KFbxNode;
						if (child) {
							child.parent = node;
						}
					}
				}
			}
		}
	}
}
