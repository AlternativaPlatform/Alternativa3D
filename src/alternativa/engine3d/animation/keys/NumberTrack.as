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
	 *
	 * Keyframe track for animating numeric properties. Each keyframe keeps its own value of the property.
	 * The value interpolates for in between keyframes.
	 */
	public class NumberTrack extends Track {

		/**
		 * @private
		 * Head of keyframe list.
		 */
		alternativa3d var keyList:NumberKey;

		private var _lastKey:NumberKey;

		/**
		 * @private
		 */
		override alternativa3d function get keyFramesList():Keyframe {
			return keyList;
		}

		/**
		 * @private
		 */
		override alternativa3d function set keyFramesList(value:Keyframe):void {
			keyList = NumberKey(value);
		}


		/**
		 * @private
		 */
		override alternativa3d function get lastKey():Keyframe {
			return _lastKey;
		}


		/**
		 * @private
		 */
		override alternativa3d function set lastKey(value:Keyframe):void {
			_lastKey = NumberKey(value);
		}

		/**
		 * Defines the name of object property which will be animated.
		 */
		public var property:String;

		/**
		 * Creates a NumberTrack object.
		 *  
		 * @param object name of animating object.
		 * @param property name of animating property.
		 */
		public function NumberTrack(object:String, property:String) {
			this.property = property;
			this.object = object;
		}

		/**
		 * Adds new keyframe. Keyframes stores ordered by its time property.
		 *
		 * @param time time of the new keyframe.
		 * @param value value of property for the new keyframe.
		 * @return added keyframe.
		 */
		public function addKey(time:Number, value:Number = 0):Keyframe {
			var key:NumberKey = new NumberKey(); 
			key._time = time;
			key.value = value;
			addKeyToList(key);
			return key;
		}

		/**
		 * @private 
		 */
		private static var temp:NumberKey = new NumberKey();

		private var recentKey:NumberKey = null;

		/**
		 * @private
		 */
		override alternativa3d function blend(time:Number, weight:Number, state:AnimationState):void {
			if (property == null) {
				return;
			}
			var prev:NumberKey;
			var next:NumberKey;
			
			if (recentKey != null && recentKey.time < time) {
				prev = recentKey;
				next = recentKey.next;
			} else {
				next = keyList;
			}
			while (next != null && next._time < time) {
				prev = next;
				next = next.next;
			}
			if (prev != null) {
				if (next != null) {
					temp.interpolate(prev, next, (time - prev._time)/(next._time - prev._time));
					state.addWeightedNumber(property, temp._value, weight);
				} else {
					state.addWeightedNumber(property, prev._value, weight);
				}
				recentKey = prev;
			} else {
				if (next != null) {
					state.addWeightedNumber(property, next._value, weight);
				}
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function createKeyFrame():Keyframe {
			return new NumberKey();
		}

		/**
		 * @private
		 */
		override alternativa3d function interpolateKeyFrame(dest:Keyframe, a:Keyframe, b:Keyframe, value:Number):void {
			NumberKey(dest).interpolate(NumberKey(a), NumberKey(b), value);
		}

		/**
		 * @inheritDoc
		 */
		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Track {
			var track:NumberTrack = new NumberTrack(object, property);
			sliceImplementation(track, start, end);
			return track;
		}

	}
}
