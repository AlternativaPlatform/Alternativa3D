package alternativa.engine3d.utils {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.EnvironmentMaterial;
	import alternativa.engine3d.materials.GlassMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TrimMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.ATFTextureResource;
	import alternativa.engine3d.resources.BitmapCubeTextureResource;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.Resource;
	import alternativa.engine3d.resources.TextureResource;

	import avmplus.getQualifiedClassName;

	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;
	/**
	 * With Resource Manager you can improve GPU-memory usage. It compares each resource and returns link on unique one.
	 * You can register/unregister you objects, meshes, textures, geometries, materials.
	 * Use uploadResources(target, resourceType)/disposeResources(target, resourceType) for uploading/disposing resources
	 * Unregister geometry before updating vertexbuffer and indexbuffer, and register after
	 * Unregister texture resource before updating, and register after
	 */
	public class ResourceManager {
		/**
		 * @private
		 */
		private static const resourceVector : Vector.<Resource> = new Vector.<Resource>();

		/**
		 * @private
		 */
		private static const resourceDictionary : Dictionary = new Dictionary();

		/**
		 * @private
		 */
		private static const compareVectorTarget : Vector.<Number> = new Vector.<Number>();

		/**
		 * @private
		 */
		private static const compareVectorSource : Vector.<Number> = new Vector.<Number>();

		/**
		 * @private
		 */
		private static var instance : ResourceManager;

		/**
		 * @private
		 */
		private const geometries : Dictionary = new Dictionary();

		/**
		 * @private
		 */
		private const textures : Dictionary = new Dictionary();

		/**
		 * Unused resources will be disposed automatically
		 */
		public var autoDisposeResources : Boolean = true;

		public static function getInstance() : ResourceManager {
			if (instance != null) {
				return instance;
			}
			instance = new ResourceManager(new Singletoniser());
			return instance;
		}

		function ResourceManager(singletoniser : Singletoniser) {
			if (singletoniser == null) {
				throw new Error("Singleton is a singleton class, use getInstance() instead.");
			}
		}

		/**
		 * Clear all maps
		 */
		public function clear() : void {
			cleanDictionary(geometries);
			cleanDictionary(textures);
		}

		/**
		 * Register all resources inside
		 * @param object
		 */
		public function registerObject3D(object : Object3D) : void {
			if (!object) return;

			const mesh : Mesh = object as Mesh;
			if (mesh) {
				registerMesh(mesh);
				return;
			}

			for (var current : Object3D = object.childrenList; current != null; current = current.next) {
				registerObject3D(current);
			}
		}

		/**
		 * Register mesh geometry all materials
		 * @param mesh
		 */
		public function registerMesh(mesh : Mesh) : void {
			if (!mesh) return;
			mesh.geometry = registerGeometry(mesh.geometry);

			const length : uint = mesh._surfacesLength;
			for (var i : uint = 0; i < length; i++) {
				const surface : Surface = mesh._surfaces[i];
				const material : Material = surface.material;
				if (material) {
					registerMaterial(material);
				}
			}
		}

		/**
		 * Register all resources of material and set unique resource links 
		 * @param material
		 */
		public function registerMaterial(material : Material) : void {
			switch((material as Object).constructor) {
				case StandardMaterial:
					const standardMaterial : StandardMaterial = material as StandardMaterial;
					standardMaterial.diffuseMap = registerTextureResource(standardMaterial.diffuseMap);
					standardMaterial.normalMap = registerTextureResource(standardMaterial.normalMap);
					standardMaterial.specularMap = registerTextureResource(standardMaterial.specularMap);
					standardMaterial.glossinessMap = registerTextureResource(standardMaterial.glossinessMap);
					standardMaterial.opacityMap = registerTextureResource(standardMaterial.opacityMap);
					break;
				case TrimMaterial:
					const trimMaterial : TrimMaterial = material as TrimMaterial;
					trimMaterial.diffuseMap = registerTextureResource(trimMaterial.diffuseMap);
					trimMaterial.normalMap = registerTextureResource(trimMaterial.normalMap);
					trimMaterial.specularMap = registerTextureResource(trimMaterial.specularMap);
					trimMaterial.glossinessMap = registerTextureResource(trimMaterial.glossinessMap);
					trimMaterial.opacityMap = registerTextureResource(trimMaterial.opacityMap);
					break;
				case EnvironmentMaterial:
					const environmentMaterial : EnvironmentMaterial = material as EnvironmentMaterial;
					environmentMaterial.diffuseMap = registerTextureResource(environmentMaterial.diffuseMap);
					environmentMaterial.environmentMap = registerTextureResource(environmentMaterial.environmentMap);
					environmentMaterial.normalMap = registerTextureResource(environmentMaterial.normalMap);
					environmentMaterial.reflectionMap = registerTextureResource(environmentMaterial.reflectionMap);
					environmentMaterial.lightMap = registerTextureResource(environmentMaterial.lightMap);
					environmentMaterial.opacityMap = registerTextureResource(environmentMaterial.opacityMap);
					break;
				case GlassMaterial:
					const glassMaterial : GlassMaterial = material as GlassMaterial;
					glassMaterial.diffuseMap = registerTextureResource(glassMaterial.diffuseMap);
					glassMaterial.environmentMap = registerTextureResource(glassMaterial.environmentMap);
					glassMaterial.normalMap = registerTextureResource(glassMaterial.normalMap);
					glassMaterial.reflectionMap = registerTextureResource(glassMaterial.reflectionMap);
					glassMaterial.lightMap = registerTextureResource(glassMaterial.lightMap);
					glassMaterial.opacityMap = registerTextureResource(glassMaterial.opacityMap);
					break;
				case TextureMaterial:
					const textureMaterial : TextureMaterial = material as TextureMaterial;
					textureMaterial.diffuseMap = registerTextureResource(textureMaterial.diffuseMap);
					textureMaterial.opacityMap = registerTextureResource(textureMaterial.opacityMap);
					break;
				default:
			}
		}

		/**
		 * Register texture resource
		 * @param resource
		 */
		public function registerTextureResource(resource : TextureResource) : TextureResource {
			if (!resource) return null;
			if (textures[resource] != undefined) {
				textures[resource] = textures[resource] + 1;
				return resource;
			}
			var result : TextureResource;
			switch((resource as Object).constructor) {
				case BitmapTextureResource:
					result = registerBitmapTextureResource(resource as BitmapTextureResource);
					break;
				case ATFTextureResource:
					// TODO:
					return resource;
					break;
				case BitmapCubeTextureResource:
					// TODO:
					return resource;
					break;
				default:
			}
			if (result == resource) {
				textures[result] = 1;
			} else {
				textures[result] = textures[result] + 1;
			}
			return result;
		}

		/**
		 * @private
		 */
		private function registerBitmapTextureResource(resource : BitmapTextureResource) : BitmapTextureResource {
			if (!resource) return null;
			const bitmapData : BitmapData = resource.data;
			if (!bitmapData) return resource;
			for (var obj:Object in textures) {
				const current : BitmapTextureResource = obj as BitmapTextureResource;
				if (!current) continue;
				const source : BitmapData = current.data;
				if (!source) continue;
				if ((source.width != bitmapData.width) || (source.height != bitmapData.height)) continue;
				if (source.compare(bitmapData) != 0) continue;
				return current;
			}
			return resource;
		}

		/**
		 * Get unique link on BitmapTextureResource with same bitmapData content
		 * @param bitmapData
		 */
		public function registerBitmapData(bitmapData : BitmapData) : BitmapTextureResource {
			if (!bitmapData) return null;
			for (var obj:Object in textures) {
				const current : BitmapTextureResource = obj as BitmapTextureResource;
				if (!current) continue;
				const source : BitmapData = current.data;
				if (!source) continue;
				if ((source.width != bitmapData.width) || (source.height != bitmapData.height)) continue;
				if (source.compare(bitmapData) != 0) continue;
				textures[current] = textures[current] + 1;
				return current;
			}
			var result : BitmapTextureResource = new BitmapTextureResource(bitmapData);
			textures[result] = 1;
			return result;
		}

		/**
		 * Get unique link on geometry
		 * @param geometry
		 */
		public function registerGeometry(geometry : Geometry) : Geometry {
			if (!geometry) return null;
			if (geometries[geometry] != undefined) {
				geometries[geometry] = geometries[geometry] + 1;
				return geometry;
			}
			compareVectorTarget.length = 0;
			for (var obj:Object in geometries) {
				var current : Geometry = obj as Geometry;
				if (!current) continue;
				if (current.numTriangles != geometry.numTriangles) continue;
				if (current.numVertices != geometry.numVertices) continue;
				compareVectorSource.length = 0;
				current.getAttributeValues(VertexAttributes.POSITION, compareVectorSource);
				if (compareVectorTarget.length == 0) geometry.getAttributeValues(VertexAttributes.POSITION, compareVectorTarget);
				if (!compareTwoVectors(compareVectorSource, compareVectorTarget)) continue;
				geometries[current] = geometries[current] + 1;
				return current;
			}
			geometries[geometry] = 1;
			return geometry;
		}

		/**
		 * Unregister all resources inside
		 * @param object
		 */
		public function unregisterObject3D(object : Object3D) : void {
			object.getResources(true, null, resourceVector, resourceDictionary);
			for each (var resource:Resource in resourceVector) {
				unregisterResource(resource);
			}
			resourceVector.length = 0;
			cleanDictionary(resourceDictionary);
		}

		/**
		 * Unregister all texture resources of material
		 * @param material
		 */
		public function unregisterMaterial(material : TextureMaterial) : void {
			material.getResources(null, resourceVector, resourceDictionary);
			for each (var resource:Resource in resourceVector) {
				unregisterResource(resource);
			}
			resourceVector.length = 0;
			cleanDictionary(resourceDictionary);
		}

		/**
		 * Unregister resource
		 * @param resource 
		 */
		public function unregisterResource(resource : Resource) : void {
			if (!resource) return;
			var dictionary : Dictionary;

			if (A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(resource)) as Class, TextureResource)) {
				dictionary = textures;
			} else if (A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(resource)) as Class, Geometry)) {
				dictionary = geometries;
			}

			if (dictionary[resource] == undefined) return;
			var count : uint = dictionary[resource] = dictionary[resource] - 1;
			if (count == 0 && autoDisposeResources) {
				dictionary[resource] = null;
				resource.dispose();
			}
			dictionary = null;
		}

		/**
		 * Upload resources on GPU
		 * @param source
		 * @param resourceType
		 */
		public static function uploadResources(source : Object3D, resourceType : Class = null) : void {
			if (!source) return;
			if (!context3d) return;
			for each (var r : Resource in source.getResources(true, resourceType, resourceVector, resourceDictionary)) {
				if (r.isUploaded) continue;
				r.upload(context3d);
			}
			resourceVector.length = 0;
			cleanDictionary(resourceDictionary);
		}

		/**
		 * Dispose resources
		 * @param source
		 * @param resourceType
		 */
		public static function disposeResources(source : Object3D, resourceType : Class = null) : void {
			for each (var r : Resource in source.getResources(true, resourceType, resourceVector, resourceDictionary)) {
				r.dispose();
			}
			resourceVector.length = 0;
			cleanDictionary(resourceDictionary);
		}

		private static function compareTwoVectors(source : Vector.<Number>, target : Vector.<Number>) : Boolean {
			const lengthSource : uint = source.length;
			const lengthTarget : uint = target.length;
			if (lengthSource != lengthTarget) return false;
			for (var i : uint = 0; i < lengthSource; i += 3) {
				if (source[i] != target[i]) return false;
				if (source[i + 1] != target[i + 1]) return false;
				if (source[i + 2] != target[i + 2]) return false;
			}
			return true;
		}

		private static function cleanDictionary(source : Dictionary) : void {
			for (var key:* in source) {
				delete source[key];
			}
		}
	}
}
class Singletoniser {
}
