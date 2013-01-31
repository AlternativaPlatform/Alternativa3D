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
	import alternativa.engine3d.animation.keys.TransformKey;
	import alternativa.engine3d.animation.keys.TransformTrack;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.VertexStream;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.SpotLight;
	import alternativa.engine3d.materials.LightMapMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;
	import alternativa.osgi.OSGi;
	import alternativa.osgi.service.clientlog.IClientLog;
	import alternativa.protocol.CompressionType;
	import alternativa.protocol.ICodec;
	import alternativa.protocol.IProtocol;
	import alternativa.protocol.OptionalMap;
	import alternativa.protocol.ProtocolBuffer;
	import alternativa.protocol.impl.PacketHelper;
	import alternativa.protocol.impl.Protocol;
	import alternativa.protocol.info.TypeCodecInfo;
	import alternativa.protocol.osgi.ProtocolActivator;
	import alternativa.types.Long;

	import commons.A3DMatrix;

	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	import platform.client.formats.a3d.osgi.Activator;
	import platform.clients.fp10.libraries.alternativaprotocol.Activator;

	import versions.version2.a3d.A3D2;
	import versions.version2.a3d.animation.A3D2AnimationClip;
	import versions.version2.a3d.animation.A3D2Keyframe;
	import versions.version2.a3d.animation.A3D2Track;
	import versions.version2.a3d.geometry.A3D2IndexBuffer;
	import versions.version2.a3d.geometry.A3D2VertexAttributes;
	import versions.version2.a3d.geometry.A3D2VertexBuffer;
	import versions.version2.a3d.materials.A3D2Image;
	import versions.version2.a3d.materials.A3D2Map;
	import versions.version2.a3d.materials.A3D2Material;
	import versions.version2.a3d.objects.A3D2AmbientLight;
	import versions.version2.a3d.objects.A3D2Box;
	import versions.version2.a3d.objects.A3D2DirectionalLight;
	import versions.version2.a3d.objects.A3D2Joint;
	import versions.version2.a3d.objects.A3D2JointBindTransform;
	import versions.version2.a3d.objects.A3D2Mesh;
	import versions.version2.a3d.objects.A3D2Object;
	import versions.version2.a3d.objects.A3D2OmniLight;
	import versions.version2.a3d.objects.A3D2Skin;
	import versions.version2.a3d.objects.A3D2SpotLight;
	import versions.version2.a3d.objects.A3D2Surface;
	import versions.version2.a3d.objects.A3D2Transform;

	use namespace alternativa3d;

	/**
	 * An object which allows to convert hierarchy of three-dimensional objects to binary  A3D format.
	 */
	public class ExporterA3D {

		private var wasInit:Boolean = false;
		private var protocol:Protocol;
		private var parents:Dictionary;
		private var geometries:Dictionary;
		private var images:Dictionary;

		private var indexBufferID:int;
		private var materialID:int;
		private var mapID:int;
		private var imageID:int;
		private var animationID:int;
		private var trackID:int;
		private var vertexBufferID:int;
		private var boxID:int;

		private var tracksMap:Dictionary;
		private var materialsMap:Dictionary;
		private var mapsMap:Dictionary;
        /**
         * @private
         */
		alternativa3d var idGenerator:IIDGenerator = new IncrementalIDGenerator();

		/**
		 * Creates an instance of ExporterA3D.
		 */
		public function ExporterA3D() {
			init();
		}

		private function init():void {
			if (wasInit) return;
			if (OSGi.getInstance() != null) {
				protocol = Protocol(OSGi.getInstance().getService(IProtocol));
				return;
			}
			OSGi.clientLog = new DummyClientLog();
			var osgi:OSGi = new OSGi();
			osgi.registerService(IClientLog, new DummyClientLog());

			new ProtocolActivator().start(osgi);
			new platform.client.formats.a3d.osgi.Activator().start(osgi);
			new platform.clients.fp10.libraries.alternativaprotocol.Activator().start(osgi);
			protocol = Protocol(osgi.getService(IProtocol));
			wasInit = true;
		}

		/**
		 * Exports a scene to  A3D format.
		 * @param root Root object of scene.
		 * @return Data in  A3D format.
		 */
		public function export(root:Object3D = null, animations:Vector.<AnimationClip> = null):ByteArray {

			boxID = 0;
			indexBufferID = 0;
			vertexBufferID = 0;
			materialID = 0;
			mapID = 0;
			imageID = 0;
			animationID = 0;
			materialsMap = new Dictionary();
			mapsMap = new Dictionary();
			geometries = new Dictionary();
			tracksMap = new Dictionary();

			images = new Dictionary();

			parents = new Dictionary();

			var a3D:A3D2 = new A3D2(
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null,
					null
			);
			if (root != null) {
				exportHierarchy(root, a3D);
			}
			if (animations != null) {
				for each (var animation:AnimationClip in animations) {
					exportAnimation(animation, a3D);
				}
			}

			var data:ByteArray = new ByteArray();
			var result:ByteArray = new ByteArray();
			var codec:ICodec = protocol.getCodec(new TypeCodecInfo(A3D2, false));

			var protocolBuffer:ProtocolBuffer = new ProtocolBuffer(data, data, new OptionalMap());
			data.writeShort(2);
			data.writeShort(0);
			codec.encode(protocolBuffer, a3D);
			data.position = 0;
			PacketHelper.wrapPacket(result, protocolBuffer, CompressionType.DEFLATE);
			return result;
		}

		private function exportAnimation(source:AnimationClip, dest:A3D2):void {
			var anim:A3D2AnimationClip = new A3D2AnimationClip(animationID, source.loop, source.name, null, exportTracks(source, dest));
			if (dest.animationClips == null) dest.animationClips = new Vector.<A3D2AnimationClip>();
			dest.animationClips[animationID] = anim; animationID++;
		}

		private function exportTracks(source:AnimationClip, dest:A3D2):Vector.<int> {
			var id:int;
			var result:Vector.<int> = new Vector.<int>();
			for (var i:int = 0; i < source.numTracks; i++) {
				var t:TransformTrack = source.getTrackAt(i) as TransformTrack;
				if (t != null && tracksMap[t] == null) {
					id = trackID++;
					var exportTrack:A3D2Track = new A3D2Track(id, exportKeyframes(t), t.object);
					tracksMap[t] = id;
					if (dest.animationTracks == null) dest.animationTracks = new Vector.<A3D2Track>();
					dest.animationTracks[id] = exportTrack;
				} else {
					id = tracksMap[t];
				}
				result.push(id);
			}
			return result;
		}

		private function exportKeyframes(source:TransformTrack):Vector.<A3D2Keyframe> {
			var result:Vector.<A3D2Keyframe> = new Vector.<A3D2Keyframe>();
			var key:TransformKey = TransformKey(source.keyFramesList);

			while (key != null) {
				var exportKey:A3D2Keyframe = new A3D2Keyframe(key._time, exportTransformFromKeyframe(key));
				result.push(exportKey);
				key = key.next;
			}
			return result;
		}

		private function exportTransformFromKeyframe(key:TransformKey):A3D2Transform {
			var m:Matrix3D = Matrix3D(key.value);
			var vec:Vector.<Number> = m.rawData;
			var exportTransform:A3D2Transform = new A3D2Transform(
					new A3DMatrix(
							vec[0], vec[4], vec[8], vec[12],
							vec[1], vec[5], vec[9], vec[13],
							vec[2], vec[6], vec[10], vec[14]
			));
			return exportTransform;
		}



		private function exportHierarchy(source:Object3D, dest:A3D2):void {
			var id:Long = idGenerator.getID(source);
			if (source.transformChanged) {
				source.composeTransforms();
			}
			if (source is SpotLight) {
				exportSpotLight(id, SpotLight(source), dest);
			} else if (source is OmniLight) {
				exportOmniLight(id, OmniLight(source), dest);
			} else if (source is DirectionalLight) {
				exportDirLight(id, DirectionalLight(source), dest);
			} else if (source is AmbientLight) {
				exportAmbientLight(id, AmbientLight(source), dest);
			} else if (source is Skin) {
				exportSkin(id, Skin(source), dest);
			} else if (source is Mesh) {
				if (Mesh(source).geometry != null) {
					exportMesh(id, Mesh(source), dest);
				} else {
					exportObject3D(id, source, dest);
				}
			} else if (source is Joint) {
				exportJoint(id, Joint(source), dest);
			} else if (source is Object3D) {
				exportObject3D(id, source, dest);
			} else {
				trace("Unsupported object type", source);
			}
			parents[source] = id;

			for (var child:Object3D = source.childrenList; child != null; child = child.next) {
				exportHierarchy(child, dest);
			}
		}

		private function exportJoint(id:Long, source:Joint, dest:A3D2):void {

			var a3DObject:A3D2Joint = new A3D2Joint(
					exportBoundBox(source.boundBox, dest),
					id,
					source.name,
					parents[source.parent is Skin ? source.parent.parent : source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.joints == null) dest.joints = new Vector.<A3D2Joint>();
			dest.joints.push(a3DObject);
		}

		private function exportObject3D(id:Long, source:Object3D, dest:A3D2):void {
			var a3DObject:A3D2Object = new A3D2Object(
					exportBoundBox(source.boundBox, dest),
					id,
					source.name,
					parents[source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.objects == null) dest.objects = new Vector.<A3D2Object>();
			dest.objects.push(a3DObject);
		}

		private function exportSpotLight(id:Long, source:SpotLight, dest:A3D2):void {
			var a3DObject:A3D2SpotLight = new A3D2SpotLight(
					source.attenuationBegin,
					source.attenuationEnd,
					exportBoundBox(source.boundBox, dest),
					source.color,
					source.falloff,
					source.hotspot,
					id,
					source.intensity,
					source.name,
					parents[source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.spotLights == null) dest.spotLights = new Vector.<A3D2SpotLight>();
			dest.spotLights.push(a3DObject);
		}

		private function exportOmniLight(id:Long, source:OmniLight, dest:A3D2):void {
			var a3DObject:A3D2OmniLight = new A3D2OmniLight(
					source.attenuationBegin,
					source.attenuationEnd,
					exportBoundBox(source.boundBox, dest),
					source.color,
					id,
					source.intensity,
					source.name,
					parents[source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.omniLights == null) dest.omniLights = new Vector.<A3D2OmniLight>();
			dest.omniLights.push(a3DObject);
		}

		private function exportDirLight(id:Long, source:DirectionalLight, dest:A3D2):void {
			var a3DObject:A3D2DirectionalLight = new A3D2DirectionalLight(
					exportBoundBox(source.boundBox, dest),
					source.color,
					id,
					source.intensity,
					source.name,
					parents[source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.directionalLights == null) dest.directionalLights = new Vector.<A3D2DirectionalLight>();
			dest.directionalLights.push(a3DObject);

		}

		private function exportAmbientLight(id:Long, source:AmbientLight, dest:A3D2):void {
			var a3DObject:A3D2AmbientLight = new A3D2AmbientLight(
					exportBoundBox(source.boundBox, dest),
					source.color,
					id,
					source.intensity,
					source.name,
					parents[source.parent],
					exportTransform(source.transform),
					source.visible
			);
			if (dest.ambientLights == null) dest.ambientLights = new Vector.<A3D2AmbientLight>();
			dest.ambientLights.push(a3DObject);
		}

		private function exportMesh(id:Long, source:Mesh, dest:A3D2):void {
			var geometryData:GeometryData = exportGeometry(source.geometry, dest);
			var a3DMesh:A3D2Mesh = new A3D2Mesh(
					exportBoundBox(source.boundBox, dest),
					id,
					geometryData.indexBufferID,
					source.name,
					parents[source.parent],
					exportSurfaces(source._surfaces, dest),
					exportTransform(source.transform),
					geometryData.vertexBufferIDs,
					source.visible
			);
			if (dest.meshes == null) dest.meshes = new Vector.<A3D2Mesh>();
			dest.meshes.push(a3DMesh);
		}

		private function exportSkin(id:Long, source:Skin, dest:A3D2):A3D2Skin {
			var geometryData:GeometryData = exportGeometry(source.geometry, dest);
			var a3DSkin:A3D2Skin = new A3D2Skin(
					exportBoundBox(source.boundBox, dest),
					id,
					geometryData.indexBufferID,
					exportJointsBindTransforms(source._renderedJoints),
					exportJointsListFromSurfacesJoints(source.surfaceJoints),
					source.name,
					exportNumJoitns(source.surfaceJoints),
					null,
					exportSurfaces(source._surfaces, dest),
					exportTransform(source.transform),
					geometryData.vertexBufferIDs,
					source.visible
			);
			if (dest.skins == null) dest.skins = new Vector.<A3D2Skin>();
			dest.skins.push(a3DSkin);
			return a3DSkin;
		}

		private function exportNumJoitns(surfaceJoints:Vector.<Vector.<Joint>>):Vector.<uint> {
			var result:Vector.<uint> = new Vector.<uint>();
			for (var i:int = 0; i < surfaceJoints.length; i++) {
				result.push(surfaceJoints[i].length);
			}
			return result;
		}

		private function exportJointsBindTransforms(joints:Vector.<Joint>):Vector.<A3D2JointBindTransform> {
			var result:Vector.<A3D2JointBindTransform> = new Vector.<A3D2JointBindTransform>();
			for each (var joint:Joint in joints) {
				result.push(new A3D2JointBindTransform(exportTransform(joint.bindPoseTransform), idGenerator.getID(joint)));
			}
			return result;
		}

		private function exportJointsListFromSurfacesJoints(surfaceJoints:Vector.<Vector.<Joint>>):Vector.<Long> {
			var result:Vector.<Long> = new Vector.<Long>();
			for (var i:int = 0; i < surfaceJoints.length; i++) {
				var joints:Vector.<Joint> = surfaceJoints[i];
				for each (var joint:Joint in joints) {
					result.push(idGenerator.getID(joint));
				}
			}
			return result;
		}

		private function exportSurfaces(surfaces:Vector.<Surface>, dest:A3D2):Vector.<A3D2Surface> {
			var result:Vector.<A3D2Surface> = new Vector.<A3D2Surface>();
			for (var i:int = 0, count:int = surfaces.length; i < count; i++) {
				var surface:Surface = surfaces[i];
				var resSurface:A3D2Surface = new A3D2Surface(surface.indexBegin, exportMaterial(surface.material, dest), surface.numTriangles);
				result[i] = resSurface;
			}
			return result;
		}

		private function exportMaterial(source:Material, dest:A3D2):int {
			if (source == null) return -1;
			var result:A3D2Material = materialsMap[source];
			if (result != null) return result.id;
			if (source is ParserMaterial) {
				var parserMaterial:ParserMaterial = source as ParserMaterial;
				result = new A3D2Material(
						exportMap(parserMaterial.textures["diffuse"], 0, dest),
						exportMap(parserMaterial.textures["glossiness"], 0, dest),
						materialID,
						exportMap(parserMaterial.textures["emission"], 0, dest),
						exportMap(parserMaterial.textures["bump"], 0, dest),
						exportMap(parserMaterial.textures["transparent"], 0, dest),
						-1,
						exportMap(parserMaterial.textures["specular"], 0, dest)
				);
			} else if (source is LightMapMaterial) {
				var lightMapMaterial:LightMapMaterial = source as LightMapMaterial;
				result = new A3D2Material(
						exportMap(lightMapMaterial.diffuseMap, 0, dest),
						-1,
						materialID,
						exportMap(lightMapMaterial.lightMap, lightMapMaterial.lightMapChannel, dest),
						-1,
						exportMap(lightMapMaterial.opacityMap, 0, dest),
						-1,
						-1);
			} else if (source is StandardMaterial) {
				var standardMaterial:StandardMaterial = source as StandardMaterial;
				result = new A3D2Material(
						exportMap(standardMaterial.diffuseMap, 0, dest),
						exportMap(standardMaterial.glossinessMap, 0, dest), materialID,
						-1,
						exportMap(standardMaterial.normalMap, 0, dest),
						exportMap(standardMaterial.opacityMap, 0, dest),
						-1,
						exportMap(standardMaterial.specularMap, 0, dest));
			} else if (source is TextureMaterial) {
				var textureMaterial:TextureMaterial = source as TextureMaterial;
				result = new A3D2Material(exportMap(textureMaterial.diffuseMap, 0, dest), -1, materialID, -1, -1, exportMap(textureMaterial.opacityMap, 0, dest), -1, -1);
			}
			materialsMap[source] = result;
			if (dest.materials == null) dest.materials = new Vector.<A3D2Material>();
			dest.materials[materialID] = result;
			return materialID++;
		}

		private function exportMap(source:TextureResource, channel:int, dest:A3D2):int {
			if (source == null) return -1;
			var result:A3D2Map = mapsMap[source];
			if (result != null) return result.id;
			if (source is ExternalTextureResource) {
				var resource:ExternalTextureResource = source as ExternalTextureResource;
				result = new A3D2Map(channel, mapID, exportImage(resource, dest));
				if (dest.maps == null) dest.maps = new Vector.<A3D2Map>();
				dest.maps[mapID] = result;
				mapsMap[source] = result;

				return mapID++;
			}
			return -1;
		}

		private function exportImage(source:ExternalTextureResource, dest:A3D2):int {
			var image:Object = images[source];
			if (image != null) return int(image);
			var result:A3D2Image = new A3D2Image(imageID, source.url);
			if (dest.images == null) dest.images = new Vector.<A3D2Image>();
			dest.images[imageID] = result;
			return imageID++;
		}

		private function exportGeometry(geometry:Geometry, dest:A3D2):GeometryData {
			var result:GeometryData = geometries[geometry];
			if (result != null) return result;
			result = new GeometryData();
			result.vertexBufferIDs = new Vector.<int>();
			var indicesData:ByteArray = new ByteArray();
			indicesData.endian = Endian.LITTLE_ENDIAN;
			var indices:Vector.<uint> = geometry.indices;
			for (var i:int = 0, count:int = indices.length; i < count; i++) {
				indicesData.writeShort(indices[i]);
			}
			var indexBuffer:A3D2IndexBuffer = new A3D2IndexBuffer(indicesData, indexBufferID, indices.length);
			result.indexBufferID = indexBufferID;
			if (dest.indexBuffers == null) dest.indexBuffers = new Vector.<A3D2IndexBuffer>();
			dest.indexBuffers[indexBufferID] = indexBuffer;
			indexBufferID++;
			for (i = 0,count = geometry._vertexStreams.length; i < count; i++) {
				var stream:VertexStream = geometry._vertexStreams[i];
				var buffer:A3D2VertexBuffer = new A3D2VertexBuffer(exportAttributes(stream.attributes), stream.data, vertexBufferID, geometry.numVertices);
				if (dest.vertexBuffers == null) dest.vertexBuffers = new Vector.<A3D2VertexBuffer>();
				dest.vertexBuffers[vertexBufferID] = buffer;
				result.vertexBufferIDs[i] = vertexBufferID++;
			}
			return result;
		}

		private function exportAttributes(attributes:Array):Vector.<A3D2VertexAttributes> {
			var prev:int = -1;
			var result:Vector.<A3D2VertexAttributes> = new Vector.<A3D2VertexAttributes>();
			for each (var attr:int in attributes) {
				if (attr == prev) continue;
				switch (attr) {
					case VertexAttributes.POSITION:
						result.push(A3D2VertexAttributes.POSITION);
						break;
					case VertexAttributes.NORMAL:
						result.push(A3D2VertexAttributes.NORMAL);
						break;
					case VertexAttributes.TANGENT4:
						result.push(A3D2VertexAttributes.TANGENT4);
						break;
					default:
						if ((attr >= VertexAttributes.JOINTS[0]) && (attr <= VertexAttributes.JOINTS[3])) {
							result.push(A3D2VertexAttributes.JOINT);
						} else if ((attr >= VertexAttributes.TEXCOORDS[0]) && (attr <= VertexAttributes.TEXCOORDS[7])) {
							result.push(A3D2VertexAttributes.TEXCOORD);
						}
						break;
				}
				prev = attr;
			}
			return result;
		}

		private function exportTransform(source:Transform3D):A3D2Transform {
			return new A3D2Transform(new A3DMatrix(
					source.a, source.b, source.c, source.d,
					source.e, source.f, source.g, source.h,
					source.i, source.j, source.k, source.l
			));
		}

		private function exportBoundBox(boundBox:BoundBox, dest:A3D2):int {
			if (boundBox == null) return -1;
			if (dest.boxes == null) dest.boxes = new Vector.<A3D2Box>();
			dest.boxes[boxID] = new A3D2Box(Vector.<Number>([boundBox.minX, boundBox.minY, boundBox.minZ, boundBox.maxX, boundBox.maxY, boundBox.maxZ]), boxID);
			return boxID++;
		}
	}
}

import alternativa.osgi.service.clientlog.IClientLog;
import alternativa.osgi.service.clientlog.IClientLogChannelListener;

class GeometryData {
	public var indexBufferID:int;
	public var vertexBufferIDs:Vector.<int>;

	public function GeometryData(indexBufferID:int = -1, vertexBufferIDs:Vector.<int> = null) {
		this.indexBufferID = indexBufferID;
		this.vertexBufferIDs = vertexBufferIDs;
	}
}

class DummyClientLog implements IClientLog {

	public function logError(channelName:String, text:String, ... vars):void {
	}

	public function log(channelName:String, text:String, ... rest):void {
	}

	public function getChannelStrings(channelName:String):Vector.<String> {
		return null;
	}

	public function addLogListener(listener:IClientLogChannelListener):void {
	}

	public function removeLogListener(listener:IClientLogChannelListener):void {
	}

	public function addLogChannelListener(channelName:String, listener:IClientLogChannelListener):void {
	}

	public function removeLogChannelListener(channelName:String, listener:IClientLogChannelListener):void {
	}

	public function getChannelNames():Vector.<String> {
		return null;
	}
}
