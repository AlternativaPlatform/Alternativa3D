/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.AnimationState;

	use namespace alternativa3d;

	/**
	 * Keyframe track baseclass.
	 *
	 * @see alternativa.engine3d.animation.AnimationClip
	 */
	public class Track {

		/**
		 * Name of the object which is animated.
		 */
		public var object:String;

		/**
		 * @private
		 */
		alternativa3d var _length:Number = 0;

		/**
		 * Creates a Track object.
		 */
		public function Track() {
		}

		/**
		 * The length of animation in seconds..
		 */
		public function get length():Number {
			return _length;
		}

		/**
		 * @private
		 */
		alternativa3d function get keyFramesList():Keyframe {
			return null;
		}

		/**
		 * @private
		 */
		alternativa3d function set keyFramesList(value:Keyframe):void {
		}

		/**
		 * @private
		 */
		alternativa3d function get lastKey():Keyframe {
			return null;
		}

		/**
		 * @private
		 */
		alternativa3d function set lastKey(value:Keyframe):void {

		}

		/**
		 * @private
		 */
		alternativa3d function addKeyToList(key:Keyframe):void {
			var time:Number = key._time;
			if (keyFramesList == null) {
				keyFramesList = key;
				lastKey = key;
				_length = (time <= 0) ? 0 : time;
				return;
			} else {
				if (keyFramesList._time > time) {
					// replace head of the keyframe list
					key.nextKeyFrame = keyFramesList;
					keyFramesList = key;
					return;
				} else {
					// adds to the end of list
					if (lastKey._time < time) {
						lastKey.nextKeyFrame = key;
						lastKey = key;
						_length = (time <= 0) ? 0 : time;
					} else {
						// search for appropriate place
						var k:Keyframe = keyFramesList;
						while (k.nextKeyFrame != null && k.nextKeyFrame._time <= time) {
							k = k.nextKeyFrame;
						}
						if (k.nextKeyFrame == null) {
							// adds to the end
							k.nextKeyFrame = key;
							_length = (time <= 0) ? 0 : time;
						} else {
							key.nextKeyFrame = k.nextKeyFrame;
							k.nextKeyFrame = key;
						}
					}

				}
			}
		}

		/**
		 *  Removes the supplied key frame.
		 *
		 * @param key the key frame to remove.
		 * @return removed key frame.
		 */
		public function removeKey(key:Keyframe):Keyframe {
			if (keyFramesList != null) {
				if (keyFramesList == key) {
					keyFramesList = keyFramesList.nextKeyFrame;
					if (keyFramesList == null) {
						lastKey = null;
						_length = 0;
					}
					return key;
				}
				var k:Keyframe = keyFramesList;
				while (k.nextKeyFrame != null && k.nextKeyFrame != key) {
					k = k.nextKeyFrame;
				}
				if (k.nextKeyFrame == key) {
					// Remove
					if (key.nextKeyFrame == null) {
						lastKey = k;
						// Last item
						_length = (k._time <= 0) ? 0 : k._time;
					}
					k.nextKeyFrame = key.nextKeyFrame;
					return key;
				}
			}
			throw new Error("Key not found");
		}

		/**
		 * Time-sorted list of key frames.
		 */
		public function get keys():Vector.<Keyframe> {
			var result:Vector.<Keyframe> = new Vector.<Keyframe>();
			var i:int = 0;
			for (var key:Keyframe = keyFramesList; key != null; key = key.nextKeyFrame) {
				result[i] = key;
				i++;
			}
			return result;
		}

		/**
		 * @private
		 */
		alternativa3d function blend(time:Number, weight:Number, state:AnimationState):void {
		}

		/**
		 * Returns a fragment of animation track between start and end time.
		 *
		 * @param start Fragment's start time.
		 * @param end Fragment's end time.
		 * @return Track fragment.
		 */
		public function slice(start:Number, end:Number = Number.MAX_VALUE):Track {
			return null;
		}

		/**
		 * @private
		 */
		alternativa3d function createKeyFrame():Keyframe {
			return null;
		}

		/**
		 * @private
		 */
		alternativa3d function interpolateKeyFrame(dest:Keyframe, a:Keyframe, b:Keyframe, value:Number):void {
		}

		/**
		 * @private
		 */
		alternativa3d function sliceImplementation(dest:Track, start:Number, end:Number):void {
			var shiftTime:Number = (start > 0) ? start : 0;
			var prev:Keyframe;
			var next:Keyframe = keyFramesList;
			// the first keyframe
			var key:Keyframe = createKeyFrame();
			var nextKey:Keyframe;
			while (next != null && next._time <= start) {
				prev = next;
				next = next.nextKeyFrame;
			}
			if (prev != null) {
				if (next != null) {
					interpolateKeyFrame(key, prev, next, (start - prev._time)/(next._time - prev._time));
					key._time = start - shiftTime;
				} else {
					// last keyframe
					interpolateKeyFrame(key, key, prev, 1);
				}
			} else {
				if (next != null) {
					// time before the start of animation
					interpolateKeyFrame(key, key, next, 1);
					key._time = next._time - shiftTime;
					prev = next;
					next = next.nextKeyFrame;
				} else {
					// empty track
					return;
				}
			}
			dest.keyFramesList = key;
			if (next == null || end <= start) {
				// one key frame
				dest._length = (key._time <= 0) ? 0 : key._time;
				return;
			}
			// copies intermediate keys
			while (next != null && next._time <= end) {
				nextKey = createKeyFrame();
				interpolateKeyFrame(nextKey, nextKey, next, 1);
				nextKey._time = next._time - shiftTime;
				key.nextKeyFrame = nextKey;
				key = nextKey;
				prev = next;
				next = next.nextKeyFrame;
			}
			// move last key
			if (next != null) {
				// time to end of the track
				nextKey = createKeyFrame();
				interpolateKeyFrame(nextKey, prev, next, (end - prev._time)/(next._time - prev._time));
				nextKey._time = end - shiftTime;
				key.nextKeyFrame = nextKey;
			} else {
				// time after current key
			}
			if (nextKey != null) {
				dest._length = (nextKey._time <= 0) ? 0 : nextKey._time;
			}
			return;
		}

	}
}
