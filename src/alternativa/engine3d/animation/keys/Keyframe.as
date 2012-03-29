/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;

	use namespace alternativa3d;

	/**
	 * Keyframe of the animation. Sets object property at given time.
	 * Keyframe animation can be defined with  NumberTrack and TransformTrack classes.
	 * 
	 * @see TransformTrack
	 * @see NumberTrack
	 */
	public class Keyframe {

		/**
		 * @private
		 * Key frame time in seconds.
		 */
		alternativa3d var _time:Number = 0;

		/**
		 * Creates a new Keyframe instance.
		 */
		public function Keyframe() {
		}

		/**
		 * Key frame time in seconds.
		 */
		public function get time():Number {
			return _time;
		}

		/**
		 * The value of animated property kept by the keyframe.
		 * Can be <code>Number</code> or <code>Matrix3D</code> depends on
		 *   <code>NumberTrack</code> or <code>TransformTrack</code> belongs to.
		 * 
		 * @see NumberTrack
		 * @see TransformTrack
		 */
		public function get value():Object {
			return null;
		}

		/**
		 * @private 
		 */
		public function set value(v:Object):void {
		}

		/**
		 * @private 
		 */
		alternativa3d function get nextKeyFrame():Keyframe {
			return null;
		}

		/**
		 * @private 
		 */
		alternativa3d function set nextKeyFrame(value:Keyframe):void {
		}

		/**
		 * Returns string representation of the object.
		 */
		public function toString():String {
			return '[Keyframe time = ' + _time.toFixed(2) + ' value = ' + value + ']';
		}

	}
}
