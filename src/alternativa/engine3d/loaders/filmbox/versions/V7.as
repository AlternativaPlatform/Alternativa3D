package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.*;
	import alternativa.engine3d.loaders.filmbox.readers.*;

	/**
	 * @private
	 * @see http://download.autodesk.com/global/docs/fbxsdk2012/en_us/index.html
	 */
	public class V7 extends VCommon implements IVersion {
		private var namesMap:Object = new Object;

		public function parseCurrentRecord(reader:IReader, stack:Array, heap:Object):void {

			var data:RecordData;

			var recordName:String = reader.getRecordName();
			switch (recordName) {
				// верхний уровень, Prop70
				case "Objects":
				case "Connections":
				case "Takes":
				case "Properties70":
					stack.push(null);
					reader.stepIn();
					break;

				case "GlobalSettings":
					stack.push(recordName);
					reader.stepIn();
					break;


				// 3D объекты
				case "Geometry":
					data = reader.getRecordData(false);
					// Geometry: 809442864, "Geometry::", "Mesh"
					if (data.strings [2] == "Mesh") {
						stack.push(heap [data.strings [0]] = new KFbxMesh);
						reader.stepIn();
					} else {
						reader.stepOver();
					}
					break;

				case "Model":
					data = reader.getRecordData(false);
					// Model: 1360186080, "Model::Plane001", "Mesh"
					namesMap [data.strings [0]] = data.strings [1];
					stack.push(heap [data.strings [1]] = new KFbxNode);
					reader.stepIn();
					break;

				case "NodeAttribute":
					data = reader.getRecordData(false);
					// NodeAttribute: 699168640, "NodeAttribute::", "Light"
					// NodeAttribute: 1396263680, "NodeAttribute::", "LimbNode"
					parseNodeAttribute(data, stack, heap) ? reader.stepIn() : reader.stepOver();
					break;

				case "Deformer":
					data = reader.getRecordData(false);
					// Deformer: 802630608, "Deformer::", "Skin"
					// Deformer: 1365552016, "SubDeformer::", "Cluster"
					switch (data.strings [2]) {
						case "Cluster":
							stack.push(heap [data.strings [0]] = new KFbxCluster);
							reader.stepIn();
							break;
						case "Skin":
							heap [data.strings [0]] = new KFbxSkin;
							reader.stepOver();
							break;
						default:
							reader.stepOver();
							break;
					}
					break;

				// разная хрень из Mesh
				case "Vertices":
				case "PolygonVertexIndex":
					setMeshNumericProperty(reader, stack, recordName);
					reader.stepOver();
					break;
				case "LayerElementMaterial":
					addMeshLayerElement(reader, stack, new KFbxLayerElementMaterial);
					reader.stepIn();
					break;
				case "LayerElementUV":
					addMeshLayerElement(reader, stack, new KFbxLayerElementUV);
					reader.stepIn();
					break;
				case "LayerElementNormal":
					addMeshLayerElement(reader, stack, new KFbxLayerElementNormal);
					reader.stepIn();
					break;


				// поля слоёв
				case "MappingInformationType":
				case "ReferenceInformationType":
				case "Normals":
				case "Materials":
				case "UV":
				case "UVIndex":
				// поля текстур
				case "RelativeFilename":
				case "ModelUVTranslation":
				case "ModelUVScaling":
				// поля кластеров
				case "Indexes":
				case "Weights":
				case "Transform":
				case "TransformLink":
				// поля анимационных кривых
				case "KeyTime":
				case "KeyValueFloat":
					setPredefinedProperty(reader, stack, recordName);
					reader.stepOver();
					break;


				case "Material":
					data = reader.getRecordData(false);
					// Material: 699162640, "Material::Default", ""
					stack.push(heap [data.strings [0]] = new KFbxSurfaceMaterial);
					reader.stepIn();
					break;

				case "Texture":
					data = reader.getRecordData(false);
					// Texture: 816837168, "Texture::character_anim:file2", ""
					stack.push(heap [data.strings [0]] = new KFbxTexture);
					reader.stepIn();
					break;

				// свойства
				case "P":
					setAmbientLight(reader, stack, heap) || setProperty(reader, stack, 4);
					reader.stepOver();
					break;


				case "C":
					parseConnection(reader.getRecordData(false), heap);
					reader.stepOver();
					break;


				case "AnimationStack":
					data = reader.getRecordData(false);
					// AnimationStack: 1391183360, "AnimStack::Take 001", "" {
					namesMap [data.strings [0]] = data.strings [1];
					heap [data.strings [1]] = new KFbxAnimStack;
					reader.stepOver();
					break;


				case "AnimationLayer":
					data = reader.getRecordData(false);
					// AnimationLayer: 817238576, "AnimLayer::BaseLayer", "" {
					heap [data.strings [0]] = new KFbxAnimLayer;
					reader.stepOver();
					break;


				case "AnimationCurveNode":
					parseAnimationCurve(reader.getRecordData(false), heap);
					reader.stepOver();
					break;


				case "AnimationCurve":
					parseAnimationCurve(reader.getRecordData(false), heap, stack);
					reader.stepIn();
					break;


				default:
					reader.stepOver();
					break;
			}
		}

		private function parseAnimationCurve(data:RecordData, heap:Object, stack:Array = null):void {
			// AnimationCurveNode: 704770192, "AnimCurveNode::S", "" {
			// AnimationCurve: 1382726720, "AnimCurve::", "" {
			var curve:KFbxAnimCurveNode = new KFbxAnimCurveNode;
			var channel:String = data.strings [1];
			var dcat:int = channel.indexOf("::");
			curve.channel = (dcat > -1) ? channel.substr(dcat + 2) : channel;
			heap [data.strings [0]] = curve;
			if (stack) stack.push(curve);
		}

		private function setAmbientLight(reader:IReader, stack:Array, heap:Object):Boolean {
			if (stack [stack.length - 2] == "GlobalSettings") {
				var data:RecordData = reader.getRecordData();
				if (data.strings [0] == "AmbientColor") {
					parseAmbientLight(data, heap);
					return true;
				}
			}
			return false;
		}

		private function parseNodeAttribute(data:RecordData, stack:Array, heap:Object):Boolean {
			// NodeAttribute: 699168640, "NodeAttribute::", "Light"
			// NodeAttribute: 1396263680, "NodeAttribute::", "LimbNode"
			var attr:KFbxNodeAttribute;
			switch (data.strings [2]) {
				case "Light":
					attr = new KFbxLight;
					break;
				case "Limb":
				case "LimbNode":
					attr = new KFbxSkeleton;
					break;
			}
			if (attr) {
				stack.push(heap [data.strings [0]] = attr);
				return true;
			}
			return false;
		}

		private function parseConnection(data:RecordData, heap:Object):void {
			var owned:Object = heap [data.strings [1]];
			if (owned == null) owned = heap [namesMap [data.strings [1]]];
			var node:KFbxNode = heap [namesMap [data.strings [2]]] as KFbxNode;
			if (data.strings [0] == "OO") {
				// аттрибуты
				if (owned is KFbxNodeAttribute) {
					node.attributes.push(owned as KFbxNodeAttribute);
					return;
				}

				if (owned is KFbxNode) {
					if (node) {
						// иерархия
						(owned as KFbxNode).parent = node;
						return;
					}

					var cluster:KFbxCluster = heap [data.strings [2]] as KFbxCluster;
					if (cluster) {
						// bind joints
						cluster.jointNode = owned as KFbxNode;
						return;
					}
				}
				// материалы нод
				if (owned is KFbxSurfaceMaterial) {
					var material:KFbxSurfaceMaterial = owned as KFbxSurfaceMaterial;
					material.node = node;
					node.materials.push(material);
					return;
				}
				// кластера
				if (owned is KFbxCluster) {
					var skin:KFbxSkin = heap [data.strings [2]] as KFbxSkin;
					skin.clusters.push(owned as KFbxCluster);
					return;
				}
				// скины
				if (owned is KFbxSkin) {
					var geom:KFbxGeometry = heap [data.strings [2]] as KFbxGeometry;
					geom.deformers.push(owned as KFbxSkin);
					return;
				}
				// слои анимации
				if (owned is KFbxAnimLayer) {
					var astack:KFbxAnimStack = heap [namesMap [data.strings [2]]] as KFbxAnimStack;
					astack.layers.push(owned as KFbxAnimLayer);
					return;
				}
				// анимационные кривые
				if (owned is KFbxAnimCurveNode) {
					var aparent:KFbxAnimCurveNode = heap [data.strings [2]] as KFbxAnimCurveNode;
					aparent.curveNodes.push(owned as KFbxAnimCurveNode);
					return;
				}

			} else

			if (data.strings [0] == "OP") {
				// текстуры
				if (owned is KFbxTexture) {
					var texture:KFbxTexture = owned as KFbxTexture;
					var channel:String;
					switch (data.strings [3]) {
						case "Bump":
							channel = "bump";
							break;
						case "SpecularColor":
							channel = "specular";
							break;
						case "DiffuseColor":
						default:
							channel = "diffuse";
							break;
						// TODO find values for glossiness, emission, transparent
					}
					material = heap [data.strings [2]] as KFbxSurfaceMaterial;
					material.textures [channel] = texture;
					material.node.textures.push(texture);
					return;
				}
				// анимационные кривые
				if (owned is KFbxAnimCurveNode) {
					var curve:KFbxAnimCurveNode = owned as KFbxAnimCurveNode;
					if (node) {
						// связь с 3д объектами
						curve.node = node;
						return;
					}

					aparent = heap [data.strings [2]] as KFbxAnimCurveNode;
					if (aparent) {
						aparent.curveNodes.push(owned as KFbxAnimCurveNode);
						// curve channel
						channel = data.strings [3];
						var barat:int = channel.indexOf("|");
						curve.channel = (barat >= 0) ? channel.substr(barat + 1) : channel;
						return;
					}
				}
			}
		}
	}
}
