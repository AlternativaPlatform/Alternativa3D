/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.SpotLight;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;

	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * Parser of <code>.3ds</code> files , that are presented as <code>ByteArray</code>.
	 */
	public class Parser3DS extends Parser {

		private static const CHUNK_MAIN:int = 0x4D4D;
		private static const CHUNK_VERSION:int = 0x0002;
		private static const CHUNK_SCENE:int = 0x3D3D;
		private static const CHUNK_ANIMATION:int = 0xB000;
		private static const CHUNK_OBJECT:int = 0x4000;
		private static const CHUNK_TRIMESH:int = 0x4100;
		private static const CHUNK_LIGHT:int = 0x4600;
		private static const CHUNK_CAMERA:int = 0x4700;
		private static const CHUNK_VERTICES:int = 0x4110;
		private static const CHUNK_FACES:int = 0x4120;
		private static const CHUNK_FACESMATERIAL:int = 0x4130;
		private static const CHUNK_FACESSMOOTHGROUPS:int = 0x4150;
		private static const CHUNK_MAPPINGCOORDS:int = 0x4140;
		//private static const CHUNK_OBJECTCOLOR:int = 0x4165;
		private static const CHUNK_TRANSFORMATION:int = 0x4160;
		//private static const CHUNK_MESHANIMATION:int = 0xB002;
		private static const CHUNK_MATERIAL:int = 0xAFFF;

		private var data:ByteArray;
		private var objectDatas:Object;
		private var animationDatas:Vector.<AnimationData>;
		private var materialDatas:Object;

		/**
		 * Performs parsing.
		 * Result of parsing is placed in lists are follows <code>objects</code>, <code>parents</code>, <code>materials</code>.
		 * @param data <code>ByteArray</code>  correspond to content of a 3ds file.
		 * @param texturesBaseURL Base path to texture files.  After parsing <code>diffuseMapURL</code> and <code>opacityMapURL</code> properties gets string values, that consists of <code>texturesBaseURL</code> and file name.
		 * @param scale Amount to multiply vertex coordinates, objects coordinates and values of objects scaling.
		 * @param respectSmoothGroups Flag of accounting of smoothing groups. If flag set to <code>true</code>, then all vertices  will duplicated according to smoothing groups, specified for the objects.
		 *
		 * @see alternativa.engine3d.loaders.ParserMaterial
		 * @see #objects
		 * @see #hierarchy
		 * @see #materials
		 */

		public function parse(data:ByteArray, texturesBaseURL:String = "", scale:Number = 1, respectSmoothGroups:Boolean = false):void {
			if (data.bytesAvailable < 6) return;
			this.data = data;
			data.endian = Endian.LITTLE_ENDIAN;
			parse3DSChunk(data.position, data.bytesAvailable);
			objects = new Vector.<Object3D>();
			hierarchy = new Vector.<Object3D>();
			materials = new Vector.<ParserMaterial>();
			buildContent(texturesBaseURL, scale, respectSmoothGroups);
			this.data = null;
			objectDatas = null;
			animationDatas = null;
			materialDatas = null;
		}

		private function readChunkInfo(dataPosition:int):ChunkInfo {
			data.position = dataPosition;
			var chunkInfo:ChunkInfo = new ChunkInfo();
			chunkInfo.id = data.readUnsignedShort();
			chunkInfo.size = data.readUnsignedInt();
			chunkInfo.dataSize = chunkInfo.size - 6;
			chunkInfo.dataPosition = data.position;
			chunkInfo.nextChunkPosition = dataPosition + chunkInfo.size;
			return chunkInfo;
		}

		private function parse3DSChunk(dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			data.position = dataPosition;
			switch (chunkInfo.id) {
				// Main
				case CHUNK_MAIN:
					parseMainChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
			}
			parse3DSChunk(chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseMainChunk(dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Version
				case CHUNK_VERSION:
					//version = data.readUnsignedInt();
					break;
				// 3D-scene
				case CHUNK_SCENE:
					parse3DChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Animation
				case CHUNK_ANIMATION:
					parseAnimationChunk(chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
			}
			parseMainChunk(chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parse3DChunk(dataPosition:int, bytesAvailable:int):void {
			while (bytesAvailable >= 6) {
				var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
				switch (chunkInfo.id) {
					// Material
					case CHUNK_MATERIAL:
						// Parse material
						var material:MaterialData = new MaterialData();
						parseMaterialChunk(material, chunkInfo.dataPosition, chunkInfo.dataSize);
						break;
					// Object
					case CHUNK_OBJECT:
						parseObject(chunkInfo);
						break;
				}
				dataPosition = chunkInfo.nextChunkPosition;
				bytesAvailable -= chunkInfo.size;
			}
		}

		private function parseObject(chunkInfo:ChunkInfo):void {
			// Create list of objects, if it need.
			if (objectDatas == null) {
				objectDatas = {};
			}
			// Create object data
			var object:ObjectData = new ObjectData();
			// Get object name
			object.name = getString(chunkInfo.dataPosition);
			// Get object data to list
			objectDatas[object.name] = object;
			// Parse object
			var offset:int = object.name.length + 1;
			parseObjectChunk(object, chunkInfo.dataPosition + offset, chunkInfo.dataSize - offset);
		}

		private function parseObjectChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Mesh
				case CHUNK_TRIMESH:
					parseMeshChunk(object, chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Light source
				case CHUNK_LIGHT:
					parseLightChunk(object, chunkInfo.dataPosition, chunkInfo.dataSize);
					break;
				// Camera
				case CHUNK_CAMERA:
					parseCameraChunk(object, chunkInfo.dataSize);
					break;
			}
			parseObjectChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseMeshChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Vertices
				case CHUNK_VERTICES:
					parseVertices(object);
					break;
				// UV
				case CHUNK_MAPPINGCOORDS:
					parseUVs(object);
					break;
				// Transformation
				case CHUNK_TRANSFORMATION:
					parseMatrix(object);
					break;
				// Faces
				case CHUNK_FACES:
					parseFaces(object, chunkInfo);
					break;
			}
			parseMeshChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseVertices(object:ObjectData):void {
			var num:int = data.readUnsignedShort();
			object.vertices = new Vector.<Number>(3*num, true);
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.vertices[j++] = data.readFloat();
				object.vertices[j++] = data.readFloat();
				object.vertices[j++] = data.readFloat();
			}
		}

		private function parseUVs(object:ObjectData):void {
			var num:int = data.readUnsignedShort();
			object.uvs = new Vector.<Number>(2*num, true);
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.uvs[j++] = data.readFloat();
				object.uvs[j++] = data.readFloat();
			}
		}

		private function parseMatrix(object:ObjectData):void {
			object.a = data.readFloat();
			object.e = data.readFloat();
			object.i = data.readFloat();
			object.b = data.readFloat();
			object.f = data.readFloat();
			object.j = data.readFloat();
			object.c = data.readFloat();
			object.g = data.readFloat();
			object.k = data.readFloat();
			object.d = data.readFloat();
			object.h = data.readFloat();
			object.l = data.readFloat();
		}

		private function parseFaces(object:ObjectData, chunkInfo:ChunkInfo):void {
			var num:int = data.readUnsignedShort();
			object.smoothGroups = new Vector.<uint>(num, true);
			object.faces = new Vector.<int>(3*num, true);
			for (var i:int = 0, j:int = 0; i < num; i++) {
				object.faces[j++] = data.readUnsignedShort();
				object.faces[j++] = data.readUnsignedShort();
				object.faces[j++] = data.readUnsignedShort();
				data.position += 2; // Skip the flag of edges rendering
			}
			var offset:int = 2 + 8*num;
			parseFacesChunk(object, chunkInfo.dataPosition + offset, chunkInfo.dataSize - offset);
		}

		private function parseFacesChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Surfaces
				case CHUNK_FACESMATERIAL:
					parseSurface(object);
					break;
				// Smoothing groups.
				case CHUNK_FACESSMOOTHGROUPS:
					parseSmoothGroups(object);
					break;
			}
			parseFacesChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseSurface(object:ObjectData):void {
			// Create list of surfaces, if it need.
			if (object.surfaces == null) {
				object.surfaces = {};
			}
			// Name of surface and number of faces.
			var sur:String = getString(data.position);
			var num:int = data.readUnsignedShort();
			if (num > 0) {
				// Create surface data
				var surface:Vector.<uint> = new Vector.<uint>(num + 1);
				// Put surface data to list
				object.surfaces[sur] = surface;
				// Get faces of surface
				for (var i:int = 0; i < num; i++) {
					surface[i] = data.readUnsignedShort();
				}
				// Also stores number of the material (starts from 1) (additionally store the serial number of material (beginning from the one))
				surface[num] = (object.surfacesCount++);
			}
		}

		private function parseSmoothGroups(object:ObjectData):void {
			var num:int = object.faces.length/3;
			for (var i:int = 0; i < num; i++) {
				object.smoothGroups [i] = data.readUnsignedInt();
			}
		}

		private function parseAnimationChunk(dataPosition:int, bytesAvailable:int):void {
			while (bytesAvailable >= 6) {
				var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
				switch (chunkInfo.id) {
					// Object animation
					case 0xB001: // ambient o_O
					case 0xB002:
					case 0xB003:
					case 0xB004: // cam target
					case 0xB005:
					case 0xB006: // spot target
					case 0xB007:
						if (animationDatas == null) {
							animationDatas = new Vector.<AnimationData>();
						}
						var animation:AnimationData = new AnimationData();
						animation.chunkId = chunkInfo.id;
						animationDatas.push(animation);
						parseObjectAnimationChunk(animation, chunkInfo.dataPosition, chunkInfo.dataSize);
						break;
					// Timeline
					case 0xB008:
						break;
				}
				dataPosition = chunkInfo.nextChunkPosition;
				bytesAvailable -= chunkInfo.size;
			}
		}

		private function parseObjectAnimationChunk(animation:AnimationData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Identification of object and its link
				case 0xB010:
					// Name of the object
					animation.objectName = getString(data.position);
					if ((animation.chunkId == 0xB004) || (animation.chunkId == 0xB006)) animation.objectName += "_target";
					data.position += 4;
					// Index of parent object in plain list of scene objects.
					animation.parentIndex = data.readUnsignedShort();
					break;
				// Name of dummy object
				case 0xB011:
					animation.instanceOf = animation.objectName;
					animation.objectName = getString(data.position);
					break;
				// Pivot
				case 0xB013:
					animation.pivot = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Offset of the object relative to its parent
				case 0xB020:
					data.position += 20;
					animation.position = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Rotation of object relative to its parent (angle-axis)
				case 0xB021:
					data.position += 20;
					animation.rotation = getRotationFrom3DSAngleAxis(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
					break;
				// Scale of object relative to its parent
				case 0xB022:
					data.position += 20;
					animation.scale = new Vector3D(data.readFloat(), data.readFloat(), data.readFloat());
					break;
			}
			parseObjectAnimationChunk(animation, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseMaterialChunk(material:MaterialData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Name of material
				case 0xA000:
					parseMaterialName(material);
					break;
				// Ambient color
				case 0xA010:
					data.position = chunkInfo.dataPosition + 6;
					material.ambient = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();
					break;
				// Diffuse color
				case 0xA020:
					data.position = chunkInfo.dataPosition + 6;
					material.diffuse = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();
					break;
				// Specular color
				case 0xA030:
					data.position = chunkInfo.dataPosition + 6;
					material.specular = (data.readUnsignedByte() << 16) + (data.readUnsignedByte() << 8) + data.readUnsignedByte();
					break;
				// Shininess percent
				case 0xA040:
					data.position = chunkInfo.dataPosition + 6;
					material.glossiness = data.readUnsignedShort();
					break;
				// Shininess strength percent
				case 0xA041:
					break;
				// Transparensy
				case 0xA050:
					data.position = chunkInfo.dataPosition + 6;
					material.transparency = data.readUnsignedShort();
					break;
				// Texture map 1
				case 0xA200:
					parseMaterialMapData("diffuse", material, chunkInfo);
					break;
				// Texture map 2
				case 0xA33A:
					break;
				// Opacity map
				case 0xA210:
					parseMaterialMapData("transparent", material, chunkInfo);
					break;
				// Bump map
				case 0xA230:
					parseMaterialMapData("bump", material, chunkInfo);
					break;
				// Specular map
				case 0xA204:
					parseMaterialMapData("specular", material, chunkInfo);
					break;
				// Shininess map
				case 0xA33C:
					parseMaterialMapData("glossiness", material, chunkInfo);
					break;
				// Self-illumination map
				case 0xA33D:
					parseMaterialMapData("emission", material, chunkInfo);
					break;
				// Reflection map
				case 0xA220:
					parseMaterialMapData("reflective", material, chunkInfo);
					break;
			}
			parseMaterialChunk(material, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseMaterialMapData(channel:String, material:MaterialData, chunkInfo:ChunkInfo):void {
			var map:MapData = new MapData;
			map.channel = channel;
			parseMapChunk(material.name, map, chunkInfo.dataPosition, chunkInfo.dataSize);
			material.maps.push(map);
		}

		private function parseMaterialName(material:MaterialData):void {
			// Create list of materials, if it need
			if (materialDatas == null) {
				materialDatas = {};
			}
			// Get name of material
			material.name = getString(data.position);
			// Put data of material in list
			materialDatas[material.name] = material;
		}

		private function parseMapChunk(materialName:String, map:MapData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// File name
				case 0xA300:
					map.filename = getString(chunkInfo.dataPosition).toLowerCase();
					break;
				case 0xA351:
					// Texture mapping options
					break;
				// Scale along U
				case 0xA354:
					map.scaleU = data.readFloat();
					break;
				// Scale along V
				case 0xA356:
					map.scaleV = data.readFloat();
					break;
				// Offset along U
				case 0xA358:
					map.offsetU = data.readFloat();
					break;
				// Offset along V
				case 0xA35A:
					map.offsetV = data.readFloat();
					break;
				// Rotation angle
				case 0xA35C:
					map.rotation = data.readFloat();
					break;
			}
			parseMapChunk(materialName, map, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function getString(index:int):String {
			data.position = index;
			var charCode:int;
			var res:String = "";
			while ((charCode = data.readByte()) != 0) {
				res += String.fromCharCode(charCode);
			}
			return res;
		}

		private function getRotationFrom3DSAngleAxis(angle:Number, x:Number, z:Number, y:Number):Vector3D {
			var res:Vector3D = new Vector3D();
			var s:Number = Math.sin(angle);
			var c:Number = Math.cos(angle);
			var t:Number = 1 - c;
			var k:Number = x*y*t + z*s;
			var half:Number;
			if (k >= 1) {
				half = angle/2;
				res.z = -2*Math.atan2(x*Math.sin(half), Math.cos(half));
				res.y = -Math.PI/2;
				res.x = 0;
				return res;
			}
			if (k <= -1) {
				half = angle/2;
				res.z = 2*Math.atan2(x*Math.sin(half), Math.cos(half));
				res.y = Math.PI/2;
				res.x = 0;
				return res;
			}
			res.z = -Math.atan2(y*s - x*z*t, 1 - (y*y + z*z)*t);
			res.y = -Math.asin(x*y*t + z*s);
			res.x = -Math.atan2(x*s - y*z*t, 1 - (x*x + z*z)*t);
			return res;
		}

		private function parseLightChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6 + 12) return;
			var x:Number = data.readFloat();
			var y:Number = data.readFloat();
			var z:Number = data.readFloat();
			object.position = new Vector3D(x, y, z);
			parseLightSubChunk(object, dataPosition + 12, bytesAvailable - 12);
		}

		private function parseLightSubChunk(object:ObjectData, dataPosition:int, bytesAvailable:int):void {
			if (bytesAvailable < 6) return;
			var chunkInfo:ChunkInfo = readChunkInfo(dataPosition);
			switch (chunkInfo.id) {
				// Float RGB
				case 0x0010:
					var r:int = Math.round(Math.max(0, 255*Math.min(1, data.readFloat())));
					var g:int = Math.round(Math.max(0, 255*Math.min(1, data.readFloat())));
					var b:int = Math.round(Math.max(0, 255*Math.min(1, data.readFloat())));
					object.lightColor = r*65536 + g*256 + b;
					break;
				// Byte RGB
				case 0x0011:
					r = data.readUnsignedByte();
					g = data.readUnsignedByte();
					b = data.readUnsignedByte();
					object.lightColor = r*65536 + g*256 + b;
					break;
				// Spot light
				case 0x4610:
					var x:Number = data.readFloat();
					var y:Number = data.readFloat();
					var z:Number = data.readFloat();
					object.target = new Vector3D(x, y, z);
					object.hotspot = data.readFloat();
					object.falloff = data.readFloat();
					break;
				// Light is off
				case 0x4620:
					object.lightOff = true;
					break;
				// Attenuation is on
				case 0x4625:
					object.attenuationOn = true;
					break;
				// Inner range
				case 0x4659:
					object.innerRange = data.readFloat();
					break;
				// Outer range
				case 0x465A:
					object.outerRange = data.readFloat();
					break;
				// Multiplier
				case 0x465B:
					object.multiplier = data.readFloat();
					break;
				default:
					break;
			}
			parseLightSubChunk(object, chunkInfo.nextChunkPosition, bytesAvailable - chunkInfo.size);
		}

		private function parseCameraChunk(object:ObjectData, bytesAvailable:int):void {
			if (bytesAvailable < 32) return;
			var x:Number = data.readFloat();
			var y:Number = data.readFloat();
			var z:Number = data.readFloat();
			object.position = new Vector3D(x, y, z);
			x = data.readFloat();
			y = data.readFloat();
			z = data.readFloat();
			object.target = new Vector3D(x, y, z);
			object.bank = data.readFloat();
			object.lens = data.readFloat();
		}

		private function buildContent(texturesBaseURL:String, scale:Number, respectSmoothGroups:Boolean):void {
			// Calculation of matrices of texture materials
			for (var materialName:String in materialDatas) {
				var materialData:MaterialData = materialDatas[materialName];
				materialData.material = new ParserMaterial();
				materialData.material.name = materialName;
				var mapData:MapData = materialData.diffuseMap;
				if (mapData != null) {
					if ((mapData.rotation != 0) ||
							(mapData.offsetU != 0) ||
							(mapData.offsetV != 0) ||
							(mapData.scaleU != 1) ||
							(mapData.scaleV != 1)) {
						// transformation of texture is set
						var materialMatrix:Matrix = new Matrix();
						var rot:Number = mapData.rotation*Math.PI/180;
						materialMatrix.translate(-mapData.offsetU, mapData.offsetV);
						materialMatrix.translate(-0.5, -0.5);
						materialMatrix.scale(mapData.scaleU, mapData.scaleV);
						materialMatrix.rotate(-rot);
						materialMatrix.translate(0.5, 0.5);
						materialData.matrix = materialMatrix;
					}
				}
				for each (mapData in materialData.maps) {
					materialData.material.textures[mapData.channel] = new ExternalTextureResource(texturesBaseURL + mapData.filename);
				}
				materialData.material.colors["ambient"] = materialData.ambient;
				materialData.material.colors["diffuse"] = materialData.diffuse;
				materialData.material.colors["specular"] = materialData.specular;
				materialData.material.glossiness = 0.01*materialData.glossiness;
				materialData.material.transparency = 0.01*materialData.transparency;
				materials.push(materialData.material);
			}
			var objectName:String;
			var objectData:ObjectData;
			var object:Object3D;
			// Scene has hierarchically related objects and (or) specified data about objects transformations.
			if (animationDatas != null) {
				if (objectDatas != null) {
					var i:int;
					var length:int = animationDatas.length;
					var animationData:AnimationData;
					for (i = 0; i < length; i++) {
						animationData = animationDatas[i];
						objectName = animationData.objectName;
						objectData = objectDatas[objectName];
						// Check for instances
						if (objectData != null) {
							for (var j:int = i + 1; j < length; j++) {
								var animationData2:AnimationData = animationDatas[j];
								if (objectName == animationData2.instanceOf) {
									animationData2.instanceOf = null;
									// Found match name for current part of animation, so make reference for it.
									var newObjectData:ObjectData = new ObjectData();
									newObjectData.name = animationData2.objectName;
									objectDatas[animationData2.objectName] = newObjectData;

									newObjectData.vertices = objectData.vertices;
									newObjectData.uvs = objectData.uvs;
									newObjectData.faces = objectData.faces;
									newObjectData.surfaces = objectData.surfaces;
									newObjectData.surfacesCount = objectData.surfacesCount;
									newObjectData.smoothGroups = objectData.smoothGroups;
									newObjectData.a = objectData.a;
									newObjectData.b = objectData.b;
									newObjectData.c = objectData.c;
									newObjectData.d = objectData.d;
									newObjectData.e = objectData.e;
									newObjectData.f = objectData.f;
									newObjectData.g = objectData.g;
									newObjectData.h = objectData.h;
									newObjectData.i = objectData.i;
									newObjectData.j = objectData.j;
									newObjectData.k = objectData.k;
									newObjectData.l = objectData.l;
									newObjectData.lightColor = objectData.lightColor;
									newObjectData.lightOff = objectData.lightOff;
									newObjectData.attenuationOn = objectData.attenuationOn;
									newObjectData.hotspot = objectData.hotspot;
									newObjectData.falloff = objectData.falloff;
									newObjectData.innerRange = objectData.innerRange;
									newObjectData.outerRange = objectData.outerRange;
									newObjectData.multiplier = objectData.multiplier;
									newObjectData.position = objectData.position;
									newObjectData.target = objectData.target;
									newObjectData.bank = objectData.bank;
									newObjectData.lens = objectData.lens;
								}
							}
						}

						if (objectData != null) {
							object = buildObject3D(objectData, animationData, scale, respectSmoothGroups);
						} else {
							// Create empty Object3D
							object = new Object3D();
						}
						object.name = objectName;
						animationData.object = object;
						if (animationData.position != null) {
							object.x = animationData.position.x*scale;
							object.y = animationData.position.y*scale;
							object.z = animationData.position.z*scale;
						}
						if (animationData.rotation != null) {
							object.rotationX = animationData.rotation.x;
							object.rotationY = animationData.rotation.y;
							object.rotationZ = animationData.rotation.z;
						}
						if (animationData.scale != null) {
							object.scaleX = animationData.scale.x;
							object.scaleY = animationData.scale.y;
							object.scaleZ = animationData.scale.z;
						}
					}
					// Add objects
					for (i = 0; i < length; i++) {
						animationData = animationDatas[i];
						objects.push(animationData.object);
						if (animationData.parentIndex == 0xFFFF) {
							hierarchy.push(animationData.object);
						} else {
							AnimationData(animationDatas[animationData.parentIndex]).object.addChild(animationData.object);
						}
					}
				}
				// Scene has no hierarchically related objects and  data about objects transformations is  not specified. Only polygonal objects woll added to container.
			} else {
				for (objectName in objectDatas) {
					objectData = objectDatas[objectName];
					if (objectData.vertices != null) {
						object = buildObject3D(objectData, null, scale, respectSmoothGroups);
						object.name = objectName;
						objects.push(object);
						hierarchy.push(object);
					}
				}
			}
		}

		private function buildObject3D(objectData:ObjectData, animationData:AnimationData, scale:Number, respectSmoothGroups:Boolean):Object3D {
			var object:Object3D;
			if (objectData.vertices != null) {
				// Create polygonal object
				object = new Mesh();
				buildMesh(object as Mesh, objectData, animationData, scale, respectSmoothGroups);
			} else {
				if (objectData.lightColor >= 0) {
					// Light
					var innerRange:Number = 0;
					var outerRange:Number = 1e15; // must be Number.MAX_VALUE, but if you set radius to ~2^60 and more then SpotLight is not working.
					if (objectData.attenuationOn && (objectData.outerRange < Number.MAX_VALUE)) {
						innerRange = objectData.innerRange*scale;
						outerRange = objectData.outerRange*scale;
					}
					if (objectData.target != null) {
						var rad:Number = Math.PI/180;
						object = new SpotLight(objectData.lightColor, innerRange, outerRange, objectData.hotspot*rad, objectData.falloff*rad);
					} else {
						object = new OmniLight(objectData.lightColor, innerRange, outerRange);
					}
					// Light intensity
					Light3D(object).intensity = objectData.lightOff ? 0 : objectData.multiplier;
				} else {
					// Camera or something else
					object = new Object3D;
				}
				if (objectData.position) {
					object.x = objectData.position.x*scale;
					object.y = objectData.position.y*scale;
					object.z = objectData.position.z*scale;
					if (objectData.target) {
						// Turn object to target
						var dx:Number = objectData.target.x*scale - object.x;
						var dy:Number = objectData.target.y*scale - object.y;
						var dz:Number = objectData.target.z*scale - object.z;
						object.rotationX = (Math.atan2(dz, Math.sqrt(((dx*dx) + (dy*dy)))) - (Math.PI/2));
						object.rotationY = 0;
						object.rotationZ = -(Math.atan2(dx, dy));
						// Pitch
						var matrix:Matrix3D = object.matrix;
						matrix.prependRotation(objectData.bank, Vector3D.Z_AXIS);
						object.matrix = matrix;
					}
				}
			}
			return object;
		}

		private function buildMesh(mesh:Mesh, objectData:ObjectData, animationData:AnimationData, scale:Number, respectSmoothGroups:Boolean):void {
			// Quit early
			if (objectData.faces == null) {
				return;
			}

			var vertices:Vector.<Vertex> = new Vector.<Vertex>(objectData.vertices.length/3);
			var faces:Vector.<Face> = new Vector.<Face>(objectData.faces.length/3);

			buildInitialGeometry(vertices, faces, objectData, animationData, scale);

			if (respectSmoothGroups) {
				cloneVerticesToRespectSmoothGroups(vertices, faces);
			}

			calculateVertexNormals(vertices, faces);

			if (materialDatas != null) {
				assignMaterialsToFaces(faces, objectData);

				cloneAndTransformVerticesToRespectUVTransforms(vertices, faces);
			}

			calculateVertexTangents(vertices, faces);

			// Default material for the faces without surfaces.
			var defaultMaterialData:MaterialData = new MaterialData;
			defaultMaterialData.numTriangles = 0;
			defaultMaterialData.material = new ParserMaterial;
			defaultMaterialData.material.colors["diffuse"] = 0x7F7F7F;
			defaultMaterialData.material.name = "default";

			var indices:Vector.<uint> = collectFacesIntoSurfaces(faces, defaultMaterialData);

			// Put all to mesh
			var vec:Vector3D, vertex:Vertex;
			var numVertices:int = vertices.length;
			var byteArray:ByteArray = new ByteArray();
			byteArray.endian = Endian.LITTLE_ENDIAN;
			for (var n:int = 0; n < numVertices; n++) {
				vertex = vertices [n];
				byteArray.writeFloat(vertex.x);
				byteArray.writeFloat(vertex.y);
				byteArray.writeFloat(vertex.z);
				byteArray.writeFloat(vertex.u);
				byteArray.writeFloat(vertex.v);

				vec = vertex.normal;
				byteArray.writeFloat(vec.x);
				byteArray.writeFloat(vec.y);
				byteArray.writeFloat(vec.z);

				vec = vertex.tangent;
				byteArray.writeFloat(vec.x);
				byteArray.writeFloat(vec.y);
				byteArray.writeFloat(vec.z);
				byteArray.writeFloat(vec.w);
			}
			mesh.geometry = new Geometry;
			mesh.geometry._indices = indices;
			mesh.geometry.addVertexStream([
				VertexAttributes.POSITION,
				VertexAttributes.POSITION,
				VertexAttributes.POSITION,
				VertexAttributes.TEXCOORDS[0],
				VertexAttributes.TEXCOORDS[0],
				VertexAttributes.NORMAL,
				VertexAttributes.NORMAL,
				VertexAttributes.NORMAL,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4,
				VertexAttributes.TANGENT4
			]);
			mesh.geometry._vertexStreams[0].data = byteArray;
			mesh.geometry._numVertices = numVertices;
			if (objectData.surfaces != null) {
				for (var key:String in objectData.surfaces) {
					var materialData:MaterialData = materialDatas[key];
					mesh.addSurface(materialData.material, 3*materialData.indexBegin, materialData.numTriangles);
				}
			}
			if (defaultMaterialData.numTriangles > 0) {
				mesh.addSurface(defaultMaterialData.material, 3*defaultMaterialData.indexBegin, defaultMaterialData.numTriangles);
			}
			mesh.calculateBoundBox();
		}

		private function buildInitialGeometry(vertices:Vector.<Vertex>, faces:Vector.<Face>, objectData:ObjectData, animationData:AnimationData, scale:Number):void {
			var correct:Boolean = false;
			if (animationData != null) {
				var a:Number = objectData.a;
				var b:Number = objectData.b;
				var c:Number = objectData.c;
				var d:Number = objectData.d;
				var e:Number = objectData.e;
				var f:Number = objectData.f;
				var g:Number = objectData.g;
				var h:Number = objectData.h;
				var i:Number = objectData.i;
				var j:Number = objectData.j;
				var k:Number = objectData.k;
				var l:Number = objectData.l;
				var det:Number = 1/(-c*f*i + b*g*i + c*e*j - a*g*j - b*e*k + a*f*k);
				objectData.a = (-g*j + f*k)*det;
				objectData.b = (c*j - b*k)*det;
				objectData.c = (-c*f + b*g)*det;
				objectData.d = (d*g*j - c*h*j - d*f*k + b*h*k + c*f*l - b*g*l)*det;
				objectData.e = (g*i - e*k)*det;
				objectData.f = (-c*i + a*k)*det;
				objectData.g = (c*e - a*g)*det;
				objectData.h = (c*h*i - d*g*i + d*e*k - a*h*k - c*e*l + a*g*l)*det;
				objectData.i = (-f*i + e*j)*det;
				objectData.j = (b*i - a*j)*det;
				objectData.k = (-b*e + a*f)*det;
				objectData.l = (d*f*i - b*h*i - d*e*j + a*h*j + b*e*l - a*f*l)*det;
				if (animationData.pivot != null) {
					objectData.d -= animationData.pivot.x;
					objectData.h -= animationData.pivot.y;
					objectData.l -= animationData.pivot.z;
				}
				correct = true;
			}
			// Creation and correcting of vertices
			var n:int, m:int, p:int, len:int = objectData.vertices.length;
			var uv:Boolean = objectData.uvs != null && objectData.uvs.length > 0;
			for (n = 0, m = 0, p = 0; n < len;) {
				var vertex:Vertex = new Vertex;
				if (correct) {
					var x:Number = objectData.vertices[n++];
					var y:Number = objectData.vertices[n++];
					var z:Number = objectData.vertices[n++];
					vertex.x = objectData.a*x + objectData.b*y + objectData.c*z + objectData.d;
					vertex.y = objectData.e*x + objectData.f*y + objectData.g*z + objectData.h;
					vertex.z = objectData.i*x + objectData.j*y + objectData.k*z + objectData.l;
				} else {
					vertex.x = objectData.vertices[n++];
					vertex.y = objectData.vertices[n++];
					vertex.z = objectData.vertices[n++];
				}
				vertex.x *= scale;
				vertex.y *= scale;
				vertex.z *= scale;
				if (uv) {
					vertex.u = objectData.uvs[m++];
					vertex.v = 1 - objectData.uvs[m++];
				} else {
					// If you leave object without uv, then the calculation of tangents is breaks
					x = vertex.x;
					y = vertex.y;
					var rxy:Number = 1e-5 + Math.sqrt(x*x + y*y);
					vertex.u = Math.atan2(rxy, vertex.z);
					vertex.v = Math.atan2(y, x);
				}
				vertices[p++] = vertex;
			}
			// Create faces
			len = objectData.faces.length;
			for (n = 0, p = 0; n < len;) {
				var face:Face = new Face();
				face.a = objectData.faces[n++];
				face.b = objectData.faces[n++];
				face.c = objectData.faces[n++];
				face.smoothGroup = objectData.smoothGroups[p];
				faces[p++] = face;
			}
		}

		private function cloneVerticesToRespectSmoothGroups(vertices:Vector.<Vertex>, faces:Vector.<Face>):void {
			// Actions with smoothing groups:
			// - if vertex is in faces with groups 1+2 and 3, then it is duplicated
			// - if vertex is in faces with groups 1+2, 3 and 1+3, then it is not duplicated

			var n:int, m:int, p:int, q:int, len:int, numVertices:int = vertices.length, numFaces:int = faces.length;
			// Calculate disjoint groups for vertices
			var vertexGroups:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVertices, true);
			for (p = 0; p < numVertices; p++) {
				vertexGroups [p] = new Vector.<uint>;
			}
			for (n = 0; n < numFaces; n++) {
				var face:Face = Face(faces[n]);
				for (m = 0; m < 3; m++) {
					var groups:Vector.<uint> = vertexGroups [(m == 0) ? face.a : ((m == 1) ? face.b : face.c)];
					var group:uint = face.smoothGroup;
					for (q = groups.length - 1; q >= 0; q--) {
						if ((group & groups [q]) > 0) {
							group |= groups [q];
							groups.splice(q, 1);
							q = groups.length - 1;
						}
					}
					groups.push(group);
				}
			}
			// Clone vertices
			var vertexClones:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVertices, true);
			for (p = 0; p < numVertices; p++) {
				if ((len = vertexGroups [p].length) < 1) continue;
				var clones:Vector.<uint> = new Vector.<uint>(len, true);
				vertexClones [p] = clones;
				clones [0] = p;
				var vertex0:Vertex = vertices [p];
				for (m = 1; m < len; m++) {
					var vertex1:Vertex = new Vertex;
					vertex1.x = vertex0.x;
					vertex1.y = vertex0.y;
					vertex1.z = vertex0.z;
					vertex1.u = vertex0.u;
					vertex1.v = vertex0.v;
					clones[m] = vertices.length;
					vertices.push(vertex1);
				}
			}
			numVertices = vertices.length;

			// Loop on faces
			for (n = 0; n < numFaces; n++) {
				face = Face(faces [n]);
				group = face.smoothGroup;

				for (m = 0; m < 3; m++) {
					p = (m == 0) ? face.a : ((m == 1) ? face.b : face.c);
					groups = vertexGroups [p];
					len = groups.length;
					clones = vertexClones [p];
					for (q = 0; q < len; q++) {
						if (((group == 0) && (groups [q] == 0)) ||
								((group & groups [q]) > 0)) {
							var index:uint = clones [q];
							if (group == 0) {
								// In case of there is no smoothing group, vertices of this face is unique
								groups.splice(q, 1);
								clones.splice(q, 1);
							}
							if (m == 0) face.a = index; else
							if (m == 1) face.b = index; else
								face.c = index;
							q = len;
						}
					}
				}
			}
		}

		private function cloneAndTransformVerticesToRespectUVTransforms(vertices:Vector.<Vertex>, faces:Vector.<Face>):void {
			// Actions with UV transformation
			//  if vertex in faces with different transform materials, then it is duplicated
			var n:int, m:int, p:int, q:int, len:int, numVertices:int = vertices.length, numFaces:int = faces.length;
			// Find transform materials for vertices
			var vertexGroups:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVertices, true);
			for (p = 0; p < numVertices; p++) {
				vertexGroups [p] = new Vector.<uint>;
			}
			for (n = 0; n < numFaces; n++) {
				var face:Face = Face(faces [n]);
				for (m = 0; m < 3; m++) {
					var groups:Vector.<uint> = vertexGroups [(m == 0) ? face.a : ((m == 1) ? face.b : face.c)];
					var group:uint = face.uvTransformGroup;
					if (groups.indexOf(group) < 0) groups.push(group);
				}
			}
			// Clone vertices
			var vertexClones:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(numVertices, true);
			for (p = 0; p < numVertices; p++) {
				if ((len = vertexGroups [p].length) < 1) continue;
				var clones:Vector.<uint> = new Vector.<uint>(len, true);
				vertexClones [p] = clones;
				clones [0] = p;
				var vertex0:Vertex = vertices [p];
				for (m = 1; m < len; m++) {
					var vertex1:Vertex = new Vertex;
					vertex1.x = vertex0.x;
					vertex1.y = vertex0.y;
					vertex1.z = vertex0.z;
					vertex1.u = vertex0.u;
					vertex1.v = vertex0.v;
					vertex1.normal = vertex0.normal;
					clones [m] = vertices.length;
					vertices.push(vertex1);
				}
			}
			numVertices = vertices.length;
			// Parse on faces, and apply the transformation
			for (n = 0; n < numFaces; n++) {
				face = Face(faces [n]);
				group = face.uvTransformGroup;

				var materialData:MaterialData = materialDatas[face.surfaceName];

				for (m = 0; m < 3; m++) {
					p = (m == 0) ? face.a : ((m == 1) ? face.b : face.c);
					groups = vertexGroups [p];
					len = groups.length;
					clones = vertexClones [p];
					q = groups.indexOf(group); // must aways be in groups
					var index:uint = clones [q];
					if (m == 0) face.a = index; else
					if (m == 1) face.b = index; else
						face.c = index;

					if (group > 0) {
						vertex0 = vertices [index];
						if (vertex0.nonTransformed) {
							vertex0.nonTransformed = false;
							var u:Number = vertex0.u;
							var v:Number = vertex0.v;
							vertex0.u = materialData.matrix.a*u + materialData.matrix.b*v + materialData.matrix.tx;
							vertex0.v = materialData.matrix.c*u + materialData.matrix.d*v + materialData.matrix.ty;
						}
					}
				}
			}
		}

		private function calculateVertexNormals(vertices:Vector.<Vertex>, faces:Vector.<Face>):void {
			var n:int, m:int, numFaces:int = faces.length;
			for (n = 0; n < numFaces; n++) {
				var face:Face = Face(faces [n]);

				// Calculation of average normals of vertices
				var vertex0:Vertex = vertices [face.a];
				var vertex1:Vertex = vertices [face.b];
				var vertex2:Vertex = vertices [face.c];

				var deltaX1:Number = vertex1.x - vertex0.x;
				var deltaY1:Number = vertex1.y - vertex0.y;
				var deltaZ1:Number = vertex1.z - vertex0.z;
				var deltaX2:Number = vertex2.x - vertex0.x;
				var deltaY2:Number = vertex2.y - vertex0.y;
				var deltaZ2:Number = vertex2.z - vertex0.z;

				face.deltaX1 = deltaX1;
				face.deltaY1 = deltaY1;
				face.deltaZ1 = deltaZ1;
				face.deltaX2 = deltaX2;
				face.deltaY2 = deltaY2;
				face.deltaZ2 = deltaZ2;

				var normalX:Number = deltaZ2*deltaY1 - deltaY2*deltaZ1;
				var normalY:Number = deltaX2*deltaZ1 - deltaZ2*deltaX1;
				var normalZ:Number = deltaY2*deltaX1 - deltaX2*deltaY1;

				var normalLen:Number = 1e-5 + Math.sqrt(normalX*normalX + normalY*normalY + normalZ*normalZ);
				normalX = normalX/normalLen;
				normalY = normalY/normalLen;
				normalZ = normalZ/normalLen;

				for (m = 0; m < 3; m++) {
					var vertex:Vertex = (m == 0) ? vertex0 : ((m == 1) ? vertex1 : vertex2);
					if (vertex.normal == null) {
						vertex.normal = new Vector3D(normalX, normalY, normalZ);
					} else {
						var vec:Vector3D = vertex.normal;
						vec.x += normalX;
						vec.y += normalY;
						vec.z += normalZ;
					}
				}
			}
		}

		private function calculateVertexTangents(vertices:Vector.<Vertex>, faces:Vector.<Face>):void {
			var n:int, m:int, numVertices:int = vertices.length, numFaces:int = faces.length;
			for (n = 0; n < numFaces; n++) {
				var face:Face = Face(faces [n]);

				// Calculation of average tangents of vertices
				var vertex0:Vertex = vertices [face.a];
				var vertex1:Vertex = vertices [face.b];
				var vertex2:Vertex = vertices [face.c];

				var deltaU1:Number = vertex1.u - vertex0.u;
				var deltaV1:Number = vertex0.v - vertex1.v;
				var deltaU2:Number = vertex2.u - vertex0.u;
				var deltaV2:Number = vertex0.v - vertex2.v;

				// Inverse determinant is included to the formulas below as common multiplier.
				// Its value is insignificantly, because vectors are normalized
				//var invdet:Number = 1 / (deltaU1 * deltaV2 - deltaU2 * deltaV1);
				//if (invdet > 1e9) invdet = 1e9; else if (invdet < -1e9) invdet = -1e9;

				var deltaX1:Number = face.deltaX1;
				var deltaY1:Number = face.deltaY1;
				var deltaZ1:Number = face.deltaZ1;
				var deltaX2:Number = face.deltaX2;
				var deltaY2:Number = face.deltaY2;
				var deltaZ2:Number = face.deltaZ2;

				var stMatrix00:Number = (deltaV2)//*invdet;
				var stMatrix01:Number = -(deltaV1)//*invdet;
				var stMatrix10:Number = -(deltaU2)//*invdet;
				var stMatrix11:Number = (deltaU1)//*invdet;

				var tangentX:Number = stMatrix00*deltaX1 + stMatrix01*deltaX2;
				var tangentY:Number = stMatrix00*deltaY1 + stMatrix01*deltaY2;
				var tangentZ:Number = stMatrix00*deltaZ1 + stMatrix01*deltaZ2;

				var biTangentX:Number = stMatrix10*deltaX1 + stMatrix11*deltaX2;
				var biTangentY:Number = stMatrix10*deltaY1 + stMatrix11*deltaY2;
				var biTangentZ:Number = stMatrix10*deltaZ1 + stMatrix11*deltaZ2;

				var tangentLen:Number = 1e-5 + Math.sqrt(tangentX*tangentX + tangentY*tangentY + tangentZ*tangentZ);
				tangentX = tangentX/tangentLen;
				tangentY = tangentY/tangentLen;
				tangentZ = tangentZ/tangentLen;

				var biTangentLen:Number = 1e-5 + Math.sqrt(biTangentX*biTangentX + biTangentY*biTangentY + biTangentZ*biTangentZ);
				biTangentX = biTangentX/biTangentLen;
				biTangentY = biTangentY/biTangentLen;
				biTangentZ = biTangentZ/biTangentLen;

				for (m = 0; m < 3; m++) {
					var vertex:Vertex = (m == 0) ? vertex0 : ((m == 1) ? vertex1 : vertex2);
					if (vertex.tangent == null) {
						vertex.tangent = new Vector3D(tangentX, tangentY, tangentZ);
						vertex.biTangent = new Vector3D(biTangentX, biTangentY, biTangentZ);
					} else {
						var vec:Vector3D;
						vec = vertex.tangent;
						vec.x += tangentX;
						vec.y += tangentY;
						vec.z += tangentZ;
						vec = vertex.biTangent;
						vec.x += biTangentX;
						vec.y += biTangentY;
						vec.z += biTangentZ;
					}
				}
			}

			// orthonormalize TBN's
			var normalX:Number, normalY:Number, normalZ:Number, dot:Number, vec2:Vector3D;
			for (n = 0; n < numVertices; n++) {
				vertex = vertices [n];
				if (vertex.normal == null) {
					vertex.normal = Vector3D.X_AXIS;
					vertex.tangent = Vector3D.Y_AXIS.clone();
					vertex.tangent.w = 1;
				} else {
					vec = vertex.normal;
					vec.normalize();
					normalX = vec.x;
					normalY = vec.y;
					normalZ = vec.z;

					vec = vertex.tangent;
					tangentX = vec.x;
					tangentY = vec.y;
					tangentZ = vec.z;

					dot = normalX*tangentX + normalY*tangentY + normalZ*tangentZ;

					// perform orthonormalization between normal and tangent: tangent -= normal*dot;
					tangentX -= normalX*dot;
					tangentY -= normalY*dot;
					tangentZ -= normalZ*dot;

					tangentLen = tangentX*tangentX + tangentY*tangentY + tangentZ*tangentZ;
					if (tangentLen > 0) {
						tangentLen = Math.sqrt(tangentLen);
						vec.x = tangentX/tangentLen;
						vec.y = tangentY/tangentLen;
						vec.z = tangentZ/tangentLen;

						// calculate direction of bi-normal
						var crossX:Number = normalY*tangentZ - normalZ*tangentY;
						var crossY:Number = normalZ*tangentX - normalX*tangentZ;
						var crossZ:Number = normalX*tangentY - normalY*tangentX;

						vec2 = vertex.biTangent;

						dot = crossX*vec2.x + crossY*vec2.y + crossZ*vec2.z;
						vec.w = (dot < 0) ? -1 : 1;
					} else {
						// tangent is degenerate, try to start  from bi-normal
						vec = vertex.biTangent;
						biTangentX = vec.x;
						biTangentY = vec.y;
						biTangentZ = vec.z;

						dot = normalX*biTangentX + normalY*biTangentY + normalZ*biTangentZ;

						// perform orthonormalization between normal and bi-normal: biTangent -= normal*dot;
						biTangentX -= normalX*dot;
						biTangentY -= normalY*dot;
						biTangentZ -= normalZ*dot;

						biTangentLen = biTangentX*biTangentX + biTangentY*biTangentY + biTangentZ*biTangentZ;
						if (biTangentLen > 0) {
							biTangentLen = Math.sqrt(biTangentLen);
							vec.x = biTangentX/biTangentLen;
							vec.y = biTangentY/biTangentLen;
							vec.z = biTangentZ/biTangentLen;
						} else {
							// bi-normal is degenerate too, get any vector that is perpendicular to the normal
							if (normalX != 0) {
								vec.x = -normalY;
								vec.y = normalX;
								vec.z = 0;
							} else {
								vec.x = 0;
								vec.y = -normalZ;
								vec.z = normalY;
							}
						}

						// calculate tangent
						biTangentX = vec.x;
						biTangentY = vec.y;
						biTangentZ = vec.z;

						vec = vertex.tangent;
						vec.x = -(normalY*biTangentZ - normalZ*biTangentY);
						vec.y = -(normalZ*biTangentX - normalX*biTangentZ);
						vec.z = -(normalX*biTangentY - normalY*biTangentX);

						dot = biTangentX*vec.x + biTangentY*vec.y + biTangentZ*vec.z;
						vec.w = (dot < 0) ? -1 : 1;
					}
				}
			}
		}

		private function assignMaterialsToFaces(faces:Vector.<Face>, objectData:ObjectData):void {
			// Assign materials
			if (objectData.surfaces != null) {
				for (var key:String in objectData.surfaces) {
					var surface:Vector.<uint> = objectData.surfaces[key];
					// Get serial number of material for sorting
					var surfaceIndex:uint = surface.pop();
					var materialData:MaterialData = materialDatas[key];
					for (var n:int = 0; n < surface.length; n++) {
						var face:Face = faces[surface[n]];
						face.surface = surfaceIndex;
						face.surfaceName = key;
						// If it need to correct UV-coordianates
						face.uvTransformGroup = (materialData.matrix != null) ? surfaceIndex : 0;
					}
				}
			}
		}

		private function sortFacesBySurface(a:Vector.<Face>, left:int, right:int):void {
			var pivot:uint, tmp:Face;
			var i:int = left;
			var j:int = right;
			pivot = a[int((left + right) >> 1)].surface;
			while (i <= j) {
				while (a[i].surface < pivot) i++;
				while (a[j].surface > pivot) j--;
				if (i <= j) {
					tmp = a[i];
					a[i] = a[j];
					i++;
					a[j] = tmp;
					j--;
				}
			}
			if (left < j) sortFacesBySurface(a, left, j);
			if (i < right) sortFacesBySurface(a, i, right);
		}

		private function collectFacesIntoSurfaces(faces:Vector.<Face>, defaultMaterialData:MaterialData):Vector.<uint> {
			var numFaces:int = faces.length;
			// Sort faces on materials
			if (numFaces) sortFacesBySurface(faces, 0, numFaces - 1);

			// Create indices, calculate indexBegin and numTriangles
			var indices:Vector.<uint> = new Vector.<uint>(numFaces*3, true);

			var lastMaterialData:MaterialData;
			for (var n:int = 0; n < numFaces; n++) {
				var face:Face = Face(faces [n]);

				var m:int = n*3;
				indices [m] = face.a;
				indices [m + 1] = face.b;
				indices [m + 2] = face.c;

				var materialData:MaterialData = defaultMaterialData;
				if (face.surfaceName != null) {
					materialData = materialDatas[face.surfaceName];
				}
				if (lastMaterialData != materialData) {
					lastMaterialData = materialData;
					materialData.indexBegin = n;
					materialData.numTriangles = 1;
				} else {
					materialData.numTriangles++;
				}
			}
			return indices;
		}
	}
}

import alternativa.engine3d.core.Object3D;
import alternativa.engine3d.loaders.ParserMaterial;

import flash.geom.Matrix;
import flash.geom.Vector3D;

class MaterialData {
	public var name:String;
	public var ambient:uint;
	public var diffuse:uint;
	public var specular:uint;
	public var glossiness:uint;
	public var transparency:uint;
	public var matrix:Matrix;
	public var material:ParserMaterial;

	public var maps:Vector.<MapData> = new Vector.<MapData>();

	public function get diffuseMap():MapData {
		for each (var map:MapData in maps) {
			if (map.channel == "diffuse") {
				return map;
			}
		}
		return null;
	}

	// parameters for Mesh.addSurface()
	public var indexBegin:uint;
	public var numTriangles:uint;
}

class MapData {
	public var channel:String;
	public var filename:String;
	public var scaleU:Number = 1;
	public var scaleV:Number = 1;
	public var offsetU:Number = 0;
	public var offsetV:Number = 0;
	public var rotation:Number = 0;
}

class ObjectData {
	public var name:String;
	// mesh
	public var vertices:Vector.<Number>;
	public var uvs:Vector.<Number>;
	public var faces:Vector.<int>;
	public var surfaces:Object;
	public var surfacesCount:uint;
	public var smoothGroups:Vector.<uint>;
	public var a:Number;
	public var b:Number;
	public var c:Number;
	public var d:Number;
	public var e:Number;
	public var f:Number;
	public var g:Number;
	public var h:Number;
	public var i:Number;
	public var j:Number;
	public var k:Number;
	public var l:Number;
	// light or camera
	public var lightColor:int = -1;
	public var lightOff:Boolean;
	public var attenuationOn:Boolean;
	public var hotspot:Number = 0;
	public var falloff:Number = 0;
	public var innerRange:Number = 0;
	public var outerRange:Number = Number.MAX_VALUE;
	public var multiplier:Number = 1;
	public var position:Vector3D;
	public var target:Vector3D;
	public var bank:Number = 0;
	public var lens:Number;
}

class AnimationData {
	public var chunkId:uint;
	public var objectName:String;
	public var object:Object3D;
	public var parentIndex:int;
	public var pivot:Vector3D;
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scale:Vector3D;
	public var instanceOf:String;
}

class ChunkInfo {
	public var id:int;
	public var size:int;
	public var dataSize:int;
	public var dataPosition:int;
	public var nextChunkPosition:int;
}

class Vertex {
	public var x:Number;
	public var y:Number;
	public var z:Number;
	public var u:Number;
	public var v:Number;
	public var nonTransformed:Boolean = true;
	public var normal:Vector3D;
	public var tangent:Vector3D;
	public var biTangent:Vector3D;
}

class Face {
	public var a:uint;
	public var b:uint;
	public var c:uint;
	public var surface:uint;
	public var surfaceName:String;
	public var smoothGroup:uint;
	public var uvTransformGroup:uint;
	public var deltaX1:Number;
	public var deltaY1:Number;
	public var deltaZ1:Number;
	public var deltaX2:Number;
	public var deltaY2:Number;
	public var deltaZ2:Number;
}
