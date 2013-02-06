/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.events.Event3D;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Levels of detail is an <code>Object3D</code> which can have several representation of different detail level.
	 * The current level will be chosen for the rendering according to distance to the camera.
	 */
	public class LOD extends Object3D {

		/**
		 * @private
		 */
		alternativa3d var levelList:Object3D;

		/**
		 * Specifies the name of the LOD level object to be used for ray intersection tests.
		 * By default, the maximum detail level object is used, but this property allows you to specify a lower level.
		 */
		public var intersectionTestLevelName:String;
		
		/**
		 * Adds a children as a new level of detail. In case of given object is a children of other <code>Object3D</code> already, it will removed from the previous place.
		 * @param level <code>Object3D</code> which will added.
		 * @param distance If the <code>LOD</code> closer to the camera than <code>distance</code> value, this level will be preferred to the distant one.
		 * @return Object, given as <code>lod</code> parameter.
		 */
		public function addLevel(level:Object3D, distance:Number):Object3D {
			// Checking for the errors.
			if (level == null) throw new TypeError("Parameter level must be non-null.");
			if (level == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3D = _parent; container != null; container = container._parent) {
				if (container == level) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Add.
			if (level._parent != this) {
				// Remove from previous parent.
				if (level._parent != null) level._parent.removeChild(level);
				// Add
				addToLevelList(level, distance);
				level._parent = this;
				// Dispatch of event.
				if (level.willTrigger(Event3D.ADDED)) level.dispatchEvent(new Event3D(Event3D.ADDED, true));
			} else {
				if (removeFromList(level) == null) removeFromLevelList(level);
				//  Add.
				addToLevelList(level, distance);
			}
			return level;
		}

		/**
		 * Removes level  of detail.
		 *
		 * @param level   Object3d which was used as level of detail that will be removed.
		 * @return  The Object3d instance that you pass in the <code>level</code> parameter.
		 * @see #addLevel()
		 */
		public function removeLevel(level:Object3D):Object3D {
			// Checking for the errors.
			if (level == null) throw new TypeError("Parameter level must be non-null.");
			if (level._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			level = removeFromLevelList(level);
			if (level == null) throw new ArgumentError("Cannot remove level.");
			// Dispatch of event.
			if (level.willTrigger(Event3D.REMOVED)) level.dispatchEvent(new Event3D(Event3D.REMOVED, true));
			level._parent = null;
			return level;
		}

		/**
		 * Returns distance was set up for the given level.    If the <code>LOD</code> closer to the camera than <code>distance</code>, this level will be preferred to the distant one.
		 * @param level  Object3d which was used as level of detail.
		 * @return Distance was set up for the given level.
		 */
		public function getLevelDistance(level:Object3D):Number {
			// Checking for the errors
			if (level == null) throw new TypeError("Parameter level must be non-null.");
			if (level._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (level == current) return level.distance;
			}
			throw new ArgumentError("Cannot get level distance.");
		}

		/**
		 * Sets distance to the given <code>level</code>. If the <code>LOD</code> closer to the camera than <code>distance</code> value, this level will be preffered to the distant one.
		 * @param level  Object3d which was used as level of detail.
		 * @param distance Distance value.
		 */
		public function setLevelDistance(level:Object3D, distance:Number):void {
			// Checking for the errors.
			if (level == null) throw new TypeError("Parameter level must be non-null.");
			if (level._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			level = removeFromLevelList(level);
			if (level == null) throw new ArgumentError("Cannot set level distance.");
			addToLevelList(level, distance);
		}

		/**
		 *  Returns <code>Object3D</code> which was used as level of detail at given distance.
		 * @param distance   Distance.
		 * @return   <code>Object3D</code> which was used as level of detail at given distance.
		 */
		public function getLevelByDistance(distance:Number):Object3D {
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (distance <= current.distance) return current;
			}
			return null;
		}

		/**
		 *
		 *  Returns <code>Object3D</code> which was used as level of detail  with given name.
		 * @param name  Name of the object.
		 * @return   <code>Object3D</code> with given name.
		 */
		public function getLevelByName(name:String):Object3D {
			// Checking for the errors.
			if (name == null) throw new TypeError("Parameter name must be non-null.");
			// Search for object
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (current.name == name) return current;
			}
			return null;
		}

		/**
		 * Returns all <code>Object3D</code>s which was used as levels of detail  in this <code>LOD</code>, in  <code>Vector.&lt;Object3D&gt;</code>.
		 * @return <code>Vector.&lt;Object3D&gt;</code> consists of <code>Object3D</code>s which was used as levels of detail.
		 */
		public function getLevels():Vector.<Object3D> {
			var res:Vector.<Object3D> = new Vector.<Object3D>();
			var num:int = 0;
			for (var current:Object3D = levelList; current != null; current = current.next) {
				res[num] = current;
				num++;
			}
			return res;
		}

		/**
		 * Number of levels of detail.
		 */
		public function get numLevels():int {
			var num:int = 0;
			for (var current:Object3D = levelList; current != null; current = current.next) num++;
			return num;
		}

		/**
		 * @private
		 */
		override alternativa3d function get useLights():Boolean {
			return true;
		}

		// Holds current level
		private var level:Object3D;

		/**
		 * @private
		 */
		override alternativa3d function calculateVisibility(camera:Camera3D):void {
			// TODO: optimize - use square of distance
			var distance:Number = Math.sqrt(localToCameraTransform.d*localToCameraTransform.d + localToCameraTransform.h*localToCameraTransform.h + localToCameraTransform.l*localToCameraTransform.l);
			for (level = levelList; level != null; level = level.next) {
				if (distance <= level.distance) {
					calculateChildVisibility(level, this, camera);
					break;
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function calculateChildVisibility(child:Object3D, parent:Object3D, camera:Camera3D):void {
			// Composing direct and reverse matrices
			if (child.transformChanged) child.composeTransforms();
			// Calculation of transfer matrix from camera to local space.
			child.cameraToLocalTransform.combine(child.inverseTransform, parent.cameraToLocalTransform);
			// Calculation of transfer matrix from local space to camera.
			child.localToCameraTransform.combine(parent.localToCameraTransform, child.transform);

			camera.globalMouseHandlingType |= child.mouseHandlingType;
			// Pass
			child.culling = parent.culling;
			// Calculating visibility of the self content
			if (child.culling >= 0) child.calculateVisibility(camera);

			// Hierarchical call
			for (var c:Object3D = child.childrenList; c != null; c = c.next) {
				calculateChildVisibility(c, child, camera);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			// Level must be choosen in CalculateVisibility
			if (level != null) collectChildDraws(level, this, camera, lights, lightsLength, useShadow);
			level = null;
		}

		/**
		 * @private
		 */
		alternativa3d function collectChildDraws(child:Object3D, parent:Object3D, camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			child.listening = parent.listening;
			// If object needs on light sources.
			if (lightsLength > 0 && child.useLights) {
				// Calculation of transfer matrices from sources to object.
				var excludedLightLength:int = this._excludedLights.length;
				var childLightsLength:int = 0;
				for (var i:int = 0; i < lightsLength; i++) {
					var light:Light3D = lights[i];
					var j:int = 0;
					while (j<excludedLightLength && this._excludedLights[j]!=light)	j++;
					if (j<excludedLightLength) continue;

					light.lightToObjectTransform.combine(child.cameraToLocalTransform, light.localToCameraTransform);
					camera.childLights[childLightsLength] = light;
					childLightsLength++;
				}
				child.collectDraws(camera, camera.childLights, childLightsLength, useShadow);
			} else {
				child.collectDraws(camera, null, 0, useShadow);
			}
			// Hierarchical call
			for (var c:Object3D = child.childrenList; c != null; c = c.next) {
				collectChildDraws(c, child, camera, lights, lightsLength, useShadow);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (hierarchy) {
				for (var current:Object3D = levelList; current != null; current = current.next) {
					current.fillResources(resources, hierarchy, resourceType);
				}
			}
			super.fillResources(resources, hierarchy, resourceType);
		}

		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D):RayIntersectionData {
			var childrenData:RayIntersectionData = super.intersectRay(origin, direction);
			var contentData:RayIntersectionData;
			var level:Object3D = levelList;
			if (intersectionTestLevelName != null) {
				level = getLevelByName(intersectionTestLevelName);
			}
			if (level != null && (boundBox == null || boundBox.intersectRay(origin, direction))) {
				if (level.transformChanged) level.composeTransforms();
				var childOrigin:Vector3D = new Vector3D();
				var childDirection:Vector3D = new Vector3D();
				childOrigin.x = level.inverseTransform.a*origin.x + level.inverseTransform.b*origin.y + level.inverseTransform.c*origin.z + level.inverseTransform.d;
				childOrigin.y = level.inverseTransform.e*origin.x + level.inverseTransform.f*origin.y + level.inverseTransform.g*origin.z + level.inverseTransform.h;
				childOrigin.z = level.inverseTransform.i*origin.x + level.inverseTransform.j*origin.y + level.inverseTransform.k*origin.z + level.inverseTransform.l;
				childDirection.x = level.inverseTransform.a*direction.x + level.inverseTransform.b*direction.y + level.inverseTransform.c*direction.z;
				childDirection.y = level.inverseTransform.e*direction.x + level.inverseTransform.f*direction.y + level.inverseTransform.g*direction.z;
				childDirection.z = level.inverseTransform.i*direction.x + level.inverseTransform.j*direction.y + level.inverseTransform.k*direction.z;
				contentData = level.intersectRay(childOrigin, childDirection);
			}
			if (childrenData != null) {
				if (contentData != null) {
					return childrenData.time < contentData.time ? childrenData : contentData;
				} else {
					return childrenData;
				}
			} else {
				return contentData;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (current.transformChanged) current.composeTransforms();
				if (transform != null) {
					current.localToCameraTransform.combine(transform, current.transform);
				} else {
					current.localToCameraTransform.copy(current.transform);
				}
				current.updateBoundBox(boundBox, current.localToCameraTransform);
				updateBoundBoxChildren(current, boundBox);
			}
		}

		private function updateBoundBoxChildren(parent:Object3D, boundBox:BoundBox):void {
			for (var current:Object3D = parent.childrenList; current != null; current = current.next) {
				if (current.transformChanged) current.composeTransforms();
				current.localToCameraTransform.combine(parent.localToCameraTransform, current.transform);
				current.updateBoundBox(boundBox, current.localToCameraTransform);
				updateBoundBoxChildren(current, boundBox);
			}
		}

		private function addToLevelList(level:Object3D, distance:Number):void {
			level.distance = distance;
			var prev:Object3D = null;
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (distance < current.distance) {
					level.next = current;
					break;
				}
				prev = current;
			}
			if (prev != null) {
				prev.next = level;
			} else {
				levelList = level;
			}
		}

		private function removeFromLevelList(level:Object3D):Object3D {
			var prev:Object3D;
			for (var current:Object3D = levelList; current != null; current = current.next) {
				if (current == level) {
					if (prev != null) {
						prev.next = current.next;
					} else {
						levelList = current.next;
					}
					current.next = null;
					return level;
				}
				prev = current;
			}
			return null;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:LOD = new LOD();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:LOD = source as LOD;
			for (var current:Object3D = src.levelList, last:Object3D; current != null; current = current.next) {
				var newLevel:Object3D = current.clone();
				if (levelList != null) {
					last.next = newLevel;
				} else {
					levelList = newLevel;
				}
				last = newLevel;
				newLevel._parent = this;
				newLevel.distance = current.distance;
			}
		}

	}
}
