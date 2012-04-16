package alternativa.engine3d.loaders {

	import alternativa.engine3d.loaders.filmbox.*;
	import alternativa.engine3d.loaders.filmbox.readers.*;
	import alternativa.engine3d.loaders.filmbox.versions.*;
	import alternativa.types.Long;

	import commons.A3DMatrix;

	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	import versions.version2.a3d.A3D2;
	import versions.version2.a3d.animation.*;
	import versions.version2.a3d.geometry.*;
	import versions.version2.a3d.materials.*;
	import versions.version2.a3d.objects.*;

	/**
	 * Парсер файлов формата <code>.fbx</code>, предоставленных в виде <code>ByteArray</code>.
	 */
	public class ParserFBX extends Parser {
		/**
		 * Выполняет парсинг.
		 * Результаты парсинга находятся в списках <code>objects</code>, <code>parents</code>, <code>materials</code> и <code>textureMaterials</code>.
		 * @param data Файл в формате <code>.fbx</code>, предоставленный в виде <code>ByteArray</code>.
		 * @param texturesBaseURL Базовый путь к файлам текстур. Во время парсинга свойствам текстурных материалов <code>diffuseMapURL</code> и <code>opacityMapURL</code> устанавливаются строковые значения, состоящие из <code>texturesBaseURL</code> и имени файла.
		 * @param scale Величина, на которую умножаются координаты вершин, координаты объектов и значения масштабирования объектов.
		 * @see alternativa.engine3d.loaders.ParserMaterial
		 * @see #objects
		 * @see #parents
		 * @see #hierarchy
		 * @see #materials
		 */
		public function parse(data:ByteArray, texturesBaseURL:String = "", scale:Number = 1):void {
			this.texturesBaseURL = texturesBaseURL;
			this.scale = scale;

			data.endian = Endian.LITTLE_ENDIAN;

			var head:String = data.readUTFBytes(5);
			data.position -= 5;

			switch (head) {
				case "; FBX":
					fileReader = new ReaderText(data);
					break;
				case "Kayda":
					fileReader = new ReaderBinary();
					break;
				default:
					fileReader = null;
					break;
			}

			if (fileReader != null) {
				fileVersion = new VUnknown();
				stack = [];
				heap = {};

				while (fileReader.hasDataLeft()) {
					stack.length = fileReader.getDepth();

					fileVersion.parseCurrentRecord(fileReader, stack, heap);

					if (fileVersion is VUnknown) {
						switch ((fileVersion as VUnknown).majorVersion) {
							case 5:
								fileVersion = new V5();
								break;
							case 6:
								fileVersion = new V6();
								break;
							case 7:
								fileVersion = new V7();
								break;
						}
					}
				}
				trace("parsed: 0 =", fileReader.getDepth());

				ids = new IncrementalIDGenerator2();
				a3d = new A3D2(new Vector.<A3D2AmbientLight>(), new Vector.<A3D2AnimationClip>(),
						new Vector.<A3D2Track>(), new Vector.<A3D2Box>(), null, null, // cube maps, decals
						new Vector.<A3D2DirectionalLight>(), new Vector.<A3D2Image>(), new Vector.<A3D2IndexBuffer>(),
						new Vector.<A3D2Joint>(), new Vector.<A3D2Map>(), new Vector.<A3D2Material>(),
						new Vector.<A3D2Mesh>(), new Vector.<A3D2Object>(), new Vector.<A3D2OmniLight>(),
						new Vector.<A3D2Skin>(), new Vector.<A3D2SpotLight>(), null, // sprites
						new Vector.<A3D2VertexBuffer>());

				var key:String, nodeNames:Dictionary = new Dictionary();
				for (key in heap) {
					var node:KFbxNode = heap [key] as KFbxNode;
					if (node) {
						convertNode(node, nodeNames [node] = heapKeyToName(key));
					}
				}
				// for перебирает ключи в случайном порядке, посему парсим анимацию после всех нод
				for (key in heap) {
					var animation:KFbxAnimStack = heap [key] as KFbxAnimStack;
					if (animation) {
						convertAnimation(animation, heapKeyToName(key), nodeNames);
					}
				}

				complete(a3d);
				trace("converted,", hierarchy.length, "(" + objects.length + ")");
			}
		}

		private var texturesBaseURL:String;
		private var scale:Number;

		private var fileReader:IReader;
		private var fileVersion:IVersion;
		private var stack:Array;
		private var heap:Object;
		private var ids:IncrementalIDGenerator2;
		private var a3d:A3D2;

		private function heapKeyToName(key:String):String {
			var iodc:int = key.indexOf("::");
			return (iodc < 0) ? key : key.substr(iodc + 2);
		}

		/** @inheritDoc */
		override public function clean():void {
			super.clean();
			fileReader = null;
			stack = null;
			heap = null;
			ids = null;
			a3d = null;
		}

		private function convertAnimation(animation:KFbxAnimStack, name:String, nodeNames:Dictionary):void {
			var tracks:Vector.<int> = convertAnimationLayers(animation, nodeNames);
			/* Repin: objIds are deprecated
			 var objIds:Vector.<Long> = collectAnimatedObjectIds (tracks);*/
			if (tracks.length > 0) {
				a3d.animationClips.push(new A3D2AnimationClip(a3d.animationClips.length, true /* loop? */, name, null
						/*objIds*/, tracks));
			}
		}

		/*private function collectAnimatedObjectIds (tracks:Vector.<int>):Vector.<Long> {
		 var ids:Vector.<Long> = new Vector.<Long>;
		 for (var i:int = 0, n:int = tracks.length; i < n; i++) {
		 var name:String = a3d.animationTracks [tracks [i]].objectName;
		 var id:Long;

		 // find matching joints
		 for (var j:int = 0, m:int = a3d.joints.length; j < m; j++) {
		 if (name == a3d.joints [j].name) {
		 id = a3d.joints [j].id; j = m;
		 }
		 }

		 if (id == null) {
		 // attempt to match other 3d objects
		 for (j = 0, m = a3d.objects.length; j < m; j++) {
		 if (name == a3d.objects [j].name) {
		 id = a3d.objects [j].id; j = m;
		 }
		 }
		 }

		 if ((id != null) && (ids.indexOf (id) < 0)) {
		 ids.push (id);
		 }
		 }

		 if (ids.length > 0) {
		 return ids;
		 }

		 return null;
		 }*/

		private function convertAnimationLayers(animation:KFbxAnimStack, nodeNames:Dictionary):Vector.<int> {
			// в fbx следущая структура:
			// stack 1-n layer 1-n curveNode 1-n curve;
			// у нас это всё дерево curveNode-ов;
			// на выходе надо набор A3D2Track-ов.
			var tracks:Vector.<int> = new Vector.<int>();

			for each (var layer:KFbxAnimLayer in animation.layers) {
				layer.fixV6();

				// собираем все KFbxNode в слое
				var nodes:Vector.<KFbxNode> = new Vector.<KFbxNode>();
				layer.collectNodes(nodes);

				for each (var node:KFbxNode in nodes) {
					// собираем все curveNode для данного KFbxNode
					var curves:Vector.<KFbxAnimCurveNode> = new Vector.<KFbxAnimCurveNode>();
					layer.collectCurves(curves, node);

					// времена ключей всех кривых в curves не обязаны быть согласованными;
					// собираем и упорядочиваем все времена
					var times:Vector.<Number> = collectKeyTimes(curves);

					// создаём A3D2Track
					tracks.push(a3d.animationTracks.length);
					a3d.animationTracks.push(new A3D2Track(a3d.animationTracks.length,
							calculateKeyframes(curves, times, node.transformationClone()), nodeNames [node]));
				}

			}

			return tracks;
		}

		private function calculateKeyframes(curves:Vector.<KFbxAnimCurveNode>, times:Vector.<Number>,
				node2:KFbxNode):Vector.<A3D2Keyframe> {
			var nodeProperties:Object = {
				T:"LclTranslation", R:"LclRotation", S:"LclScaling"
			}

			var frames:Vector.<A3D2Keyframe> = new Vector.<A3D2Keyframe>(times.length);

			for (var i:int = 0, n:int = times.length; i < n; i++) {
				var t:Number = times [int(i)];
				for each (var curve:KFbxAnimCurveNode in curves) {
					var property:Vector.<Number> = node2 [nodeProperties [curve.channel]];
					if (property) {
						for each (var terminalCurve:KFbxAnimCurveNode in curve.curveNodes) {

							if (terminalCurve.KeyTime.length == 0) {
								// this does happen for some reason :(
								continue;
							}

							var index:int;
							switch (terminalCurve.channel) {
								case "X":
									index = 0;
									break;
								case "Y":
									index = 1;
									break;
								case "Z":
									index = 2;
									break;
								default:
									index = -1;
									break;
							}
							if (index >= 0) {
								// совпадает время ключа?
								if ((terminalCurve.KeyTime.length > i) && (terminalCurve.KeyTime [int(i)] == t)) {
									// да
									property [index] = terminalCurve.KeyValueFloat [int(i)];
								} else {
									// нет, интерполируем
									property [index] = terminalCurve.interpolateValue(t);
								}
							}
						}
					}
				}

				// SDK: The time unit in FBX (KTime) is 1/46186158000 of one second.
				frames [i] = new A3D2Keyframe(t/4.6186158e10, convertMatrix(node2.calculateNodeTransformation()));
			}

			return frames;
		}

		private function collectKeyTimes(curves:Vector.<KFbxAnimCurveNode>):Vector.<Number> {
			// не совпадают ли времена ключей во всех кривых?
			var timesAreSame:Boolean;
			var times:Vector.<Number> = curves [0].curveNodes [0].KeyTime;
			for each (var curve:KFbxAnimCurveNode in curves) {
				for each (var terminalCurve:KFbxAnimCurveNode in curve.curveNodes) {

					if (terminalCurve.KeyTime.length == 0) {
						// this does happen for some reason :(
						// will be ignored later, so ignore now
						continue;
					}

					if (terminalCurve.KeyTime.length != times.length) {
						timesAreSame = false;
						break;
					} else {
						// времена всё ещё могут быть разными
						for (var i:int = 0, n:int = terminalCurve.KeyTime.length; i < n; i++) {
							if (times [int(i)] != terminalCurve.KeyTime [int(i)]) {
								timesAreSame = false;
								break;
							}
						}
						if (!timesAreSame) break;
					}
				}
				if (!timesAreSame) break;
			}

			if (timesAreSame) {
				return times;
			}

			// нет, не совпадают
			var ts:Array = [];
			for each (curve in curves) {
				for each (terminalCurve in curve.curveNodes) {
					for (i = 0, n = terminalCurve.KeyTime.length; i < n; i++) {
						var t:Number = terminalCurve.KeyTime [int(i)];
						if (ts.indexOf(t) < 0) {
							ts.push(t);
						}
					}
				}
			}

			ts.sort(Array.NUMERIC);
			return Vector.<Number>(ts);
		}

		private function convertNode(node:KFbxNode, name:String):void {
			if (node.attributes.length == 0) {
				// пустой 3D объект
				a3d.objects.push(new A3D2Object(-1, ids.getID(node), name, ids.getID(node.parent),
						convertMatrix(node.calculateNodeTransformation()), node.isVisible()));
				//trace ("Object3D:", name);

			} else {
				var nodeTransform:Matrix3D = node.calculateNodeTransformation();
				var attrTransform:Matrix3D = node.calculateAttributesTransformation();

				var useWrapperNode:Boolean = (attrTransform != null) || (node.attributes.length > 1);
				if (useWrapperNode) {
					// промежуточная нода для поддержки "geometric transform"
					// аттрибутов из 3dmax или множества аттрибутов
					a3d.objects.push(new A3D2Object(-1, ids.getID(node), null, ids.getID(node.parent),
							convertMatrix(nodeTransform), node.isVisible()));

					nodeTransform = attrTransform;
				}

				for each (var attribute:KFbxNodeAttribute in node.attributes) {
					var id:Long = useWrapperNode ? ids.getID(new KFbxNode) : ids.getID(node);
					var pid:Long = useWrapperNode ? ids.getID(node) : ids.getID(node.parent);

					// mesh, light, и т.п.
					var mesh:KFbxMesh = attribute as KFbxMesh;
					if (mesh) {
						convertMesh(mesh, node, name, id, pid, nodeTransform);
						continue;
					}

					var light:KFbxLight = attribute as KFbxLight;
					if (light) {
						//nodeTransform.prependRotation (90, Vector3D.X_AXIS); TODO fix this shit
						convertLight(light, node, name, id, pid, nodeTransform);
						continue;
					}

					var joint:KFbxSkeleton = attribute as KFbxSkeleton;
					if (joint) {
						convertJoint(joint, node, name, id, pid, nodeTransform);
						continue;
					}
				}
			}
		}

		private function convertJoint(joint:KFbxSkeleton, node:KFbxNode, name:String, id:Long, pid:Long,
				nodeTransform:Matrix3D):void {
			a3d.joints.push(new A3D2Joint(-1, id, name, pid, convertMatrix(nodeTransform), node.isVisible()));
		}

		private function convertLight(light:KFbxLight, node:KFbxNode, name:String, id:Long, pid:Long,
				nodeTransform:Matrix3D):void {
			switch (light.LightType) {
				case -1:
					a3d.ambientLights.push(new A3D2AmbientLight(-1, convertColor(light.Color), id, light.getIntensity(),
							name, pid, convertMatrix(nodeTransform), node.isVisible()));
					break;
				case 0:
					a3d.omniLights.push(new A3D2OmniLight(light.FarAttenuationStart*scale,
							light.FarAttenuationEnd*scale, -1, convertColor(light.Color), id, light.getIntensity(),
							name, pid, convertMatrix(nodeTransform), node.isVisible()));
					break;
				case 1:
					a3d.directionalLights.push(new A3D2DirectionalLight(-1, convertColor(light.Color), id,
							light.getIntensity(), name, pid, convertMatrix(nodeTransform), node.isVisible()));
					break;
				case 2:
					var rad:Number = Math.PI/180;
					a3d.spotLights.push(new A3D2SpotLight(light.FarAttenuationStart*scale,
							light.FarAttenuationEnd*scale, -1, convertColor(light.Color), rad*light.Coneangle,
							rad*((light.HotSpot > 0) ? light.HotSpot : light.Coneangle), id, light.getIntensity(), name,
							pid, convertMatrix(nodeTransform), node.isVisible()));
					break;
			}
		}

		private function convertColor(color:Vector.<Number>):uint {
			return uint(255*color [0])*65536 + uint(255*color [1])*256 + uint(255*color [2]);
		}

		private function convertMesh(mesh:KFbxMesh, node:KFbxNode, name:String, id:Long, pid:Long,
				nodeTransform:Matrix3D):void {
			var mi:MaterialsInfo = prepareMaterialsInfo(mesh, node);
			var vbr:ConvertVertexBufferResult = convertVertexBuffer(mesh, mi);
			var ibr:ConvertIndexBufferResult = convertIndexBuffer(node,
					convertPolygonsMap(mesh.PolygonVertexIndex, vbr.polygonVerticesMap), mi);
			bakeTextureTransforms(mesh, vbr, ibr);
			if (mesh.deformers.length > 0) {
				// skins
				var csr:ConvertSkinsResult = convertSkinsAndPatchVertexBuffer(mesh, vbr, ibr);
				a3d.skins.push(new A3D2Skin(vbr.bboxId, id, ibr.ibufId, csr.jointBindTransforms, csr.joints, name,
						csr.numJoints, pid, ibr.surfaces, convertMatrix(nodeTransform), Vector.<int>([vbr.vbufId]),
						node.isVisible()));
			} else {
				// meshes
				a3d.meshes.push(new A3D2Mesh(vbr.bboxId, id, ibr.ibufId, name, pid, ibr.surfaces,
						convertMatrix(nodeTransform), Vector.<int>([vbr.vbufId]), node.isVisible()));
			}
		}

		private function convertSkinsAndPatchVertexBuffer(mesh:KFbxMesh, vbr:ConvertVertexBufferResult,
				ibr:ConvertIndexBufferResult):ConvertSkinsResult {
			var vertexBuffer:A3D2VertexBuffer = a3d.vertexBuffers [vbr.vbufId];

			var surfaceCount:int = ibr.surfaces.length;
			var vertexCount:uint = vertexBuffer.vertexCount;
			var maxJointsPerVertexDoubled:int = 8*2;

			var jointsAndWeights:Vector.<Number> = new Vector.<Number>(maxJointsPerVertexDoubled*vertexCount, true);
			var freeSpotOffsets:Vector.<uint> = new Vector.<uint>(vertexCount, true);

			var numJoints:Vector.<uint> = new Vector.<uint>(surfaceCount, true);

			// все кластеры соответствуют renderedJoints (при условии одного джоинта на кластер TODO выяснить)
			var matrix1:Matrix3D = new Matrix3D(), matrix2:Matrix3D = new Matrix3D();
			var jointIds:Vector.<Long> = new Vector.<Long>();
			var jointBindTransforms:Vector.<A3D2JointBindTransform> = new Vector.<A3D2JointBindTransform>();
			for each (var skin:KFbxSkin in mesh.deformers) {
				var i:int = jointBindTransforms.length;
				jointBindTransforms.length += skin.clusters.length;
				for each (var cluster:KFbxCluster in skin.clusters) {
					var jId:Long = ids.getID(cluster.jointNode);
					jointIds [i] = jId;
					// http://area.autodesk.com/forum/autodesk-fbx/fbx-sdk/question-about-skinning-could-you-please-help-me-jiayang/
					// Cluster TransformLink is the global matrix of the bone(link) at the binding moment.
					// Cluster Transform is the global matrix of the geometry at the binding moment.
					// email from Jiayang.Xu@autodesk.com:
					// FBX writer will write it as: Transform = TransformLink.Inverse() * Transform;
					// But then FBX reader will do "Transform = TransformLink * Transform;" to compensate what is done in writer.
					// email from Robert.Goulet@autodesk.com:
					// I think this was because the inversed transform was going right into the graphic card transform in FiLMBOX for
					// real-time rendering. Since the renderer needed the inverse matrix, that's how it got stored in the file.
					matrix1.rawData = cluster.Transform;
					matrix2.rawData = cluster.TransformLink;
					jointBindTransforms [i] = new A3D2JointBindTransform(convertMatrix(matrix1), jId);
					// weights and surfaces
					var i3:int = i*3;
					for (var j:int = 0, n:int = cluster.Indexes.length; j < n; j++) {
						var weight:Number = cluster.Weights [j];
						var affectedVertices:Vector.<int> = vbr.vertexClonesMap [cluster.Indexes [j]];
						for (var k:int = 0, m:int = affectedVertices.length; k < m; k++) {
							var vertexIndex:int = affectedVertices [k];
							var p:int = freeSpotOffsets [vertexIndex];
							var q:int = maxJointsPerVertexDoubled*vertexIndex + p;
							jointsAndWeights [q] = i3;
							jointsAndWeights [q + 1] = weight;
							freeSpotOffsets [vertexIndex] = p + 2;
						}
					}

					i++;
				}
			}

			n = jointIds.length;
			var surfaceJoints:Vector.<Long> = new Vector.<Long>();
			for (i = 0; i < surfaceCount; i++) {
				numJoints [i] = n;
				for (j = 0; j < n; j++) {
					surfaceJoints.push(jointIds [j]);
				}
			}

			// skin data converted; re-assemble vertex buffer
			var usedJointsPerVertexDoubled:int = 0;
			for (i = 0; i < vertexCount; i++) {
				n = freeSpotOffsets [i];
				if (n > usedJointsPerVertexDoubled) usedJointsPerVertexDoubled = n;
			}

			if (usedJointsPerVertexDoubled%4 > 0) {
				usedJointsPerVertexDoubled += 4 - (usedJointsPerVertexDoubled%4);
			}

			if (usedJointsPerVertexDoubled > maxJointsPerVertexDoubled) {
				usedJointsPerVertexDoubled = maxJointsPerVertexDoubled;
			}

			var jointsAttributesPerVertex:int = usedJointsPerVertexDoubled/4;

			for (i = 0; i < jointsAttributesPerVertex; i++) {
				vertexBuffer.attributes.push(A3D2VertexAttributes.JOINT);
			}

			var bytesIn:ByteArray = vertexBuffer.byteBuffer;
			bytesIn.position = 0;
			var bytesOut:ByteArray = new ByteArray();
			bytesOut.endian = bytesIn.endian;
			i = 0;
			while (bytesIn.bytesAvailable) {
				bytesIn.readBytes(bytesOut, bytesOut.position, vbr.bytesPerVertex);
				bytesOut.position = bytesOut.length;
				for (j = 0, k = i*maxJointsPerVertexDoubled; j < usedJointsPerVertexDoubled; j++) {
					bytesOut.writeFloat(jointsAndWeights [k + j]);
				}
				i++;
			}
			vertexBuffer.byteBuffer = bytesOut;

			// will not be used, but just to be consistent
			vbr.bytesPerVertex += jointsAttributesPerVertex*4*4;

			return new ConvertSkinsResult(jointBindTransforms, surfaceJoints, numJoints);
		}

		private function bakeTextureTransforms(mesh:KFbxMesh, vbr:ConvertVertexBufferResult,
				ibr:ConvertIndexBufferResult):void {
			// пока трансформация текстур не поддерживается A3D материалами, жарим uv
			var writtenVertices:Object = new Object();
			var bytes:ByteArray = a3d.vertexBuffers [vbr.vbufId].byteBuffer;

			var texture:KFbxTexture, nonTrivialTransformationFound:Boolean;
			for (var i:int = 0, j:int = -1; i < vbr.polygonVerticesMap.length; i++) {
				// текстура вершины?
				if ((i == 0) || (mesh.PolygonVertexIndex [i - 1] < 0)) {
					j++;
					texture = ibr.textures [j];
					nonTrivialTransformationFound = false;
				}

				if (texture) {

					var k:int = vbr.polygonVerticesMap [i];
					if (writtenVertices [k]) continue;
					writtenVertices [k] = true;

					var T:Matrix = texture.transformation;
					if (T == null) T = texture.calculateTextureTransformation();

					if (!nonTrivialTransformationFound) {
						var d:Number = 0, di:Number;
						di = T.a - 1;
						if (di > 0) d += di; else d -= di;
						di = T.b;
						if (di > 0) d += di; else d -= di;
						di = T.c;
						if (di > 0) d += di; else d -= di;
						di = T.d - 1;
						if (di > 0) d += di; else d -= di;
						di = T.tx;
						if (di > 0) d += di; else d -= di;
						di = T.ty;
						if (di > 0) d += di; else d -= di;
						nonTrivialTransformationFound = (d > 1e-6);
					}

					if (nonTrivialTransformationFound) {
						var p:int = vbr.bytesPerVertex*k + vbr.uvOffset;

						bytes.position = p;
						var u:Number = bytes.readFloat();
						var v:Number = 1 - bytes.readFloat();

						bytes.position = p;
						bytes.writeFloat(u*T.a + v*T.b + T.tx);
						bytes.writeFloat(1 - (u*T.c + v*T.d + T.ty));
					} else {
						// если тривиальная трансформация, пропускаем все вершины в этом полике
						texture = null;
					}
				}
			}
		}

		private function convertIndexBuffer(node:KFbxNode, polygons:Vector.<Vector.<int>>,
				materialsInfo:MaterialsInfo):ConvertIndexBufferResult {

			var sizeOfShort:int = 2;
			var indicesData:ByteArray = new ByteArray();
			indicesData.endian = Endian.LITTLE_ENDIAN;

			var surfaces:Vector.<A3D2Surface> = new Vector.<A3D2Surface>();
			var indexBegin:int = 0, numTriangles:int = 0;

			var textures:Vector.<KFbxTexture> = new Vector.<KFbxTexture>(polygons [0].length);

			var materialHashTable:Object = new Object(); // Dictionary?
			var lastMaterialHash:int = -1, lastMaterial:KFbxSurfaceMaterial = new KFbxSurfaceMaterial();

			var polygons0:Vector.<int> = polygons [0];
			var polygons1:Vector.<int> = polygons [1];

			for (var i:int = 0, n:int = polygons0.length; i <= n; i++) {
				// выполняем цикл на 1 раз больше, чем нужно, чтобы создать последний сурфейс TODO поправить
				var materialHash:int = (i < n) ? calculateMaterialHash(i, materialsInfo) : int.MAX_VALUE;

				if ((lastMaterialHash != materialHash) && !(lastMaterialHash < 0)) {
					// detected end of surface - get or create the material
					if (materialHashTable [lastMaterialHash] == null) {
						calculateMaterial(i - 1, node, materialsInfo, lastMaterial);
						materialHashTable [lastMaterialHash] = convertMaterial(lastMaterial);

						// заодно коллекционируем текстуры по полигонам
						// (эта хрень нужна только для текстурных трансформаций)
						var texture:KFbxTexture = lastMaterial.textures ["diffuse"];
						if (texture != null) {
							for (j = i - 1; (j > -1) && (textures [j] == null); j--) {
								textures [j] = texture;
							}
						}
					}

					surfaces.push(new A3D2Surface(indexBegin, materialHashTable [lastMaterialHash], numTriangles));
					indexBegin = indicesData.length/sizeOfShort;
					numTriangles = 0;
				}

				if (i < n) {
					for (var j:int = polygons0 [i], m:int = (i < n - 1) ? polygons0 [i + 1] : polygons1.length; j < m; j++) {
						indicesData.writeShort(polygons1 [j]);
						if (j%3 == 0) numTriangles++;
					}

					lastMaterialHash = materialHash;
				}
			}

			return new ConvertIndexBufferResult(a3d.indexBuffers.push(new A3D2IndexBuffer(indicesData,
					a3d.indexBuffers.length, indicesData.length/sizeOfShort)) - 1, surfaces, textures);
		}

		private function convertMaterial(lastMaterial:KFbxSurfaceMaterial):int {
			return a3d.materials.push(new A3D2Material(convertTexture(lastMaterial.textures ["diffuse"]),
					convertTexture(lastMaterial.textures ["glossiness"]), a3d.materials.length,
					convertTexture(lastMaterial.textures ["emission"]), convertTexture(lastMaterial.textures ["bump"]),
					convertTexture(lastMaterial.textures ["transparent"]), -1,
					convertTexture(lastMaterial.textures ["specular"]))) - 1;
		}

		private function convertTexture(texture:KFbxTexture):int {
			if (texture) {
				var file:String = texture.RelativeFilename;
				if (texturesBaseURL != "") {
					var slash:int = file.lastIndexOf("\\");
					if (slash < 0) slash = file.lastIndexOf("/");
					if (slash > 1) file = file.substr(slash + 1);
					file = texturesBaseURL + file;
				}
				return a3d.maps.push(new A3D2Map(0, a3d.maps.length,
						a3d.images.push(new A3D2Image(a3d.images.length, file)) - 1)) - 1;
			}
			return -1;
		}

		private function prepareMaterialsInfo(mesh:KFbxMesh, node:KFbxNode):MaterialsInfo {
			// это вынесено сюда, т.к. кроме создания материалов в convertIndexBuffer нам придётся
			// дублировать вершины для граней с трансформирующими материалами в convertVertexBuffer
			var info:MaterialsInfo = new MaterialsInfo();
			var layer:KFbxLayer = mesh.layers [0];
			info.matLayer = layer.getLayerElement(KFbxLayerElementMaterial) as KFbxLayerElementMaterial;
			info.texLayers = new Vector.<KFbxLayerElementTexture>();
			for each (var channel:String in ["diffuse", "specular", "bump"]) {
				var texLayer:KFbxLayerElementTexture = layer.getLayerElement(KFbxLayerElementTexture, "renderChannel",
						channel) as KFbxLayerElementTexture;
				if (texLayer) info.texLayers.push(texLayer);
			}
			info.materialHashBase = 1 + Math.max(node.materials.length, node.textures.length);
			return info;
		}

		private function calculateMaterialHash(i:int, materialsInfo:MaterialsInfo):int {
			// хеш материала нужен для сравнения материалов поликов - т.е. не имеет права давать коллизии
			var materialHash:int = 0;
			// кроме ByPolygon, маппинг может быть AllSame или NoMappingInformation
			// в обоих случаях нет нужды менять materialHash
			if (materialsInfo.matLayer && (materialsInfo.matLayer.MappingInformationType == "ByPolygon")) {
				materialHash = materialsInfo.matLayer.Materials [i];
			}
			for each (var texLayer:KFbxLayerElementTexture in materialsInfo.texLayers) {
				if (texLayer.MappingInformationType == "ByPolygon") {
					var textureId:int = texLayer.TextureId [i];
					if (textureId < 0) textureId = -1;
					materialHash = materialHash*materialsInfo.materialHashBase + textureId;
				}
			}
			return materialHash;
		}

		private function calculateMaterial(i:int, node:KFbxNode, materialsInfo:MaterialsInfo,
				material:KFbxSurfaceMaterial):void {
			// TODO support material templates for v7
			if (materialsInfo.matLayer) {
				if (materialsInfo.matLayer.MappingInformationType == "AllSame") {
					node.materials [materialsInfo.matLayer.Materials [0]].copyTo(material);
				} else if (materialsInfo.matLayer.MappingInformationType == "ByPolygon") {
					node.materials [materialsInfo.matLayer.Materials [i]].copyTo(material);
				}
			}
			for each (var texLayer:KFbxLayerElementTexture in materialsInfo.texLayers) {
				if (texLayer.MappingInformationType == "ByPolygon") {
					var index:int = texLayer.TextureId [i];
					// v5 can have mapping but no textures, or negative indices :(
					if ((index >= 0) && (index < node.textures.length)) {
						material.textures [texLayer.renderChannel] = node.textures [index];
					}
				} else if (texLayer.MappingInformationType == "AllSame") {
					material.textures [texLayer.renderChannel] = node.textures [texLayer.TextureId [0]];
				}
			}
		}

		private function convertPolygonsMap(rawPolygonsData:Vector.<Number>,
				polygonVerticesMap:Vector.<int>):Vector.<Vector.<int>> {
			// map [0] = pointers in map [1]
			// map [1] = triangle indices for original polygons
			var map:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(2, true);
			var pointers:Vector.<int> = new Vector.<int>();
			map [0] = pointers;
			var triangles:Vector.<int> = new Vector.<int>();
			map [1] = triangles;
			for (var k:int = 1, m:int = 0, n:int = rawPolygonsData.length; k < n; k++) {
				var index:int = rawPolygonsData [k];
				if (index < 0) {
					// end of polygon - triangulate it
					pointers.push(triangles.length);
					var i:int = m, j:int = k, done:Boolean = false;
					do {
						i++;
						if (i < j) {
							triangles.push(polygonVerticesMap [i - 1], polygonVerticesMap [i], polygonVerticesMap [j]);
						} else {
							done = true;
						}

						j--;
						if (i < j) {
							triangles.push(polygonVerticesMap [j], polygonVerticesMap [j + 1], polygonVerticesMap [i]);
						} else {
							done = true;
						}
					} while (!done);
					m = k + 1;
				}
			}
			return map;
		}

		private function convertVertexBuffer(mesh:KFbxMesh, materialsInfo:MaterialsInfo):ConvertVertexBufferResult {
			var vertices:Vector.<Number> = mesh.Vertices, polyIndex:Vector.<Number> = mesh.PolygonVertexIndex;

			var uvsLayer:KFbxLayerElementUV = mesh.layers [0].getLayerElement(KFbxLayerElementUV) as KFbxLayerElementUV;
			if (uvsLayer == null) uvsLayer = KFbxLayerElementUV.generateDefaultTextureMap(mesh);

			var normalsLayer:KFbxLayerElementNormal = mesh.layers [0].getLayerElement(KFbxLayerElementNormal) as KFbxLayerElementNormal;
			if (normalsLayer == null) normalsLayer = KFbxLayerElementNormal.generateDefaultNormals(mesh);

			var uvs:Vector.<Number> = uvsLayer.UV;
			var uvIndices:Vector.<Number> = uvsLayer.UVIndex;
			var normals:Vector.<Number> = normalsLayer.Normals;

			// переводим все возможные uvsLayer.MappingInformationType/ReferenceInformationType в "ByPolygonVertex"/"IndexToDirect"
			var uvIndicesByPolygonVertex:Vector.<int> = convertUVMappingToByPolygonVertex(uvsLayer.MappingInformationType,
					uvsLayer.ReferenceInformationType, uvIndices, polyIndex, uvs);

			// переводим все возможные normalsLayer.MappingInformationType в "ByPolygonVertex" c ReferenceInformationType = "IndexToDirect"
			var normalIndicesByPolygonVertex:Vector.<int> = convertNormalsToByPolygonVertex(normalsLayer.MappingInformationType,
					normals, polyIndex);

			var i:int, j:int, k:int;

			// т.к. комбинаций координат/UV/нормалей м.б. больше чем вершин, последние надо клонировать
			// при этом нужны карты вершин старые->новые для триангуляции поликов и цепляния костей
			// pmap [i] = индекс вершины (или клона) на позиции i в mesh.PolygonVertexIndex
			// vmap [i] = массив индексов вершины и клонов, соответствующих вершине i в mesh.Vertices
			var pmap:Vector.<int> = new Vector.<int>(polyIndex.length);
			var vmap:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(j = vertices.length/3, true);
			for (i = 0; i < j; i++) vmap [i] = new Vector.<int>();

			// теперь разворачиваем вертексы
			var vertexHashBaseUV:int = 1 + uvs.length/2;
			var vertexHashBasePolyVertices:int = 1 + Math.max(j, polyIndex.length);
			var vertexHashTable:Dictionary = new Dictionary();

			// TODO учитывать только трансформирующие материалы?
			var lastPolygon:int = 0;
			var lastMaterialHash:int = calculateMaterialHash(0, materialsInfo);

			var polyLength:int = polyIndex.length;
			for (i = 0; i < polyLength; i++) {
				var vertexIdx:int = polyIndex [i];
				if (vertexIdx < 0) vertexIdx = -vertexIdx - 1;

				if ((i > 0) && (polyIndex [i - 1] < 0)) {
					lastPolygon++;
					lastMaterialHash = calculateMaterialHash(lastPolygon, materialsInfo);
				}

				// нужен хеш без коллизий; int уже не достаточно
				var vertexHash:Long = Long.getLong(vertexHashBaseUV*vertexIdx + uvIndicesByPolygonVertex [i],
						vertexHashBasePolyVertices*lastMaterialHash + normalIndicesByPolygonVertex [i]);

				if (vertexHashTable [vertexHash] != null) {
					pmap [i] = vertexHashTable [vertexHash];
				} else {
					if (vmap [vertexIdx].length == 0) {
						// vertexIdx встретился первый раз
						pmap [i] = vertexHashTable [vertexHash] = vertexIdx;
						vmap [vertexIdx].push(vertexIdx);
					} else {
						// нужен клон
						pmap [i] = vertexHashTable [vertexHash] = j;
						vmap [vertexIdx].push(j);
						j++;
					}
				}
			}

			// считаем тангенты (только для исходных вершин)
			var tangents:Vector.<Number> = calculateVertexTangents(vertices, uvs, polyIndex, uvIndicesByPolygonVertex,
					normalIndicesByPolygonVertex);

			// наконец, пишем буффер
			var bytesPerVertex:int = (3 + 2 + 3 + 4)*4;
			var bytes:ByteArray = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.length = bytesPerVertex*j;

			var x:Number, y:Number, z:Number, cx:Number, cy:Number, cz:Number, nx:Number, ny:Number, nz:Number, tx:Number, ty:Number, tz:Number;
			var minX:Number = +Number.MAX_VALUE, minY:Number = +Number.MAX_VALUE, minZ:Number = +Number.MAX_VALUE;
			var maxX:Number = -Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE, maxZ:Number = -Number.MAX_VALUE;

			var writtenVertices:Object = new Object();

			for (i = 0; i < polyIndex.length; i++) {
				k = pmap [i];
				if (writtenVertices [k]) continue;
				bytes.position = bytesPerVertex*k;
				writtenVertices [k] = true;

				j = polyIndex [i];
				if (j < 0) j = -j - 1;
				j *= 3;
				bytes.writeFloat(x = scale*vertices [j]);
				bytes.writeFloat(y = scale*vertices [j + 1]);
				bytes.writeFloat(z = scale*vertices [j + 2]);

				if (minX > x) minX = x;
				if (maxX < x) maxX = x;
				if (minY > y) minY = y;
				if (maxY < y) maxY = y;
				if (minZ > z) minZ = z;
				if (maxZ < z) maxZ = z;

				k = uvIndicesByPolygonVertex [i]*2;
				bytes.writeFloat(uvs [k]);
				bytes.writeFloat(1 - uvs [k + 1]);

				k = normalIndicesByPolygonVertex [i]*3;
				bytes.writeFloat(nx = normals [k]);
				bytes.writeFloat(ny = normals [k + 1]);
				bytes.writeFloat(nz = normals [k + 2]);

				j *= 2;
				tx = tangents [j];
				ty = tangents [j + 1];
				tz = tangents [j + 2];

				var dot:Number = tx*nx + ty*ny + tz*nz;
				tx -= nx*dot;
				ty -= ny*dot;
				tz -= nz*dot;
				dot = Math.sqrt(tx*tx + ty*ty + tz*tz + 1e-5);
				tx /= dot;
				ty /= dot;
				tz /= dot;

				bytes.writeFloat(tx);
				bytes.writeFloat(ty);
				bytes.writeFloat(tz);

				cx = ny*tz - nz*ty;
				cy = nz*tx - nx*tz;
				cz = nx*ty - ny*tx;

				dot = cx*tangents [j + 3] + cy*tangents [j + 4] + cz*tangents [j + 5];

				bytes.writeFloat((dot < 0) ? -1 : 1);
			}
			//trace ("bbox:", minX, minY, minZ, maxX, maxY, maxZ);

			return new ConvertVertexBufferResult(a3d.vertexBuffers.push(new A3D2VertexBuffer(Vector.<A3D2VertexAttributes>(
					[
						A3D2VertexAttributes.POSITION, A3D2VertexAttributes.TEXCOORD, A3D2VertexAttributes.NORMAL,
						A3D2VertexAttributes.TANGENT4
					]), bytes, a3d.vertexBuffers.length, bytes.length/bytesPerVertex)) - 1,

					(minX <= maxX) ? a3d.boxes.push(new A3D2Box(Vector.<Number>([minX, minY, minZ, maxX, maxY, maxZ]),
							a3d.boxes.length)) - 1 : -1,

					vmap, pmap, bytesPerVertex, 3*4);
		}

		private function calculateVertexTangents(vertices:Vector.<Number>, uvs:Vector.<Number>,
				polyIndex:Vector.<Number>, uvIndicesByPolygonVertex:Vector.<int>,
				normalIndicesByPolygonVertex:Vector.<int>):Vector.<Number> {

			var tangents:Vector.<Number> = new Vector.<Number>(vertices.length*2);

			var i:int = 0;
			var x0:Number, y0:Number, z0:Number, u0:Number, v0:Number;
			var x1:Number, y1:Number, z1:Number, u1:Number, v1:Number;
			var x2:Number, y2:Number, z2:Number, u2:Number, v2:Number;
			//var vn:Vector3D;
			while (i < polyIndex.length) {
				var a:int = polyIndex [i], a3:int = a*3;
				var b:int = polyIndex [i + 1], b3:int = b*3;
				var c:int = polyIndex [i + 2], c3:int;
				if (c < 0) c = -c - 1;
				c3 = c*3;

				x0 = vertices [a3];
				y0 = vertices [a3 + 1];
				z0 = vertices [a3 + 2];
				x1 = vertices [b3];
				y1 = vertices [b3 + 1];
				z1 = vertices [b3 + 2];
				x2 = vertices [c3];
				y2 = vertices [c3 + 1];
				z2 = vertices [c3 + 2];

				var deltaX1:Number = x1 - x0;
				var deltaY1:Number = y1 - y0;
				var deltaZ1:Number = z1 - z0;
				var deltaX2:Number = x2 - x0;
				var deltaY2:Number = y2 - y0;
				var deltaZ2:Number = z2 - z0;

				a = uvIndicesByPolygonVertex [i]*2;
				b = uvIndicesByPolygonVertex [i + 1]*2;
				c = uvIndicesByPolygonVertex [i + 2]*2;

				u0 = uvs [a];
				v0 = uvs [a + 1];
				u1 = uvs [b];
				v1 = uvs [b + 1];
				u2 = uvs [c];
				v2 = uvs [c + 1];

				var deltaU1:Number = u1 - u0;
				var deltaV1:Number = v0 - v1;
				var deltaU2:Number = u2 - u0;
				var deltaV2:Number = v0 - v2;

				var invdet:Number = 1/(deltaU1*deltaV2 - deltaU2*deltaV1);
				if (invdet > 1e9) invdet = 1e9; else if (invdet < -1e9) invdet = -1e9;

				var stMatrix00:Number = (deltaV2)*invdet;
				var stMatrix01:Number = -(deltaV1)*invdet;
				var stMatrix10:Number = -(deltaU2)*invdet;
				var stMatrix11:Number = (deltaU1)*invdet;

				var tangentX:Number = stMatrix00*deltaX1 + stMatrix01*deltaX2;
				var tangentY:Number = stMatrix00*deltaY1 + stMatrix01*deltaY2;
				var tangentZ:Number = stMatrix00*deltaZ1 + stMatrix01*deltaZ2;

				var biTangentX:Number = stMatrix10*deltaX1 + stMatrix11*deltaX2;
				var biTangentY:Number = stMatrix10*deltaY1 + stMatrix11*deltaY2;
				var biTangentZ:Number = stMatrix10*deltaZ1 + stMatrix11*deltaZ2;

				do {
					c = polyIndex [i++];
					if (c < 0) c = -c - 1;
					c *= 6;
					tangents [c] += tangentX;
					tangents [c + 1] += tangentY;
					tangents [c + 2] += tangentZ;
					tangents [c + 3] += biTangentX;
					tangents [c + 4] += biTangentY;
					tangents [c + 5] += biTangentZ;
				} while (polyIndex [i - 1] >= 0);
			}

			return tangents;
		}

		private function convertUVMappingToByPolygonVertex(mappingInformationType:String,
				referenceInformationType:String, uvIndices:Vector.<Number>, polygonVertexIndex:Vector.<Number>,
				uvs:Vector.<Number>):Vector.<int> {

			var i:int, j:int;
			var n:int = polygonVertexIndex.length;
			var uvIndicesByPolygonVertex:Vector.<int> = new Vector.<int>(n);

			if (referenceInformationType == "Direct") {
				switch (mappingInformationType) {
					case "ByVertice":
						for (i = 0; i < n; i++) {
							j = polygonVertexIndex [i];
							if (j < 0) j = -j - 1;
							uvIndicesByPolygonVertex [i] = j;
						}
						break;
					case "ByPolygonVertex":
						convertByPolygonDataFromDirectToIndex(uvs, uvIndicesByPolygonVertex);
						break;
				}
			} else {
				switch (mappingInformationType) {
					case "ByVertice":
						for (i = 0; i < n; i++) {
							j = polygonVertexIndex [i];
							if (j < 0) j = -j - 1;
							uvIndicesByPolygonVertex [i] = uvIndices [j];
						}
						break;
					case "ByPolygonVertex":
						for (i = 0; i < n; i++) {
							uvIndicesByPolygonVertex [i] = uvIndices [i];
						}
						break;
				}
			}
			return uvIndicesByPolygonVertex;
		}

		private function convertNormalsToByPolygonVertex(mappingInformationType:String, normals:Vector.<Number>,
				polygonVertexIndex:Vector.<Number>):Vector.<int> {

			var i:int, j:int;
			var n:int = polygonVertexIndex.length;
			var normalsByPolygonVertex:Vector.<int> = new Vector.<int>(n);

			// нормали почему-то всегда "Direct" - тут мы строим индексы для иммитации "IndexToDirect"
			switch (mappingInformationType) {
				case "ByVertice":
					for (i = 0; i < n; i++) {
						j = polygonVertexIndex [i];
						if (j < 0) j = -j - 1;
						normalsByPolygonVertex [i] = j;
					}
					break;
				case "ByPolygonVertex":
					convertByPolygonDataFromDirectToIndex(normals, normalsByPolygonVertex);
					break;
			}

			return normalsByPolygonVertex;
		}

		private function convertByPolygonDataFromDirectToIndex(data:Vector.<Number>, /* out */
				indices:Vector.<int>):void {
			var i:int, j:int, k:int, n:int = indices.length, stride:int = data.length/n;
			// тут можно было бы сделать for (i = 0; i < n; i++) indices [i] = i; return;
			// но тогда вершины во всех поликах будут уникальны (клонированы), поэтому придётся
			// искать повторения данных, т.к. все экспортируют в режиме ByPolygonVertex
			var similarDataIndices:Object = new Object();
			for (i = 0; i < n; i++) {
				j = i*stride;
				// тут ожидаются коллизии: данные ЮВ в диапазоне 0..1, нормали -1..1
				// множитель при data [j + k]: больше - память на массивы, меньше - перебор длинных массивов
				var dataHash:int = 0;
				for (k = 0; k < stride; k++) {
					dataHash = 200*dataHash + int(data [j + k]*300);
				}

				if (similarDataIndices [dataHash]) {
					var bucket:Vector.<int> = similarDataIndices [dataHash] as Vector.<int>;
					var miss:Boolean = true;
					for (var p:int = 0, q:int = bucket.length; p < q; p++) {
						var candidate:int = bucket [p];
						var difference:Number, differenceTotal:Number = 0;
						for (k = 0; k < stride; k++) {
							difference = data [j + k] - data [candidate + k];
							if (difference > 0) {
								differenceTotal += difference;
							} else {
								differenceTotal -= difference;
							}
						}
						if (differenceTotal < 1e-4) {
							// нашли повтор
							indices [i] = candidate/stride;
							miss = false;
							break;
						}
					}
					if (miss) {
						indices [i] = i;
						bucket.push(j);
					}
				} else {
					indices [i] = i;
					similarDataIndices [dataHash] = Vector.<int>([j]);
				}
			}
		}

		private function convertMatrix(m:Matrix3D):A3D2Transform {
			return convertMatrixRawData(m.rawData);
		}

		private function convertMatrixRawData(vec:Vector.<Number>):A3D2Transform {
			return new A3D2Transform(new A3DMatrix(vec[0], vec[4], vec[8], vec[12]*scale, vec[1], vec[5], vec[9],
					vec[13]*scale, vec[2], vec[6], vec[10], vec[14]*scale));
		}
	}
}

import alternativa.engine3d.loaders.filmbox.KFbxLayerElementMaterial;
import alternativa.engine3d.loaders.filmbox.KFbxLayerElementTexture;
import alternativa.engine3d.loaders.filmbox.KFbxTexture;
import alternativa.types.Long;

import flash.utils.Dictionary;

import versions.version2.a3d.objects.A3D2JointBindTransform;
import versions.version2.a3d.objects.A3D2Surface;

// 1, IncrementalIDGenerator is Object3D-only :(
class IncrementalIDGenerator2 {

	private var lastID:uint = 0;
	private var objects:Dictionary = new Dictionary(true);

	public function getID(object:Object):Long {
		// 2, return null for null?
		if (object == null) return null;

		var result:Long = this.objects [object];
		if (result == null) {
			result = this.objects [object] = Long.fromInt(this.lastID);
			this.lastID++;
		}
		;
		return result;
	}
}

class MaterialsInfo {
	public var matLayer:KFbxLayerElementMaterial;
	public var texLayers:Vector.<KFbxLayerElementTexture>;
	public var materialHashBase:int;
}

class ConvertVertexBufferResult {
	public var vbufId:int;
	public var bboxId:int;

	/**
	 * for re-mapping skin clusters.
	 * vertexClonesMap [i] = массив индексов вершины и клонов, соответствующих вершине i в mesh.Vertices
	 */
	public var vertexClonesMap:Vector.<Vector.<int>>;

	/**
	 * for re-mapping index buffer.
	 * polygonVerticesMap [i] = индекс вершины (или клона) на позиции i в mesh.PolygonVertexIndex
	 */
	public var polygonVerticesMap:Vector.<int>;

	public var bytesPerVertex:int, uvOffset:int;

	public function ConvertVertexBufferResult(vbufId:int, bboxId:int, vmap:Vector.<Vector.<int>>, pmap:Vector.<int>,
			bpv:int, uvo:int) {
		this.vbufId = vbufId;
		this.bboxId = bboxId;

		this.vertexClonesMap = vmap;
		this.polygonVerticesMap = pmap;
		this.bytesPerVertex = bpv;
		this.uvOffset = uvo
	}
}

class ConvertIndexBufferResult {
	public var ibufId:int;
	public var surfaces:Vector.<A3D2Surface>;
	public var textures:Vector.<KFbxTexture>;

	public function ConvertIndexBufferResult(ibufId:int, surfaces:Vector.<A3D2Surface>, textures:Vector.<KFbxTexture>) {
		this.ibufId = ibufId;
		this.surfaces = surfaces;
		this.textures = textures;
	}
}

class ConvertSkinsResult {
	public var jointBindTransforms:Vector.<A3D2JointBindTransform>;
	public var joints:Vector.<Long>;
	public var numJoints:Vector.<uint>;

	public function ConvertSkinsResult(jointBindTransforms:Vector.<A3D2JointBindTransform>, joints:Vector.<Long>,
			numJoints:Vector.<uint>) {
		this.jointBindTransforms = jointBindTransforms;
		this.joints = joints;
		this.numJoints = numJoints;
	}
}
