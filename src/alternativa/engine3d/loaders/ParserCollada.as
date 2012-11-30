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
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.loaders.collada.DaeDocument;
	import alternativa.engine3d.loaders.collada.DaeElement;
	import alternativa.engine3d.loaders.collada.DaeGeometry;
	import alternativa.engine3d.loaders.collada.DaeMaterial;
	import alternativa.engine3d.loaders.collada.DaeNode;
	import alternativa.engine3d.loaders.collada.DaeObject;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	use namespace alternativa3d;

	/**
	 * A parser performs parsing of collada xml.
	 */
	public class ParserCollada extends Parser {

		/**
		 * List of the light sources
		 */
		public var lights:Vector.<Light3D>;

		/**
		 * Creates a new ParserCollada  instance.
		 */
		public function ParserCollada() {
		}

		/**
		 * Clears all links to external objects.
		 */
		override public function clean():void {
			super.clean();
			lights = null;
		}

		/**
		 * @private
		 * Initialization before the parsing
		 */
		override alternativa3d function init():void {
			super.init();
			//			cameras = new Vector.<Camera3D>();
			lights = new Vector.<Light3D>();
		}

        /**
         * Method parses <code>xml</code> of collada and fills arrays <code>objects</code>,  <code>hierarchy</code>, <code>materials</code>, <code>animations</code>
         * If you need to download textures, use class <code>TexturesLoader</code>.
         * <p>Path to collada file should match with  <code>URI</code> specification. E.g., <code>file:///C:/test.dae</code> or <code>/C:/test.dae</code> for the full paths and  <code>test.dae</code>, <code>./test.dae</code>  in case of relative.</p>
         *
         * @param data <code>XML</code> data type of collada.
         * @param baseURL Path to  textures relative to swf-file (Or file name only in case of <code>trimPaths=true</code>).
         * @param trimPaths Use  file names only, without paths.
         *
         * @see alternativa.engine3d.loaders.TexturesLoader
         * @see #objects
         * @see #hierarchy
         * @see #materials
         */
		public function parse(data:XML, baseURL:String = null, trimPaths:Boolean = false):void {
			init();

			var document:DaeDocument = new DaeDocument(data, 0);
			if (document.scene != null) {
				parseNodes(document.scene.nodes, null, false);
				parseMaterials(document.materials, baseURL, trimPaths);
			}
		}

        /**
         * Method parses <code>xml</code> of collada asynchronously and fills arrays <code>objects</code>,  <code>hierarchy</code>, <code>materials</code>, <code>animations</code>
         * It is slower than <code>parse</code> but does not lock the thread.
		 * If you need to download textures, use class <code>TexturesLoader</code>.
         * <p>Path to collada file should match with  <code>URI</code> specification. E.g., <code>file:///C:/test.dae</code> or <code>/C:/test.dae</code> for the full paths and  <code>test.dae</code>, <code>./test.dae</code>  in case of relative.</p>
         *
		 * @param onComplete Callback function accepting ParserCollada object as its argument.
         * @param data <code>XML</code> data type of collada.
         * @param baseURL Path to  textures relative to swf-file (Or file name only in case of <code>trimPaths=true</code>).
         * @param trimPaths Use  file names only, without paths.
         *
         * @see alternativa.engine3d.loaders.TexturesLoader
         * @see #objects
         * @see #hierarchy
         * @see #materials
         */
		public function parseAsync(onComplete:Function, data:XML, baseURL:String = null, trimPaths:Boolean = false):void {
			init();

			var document:DaeDocument = new DaeDocument(data, 0);
			if (document.scene != null) {
				parseMaterials(document.materials, baseURL, trimPaths);
				addNodesToQueue(document.scene.nodes, null, false);
				
				// parse nodes internal sttructures ahead of time to avoid congestion
				addElementsToQueue(document.controllers);
				addElementsToQueue(document.channels);
				addElementsToQueue(document.geometries);
				for each (var geom:DaeGeometry in document.geometries) {
					addElementsToQueue (geom.primitives);
				}
				addElementsToQueue(document.sources);
				
				parseQueuedElements(onComplete);
			}
		}

		/**
		 * Adds components of animated object to lists objects, parents, hierarchy, cameras, animations  and to parent container.
		 */
		private function addObject(animatedObject:DaeObject, parent:Object3D, layer:String):Object3D {
			var object:Object3D = Object3D(animatedObject.object);
			this.objects.push(object);
			if (parent == null) {
				this.hierarchy.push(object);
			} else {
				parent.addChild(object);
			}
//			if (object is Camera3D) {
//				this.cameras.push(object as Camera3D);
//			}
			if (object is Light3D) {
				lights.push(Light3D(object));
			}
			if (animatedObject.animation != null) {
				this.animations.push(animatedObject.animation);
			}
			if (layer) {
				layersMap[object] = layer;
			}
			return object;
		}

		/**
		 * Adds objects to  objects, parents, hierarchy, cameras and animations  lists and to parent container.
		 *
		 * @return first object
		 */
		private function addObjects(animatedObjects:Vector.<DaeObject>, parent:Object3D, layer:String):Object3D {
			var first:Object3D = addObject(animatedObjects[0], parent, layer);
			for (var i:int = 1, count:int = animatedObjects.length; i < count; i++) {
				addObject(animatedObjects[i], parent, layer);
			}
			return first;
		}

		/**
		 * Check if is there  a skin among child objects.
		 */
		private function hasSkinsInChildren(node:DaeNode):Boolean {
			var nodes:Vector.<DaeNode> = node.nodes;
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var child:DaeNode = nodes[i];
				child.parse();
				if (child.skins != null) {
					return true;
				}
				if (hasSkinsInChildren(child)) {
					return true;
				}
			}
			return false;
		}

		private function parseNodes(nodes:Vector.<DaeNode>, parent:Object3D, skinsOnly:Boolean = false):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				node.parse();

				// Object to which child objects will be added.
				var container:Object3D = null;
				if (node.skins != null) {
					// Main joint of skin
					container = addObjects(node.skins, parent, node.layer);
				} else {
					if (!skinsOnly && !node.skinOrTopmostJoint) {
						if (node.objects != null) {
							container = addObjects(node.objects, parent, node.layer);
						} else {
							// Empty Object3D
							container = new Object3D();
							container.name = node.cloneString(node.name);
							addObject(node.applyAnimation(node.applyTransformations(container)), parent, node.layer);
							container.calculateBoundBox();
						}
					} else {
						// Object or its parent is a skin or joint
						// Create an object  only if there are a child skins
						if (hasSkinsInChildren(node)) {
							container = new Object3D();
							container.name = node.cloneString(node.name);
							addObject(node.applyAnimation(node.applyTransformations(container)), parent, node.layer);
							parseNodes(node.nodes, container, skinsOnly || node.skinOrTopmostJoint);
							container.calculateBoundBox();
						}
					}
				}
				// Parse children
				if (container != null) {
					parseNodes(node.nodes, container, skinsOnly || node.skinOrTopmostJoint);
				}
			}
		}

		private var queue:Vector.<QueueElement> = new Vector.<QueueElement> ();

		private function addNodesToQueue(nodes:Vector.<DaeNode>, parent:Object3D, skinsOnly:Boolean):void {
			for (var j:int = 0; j < queue.length; j++) {
				if (queue[j].element is DaeNode) {
					break;
				}
			}
			for (var i:int = nodes.length; i > 0; i--) {
				var args:QueueElement = new QueueElement;
				args.element = nodes[i - 1];
				args.parent = parent;
				args.skinsOnly = skinsOnly;
				queue.splice(j, 0, args);
			}
		}

		private function addElementsToQueue(elements:Object):void {
			for each (var element:DaeElement in elements) {
				var args:QueueElement = new QueueElement;
				args.element = element;
				queue.unshift(args);
			}
		}

		private const ASYNC_LIMIT:int = 50;
		private const ASYNC_TIMEOUT:int = 1;

		private function parseQueuedElements(onComplete:Function):void {
			var t:int = getTimer ();
			do {
				if (queue.length == 0) {
					// make sure onComplete is called after parseAsync exits
					setTimeout (onComplete, ASYNC_TIMEOUT, this);
					return;
				}

				var args:QueueElement = queue.shift();
				args.element.parse();

				if (args.element is DaeNode) {
					var node:DaeNode = args.element as DaeNode;
					var parent:Object3D = args.parent;
					var skinsOnly:Boolean = args.skinsOnly;

					// Object to which child objects will be added.
					var container:Object3D = null;
					if (node.skins != null) {
						// Main joint of skin
						container = addObjects(node.skins, parent, node.layer);
					} else {
						if (!skinsOnly && !node.skinOrTopmostJoint) {
							if (node.objects != null) {
								container = addObjects(node.objects, parent, node.layer);
							} else {
								// Empty Object3D
								container = new Object3D();
								container.name = node.cloneString(node.name);
								addObject(node.applyAnimation(node.applyTransformations(container)), parent, node.layer);
								container.calculateBoundBox();
							}
						} else {
							// Object or its parent is a skin or joint
							// Create an object  only if there are a child skins
							if (hasSkinsInChildren(node)) {
								container = new Object3D();
								container.name = node.cloneString(node.name);
								addObject(node.applyAnimation(node.applyTransformations(container)), parent, node.layer);
								addNodesToQueue(node.nodes, container, skinsOnly || node.skinOrTopmostJoint);
								container.calculateBoundBox();
							}
						}
					}
					// Parse children
					if (container != null) {
						addNodesToQueue(node.nodes, container, skinsOnly || node.skinOrTopmostJoint);
					}
				}

			} while (getTimer () - t < ASYNC_LIMIT);

			setTimeout (parseQueuedElements, ASYNC_TIMEOUT, onComplete);
		}

		private function trimPath(path:String):String {
			var index:int = path.lastIndexOf("/");
			return (index < 0) ? path : path.substr(index + 1);
		}

		private function parseMaterials(materials:Object, baseURL:String, trimPaths:Boolean):void {
			var tmaterial:ParserMaterial;
			for each (var material:DaeMaterial in materials) {
				if (material.used) {
					material.parse();
					this.materials.push(material.material);
				}
			}
			var resource:ExternalTextureResource;
			// Prepare paths
			if (trimPaths) {
				for each (tmaterial in this.materials) {
					for each(resource in tmaterial.textures) {
						if (resource != null && resource.url != null) {
							resource.url = trimPath(fixURL(resource.url));
						}
					}
				}
			} else {
				for each (tmaterial in this.materials) {
					for each(resource in tmaterial.textures) {
						if (resource != null && resource.url != null) {
							resource.url = fixURL(resource.url);
						}
					}
				}
			}
			var base:String;
			if (baseURL != null) {
				baseURL = fixURL(baseURL);
				var end:int = baseURL.lastIndexOf("/");
				base = (end < 0) ? "" : baseURL.substr(0, end);
				for each (tmaterial in this.materials) {
					for each(resource in tmaterial.textures) {
						if (resource != null && resource.url != null) {
							resource.url = resolveURL(resource.url, base);
						}
					}
				}
			}
		}

		/**
		 * @private
		 * Prosesses URL with following actions.
		 * Replaces backslashes with slashes, adds three direct slashes after <code>file:</code>
		 */
		private function fixURL(url:String):String {
			var pathStart:int = url.indexOf("://");
			pathStart = (pathStart < 0) ? 0 : pathStart + 3;
			var pathEnd:int = url.indexOf("?", pathStart);
			pathEnd = (pathEnd < 0) ? url.indexOf("#", pathStart) : pathEnd;
			var path:String = url.substring(pathStart, (pathEnd < 0) ? 0x7FFFFFFF : pathEnd);
			path = path.replace(/\\/g, "/");
			var fileIndex:int = url.indexOf("file://");
			if (fileIndex >= 0) {
				if (url.charAt(pathStart) == "/") {
					return "file://" + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
				}
				return "file:///" + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
			}
			return url.substring(0, pathStart) + path + ((pathEnd >= 0) ? url.substring(pathEnd) : "");
		}

		/**
		 * @private
		 */
		private function mergePath(path:String, base:String, relative:Boolean = false):String {
			var baseParts:Array = base.split("/");
			var parts:Array = path.split("/");
			for (var i:int = 0, count:int = parts.length; i < count; i++) {
				var part:String = parts[i];
				if (part == "..") {
					var basePart:String = baseParts.pop();
					while (basePart == "." || basePart == "" && basePart != null) basePart = baseParts.pop();
					if (relative) {
						if (basePart == "..") {
							baseParts.push("..", "..");
						} else if (basePart == null) {
							baseParts.push("..");
						}
					}
				} else {
					baseParts.push(part);
				}
			}
			return baseParts.join("/");
		}

		/**
		 * @private
		 * Converts relative paths to full paths
		 */
		private function resolveURL(url:String, base:String):String {
			if (base == "") {
				return url;
			}
			// http://labs.apache.org/webarch/uri/rfc/rfc3986.html
			if (url.charAt(0) == "." && url.charAt(1) == "/") {
				// File at the same folder
				return base + url.substr(1);
			} else if (url.charAt(0) == "/") {
				// Full path
				return url;
			} else if (url.charAt(0) == "." && url.charAt(1) == ".") {
				// Above on level
				var queryAndFragmentIndex:int = url.indexOf("?");
				queryAndFragmentIndex = (queryAndFragmentIndex < 0) ? url.indexOf("#") : queryAndFragmentIndex;
				var path:String;
				var queryAndFragment:String;
				if (queryAndFragmentIndex < 0) {
					queryAndFragment = "";
					path = url;
				} else {
					queryAndFragment = url.substring(queryAndFragmentIndex);
					path = url.substring(0, queryAndFragmentIndex);
				}
				// Split base URL on parts
				var bPath:String;
				var bSlashIndex:int = base.indexOf("/");
				var bShemeIndex:int = base.indexOf(":");
				var bAuthorityIndex:int = base.indexOf("//");
				if (bAuthorityIndex < 0 || bAuthorityIndex > bSlashIndex) {
					if (bShemeIndex >= 0 && bShemeIndex < bSlashIndex) {
						// Scheme exists, no domain
						var bSheme:String = base.substring(0, bShemeIndex + 1);
						bPath = base.substring(bShemeIndex + 1);
						if (bPath.charAt(0) == "/") {
							return bSheme + "/" + mergePath(path, bPath.substring(1), false) + queryAndFragment;
						} else {
							return bSheme + mergePath(path, bPath, false) + queryAndFragment;
						}
					} else {
						// No Scheme, no domain
						if (base.charAt(0) == "/") {
							return "/" + mergePath(path, base.substring(1), false) + queryAndFragment;
						} else {
							return mergePath(path, base, true) + queryAndFragment;
						}
					}
				} else {
					bSlashIndex = base.indexOf("/", bAuthorityIndex + 2);
					var bAuthority:String;
					if (bSlashIndex >= 0) {
						bAuthority = base.substring(0, bSlashIndex + 1);
						bPath = base.substring(bSlashIndex + 1);
						return bAuthority + mergePath(path, bPath, false) + queryAndFragment;
					} else {
						bAuthority = base;
						return bAuthority + "/" + mergePath(path, "", false);
					}
				}
			}
			var shemeIndex:int = url.indexOf(":");
			var slashIndex:int = url.indexOf("/");
			if (shemeIndex >= 0 && (shemeIndex < slashIndex || slashIndex < 0)) {
				// Contains the schema
				return url;
			}
			return base + "/" + url;
		}

		/**
		 * Returns animation from  <code>animations</code> array  by object, to which it refers.
		 */
		public function getAnimationByObject(object:Object):AnimationClip {
			for each (var animation:AnimationClip in animations) {
				var objects:Array = animation._objects;
				if (objects.indexOf(object) >= 0) {
					return animation;
				}
			}
			return null;
		}

		/**
		 * Parses and returns animation.
		 */
		public static function parseAnimation(data:XML):AnimationClip {
			
			var document:DaeDocument = new DaeDocument(data, 0);
			var clip:AnimationClip = new AnimationClip();
			collectAnimation(clip, document.scene.nodes);
			return (clip.numTracks > 0) ? clip : null;
		}

		/**
		 * @private
		 */
		private static function collectAnimation(clip:AnimationClip, nodes:Vector.<DaeNode>):void {
			for (var i:int = 0, count:int = nodes.length; i < count; i++) {
				var node:DaeNode = nodes[i];
				var animation:AnimationClip = node.parseAnimation();
				if (animation != null) {
					for (var t:int = 0, numTracks:int = animation.numTracks; t < numTracks; t++) {
						var track:Track = animation.getTrackAt(t);
						clip.addTrack(track);
					}
				} else {
					clip.addTrack(node.createStaticTransformTrack());
				}
				collectAnimation(clip, node.nodes);
			}
		}
	}
}

import alternativa.engine3d.core.Object3D;
import alternativa.engine3d.loaders.collada.DaeElement;
class QueueElement {
	public var element:DaeElement;
	public var parent:Object3D;
	public var skinsOnly:Boolean;
}