/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.animation.keys.Track;
	import alternativa.engine3d.animation.keys.TransformKey;
	import alternativa.engine3d.animation.keys.TransformTrack;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.VertexStream;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.SpotLight;
	import alternativa.engine3d.materials.A3DUtils;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.LOD;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.types.Long;

	import commons.A3DMatrix;
	import commons.Id;

	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	import versions.version1.a3d.A3D;
	import versions.version1.a3d.geometry.A3DGeometry;
	import versions.version1.a3d.geometry.A3DIndexBuffer;
	import versions.version1.a3d.geometry.A3DVertexBuffer;
	import versions.version1.a3d.id.ParentId;
	import versions.version1.a3d.materials.A3DImage;
	import versions.version1.a3d.materials.A3DMap;
	import versions.version1.a3d.materials.A3DMaterial;
	import versions.version1.a3d.objects.A3DBox;
	import versions.version1.a3d.objects.A3DObject;
	import versions.version1.a3d.objects.A3DSurface;
	import versions.version2.a3d.A3D2;
	import versions.version2.a3d.A3D2Extra1;
	import versions.version2.a3d.A3D2Extra2;
	import versions.version2.a3d.animation.A3D2AnimationClip;
	import versions.version2.a3d.animation.A3D2Keyframe;
	import versions.version2.a3d.animation.A3D2Track;
	import versions.version2.a3d.geometry.A3D2IndexBuffer;
	import versions.version2.a3d.geometry.A3D2VertexAttributes;
	import versions.version2.a3d.geometry.A3D2VertexBuffer;
	import versions.version2.a3d.materials.A3D2CubeMap;
	import versions.version2.a3d.materials.A3D2Image;
	import versions.version2.a3d.materials.A3D2Map;
	import versions.version2.a3d.materials.A3D2Material;
	import versions.version2.a3d.objects.A3D2AmbientLight;
	import versions.version2.a3d.objects.A3D2Box;
	import versions.version2.a3d.objects.A3D2DirectionalLight;
	import versions.version2.a3d.objects.A3D2Joint;
	import versions.version2.a3d.objects.A3D2JointBindTransform;
	import versions.version2.a3d.objects.A3D2LOD;
	import versions.version2.a3d.objects.A3D2Layer;
	import versions.version2.a3d.objects.A3D2Mesh;
	import versions.version2.a3d.objects.A3D2Object;
	import versions.version2.a3d.objects.A3D2OmniLight;
	import versions.version2.a3d.objects.A3D2Skin;
	import versions.version2.a3d.objects.A3D2SpotLight;
	import versions.version2.a3d.objects.A3D2Sprite;
	import versions.version2.a3d.objects.A3D2Surface;
	import versions.version2.a3d.objects.A3D2Transform;

	use namespace alternativa3d;

	/**
	 * Base class for classes, that perform parsing of scenes of different formats.
	 */
	public class Parser {

		/**
		 * List of root objects. Root objects are objects, that have no parents.
		 * @see alternativa.engine3d.core.Object3D
		 */
		public var hierarchy:Vector.<Object3D>;
		/**
		 * List of objects, that are got after parsing.
		 * @see alternativa.engine3d.core.Object3D
		 */
		public var objects:Vector.<Object3D>;

		/**
		 * Array of animations.
		 */
		public var animations:Vector.<AnimationClip>;

		/**
		 * List of all materials assigned to objects, that are got after parsing.
		 * @see alternativa.engine3d.loaders.ParserMaterial
		 */
		public var materials:Vector.<ParserMaterial>;

		private var maps:Dictionary;

		private var cubemaps:Dictionary;

		/**
		 * @private
		 */
		alternativa3d var layersMap:Dictionary;
        /**
         * @private
         */
		alternativa3d var layers:Vector.<String>;
        /**
         * @private
         */
		alternativa3d var compressedBuffers:Boolean = false;

		private var parsedMaterials:Dictionary;
		private var parsedGeometries:Object;
		private var unpackedBuffers:Dictionary;

		/**
		 * Returns object from array <code>objects</code> by name.
		 */
		public function getObjectByName(name:String):Object3D {
			for each (var object:Object3D in objects) {
				if (object.name == name) return object;
			}
			return null;
		}

		/**
		 * Returns name of layer for specified object.
		 */
		public function getLayerByObject(object:Object3D):String {
			return layersMap[object];
		}

		/**
		 * Erases all links to external objects.
		 */
		public function clean():void {
			hierarchy = null;
			objects = null;
			materials = null;
			animations = null;
			layersMap = null;
			objectsMap = null;
			a3DBoxes = null;
			parents = null;
			layers = null;
		}

		/**
		 * @private
		 */
		alternativa3d function init():void {
			hierarchy = new Vector.<Object3D>();
			objects = new Vector.<Object3D>();
			materials = new Vector.<ParserMaterial>();
			animations = new Vector.<AnimationClip>();
			layersMap = new Dictionary(true);
			layers = new Vector.<String>();
		}

		protected function complete(a3d:Object):void {
			init();
			if (a3d is A3D) {
				doParse2_0(convert1_2(A3D(a3d)));
			} else if (a3d is A3D2) {
				doParse2_0(A3D2(a3d));
			} else if (a3d is Vector.<Object>) {
				var vec:Vector.<Object> = a3d as Vector.<Object>;
				var len:int = vec.length;
				for (var i:int = 0; i < len; i++) {
					doParsePart(vec[i]);
				}
			}
			completeHierarchy();
		}

		private function doParsePart(a3d:Object):void {
			if (a3d is A3D) {
				doParse2_0(convert1_2(A3D(a3d)));
			} else if (a3d is A3D2) {
				doParse2_0(A3D2(a3d));
			} else if (a3d is A3D2Extra1) {
				doParseExtra1(A3D2Extra1(a3d));
			} else if (a3d is A3D2Extra2) {
				doParseExtra2(A3D2Extra2(a3d));
			}
		}

		private function doParseExtra1(a3d:A3D2Extra1):void {
			var layersVec:Vector.<A3D2Layer> = a3d.layers;
			for each (var layer:A3D2Layer in layersVec) {
				var layerName:String = (layer.name == null || layer.name.length == 0) ? "default" : layer.name;
				layers.push(layerName);
				for each (var id:Long in layer.objects) {
					if (objectsMap[id] != null) {
						layersMap[objectsMap[id]] = layerName;
					}
				}
			}
		}

		private function doParseExtra2(a3d:A3D2Extra2):void {
			var lodsVec:Vector.<A3D2LOD> = a3d.lods;
			for each (var lod:A3D2LOD in lodsVec) {
				var resObject:LOD = new LOD();
				resObject.visible = lod.visible;
				resObject.name = lod.name;
				parents[resObject] = lod.parentId;
				objectsMap[lod.id] = resObject;
				var length:uint = lod.objects.length;
				for (var i:int = 0; i < length; i++) {
					resObject.addLevel(objectsMap[lod.objects[i]], lod.distances[i]);
				}
				decomposeTransformation(lod.transform, resObject);

			}
		}

		private var objectsMap:Dictionary;

		private var parents:Dictionary = new Dictionary();

		private var a3DBoxes:Dictionary = new Dictionary();

		private function doParse2_0(a3d:A3D2):void {
			maps = new Dictionary();
			cubemaps = new Dictionary();
			parsedMaterials = new Dictionary();
			parsedGeometries = new Dictionary();
			unpackedBuffers = new Dictionary();
			objectsMap = new Dictionary();
			parents = new Dictionary();
			a3DBoxes = new Dictionary();


			var parsedTracks:Dictionary = new Dictionary();
			var a3DIndexBuffers:Dictionary = new Dictionary();
			var a3DVertexBuffers:Dictionary = new Dictionary();
			var a3DMaterials:Dictionary = new Dictionary();
			var a3DMaps:Dictionary = new Dictionary();
			var a3DImages:Dictionary = new Dictionary();
			var a3DCubeMaps:Dictionary = new Dictionary();
			var a3DObject:A3D2Object;
			var a3DMesh:A3D2Mesh;

			var a3DIndexBuffer:A3D2IndexBuffer;
			var a3DVertexBuffer:A3D2VertexBuffer;
			var a3DMaterial:A3D2Material;
			var a3DBox:A3D2Box;
			var a3DMap:A3D2Map;
			var a3DImage:A3D2Image;
			var a3DAmbientLight:A3D2AmbientLight;
			var a3DOmniLight:A3D2OmniLight;
			var a3DSpotLight:A3D2SpotLight;
			var a3DDirLight:A3D2DirectionalLight;
			var a3DSkin:A3D2Skin;
			var a3DJoint:A3D2Joint;
			var a3DSprite:A3D2Sprite;
			var a3DCubeMap:A3D2CubeMap;

			for each(a3DIndexBuffer in a3d.indexBuffers) {
				a3DIndexBuffers[a3DIndexBuffer.id] = a3DIndexBuffer;
			}
			for each (var a3DTrack:A3D2Track in a3d.animationTracks) {
				var resTrack:TransformTrack = new TransformTrack(a3DTrack.objectName);
				for each (var a3DKeyFrame:A3D2Keyframe in a3DTrack.keyframes) {
					var tFrame:TransformKey = new TransformKey();
					tFrame._time = a3DKeyFrame.time;

					var components:Vector.<Vector3D> = getMatrix3D(a3DKeyFrame.transform).decompose(Orientation3D.QUATERNION);

					tFrame.x = components[0].x;
					tFrame.y = components[0].y;
					tFrame.z = components[0].z;
					tFrame.rotation = components[1];
					tFrame.scaleX = components[2].x;
					tFrame.scaleY = components[2].y;
					tFrame.scaleZ = components[2].z;
					resTrack.addKeyToList(tFrame);
				}
				parsedTracks[a3DTrack.id] = resTrack;
			}

			var animationClip:AnimationClip;

			// Animation parsing
			if (a3d.animationTracks != null && a3d.animationTracks.length > 0) {
				if (a3d.animationClips == null || a3d.animationClips.length == 0) {
					animationClip = new AnimationClip();
					for each (resTrack in parsedTracks) {
						animationClip.addTrack(resTrack);
					}
					animations.push(animationClip);
				} else {
					for each (var a3DAnim:A3D2AnimationClip in a3d.animationClips) {
						animationClip = new AnimationClip(a3DAnim.name);
						animationClip.loop = a3DAnim.loop;
						for each (var trackID:int in a3DAnim.tracks) {
							var track:Track = parsedTracks[trackID];
							if (track != null) {
								animationClip.addTrack(track);
							}
						}
						animations.push(animationClip);
					}
				}
			}


			for each (a3DVertexBuffer in a3d.vertexBuffers) {
				a3DVertexBuffers[a3DVertexBuffer.id] = a3DVertexBuffer;
			}

			for each (a3DBox in a3d.boxes) {
				a3DBoxes[a3DBox.id] = a3DBox;
			}

			for each (a3DMaterial in a3d.materials) {
				a3DMaterials[a3DMaterial.id] = a3DMaterial;
			}

			for each (a3DMap in a3d.maps) {
				a3DMaps[a3DMap.id] = a3DMap;
			}

			for each (a3DCubeMap in a3d.cubeMaps) {
				a3DCubeMaps[a3DCubeMap.id] = a3DCubeMap;
			}


			for each (a3DImage in a3d.images) {
				a3DImages[a3DImage.id] = a3DImage;
			}
			var jointsMap:Dictionary = new Dictionary();

			for each (a3DJoint in a3d.joints) {
				var resJoint:Joint = new Joint();
				resJoint.visible = a3DJoint.visible;
				resJoint.name = a3DJoint.name;
				parents[resJoint] = a3DJoint.parentId;
				jointsMap[a3DJoint.id] = resJoint;
				decomposeTransformation(a3DJoint.transform, resJoint);
				a3DBox = a3DBoxes[a3DJoint.boundBoxId];
				if (a3DBox != null) {
					parseBoundBox(a3DBox.box, resJoint);
				}
			}

			for each (a3DObject in a3d.objects) {
				var resObject:Object3D = new Object3D();
				resObject.visible = a3DObject.visible;
				resObject.name = a3DObject.name;
				parents[resObject] = a3DObject.parentId;
				objectsMap[a3DObject.id] = resObject;
				jointsMap[a3DObject.id] = resObject;
				decomposeTransformation(a3DObject.transform, resObject);

				a3DBox = a3DBoxes[a3DObject.boundBoxId];
				if (a3DBox != null) {
					parseBoundBox(a3DBox.box, resObject);
				}

			}

			for each (a3DSprite in a3d.sprites) {
				var resSprite:Sprite3D = new Sprite3D(a3DSprite.width, a3DSprite.height);
				resSprite.material = parseMaterial(a3DMaterials[a3DSprite.materialId], a3DMaps, a3DCubeMaps, a3DImages);
				resSprite.originX = a3DSprite.originX;
				resSprite.originY = a3DSprite.originY;
				resSprite.perspectiveScale = a3DSprite.perspectiveScale;
				resSprite.alwaysOnTop = a3DSprite.alwaysOnTop;
				resSprite.rotation = a3DSprite.rotation;
				objectsMap[a3DSprite.id] = resSprite;
				decomposeTransformation(a3DSprite.transform, resSprite);
			}

			for each (a3DSkin in a3d.skins) {
				var resSkin:Mesh = parseSkin(a3DSkin, jointsMap, parents, a3DIndexBuffers, a3DVertexBuffers, a3DMaterials, a3DMaps, a3DCubeMaps, a3DImages);
				resSkin.visible = a3DSkin.visible;
				resSkin.name = a3DSkin.name;
				objectsMap[a3DSkin.id] = resSkin;
				//The transformation should not affect skin (Due collada comatibility)
				//decomposeTransformation(a3DSkin.transform, resSkin);
				a3DBox = a3DBoxes[a3DSkin.boundBoxId];
				if (a3DBox != null) {
					parseBoundBox(a3DBox.box, resSkin);
				}
			}

			for each (a3DAmbientLight in a3d.ambientLights) {
				var resAmbientLight:AmbientLight = new AmbientLight(a3DAmbientLight.color);
				resAmbientLight.intensity = a3DAmbientLight.intensity;
				resAmbientLight.visible = a3DAmbientLight.visible;
				resAmbientLight.name = a3DAmbientLight.name;
				parents[resAmbientLight] = a3DAmbientLight.parentId;
				objectsMap[a3DAmbientLight.id] = resAmbientLight;
				decomposeTransformation(a3DAmbientLight.transform, resAmbientLight);
				a3DBox = a3DBoxes[a3DAmbientLight.boundBoxId];
				if (a3DBox != null) {
					parseBoundBox(a3DBox.box, resAmbientLight);
				}
			}

			for each (a3DOmniLight in a3d.omniLights) {
				var resOmniLight:OmniLight = new OmniLight(a3DOmniLight.color, a3DOmniLight.attenuationBegin, a3DOmniLight.attenuationEnd);
				resOmniLight.intensity = a3DOmniLight.intensity;
				resOmniLight.visible = a3DOmniLight.visible;
				resOmniLight.name = a3DOmniLight.name;
				parents[resOmniLight] = a3DOmniLight.parentId;
				objectsMap[a3DOmniLight.id] = resOmniLight;
				decomposeTransformation(a3DOmniLight.transform, resOmniLight);
			}

			for each (a3DSpotLight in a3d.spotLights) {
				var resSpotLight:SpotLight = new SpotLight(a3DSpotLight.color, a3DSpotLight.attenuationBegin, a3DSpotLight.attenuationEnd, a3DSpotLight.hotspot, a3DSpotLight.falloff);
				resSpotLight.intensity = a3DSpotLight.intensity;
				resSpotLight.visible = a3DSpotLight.visible;
				resSpotLight.name = a3DSpotLight.name;
				parents[resSpotLight] = a3DSpotLight.parentId;
				objectsMap[a3DSpotLight.id] = resSpotLight;
				decomposeTransformation(a3DSpotLight.transform, resSpotLight);
			}

			for each(a3DDirLight in a3d.directionalLights) {
				var resDirLight:DirectionalLight = new DirectionalLight(a3DDirLight.color);
				resDirLight.visible = a3DDirLight.visible;
				resDirLight.name = a3DDirLight.name;
				parents[resDirLight] = a3DDirLight.parentId;
				objectsMap[a3DDirLight.id] = resDirLight;
				decomposeTransformation(a3DDirLight.transform, resDirLight);
			}

			for each (a3DMesh in a3d.meshes) {
				var resMesh:Mesh = parseMesh(a3DMesh, a3DIndexBuffers, a3DVertexBuffers, a3DMaterials, a3DMaps, a3DCubeMaps, a3DImages);
				resMesh.visible = a3DMesh.visible;
				resMesh.name = a3DMesh.name;
				parents[resMesh] = a3DMesh.parentId;
				objectsMap[a3DMesh.id] = resMesh;
				decomposeTransformation(a3DMesh.transform, resMesh);
				a3DBox = a3DBoxes[a3DMesh.boundBoxId];
				if (a3DBox != null) {
					parseBoundBox(a3DBox.box, resMesh);
				}
			}
			maps = null;
			parsedMaterials = null;
			parsedGeometries = null;
		}

		private function completeHierarchy():void {
			var parent:Long;
			var p:Object3D;
			var object:Object3D;
			for each (object in objectsMap) {
				objects.push(object);
				if (object.parent != null) continue;
				parent = parents[object];
				if (parent != null) {
					p = objectsMap[parent];
					if (p != null) {
						p.addChild(object);
					} else {
						hierarchy.push(object);
					}
				} else {
					hierarchy.push(object);
				}
			}
		}

		private function parseBoundBox(box:Vector.<Number>, destination:Object3D):void {
			destination.boundBox = new BoundBox();
			destination.boundBox.minX = box[0];
			destination.boundBox.minY = box[1];
			destination.boundBox.minZ = box[2];
			destination.boundBox.maxX = box[3];
			destination.boundBox.maxY = box[4];
			destination.boundBox.maxZ = box[5];
		}

		private final function unpackVertexBuffer(buffer:ByteArray):void {
			var tempBuffer:ByteArray = new ByteArray();
			tempBuffer.endian = Endian.LITTLE_ENDIAN;
			buffer.position = 0;
			while (buffer.bytesAvailable > 0) {
				var data:uint = buffer.readUnsignedShort();
				var vi:uint = data;
				vi &= 0x7FFF;
				vi ^= (vi + 0x1c000) ^ vi;
				vi = vi << 13;
				tempBuffer.writeUnsignedInt(data > 0x8000 ? vi | 0x80000000 : vi);
			}
			buffer.position = 0;
			buffer.writeBytes(tempBuffer);

		}

		private function getMatrix3D(transform:A3D2Transform):Matrix3D {
			if (transform == null) return null;
			var matrix:A3DMatrix = transform.matrix;
			return new Matrix3D(Vector.<Number>(
					[matrix.a, matrix.e, matrix.i, 0,
						matrix.b, matrix.f, matrix.j, 0,
						matrix.c, matrix.g, matrix.k, 0,
						matrix.d, matrix.h, matrix.l, 1
					]));
		}

		private function decomposeTransformation(transform:A3D2Transform, obj:Object3D):void {
			if (transform == null) return;
			var mat:Matrix3D = getMatrix3D(transform);
			var vecs:Vector.<Vector3D> = mat.decompose();
			obj.x = vecs[0].x;
			obj.y = vecs[0].y;
			obj.z = vecs[0].z;
			obj.rotationX = vecs[1].x;
			obj.rotationY = vecs[1].y;
			obj.rotationZ = vecs[1].z;
			obj.scaleX = vecs[2].x;
			obj.scaleY = vecs[2].y;
			obj.scaleZ = vecs[2].z;
		}

		private function decomposeBindTransformation(transform:A3D2Transform, obj:Joint):void {
			if (transform == null) return;
			var matrix:A3DMatrix = transform.matrix;
			var mat:Vector.<Number> = Vector.<Number>([
				matrix.a, matrix.b, matrix.c, matrix.d,
				matrix.e, matrix.f, matrix.g, matrix.h,
				matrix.i, matrix.j, matrix.k, matrix.l]
			);

			obj.setBindPoseMatrix(mat);
		}

		private function parseMesh(a3DMesh:A3D2Mesh, indexBuffers:Dictionary, vertexBuffers:Dictionary, materials:Dictionary, a3DMaps:Dictionary, a3DCubeMaps:Dictionary, images:Dictionary):Mesh {
			var res:Mesh = new Mesh();
			res.geometry = parseGeometry(a3DMesh.indexBufferId, a3DMesh.vertexBuffers, indexBuffers, vertexBuffers);
			var surfaces:Vector.<A3D2Surface> = a3DMesh.surfaces;
			for (var i:int = 0; i < surfaces.length; i++) {
				var s:A3D2Surface = surfaces[i];
				var m:ParserMaterial = parseMaterial(materials[s.materialId], a3DMaps, a3DCubeMaps, images);
				res.addSurface(m, s.indexBegin, s.numTriangles);
			}
			return res;
		}

		private function parseSkin(a3DSkin:A3D2Skin, jointsMap:Dictionary, parents:Dictionary, indexBuffers:Dictionary, vertexBuffers:Dictionary, materials:Dictionary, a3DMaps:Dictionary, a3DCubeMaps:Dictionary, images:Dictionary):Skin {
			var geometry:Geometry = parseGeometry(a3DSkin.indexBufferId, a3DSkin.vertexBuffers, indexBuffers, vertexBuffers);
			var res:Skin = new Skin(getNumInfluences(geometry));
			res.geometry = geometry;
			var surfaces:Vector.<A3D2Surface> = a3DSkin.surfaces;
			for (var i:int = 0; i < surfaces.length; i++) {
				var s:A3D2Surface = surfaces[i];
				var m:ParserMaterial = parseMaterial(materials[s.materialId], a3DMaps, a3DCubeMaps, images);
				res.addSurface(m, s.indexBegin, s.numTriangles);
			}
			copyBones(res, a3DSkin, jointsMap, parents);
			return res;
		}

		private function copyBones(skin:Skin, a3DSkin:A3D2Skin, jointsMap:Dictionary, parents:Dictionary):void {
			var rootBones:Vector.<Joint> = new Vector.<Joint>();
			var s2dMap:Dictionary = new Dictionary();
			var sourceJoints:Dictionary = new Dictionary();
			var jointIDs:Dictionary = new Dictionary();
			var joint:Joint;
			var object:Object3D;
			var indexOffset:uint = 0;
			var dJoint:Joint;
			for each (var numJoints:uint in a3DSkin.numJoints) {
				for (var i:int = 0; i < numJoints; i++) {
					var key:Long = a3DSkin.joints[int(indexOffset + i)];
					object = jointsMap[key];
					sourceJoints[key] = object;
					jointIDs[object] = key;
				}
				indexOffset += numJoints;
			}

			for (var idk:* in sourceJoints) {
				object = sourceJoints[idk];
				if (object == null) {
					throw new Error("Joint for skin " + a3DSkin.name + " not found");
				}
				delete objectsMap[idk];
				s2dMap[object] = cloneJoint(object);
			}
			var count:int;
			indexOffset = 0;
			for (i = 0, count = a3DSkin.numJoints.length; i < count; i++) {
				numJoints = a3DSkin.numJoints[i];
				skin.surfaceJoints[i] = new Vector.<Joint>();
				for (var j:int = 0; j < numJoints; j++) {
					skin.surfaceJoints[i].push(s2dMap[sourceJoints[a3DSkin.joints[int(indexOffset + j)]]]);
				}
				indexOffset += numJoints;
			}
			skin.calculateSurfacesProcedures();

			for (i = 0; i < a3DSkin.jointBindTransforms.length; i++) {
				var bindPose:A3D2JointBindTransform = a3DSkin.jointBindTransforms[i];
				//Joint is not affect to vertices, but affect on transformation of other joints (due to hierarchy).
				if (sourceJoints[bindPose.id] == null) {
					object = jointsMap[bindPose.id];
					sourceJoints[bindPose.id] = object;
					s2dMap[object] = cloneJoint(object);
				}
				decomposeBindTransformation(bindPose.bindPoseTransform, Joint(s2dMap[sourceJoints[bindPose.id]]));
			}
			var skinParent:Long = null;
			for each(object in sourceJoints) {
				dJoint = s2dMap[object];
				var parent:Long = parents[object];
				if (isRootJointNode(object, parents, sourceJoints, jointsMap)) {
					skinParent = parent;
					rootBones.push(dJoint);
				} else {
					var pJointSource:Object3D = jointsMap[parent];
					var pJoint:Joint = s2dMap[pJointSource];
					if (pJoint == null) {
						attachJoint(dJoint, object, parents, jointsMap, s2dMap);
					} else {
						pJoint.addChild(dJoint);
					}
				}
			}
			if (skinParent != null) {
				parents[skin] = skinParent;
			}

			skin._renderedJoints = new Vector.<Joint>();
			for (i = 0; i < numJoints; i++) {
				skin._renderedJoints.push(s2dMap[sourceJoints[a3DSkin.joints[i]]]);
			}

			for each(joint in rootBones) {
				skin.addChild(joint);
			}
		}

		private function attachJoint(joint:Joint, source:Object3D, parents:Dictionary, sourceJoints:Dictionary, s2dMap:Dictionary):void {
			var parentID:Long = parents[source];
			var parentSource:Object3D = sourceJoints[parentID];
			var parentDestination:Joint = s2dMap[parentSource];
			if (parentDestination == null) {
				s2dMap[parentSource] = parentDestination = cloneJoint(parentSource);
				delete objectsMap[parentID];
				attachJoint(parentDestination, parentSource, parents, sourceJoints, s2dMap);
			}
			parentDestination.addChild(joint);
		}

		private function isRootJointNode(joint:Object3D, parents:Dictionary, joints:Dictionary, jointsMap:Dictionary):Boolean {
			var parent:Long = parents[joint];
			while (parent != null) {
				var current:Object3D = jointsMap[parent];
				if (joints[parent] != null) {
					return false;
				}
				parent = parents[current];
			}

			return true;
		}

		private function cloneJoint(source:Object3D):Joint {
			var result:Joint = new Joint();
			result.name = source.name;
			result.visible = source.visible;
			result.boundBox = source.boundBox ? source.boundBox.clone() : null;
			result._x = source._x;
			result._y = source._y;
			result._z = source._z;
			result._rotationX = source._rotationX;
			result._rotationY = source._rotationY;
			result._rotationZ = source._rotationZ;
			result._scaleX = source._scaleX;
			result._scaleY = source._scaleY;
			result._scaleZ = source._scaleZ;
			result.composeTransforms();
			return result;
		}

		private function getNumInfluences(geometry:Geometry):uint {
			var result:uint = 0;
			for (var i:int = 0, count:int = VertexAttributes.JOINTS.length; i < count; i++) {
				if (geometry.hasAttribute(VertexAttributes.JOINTS[i])) {
					result += 2;
				}
			}
			return result;
		}

		private function parseGeometry(indexBufferID:int, vertexBuffersIDs:Vector.<int>, indexBuffers:Dictionary, vertexBuffers:Dictionary):Geometry {
			var key:String = "i" + indexBufferID.toString();
			for each(var id:int in vertexBuffersIDs) {
				key += "v" + id.toString();
			}
			var geometry:Geometry = parsedGeometries[key];
			if (geometry != null) return geometry;
			geometry = new Geometry();
			var a3dIB:A3D2IndexBuffer = indexBuffers[indexBufferID];

			var indices:Vector.<uint> = A3DUtils.byteArrayToVectorUint(a3dIB.byteBuffer);
			var uvoffset:int = 0;
			geometry._indices = indices;
			var buffers:Vector.<int> = vertexBuffersIDs;
			var vertexCount:uint;
			for (var j:int = 0; j < buffers.length; j++) {
				var buffer:A3D2VertexBuffer = vertexBuffers[buffers[j]];
				if (compressedBuffers) {
					if (unpackedBuffers[buffer] == null) {
						unpackVertexBuffer(buffer.byteBuffer);
						unpackedBuffers[buffer] = true;
					}
				}

				vertexCount = buffer.vertexCount;
				var byteArray:ByteArray = buffer.byteBuffer;
				byteArray.endian = Endian.LITTLE_ENDIAN;
				var offset:int = 0;
				var attributes:Array = [];
				var jointsOffset:int = 0;
				for (var k:int = 0; k < buffer.attributes.length; k++) {
					var attr:int;
					switch (buffer.attributes[k]) {
						case A3D2VertexAttributes.POSITION:
							attr = VertexAttributes.POSITION;
							break;
						case A3D2VertexAttributes.NORMAL:
							attr = VertexAttributes.NORMAL;
							break;
						case A3D2VertexAttributes.TANGENT4:
							attr = VertexAttributes.TANGENT4;
							break;
						case A3D2VertexAttributes.TEXCOORD:
							attr = VertexAttributes.TEXCOORDS[uvoffset];
							uvoffset++;
							break;
						case A3D2VertexAttributes.JOINT:
							attr = VertexAttributes.JOINTS[jointsOffset];
							jointsOffset++;
							break;
					}
					var numFloats:int = VertexAttributes.getAttributeStride(attr);
					numFloats = (numFloats < 1) ? 1 : numFloats;
					for (var t:int = 0; t < numFloats; t++) {
						attributes[offset] = attr;
						offset++;
					}
				}
				geometry.addVertexStream(attributes);
				geometry._vertexStreams[0].data = byteArray;
			}
			geometry._numVertices = (buffers.length > 0) ? vertexCount : 0;
			parsedGeometries[key] = geometry;

			return geometry;
		}

		private function parseMap(source:A3D2Map, images:Dictionary):ExternalTextureResource {
			if (source == null) return null;
			var res:ExternalTextureResource = maps[source.imageId];
			if (res != null) return res;
			res = maps[source.imageId] = new ExternalTextureResource(images[source.imageId].url);
			return res;
		}

		private function parseCubeMap(source:A3D2CubeMap, images:Dictionary):ExternalTextureResource {
			return null;
		}

		private function parseMaterial(source:A3D2Material, a3DMaps:Dictionary, a3DCubeMaps:Dictionary, images:Dictionary):ParserMaterial {
			if (source == null) return null;
			var res:ParserMaterial = parsedMaterials[source.id];
			if (res != null) return res;

			res = parsedMaterials[source.id] = new ParserMaterial();
			res.textures["diffuse"] = parseMap(a3DMaps[source.diffuseMapId], images);
			res.textures["emission"] = parseMap(a3DMaps[source.lightMapId], images);
			res.textures["bump"] = parseMap(a3DMaps[source.normalMapId], images);
			res.textures["specular"] = parseMap(a3DMaps[source.specularMapId], images);
			res.textures["glossiness"] = parseMap(a3DMaps[source.glossinessMapId], images);
			res.textures["transparent"] = parseMap(a3DMaps[source.opacityMapId], images);
			res.textures["reflection"] = parseCubeMap(a3DCubeMaps[source.reflectionCubeMapId], images);
			materials.push(res);
			return res;
		}

		private static function convert1_2(source:A3D):A3D2 {
			// source.boxes
			var sourceBoxes:Vector.<A3DBox> = source.boxes;
			var destBoxes:Vector.<A3D2Box> = null;
			if (sourceBoxes != null) {
				destBoxes = new Vector.<A3D2Box>();
				for (var i:int = 0, count:int = sourceBoxes.length; i < count; i++) {
					var sourceBox:A3DBox = sourceBoxes[i];
					var destBox:A3D2Box = new A3D2Box(sourceBox.box, sourceBox.id.id);
					destBoxes[i] = destBox;
				}
			}

			// source.geometries
			var sourceGeometries:Dictionary = new Dictionary();
			if (source.geometries != null) {
				for each(var sourceGeometry:A3DGeometry in source.geometries) {
					sourceGeometries[sourceGeometry.id.id] = sourceGeometry;
				}
			}

			// source.images
			var sourceImages:Vector.<A3DImage> = source.images;
			var destImages:Vector.<A3D2Image> = null;
			if (sourceImages != null) {
				destImages = new Vector.<A3D2Image>();
				for (i = 0, count = sourceImages.length; i < count; i++) {
					var sourceImage:A3DImage = sourceImages[i];
					var destImage:A3D2Image = new A3D2Image(sourceImage.id.id, sourceImage.url);
					destImages[i] = destImage;
				}
			}

			// source.maps
			var sourceMaps:Vector.<A3DMap> = source.maps;
			var destMaps:Vector.<A3D2Map> = null;
			if (sourceMaps != null) {
				destMaps = new Vector.<A3D2Map>();
				for (i = 0, count = sourceMaps.length; i < count; i++) {
					var sourceMap:A3DMap = sourceMaps[i];
					var destMap:A3D2Map = new A3D2Map(sourceMap.channel, sourceMap.id.id, sourceMap.imageId.id);
					destMaps[i] = destMap;
				}
			}

			// source.materials
			var sourceMaterials:Vector.<A3DMaterial> = source.materials;
			var destMaterials:Vector.<A3D2Material> = null;
			if (sourceMaterials != null) {
				destMaterials = new Vector.<A3D2Material>();
				for (i = 0, count = sourceMaterials.length; i < count; i++) {
					var sourceMaterial:A3DMaterial = sourceMaterials[i];
					var destMaterial:A3D2Material =
							new A3D2Material(
									idToInt(sourceMaterial.diffuseMapId),
									idToInt(sourceMaterial.glossinessMapId),
									idToInt(sourceMaterial.id),
									idToInt(sourceMaterial.lightMapId),
									idToInt(sourceMaterial.normalMapId),
									idToInt(sourceMaterial.opacityMapId),
									-1,
									idToInt(sourceMaterial.specularMapId)
							);
					destMaterials[i] = destMaterial;
				}
			}

			// source.objects
			var sourceObjects:Vector.<A3DObject> = source.objects;
			var destObjects:Vector.<A3D2Object> = null;
			var destMeshes:Vector.<A3D2Mesh> = null;
			var destVertexBuffers:Vector.<A3D2VertexBuffer> = null;
			var destIndexBuffers:Vector.<A3D2IndexBuffer> = null;
			var lastIndexBufferIndex:uint = 0;
			var lastVertexBufferIndex:uint = 0;
			var objectsMap:Dictionary = new Dictionary();
			if (sourceObjects != null) {
				destMeshes = new Vector.<A3D2Mesh>();
				destObjects = new Vector.<A3D2Object>();
				destVertexBuffers = new Vector.<A3D2VertexBuffer>();
				destIndexBuffers = new Vector.<A3D2IndexBuffer>();
				for (i = 0, count = sourceObjects.length; i < count; i++) {
					var sourceObject:A3DObject = sourceObjects[i];
					if (sourceObject.surfaces != null && sourceObject.surfaces.length > 0) {
						var destMesh:A3D2Mesh = null;
						sourceGeometry = sourceGeometries[sourceObject.geometryId.id];
						var destIndexBufferId:int = -1;
						var destVertexBuffersIds:Vector.<int> = new Vector.<int>();
						if (sourceGeometry != null) {

							var sourceIndexBuffer:A3DIndexBuffer = sourceGeometry.indexBuffer;
							var sourceVertexBuffers:Vector.<A3DVertexBuffer> = sourceGeometry.vertexBuffers;
							var destIndexBuffer:A3D2IndexBuffer = new A3D2IndexBuffer(sourceIndexBuffer.byteBuffer, lastIndexBufferIndex++, sourceIndexBuffer.indexCount);
							destIndexBufferId = destIndexBuffer.id;
							destIndexBuffers.push(destIndexBuffer);
							for (var j:int = 0, inCount:int = sourceVertexBuffers.length; j < inCount; j++) {
								var sourceVertexBuffer:A3DVertexBuffer = sourceVertexBuffers[j];
								var sourceAttributes:Vector.<int> = sourceVertexBuffer.attributes;
								var destAttributes:Vector.<A3D2VertexAttributes> = new Vector.<A3D2VertexAttributes>();
								for (var k:int = 0, kCount:int = sourceAttributes.length; k < kCount; k++) {
									var attr:int = sourceAttributes[k];

									switch (attr) {
										case 0:
											destAttributes[k] = A3D2VertexAttributes.POSITION;
											break;
										case 1:
											destAttributes[k] = A3D2VertexAttributes.NORMAL;
											break;
										case 2:
											destAttributes[k] = A3D2VertexAttributes.TANGENT4;
											break;
										case 3:
											break;
										case 4:
											break;
										case 5:
											destAttributes[k] = A3D2VertexAttributes.TEXCOORD;
											break;
									}
								}
								var destVertexBuffer:A3D2VertexBuffer =
										new A3D2VertexBuffer(
												destAttributes,
												sourceVertexBuffer.byteBuffer,
												lastVertexBufferIndex++,
												sourceVertexBuffer.vertexCount
										);
								destVertexBuffers.push(destVertexBuffer);
								destVertexBuffersIds.push(destVertexBuffer.id);
							}
						}
						destMesh = new A3D2Mesh(
								idToInt(sourceObject.boundBoxId),
								idToLong(sourceObject.id),
								destIndexBufferId,
								sourceObject.name,
								convertParent1_2(sourceObject.parentId),
								convertSurfaces1_2(sourceObject.surfaces),
								new A3D2Transform(sourceObject.transformation.matrix),
								destVertexBuffersIds,
								sourceObject.visible
						);
						destMeshes.push(destMesh);
						objectsMap[sourceObject.id.id] = destMesh;
					} else {
						var destObject:A3D2Object = new A3D2Object(
								idToInt(sourceObject.boundBoxId),
								idToLong(sourceObject.id),
								sourceObject.name,
								convertParent1_2(sourceObject.parentId),
								new A3D2Transform(sourceObject.transformation.matrix),
								sourceObject.visible
						);
						destObjects.push(destObject);
						objectsMap[sourceObject.id.id] = destObject;
					}
				}
			}

			var result:A3D2 = new A3D2(
					null, null, null, destBoxes, null, null, null, destImages, destIndexBuffers, null,
					destMaps, destMaterials,
					destMeshes != null && destMeshes.length > 0 ? destMeshes : null,
					destObjects != null && destObjects.length > 0 ? destObjects : null,
					null, null, null, null, destVertexBuffers
			);
			return result;
		}

		private static function idToInt(id:Id):int {
			return id != null ? id.id : -1;
		}

		private static function idToLong(id:Id):Long {
			return id != null ? Long.fromInt(id.id) : Long.fromInt(-1);
		}

		private static function convertParent1_2(parentId:ParentId):Long {
			if (parentId == null) return null;
			return parentId != null ? Long.fromInt(parentId.id) : null;
		}

		private static function convertSurfaces1_2(source:Vector.<A3DSurface>):Vector.<A3D2Surface> {
			var dest:Vector.<A3D2Surface> = new Vector.<A3D2Surface>();
			for (var i:int = 0, count:int = source.length; i < count; i++) {
				var sourceSurface:A3DSurface = source[i];
				var destSurface:A3D2Surface = new A3D2Surface(
						sourceSurface.indexBegin,
						idToInt(sourceSurface.materialId),
						sourceSurface.numTriangles);
				dest[i] = destSurface;
			}
			return dest;
		}
        /**
         * @private
         */
		alternativa3d static function traceGeometry(geometry:Geometry):void {
			var vertexStream:VertexStream = geometry._vertexStreams[0];
			var prev:int = -1;

			var attribtuesLength:int = vertexStream.attributes.length;
			var stride:int = attribtuesLength*4;
			var length:int = vertexStream.data.length/stride;
			var data:ByteArray = vertexStream.data;

			for (var j:int = 0; j < length; j++) {
				var traceString:String = "V" + j + " ";
				var offset:int = -4;
				for (var i:int = 0; i < attribtuesLength; i++) {
					var attr:int = vertexStream.attributes[i];
					var x:Number, y:Number, z:Number;
					if (attr == prev) continue;
					offset = geometry.getAttributeOffset(attr)*4;
					switch (attr) {
						case VertexAttributes.POSITION:
							data.position = j*stride + offset;
							traceString += "P[" + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(2) + "] ";
							break;
						case 20:
							data.position = j*stride + offset;
							traceString += "A[" + data.readFloat().toString(2) + "]";
							break;
						case VertexAttributes.NORMAL:
							data.position = j*stride + offset;
							x = data.readFloat();
							y = data.readFloat();
							z = data.readFloat();
							break;
						case VertexAttributes.TANGENT4:
							data.position = j*stride + offset;
							x = data.readFloat();
							y = data.readFloat();
							z = data.readFloat();
							break;
						case VertexAttributes.JOINTS[0]:
							data.position = j*stride + offset;
							traceString += "J0[" + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + "] ";
							break;
						case VertexAttributes.JOINTS[1]:
							data.position = j*stride + offset;
							traceString += "J1[" + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + "] ";
							break;
						case VertexAttributes.JOINTS[2]:
							data.position = j*stride + offset;
							traceString += "J1[" + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + "] ";
							break;
						case VertexAttributes.JOINTS[3]:
							data.position = j*stride + offset;
							traceString += "J1[" + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + ", " + data.readFloat().toFixed(0) + " = " + data.readFloat().toFixed(2) + "] ";
							break;

					}
					prev = attr;
				}
				trace(traceString);

			}

		}
	}
}
