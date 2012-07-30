/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.keys.Track;
	import alternativa.engine3d.core.Object3D;

	use namespace alternativa3d;

	/**
	 *
	 * Plays complex animation which consists of a set of animation tracks.
	 * Every  animated property of every model's element presented by separated track.
	 * Track is somewhat similar to separate animated layer in Flash, but the layer stores  animation of all properties for some element at once.
	 * In opposite, track stores animation for every property (for an example, separate track for a scale and separate track for a coordinates).
	 * Track also can contain keyframes in arbitrary positions. Frames, contained between keyframes, are linearly interpolated
	 * (i.e. behave themselves like a timeline frames in flash, for which motion twin  was created ).
	 * Animation clip connects each track with a specific object.
	 * Animation clip stores information about animation for the whole model, i.e. for any element state at any time moment.
	 * Animation works handled by <code>AnimationController</code>.
	 *
	 * @see alternativa.engine3d.animation.keys.Track
	 * @see alternativa.engine3d.animation.keys.TransformTrack
	 * @see alternativa.engine3d.animation.keys.NumberTrack
     * @see alternativa.engine3d.animation.AnimationController
	 */
	public class AnimationClip extends AnimationNode {

		/**
		 * @private
		 */
		alternativa3d var _objects:Array;

		/**
		 * Name of the animation clip.
		 */
		public var name:String;

		/**
		 * Defines if animation should be repeated.
		 */
		public var loop:Boolean = true;

		/**
		 * Length of animation in seconds. If length of any animation track is changed, updateLength()
		 * method should be called to recalculate the length of the clip.
		 *
		 * @see #updateLength()
		 */
		public var length:Number = 0;
		/**
		 * Handles the active animation execution. Plays animation if value is true.
		 *
		 * @see AnimationNode#isActive
		 */
		public var animated:Boolean = true;

		/**
		 * @private
		 * Current value of time.
		 */
		private var _time:Number = 0;

		/**
		 * @private
		 */
		private var _numTracks:int = 0;
		/**
		 * @private
		 */
		private var _tracks:Vector.<Track> = new Vector.<Track>();

		/**
		 * @private
		 */
		private var _notifiersList:AnimationNotify;

		/**
		 * Creates a AnimationClip object.
		 *
		 * @param name name of the clip
		 */
		public function AnimationClip(name:String = null) {
			this.name = name;
		}

		/**
		 * The list of animated objects. Animation tracks are bound to the objects by object names.
		 *
		 * @see Track#object
		 */
		public function get objects():Array {
			return (_objects == null) ? null : [].concat(_objects);
		}

		/**
		 * @private
		 */
		public function set objects(value:Array):void {
			updateObjects(_objects, controller, value, controller);
			_objects = (value == null) ? null : [].concat(value);
		}

		/**
		 * @private
		 */
		override alternativa3d function setController(value:AnimationController):void {
			updateObjects(_objects, controller, _objects, value);
			this.controller = value;
		}

		/**
		 * @private
		 */
		private function addObject(object:Object):void {
			if (_objects == null) {
				_objects = [object];
			} else {
				_objects.push(object);
			}
			if (controller != null) {
				controller.addObject(object);
			}
		}

		/**
		 * @private
		 */
		private function updateObjects(oldObjects:Array, oldController:AnimationController, newObjects:Array, newController:AnimationController):void {
			var i:int, count:int;
			if (oldController != null && oldObjects != null) {
				for (i = 0, count = _objects.length; i < count; i++) {
					oldController.removeObject(oldObjects[i]);
				}
			}
			if (newController != null && newObjects != null) {
				for (i = 0, count = newObjects.length; i < count; i++) {
					newController.addObject(newObjects[i]);
				}
			}
		}

		/**
		 * Updates the length of the clip in order to match with length of longest track.
		 * Should be called after track was changed.
		 */
		public function updateLength():void {
			for (var i:int = 0; i < _numTracks; i++) {
				var track:Track = _tracks[i];
				var len:Number = track.length;
				if (len > length) {
					length = len;
				}
			}
		}

		/**
		 * Adds a new track to the animation clip.
		 * The total length of the clip is recalculated automatically.
		 *
		 * @param track track which should be added.
		 * @return added track.
		 *
		 * @see #length
		 */
		public function addTrack(track:Track):Track {
			if (track == null) {
				throw new Error("Track can not be null");
			}
			_tracks[_numTracks++] = track;
			if (track.length > length) {
				length = track.length;
			}
			return track;
		}

		/**
		 * Removes the specified track from the clip. The clip length is automatically recalculated.
		 *
		 * @param track track which should be removed.
		 * @return removed track.
		 *
		 * @see #length
		 * @throw Error if the AnimationClip does not include the track.
		 */
		public function removeTrack(track:Track):Track {
			var index:int = _tracks.indexOf(track);
			if (index < 0) throw new ArgumentError("Track not found");
			_numTracks--;
			var j:int = index + 1;
			while (index < _numTracks) {
				_tracks[index] = _tracks[j];
				index++;
				j++;
			}
			_tracks.length = _numTracks;
				length = 0;
				for (var i:int = 0; i < _numTracks; i++) {
					var t:Track = _tracks[i];
					if (t.length > length) {
						length = t.length;
					}
				}
			return track;
		}

		/**
		 * Returns the track object instance that exists at the specified index.
		 *
		 * @param index index.
		 * @return the track object instance that exists at the specified index.
		 */
		public function getTrackAt(index:int):Track {
			return _tracks[index];
		}

		/**
		 * Number of tracks in the AnimationClip.
		 */
		public function get numTracks():int {
			return _numTracks;
		}

		/**
		 * @private
		 */
		override alternativa3d function update(interval:Number, weight:Number):void {
			var oldTime:Number = _time;
			if (animated) {
				_time += interval*speed;
				if (loop) {
					if (_time < 0) {
						// TODO: Loop processing
		//				_position = (length <= 0) ? 0 : _position % length;
						_time = 0;
					} else {
						if (_time >= length) {
							collectNotifiers(oldTime, length);
							_time = (length <= 0) ? 0 : _time % length;
							collectNotifiers(0, _time < oldTime ? _time : oldTime);
						} else {
							collectNotifiers(oldTime, _time);
						}
					}
				} else {
					if (_time < 0) {
						_time = 0;
					} else if (_time >= length) {
						_time = length;
					}
					collectNotifiers(oldTime, _time);
				}
			}
			if (weight > 0) {
				for (var i:int = 0; i < _numTracks; i++) {
					var track:Track = _tracks[i];
					if (track.object != null) {
						var state:AnimationState = controller.getState(track.object);
						if (state != null) {
							track.blend(_time, weight, state);
						}
					}
				}
			}
		}

		/**
		 * Current time of animation.
		 */
		public function get time():Number {
			return _time;
		}

		/**
		 * @private
		 */
		public function set time(value:Number):void {
			_time = value;
		}

		/**
		 * Current normalized time in the interval [0, 1].
		 */
		public function get normalizedTime():Number {
			return (length == 0) ? 0 : _time/length;
		}

		/**
		 * @private
		 */
		public function set normalizedTime(value:Number):void {
			_time = value*length;
		}

		/**
		 * @private
		 */
		private function getNumChildren(object:Object):int {
			if (object is Object3D) {
				return Object3D(object).numChildren;
			}
			return 0;
		}

		/**
		 * @private
		 */
		private function getChildAt(object:Object, index:int):Object {
			if (object is Object3D) {
				return Object3D(object).getChildAt(index);
			}
			return null;
		}

		/**
		 * @private
		 */
		private function addChildren(object:Object):void {
			for (var i:int = 0, numChildren:int = getNumChildren(object); i < numChildren; i++) {
				var child:Object = getChildAt(object, i);
				addObject(child);
				addChildren(child);
			}
		}

		/**
		 * Binds tracks from the animation clip to given object. Only those tracks which have object property equal to the object's name are bound.
		 *
		 * @param object The object to which tracks are bound.
		 * @param includeDescendants If true, the whole tree of the object's children (if any) is processed.
		 *
		 * @see #objects
		 * @see alternativa.engine3d.animation.keys.Track#object
		 */
		public function attach(object:Object, includeDescendants:Boolean):void {
			updateObjects(_objects, controller, null, controller);
			_objects = null;
			addObject(object);
			if (includeDescendants) {
				addChildren(object);
			}
		}

		/**
		 * @private
		 */
		alternativa3d function collectNotifiers(start:Number, end:Number):void {
			for (var notify:AnimationNotify = _notifiersList; notify != null; notify = notify.next) {
				if (notify._time > start && notify._time <= end) {
					// add notify to dispatched
					notify.processNext = controller.nearestNotifyers;
					controller.nearestNotifyers = notify;
				}
			}
		}

		/**
		 * Creates an AnimationNotify instance which is capable of firing notification events when playback reaches the specified time on the time line.
		 *
		 * @param time The time in seconds to which the notification trigger will be bound.
		 * @param name The name of AnimationNotify instance.
		 *
		 * @return A new instance of AnimationNotify class bound to specified time counting from start of the time line.
		 *
		 * @see AnimationNotify
		 */
		public function addNotify(time:Number, name:String = null):AnimationNotify {
			time = (time <= 0) ? 0 : ((time >= length) ? length : time);
			var notify:AnimationNotify = new AnimationNotify(name);
			notify._time = time;
			if (_notifiersList == null) {
				_notifiersList = notify;
				return notify;
			} else {
				if (_notifiersList._time > time) {
					// Replaces the first key
					notify.next = _notifiersList;
					_notifiersList = notify;
					return notify;
				} else {
					// Search for appropriate place
					var n:AnimationNotify = _notifiersList;
					while (n.next != null && n.next._time <= time) {
						n = n.next;
					}
					if (n.next == null) {
						// Places at the end
						n.next = notify;
					} else {
						notify.next = n.next;
						n.next = notify;
					}
				}
			}
			return notify;
		}

		/**
		 * Creates an AnimationNotify instance which is capable of firing notification events when playback reaches
		 * the specified time on the time line. The time is specified as an offset from the end of time line towards its start.
		 *
		 * @param offsetFromEnd The offset in seconds from the end of the time line towards its start, where the event object will be set in.
		 * @param name The name of notification trigger.
		 *
		 * @return A new instance of AnimationNotify class bound to specified time.
		 *
		 * @see AnimationNotify
		 */
		// TODO: name of method (addNotifyAtEnd) is incomprehensible. Rename to addNotifyFromFinish (or something else).
		public function addNotifyAtEnd(offsetFromEnd:Number = 0, name:String = null):AnimationNotify {
			return addNotify(length - offsetFromEnd, name);
		}

		/**
		 * Removes specified notification trigger.
		 *
		 * @param notify The notification trigger to remove.
		 * @return The removed notification trigger.
		 */
		public function removeNotify(notify:AnimationNotify):AnimationNotify {
			if (_notifiersList != null) {
				if (_notifiersList == notify) {
					_notifiersList = _notifiersList.next;
					return notify;
				}
				var n:AnimationNotify = _notifiersList;
				while (n.next != null && n.next != notify) {
					n = n.next;
				}
				if (n.next == notify) {
					// removes
					n.next = notify.next;
					return notify;
				}
			}
			throw new Error("Notify not found");
		}

		/**
		 * The list of notification triggers.
		 */
		public function get notifiers():Vector.<AnimationNotify> {
			var result:Vector.<AnimationNotify> = new Vector.<AnimationNotify>();
			var i:int = 0;
			for (var notify:AnimationNotify = _notifiersList; notify != null; notify = notify.next) {
				result[i] = notify;
				i++;
			}
			return result;
		}

		/**
		 * Returns a fragment of the clip between specified bounds.
		 *
		 * @param start The start time of a fragment in seconds.
		 * @param end The end time of a fragment in seconds.
		 * @return The clip fragment.
		 */
		public function slice(start:Number, end:Number = Number.MAX_VALUE):AnimationClip {
			var sliced:AnimationClip = new AnimationClip(name);
			sliced.animated = animated;
			sliced.loop = loop;
			sliced._objects = (_objects == null) ? null : [].concat(_objects);
			for (var i:int = 0; i < _numTracks; i++) {
				sliced.addTrack(_tracks[i].slice(start, end));
			}
			return sliced;
		}

		/**
		 * Clones the clip. Both the clone and the original reference the same tracks.
		 */
		public function clone():AnimationClip {
			var cloned:AnimationClip = new AnimationClip(name);
			cloned.animated = animated;
			cloned.loop = loop;
			cloned._objects = (_objects == null) ? null : [].concat(_objects);
			for (var i:int = 0; i < _numTracks; i++) {
				cloned.addTrack(_tracks[i]);
			}
			cloned.length = length;
			return cloned;
		}

	}
}
