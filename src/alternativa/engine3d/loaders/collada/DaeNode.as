/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.animation.keys.NumberTrack;
	import alternativa.engine3d.animation.keys.Track;
	import alternativa.engine3d.animation.keys.TransformTrack;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * @private
	 */
	public class DaeNode extends DaeElement {
	
		use namespace collada;

		public var scene:DaeVisualScene;
		public var parent:DaeNode;

		// Skin or top-level joint.
		public var skinOrTopmostJoint:Boolean = false;

		/**
		 * Animation channels of this node.
		 */
		private var channels:Vector.<DaeChannel>;

		/**
		 * Vector of controllers, which have reference to this node.
		 */
		private var instanceControllers:Vector.<DaeInstanceController>;

		/**
		 * Array of nodes at this node.
		 */
		public var nodes:Vector.<DaeNode>;
	
		/**
		 * Array of objects at this node.
		 * Call <code>parse()</code> before using.
		 *
		 */
		public var objects:Vector.<DaeObject>;

		/**
		 * Vector of skins at this node.
		 * Call <code>parse()</code> before using.
		 *
		 */
		public var skins:Vector.<DaeObject>;

		/**
		 * Name of object for animation
		 */
		public function get animName():String {
			var n:String = this.name;
			return (n == null) ? this.id : n;
		}

		/**
		 * Create node from xml. Child nodes are created recursively.
		 */
		public function DaeNode(data:XML, document:DaeDocument, scene:DaeVisualScene = null, parent:DaeNode = null) {
			super(data, document);
	
			this.scene = scene;
			this.parent = parent;
	
			// Others node's declares inside <node>
			constructNodes();
		}

		private function constructNodes():void {
			var nodesList:XMLList = data.node;
			var count:int = nodesList.length();
			nodes = new Vector.<DaeNode>(count);
			for (var i:int = 0; i < count; i++) {
				var node:DaeNode = new DaeNode(nodesList[i], document, scene, this);
				if (node.id != null) {
					document.nodes[node.id] = node;
				}
				nodes[i] = node;
			}
		}

		internal function registerInstanceControllers():void {
			var instanceControllerXMLs:XMLList = data.instance_controller;
			var i:int;
			var count:int = instanceControllerXMLs.length()
			for (i = 0; i < count; i++) {
				skinOrTopmostJoint = true;
				var instanceControllerXML:XML = instanceControllerXMLs[i];
				var instanceController:DaeInstanceController = new DaeInstanceController(instanceControllerXML, document, this);
				if (instanceController.parse()) {
					var jointNodes:Vector.<DaeNode> = instanceController.topmostJoints;
					var numNodes:int = jointNodes.length;
					if (numNodes > 0) {
						var jointNode:DaeNode = jointNodes[0];
						jointNode.addInstanceController(instanceController);
						for (var j:int = 0; j < numNodes; j++) {
							jointNodes[j].skinOrTopmostJoint = true;
						}
					}
				}
			}
			count = nodes.length;
			for (i = 0; i < count; i++) {
				nodes[i].registerInstanceControllers();
			}
		}

		public function addChannel(channel:DaeChannel):void {
			if (channels == null) {
				channels = new Vector.<DaeChannel>();
			}
			channels.push(channel);
		}

		public function addInstanceController(controller:DaeInstanceController):void {
			if (instanceControllers == null) {
				instanceControllers = new Vector.<DaeInstanceController>();
			}
			instanceControllers.push(controller);
		}

		override protected function parseImplementation():Boolean {
			this.skins = parseSkins();
			this.objects = parseObjects();
			return true;
		}

		private function parseInstanceMaterials(geometry:XML):Object {
			var instances:Object = {};
			var list:XMLList = geometry.bind_material.technique_common.instance_material;
			for (var i:int = 0, count:int = list.length(); i < count; i++) {
				var instance:DaeInstanceMaterial = new DaeInstanceMaterial(list[i], document);
				instances[instance.symbol] = instance;
			}
			return instances;
		}

		/**
		 * Returns node by Sid.
		 */
		public function getNodeBySid(sid:String):DaeNode {
			if (sid == this.sid) {
				return this;
			}

			var levelNodes:Vector.<Vector.<DaeNode> > = new Vector.<Vector.<DaeNode> >;
			var levelNodes2:Vector.<Vector.<DaeNode> > = new Vector.<Vector.<DaeNode> >;

			levelNodes.push(nodes);
			var len:int = levelNodes.length;
			while (len > 0) {
				for (var i:int = 0; i < len; i++) {
					var children:Vector.<DaeNode> = levelNodes[i];
					var count:int = children.length;
					for (var j:int = 0; j < count; j++) {
						var node:DaeNode = children[j];
						if (node.sid == sid) {
							return node;
						}
						if (node.nodes.length > 0) {
							levelNodes2.push(node.nodes);
						}
					}
				}
				var temp:Vector.<Vector.<DaeNode> > = levelNodes;
				levelNodes = levelNodes2;
				levelNodes2 = temp;
				levelNodes2.length = 0;

				len = levelNodes.length;
			}
			return null;
		}

		/**
		 * Parses and returns array of skins, associated with this node.
		 */
		public function parseSkins():Vector.<DaeObject> {
			if (instanceControllers == null) {
				return null;
			}
			var skins:Vector.<DaeObject> = new Vector.<DaeObject>();
			for (var i:int = 0, count:int = instanceControllers.length; i < count; i++) {
				var instanceController:DaeInstanceController = instanceControllers[i];
				instanceController.parse();
				var skinAndAnimatedJoints:DaeObject = instanceController.parseSkin(parseInstanceMaterials(instanceController.data));
				if (skinAndAnimatedJoints != null) {
					var skin:Skin = Skin(skinAndAnimatedJoints.object);
					// Name is got from node, that contains instance_controller.
					skin.name = cloneString(instanceController.node.name);
					// Not apply transformation and animation for skin. It specifies at root joints.
					skins.push(skinAndAnimatedJoints);
				}
			}
			return (skins.length > 0) ? skins : null;
		}

		/**
		 * Parses and returns array of objects, associated with this node.
		 * Can be Mesh or Object3D, if type of object is unknown.
		 */
		public function parseObjects():Vector.<DaeObject> {
			var objects:Vector.<DaeObject> = new Vector.<DaeObject>();
			var children:XMLList = data.children();
			var i:int, count:int;

			for (i = 0, count = children.length(); i < count; i++) {
				var child:XML = children[i];
				switch (child.localName()) {
					case "instance_light":
						var lightInstance:DaeLight = document.findLight(child.@url[0]);
						if (lightInstance != null) {
							var light:Light3D = lightInstance.parseLight();
							if (light != null) {
								light.name = cloneString(name);
								if (lightInstance.revertDirection) {
									// Rotate 180 degrees along the x-axis, for correspondence to engine
									var rotXMatrix:Matrix3D = new Matrix3D();
									rotXMatrix.appendRotation(180, Vector3D.X_AXIS);
									// Not upload animations yet for these light sources
									objects.push(new DaeObject(applyTransformations(light, rotXMatrix)));
								} else {
									objects.push(applyAnimation(applyTransformations(light)));
								}
							}
						} else {
							document.logger.logNotFoundError(child.@url[0]);
						}
						break;
					case "instance_geometry":
						var geom:DaeGeometry = document.findGeometry(child.@url[0]);
						if (geom != null) {
							geom.parse();
							var mesh:Mesh = geom.parseMesh(parseInstanceMaterials(child));
							if(mesh != null){
								mesh.name = cloneString(name);
								objects.push(applyAnimation(applyTransformations(mesh)));	
							}
						} else {
							document.logger.logNotFoundError(child.@url[0]);
						}
						break;
					case "instance_node":
						document.logger.logInstanceNodeError(child);
						break;
				}
			}
			return (objects.length > 0) ? objects : null;
		}

		/**
		 * Returns transformation of node as a matrix.
		 * @param initialMatrix To this matrix tranformation will appended.
		 */
		private function getMatrix(initialMatrix:Matrix3D = null):Matrix3D {
			var matrix:Matrix3D = (initialMatrix == null) ? new Matrix3D() : initialMatrix;
			var components:Array;
			var children:XMLList = data.children();
			for (var i:int = children.length() - 1; i >= 0; i--) {
				//Transformations are append from the end to begin
				var child:XML = children[i];
				var sid:XML = child.@sid[0];
				if (sid != null && sid.toString() == "post-rotationY") {
					// Default 3dsmax exporter writes some trash which ignores
					continue;
				}
				switch (child.localName()) {
					case "scale" : {
						components = parseNumbersArray(child);
						matrix.appendScale(components[0], components[1], components[2]);
						break;
					}
					case "rotate" : {
						components = parseNumbersArray(child);
						matrix.appendRotation(components[3], new Vector3D(components[0], components[1], components[2]));
						break;
					}
					case "translate" : {
						components = parseNumbersArray(child);
						matrix.appendTranslation(components[0]*document.unitScaleFactor,
								components[1]*document.unitScaleFactor, components[2]*document.unitScaleFactor);
						break;
					}
					case "matrix" : {
						components = parseNumbersArray(child);
						matrix.append(new Matrix3D(Vector.<Number>([components[0], components[4], components[8],  components[12],
							components[1], components[5], components[9],  components[13],
							components[2], components[6], components[10], components[14],
							components[3]*document.unitScaleFactor ,components[7]*document.unitScaleFactor, components[11]*document.unitScaleFactor, components[15]])));
						break;
					}
					case "lookat" : {
						break;
					}
					case "skew" : {
						document.logger.logSkewError(child);
						break;
					}
				}
			}
			return matrix;
		}

		/**
		 * Apply transformation to object.
		 * @param prepend If  is not <code>null</code> transformation will added to this matrix.
		 */
		public function applyTransformations(object:Object3D, prepend:Matrix3D = null, append:Matrix3D = null):Object3D {
			var matrix:Matrix3D = getMatrix(prepend);
			if (append != null) {
				matrix.append(append);
			}
			var vs:Vector.<Vector3D> = matrix.decompose();
			var t:Vector3D = vs[0];
			var r:Vector3D = vs[1];
			var s:Vector3D = vs[2];
			object.x = t.x;
			object.y = t.y;
			object.z = t.z;
			object.rotationX = r.x;
			object.rotationY = r.y;
			object.rotationZ = r.z;
			object.scaleX = s.x;
			object.scaleY = s.y;
			object.scaleZ = s.z;
			return object;
		}

		public function applyAnimation(object:Object3D):DaeObject {
			var animation:AnimationClip = parseAnimation(object);
			if (animation == null) {
				return new DaeObject(object);
			}
			object.name = animName;
			animation.attach(object, false);
			return new DaeObject(object, animation);
		}

		/**
		 * Returns animation of node.
		 */
		public function parseAnimation(object:Object3D = null):AnimationClip {
			if (channels == null || !hasTransformationAnimation()) {
				return null;
			}
			var channel:DaeChannel = getChannel(DaeChannel.PARAM_MATRIX);
			if (channel != null) {
				return createClip(channel.tracks);
			}
			var clip:AnimationClip = new AnimationClip();
			var components:Vector.<Vector3D> = (object != null) ? null : getMatrix().decompose();
			
			// Translation
			channel = getChannel(DaeChannel.PARAM_TRANSLATE);
			if (channel != null) {
				addTracksToClip(clip, channel.tracks);
			} else {
				channel = getChannel(DaeChannel.PARAM_TRANSLATE_X);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("x", (object == null) ? components[0].x : object.x));
				}
				channel = getChannel(DaeChannel.PARAM_TRANSLATE_Y);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("y", (object == null) ? components[0].y : object.y));
				}
				channel = getChannel(DaeChannel.PARAM_TRANSLATE_Z);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("z", (object == null) ? components[0].z : object.z));
				}
			}
			// Rotation
			channel = getChannel(DaeChannel.PARAM_ROTATION_X);
			if (channel != null) {
				addTracksToClip(clip, channel.tracks);
			} else {
				clip.addTrack(createValueStaticTrack("rotationX", (object == null) ? components[1].x : object.rotationX));
			}
			channel = getChannel(DaeChannel.PARAM_ROTATION_Y);
			if (channel != null) {
				addTracksToClip(clip, channel.tracks);
			} else {
				clip.addTrack(createValueStaticTrack("rotationY", (object == null) ? components[1].y : object.rotationY));
			}
			channel = getChannel(DaeChannel.PARAM_ROTATION_Z);
			if (channel != null) {
				addTracksToClip(clip, channel.tracks);
			} else {
				clip.addTrack(createValueStaticTrack("rotationZ", (object == null) ? components[1].z : object.rotationZ));
			}
			// Scale
			channel = getChannel(DaeChannel.PARAM_SCALE);
			if (channel != null) {
				addTracksToClip(clip, channel.tracks);
			} else {
				channel = getChannel(DaeChannel.PARAM_SCALE_X);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("scaleX", (object == null) ? components[2].x : object.scaleX));
				}
				channel = getChannel(DaeChannel.PARAM_SCALE_Y);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("scaleY", (object == null) ? components[2].y : object.scaleY));
				}
				channel = getChannel(DaeChannel.PARAM_SCALE_Z);
				if (channel != null) {
					addTracksToClip(clip, channel.tracks);
				} else {
					clip.addTrack(createValueStaticTrack("scaleZ", (object == null) ? components[2].z : object.scaleZ));
				}
			}
			if (clip.numTracks > 0) {
				return clip;
			}
			return null;
		}

		private function createClip(tracks:Vector.<Track>):AnimationClip {
			var clip:AnimationClip = new AnimationClip();
			for (var i:int = 0, count:int = tracks.length; i < count; i++) {
				clip.addTrack(tracks[i]);
			}
			return clip;
		}

		private function addTracksToClip(clip:AnimationClip, tracks:Vector.<Track>):void {
			for (var i:int = 0, count:int = tracks.length; i < count; i++) {
				clip.addTrack(tracks[i]);
			}
		}

		private function hasTransformationAnimation():Boolean {
			for (var i:int = 0, count:int = channels.length; i < count; i++) {
				var channel:DaeChannel = channels[i];
				channel.parse();
				var result:Boolean = channel.animatedParam == DaeChannel.PARAM_MATRIX;
				result ||= channel.animatedParam == DaeChannel.PARAM_TRANSLATE;
				result ||= channel.animatedParam == DaeChannel.PARAM_TRANSLATE_X;
				result ||= channel.animatedParam == DaeChannel.PARAM_TRANSLATE_Y;
				result ||= channel.animatedParam == DaeChannel.PARAM_TRANSLATE_Z;
				result ||= channel.animatedParam == DaeChannel.PARAM_ROTATION_X;
				result ||= channel.animatedParam == DaeChannel.PARAM_ROTATION_Y;
				result ||= channel.animatedParam == DaeChannel.PARAM_ROTATION_Z;
				result ||= channel.animatedParam == DaeChannel.PARAM_SCALE;
				result ||= channel.animatedParam == DaeChannel.PARAM_SCALE_X;
				result ||= channel.animatedParam == DaeChannel.PARAM_SCALE_Y;
				result ||= channel.animatedParam == DaeChannel.PARAM_SCALE_Z;
				if (result) {
					return true;
				}
			}
			return false;
		}

		private function getChannel(param:String):DaeChannel {
			for (var i:int = 0, count:int = channels.length; i < count; i++) {
				var channel:DaeChannel = channels[i];
				channel.parse();
				if (channel.animatedParam == param) {
					return channel;
				}
			}
			return null;
		}

		private function concatTracks(source:Vector.<Track>, dest:Vector.<Track>):void {
			for (var i:int = 0, count:int = source.length; i < count; i++) {
				dest.push(source[i]);
			}
		}

		private function createValueStaticTrack(property:String, value:Number):Track {
			var track:NumberTrack = new NumberTrack(animName, property);
			track.addKey(0, value);
			return track;
		}

		public function createStaticTransformTrack():TransformTrack {
			var track:TransformTrack = new TransformTrack(animName);
			track.addKey(0, getMatrix());
			return track;
		}

        public function get layer():String {
            var layerXML:XML = data.@layer[0];
			return (layerXML == null) ? null : layerXML.toString();
        }

	}
}
