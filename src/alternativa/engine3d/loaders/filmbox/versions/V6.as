package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.*;
	import alternativa.engine3d.loaders.filmbox.readers.*;

	/**
	 * @private
	 * @see http://paulbourke.net/dataformats/fbx/fbx.pdf ?
	 */
	public class V6 extends VCommon implements IVersion {
		public function parseCurrentRecord(reader:IReader, stack:Array, heap:Object):void {

			var data:RecordData;

			var recordName:String = reader.getRecordName();
			switch (recordName) {
				// верхний уровень, Prop60
				case "Objects":
				case "Connections":
				case "Takes":
				case "Properties60":
				case "Version5":
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
					switch (data.strings.length) {
						case 2:
							// свойства объектов
							parseModelRecord(data, stack, heap);
							reader.stepIn();
							break;
						case 1:
							// анимация объектов
							parseAnimationLayer(data, stack, heap);
							reader.stepIn();
							break;
						default:
							// не должно бы, на всякий случай
							reader.stepOver();
							break;
					}
					break;

				case "Deformer":
					data = reader.getRecordData();
					switch (data.strings [1]) {
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
				case "LayerElementTexture":
					addMeshLayerElement(reader, stack, new KFbxLayerElementTexture);
					reader.stepIn();
					break;
				case "LayerElementSpecularTextures":
					addMeshLayerElement(reader, stack, new KFbxLayerElementTexture("specular"));
					reader.stepIn();
					break;
				case "LayerElementBumpTextures":
					addMeshLayerElement(reader, stack, new KFbxLayerElementTexture("bump"));
					reader.stepIn();
					break;
				case "LayerElementUV":
					addMeshLayerElement(reader, stack, new KFbxLayerElementUV);
					reader.stepIn();
					break;
				/*
				 case "LayerElementSpecularUV":
				 case "LayerElementBumpUV":
				 multiple UVs per vertex aren't supported
				 */
				case "LayerElementNormal":
					addMeshLayerElement(reader, stack, new KFbxLayerElementNormal);
					reader.stepIn();
					break;


				// поля слоёв
				case "MappingInformationType":
				case "ReferenceInformationType":
				case "Normals":
				case "Materials":
				case "TextureId":
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
					setPredefinedProperty(reader, stack, recordName);
					reader.stepOver();
					break;

				case "Material":
					data = reader.getRecordData();
					stack.push(heap [data.strings [0]] = new KFbxSurfaceMaterial);
					reader.stepIn();
					break;

				case "Texture":
					data = reader.getRecordData();
					stack.push(heap [data.strings [0]] = new KFbxTexture);
					reader.stepIn();
					break;


				// свойства
				case "Property":
					// someSpecialCase () ||
					setProperty(reader, stack, 3);
					reader.stepOver();
					break;


				case "Connect":
					parseConnection(reader.getRecordData(), heap);
					reader.stepOver();
					break;


				case "Take":
					data = reader.getRecordData();
					stack.push(heap [data.strings [0]] = new KFbxAnimStack);
					reader.stepIn();
					break;


				case "Channel":
					parseAnimationChannel(reader.getRecordData(), stack);
					reader.stepIn();
					break;


				case "Key":
					parseAnimationKey(reader.getRecordData(false), stack);
					reader.stepOver();
					break;


				default:
					reader.stepOver();
					break;
			}
		}

		private function parseModelRecord(data:RecordData, stack:Array, heap:Object):void {
			var attr:KFbxNodeAttribute;
			switch (data.strings [1]) {
				case "Light":
					attr = new KFbxLight;
					break;
				case "Limb":
				case "LimbNode":
					attr = new KFbxSkeleton;
					break;
				case "Mesh":
					attr = new KFbxMesh;
					break;
			}
			var node:KFbxNode = new KFbxNode;
			if (attr) {
				node.attributes.push(attr);
			}
			stack.push(heap [data.strings [0]] = node);
		}

		private function parseConnection(data:RecordData, heap:Object):void {
			if (data.strings [0] == "OO") {
				var owned:Object = heap [data.strings [1]];
				var owner:Object = heap [data.strings [2]];

				if (owned is KFbxNode) {
					if (owner is KFbxNode) {
						// иерархия
						(owned as KFbxNode).parent = owner as KFbxNode;
						return;
					}
					if (owner is KFbxCluster) {
						// bind joints
						(owner as KFbxCluster).jointNode = owned as KFbxNode;
						return;
					}
				}
				// материалы нод
				if (owned is KFbxSurfaceMaterial) {
					(owner as KFbxNode).materials.push(owned as KFbxSurfaceMaterial);
					return;
				}
				// текстуры
				if (owned is KFbxTexture) {
					(owner as KFbxNode).textures.push(owned as KFbxTexture);
					return;
				}
				// кластера
				if (owned is KFbxCluster) {
					(owner as KFbxSkin).clusters.push(owned as KFbxCluster);
					return;
				}
				// скины
				if (owned is KFbxSkin) {
					var geom:KFbxGeometry = (owner as KFbxNode).getAttribute(KFbxGeometry) as KFbxGeometry;
					if (geom) {
						geom.deformers.push(owned as KFbxSkin);
					}
					return;
				}

			} else {
				// ???
			}
		}

		private function parseAnimationChannel(data:RecordData, stack:Array):void {
			var aniChannel:KFbxAnimCurveNode = new KFbxAnimCurveNode;
			aniChannel.channel = data.strings [0];
			var aniChannelParent:KFbxAnimCurveNode = stack [stack.length - 1] as KFbxAnimCurveNode;
			aniChannelParent.curveNodes.push(aniChannel);
			stack.push(aniChannel);
		}

		private function parseAnimationLayer(data:RecordData, stack:Array, heap:Object):void {
			var aniLayer:KFbxAnimLayer = new KFbxAnimLayer;
			aniLayer.node = heap [data.strings [0]] as KFbxNode;
			var aniStack:KFbxAnimStack = stack [stack.length - 1] as KFbxAnimStack;
			aniStack.layers.push(aniLayer);
			stack.push(aniLayer);
		}

		/**
		 * @see http://code.google.com/p/blender-to-unity/issues/detail?id=2
		 short:
		 0,-14.7206611633301,U,a,n,...

		 0,1.619677305221558,C,n,
		 14779570560,1.619677901268005,C,n,
		 25864248480,1.619676709175110,C,n,
		 27711694800,1.619677901268005,C,n,...

		 0,0,U,s,0,0,n,
		 48110581250,0,U,s,0,0,n

		 variable length:
		 0, 90, U, s, 0, 0, a, 0.333233326673508, 0.333233326673508,
		 7697693000, 90, U, s, 0, -0, a, 0.333233326673508, 0.333233326673508,
		 15395386000, 90, U, s, 0, 0, r, 0.989998996257782

		 neither [s]mooth nor [b]roken tangent:
		 38488465000, 31.6565208435059, U, p, 100, -48.1283378601074, n, n,


		 The keys are represented like this:
		 1. The first value of a key is a number that represents the time of the key
		 2. The second value is the amplitude of the key, this can be meters for
		 translation or degrees for a rotation...
		 3. The third value is a character that represents the interpolation between the
		 keys, this can be 'C' for constant, 'L' for linear and 'U' for user defined. This
		 last one can be used to represent Bezier curves.
		 4. The fourth value is only needed when using user defined interpolation. This
		 value is a character 's', for unified tangents and 'b' for broken tangents.
		 5. The fifth value is a number that represents the direction of the right tangent
		 of the current key, this is the amplitude the tangent would have, at the current time
		 + 1 second. The screenshot attached explains a lot.
		 6. The sixth value is a number that represents the direction of the left tangent
		 of the next key. This notation is exactly the same as the notation for the fifth value.
		 7. The seventh value is a character 'a'.
		 8. The eight' value is a number representing the horizontal amplitude of the right
		 tangent of the current key. This is a number between 0 and 1, where 1 is the distance
		 between the current key and the next key. This can also be seen on the screen attached.
		 9. The ninth value is also a number representing the horizontal amplitude, but
		 this time of the left tangent of the next key.

		 */
		private function parseAnimationKey(data:RecordData, stack:Array):void {
			var aniCurve:KFbxAnimCurveNode = stack [stack.length - 1] as KFbxAnimCurveNode;
			for (var i:int = 0, n:int = data.strings.length; i < n;) {

				aniCurve.KeyTime.push(parseFloat(data.strings [i]));
				aniCurve.KeyValueFloat.push(parseFloat(data.strings [i + 1]));

				// находим начало следующего ключа
				switch (data.strings [i + 2]) {
					case "L":
						i += 3;
						break;
					case "C":
						i += 4;
						break;
					case "U":
						switch (data.strings [i + 3]) {
							case "a":
								i += 5;
								break;
							case "p":
								i += 8;
								break;
							case "b":
							case "s":
								switch (data.strings [i + 6]) {
									case "n":
										i += 7;
										break;
									case "r":
										i += 8;
										break;
									case "a":
										i += 9;
										break;
								}
								break;
							default:
								trace("unexpected key format (V6)");
								i = n;
								break;
						}
						break;
					default:
						trace("unexpected key format (V6)");
						i = n;
						break;
				}
			}
		}
	}
}
