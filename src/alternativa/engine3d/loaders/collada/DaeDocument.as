/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	/**
	 * @private
	 */
	public class DaeDocument {

		use namespace collada;

		public var scene:DaeVisualScene;

		/**
		 * Collada file
		 */
		private var data:XML;

		// Dictionaries to store matchings id-> DaeElement
		public var sources:Object;
		internal var arrays:Object;
		internal var vertices:Object;
		public var geometries:Object;
		internal var nodes:Object;
		internal var lights:Object;
		internal var images:Object;
		internal var effects:Object;
		public var controllers:Object;
		internal var samplers:Object;

		public var channels:Vector.<DaeChannel>;

		public var materials:Object;

		internal var logger:DaeLogger;

		public var versionMajor:uint;
		public var versionMinor:uint;
		public var unitScaleFactor:Number = 1;
		public function DaeDocument(document:XML, units:Number) {
			this.data = document;

			var versionComponents:Array = data.@version[0].toString().split(/[.,]/);
			versionMajor = parseInt(versionComponents[1], 10);
			versionMinor = parseInt(versionComponents[2], 10);

			var colladaUnit:Number = parseFloat(data.asset[0].unit[0].@meter);
			if (units > 0) {
				unitScaleFactor = colladaUnit/units;
			} else {
				unitScaleFactor = 1;
			}

			logger = new DaeLogger();

			constructStructures();
			constructScenes();
			registerInstanceControllers();
			constructAnimations();
		}

		private function getLocalID(url:XML):String {
			var path:String = url.toString();
			if (path.charAt(0) == "#") {
				return path.substr(1);
			} else {
				logger.logExternalError(url);
				return null;
			}
		}

		// Search for the declarations of items and fill the dictionaries.
		private function constructStructures():void {
			var element:XML;

			sources = {};
			arrays = {};
			for each (element in data..source) {
				// Collect all <source>. Dictionary <code>arrays</code> is filled at constructors.
				var source:DaeSource = new DaeSource(element, this);
				if (source.id != null) {
					sources[source.id] = source;
				}
			}

			lights = {};
			for each (element in data.library_lights.light) {
				// Collect all <image>.
				var light:DaeLight = new DaeLight(element, this);
				if (light.id != null) {
					lights[light.id] = light;
				}
			}
			images = {};
			for each (element in data.library_images.image) {
				// Collect all <image>.
				var image:DaeImage = new DaeImage(element, this);
				if (image.id != null) {
					images[image.id] = image;
				}
			}
			effects = {};
			for each (element in data.library_effects.effect) {
				// Collect all <effect>. Dictionary <code>images</code> is filled at constructors.
				var effect:DaeEffect = new DaeEffect(element, this);
				if (effect.id != null) {
					effects[effect.id] = effect;
				}
			}
			materials = {};
			for each (element in data.library_materials.material) {
				// Collect all <material>.
				var material:DaeMaterial = new DaeMaterial(element, this);
				if (material.id != null) {
					materials[material.id] = material;
				}
			}
			geometries = {};
			vertices = {};
			for each (element in data.library_geometries.geometry) {
				// Collect all <geometry>. Dictionary <code>vertices</code> is filled at constructors.
				var geom:DaeGeometry = new DaeGeometry(element, this);
				if (geom.id != null) {
					geometries[geom.id] = geom;
				}
			}

			controllers = {};
			for each (element in data.library_controllers.controller) {
				// Collect all <controllers>.
				var controller:DaeController = new DaeController(element, this);
				if (controller.id != null) {
					controllers[controller.id] = controller;
				}
			}

			nodes = {};
			for each (element in data.library_nodes.node) {
				// Create only root nodes. Others are created recursively at constructors.
				var node:DaeNode = new DaeNode(element, this);
				if (node.id != null) {
					nodes[node.id] = node;
				}
			}
		}

		private function constructScenes():void {
			var vsceneURL:XML = data.scene.instance_visual_scene.@url[0];
			var vsceneID:String = getLocalID(vsceneURL);
			for each (var element:XML in data.library_visual_scenes.visual_scene) {
				// Create visual_scene. node's are created at constructors.
				var vscene:DaeVisualScene = new DaeVisualScene(element, this);
				if (vscene.id == vsceneID) {
					this.scene = vscene;
				}
			}
			if (vsceneID != null && scene == null) {
				logger.logNotFoundError(vsceneURL);
			}
		}

		private function registerInstanceControllers():void {
			if (scene != null) {
				for (var i:int = 0, count:int = scene.nodes.length; i < count; i++) {
					scene.nodes[i].registerInstanceControllers();
				}
			}
		}

		private function constructAnimations():void {
			var element:XML;
			samplers = {};
			for each (element in data.library_animations..sampler) {
				// Collect all <sampler>.
				var sampler:DaeSampler = new DaeSampler(element, this);
				if (sampler.id != null) {
					samplers[sampler.id] = sampler;
				}
			}

			for each (element in data.library_animations..channel) {
				var channel:DaeChannel = new DaeChannel(element, this);
				var node:DaeNode = channel.node;
				if (node != null) {
					node.addChannel(channel);
					if (channels == null) {
						channels = new Vector.<DaeChannel>;
					}
					channels.push (channel);
				}
			}
		}

		public function findArray(url:XML):DaeArray {
			return arrays[getLocalID(url)];
		}

		public function findSource(url:XML):DaeSource {
			return sources[getLocalID(url)];
		}

		public function findLight(url:XML):DaeLight {
			return lights[getLocalID(url)];
		}

		public function findImage(url:XML):DaeImage {
			return images[getLocalID(url)];
		}

		public function findImageByID(id:String):DaeImage {
			return images[id];
		}

		public function findEffect(url:XML):DaeEffect {
			return effects[getLocalID(url)];
		}

		public function findMaterial(url:XML):DaeMaterial {
			return materials[getLocalID(url)];
		}

		public function findVertices(url:XML):DaeVertices {
			return vertices[getLocalID(url)];
		}

		public function findGeometry(url:XML):DaeGeometry {
			return geometries[getLocalID(url)];
		}

		public function findNode(url:XML):DaeNode {
			return nodes[getLocalID(url)];
		}

		public function findNodeByID(id:String):DaeNode {
			return nodes[id];
		}

		public function findController(url:XML):DaeController {
			return controllers[getLocalID(url)];
		}

		public function findSampler(url:XML):DaeSampler {
			return samplers[getLocalID(url)];
		}

	}
}
