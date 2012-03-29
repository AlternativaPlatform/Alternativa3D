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
	 * @private 
	 */
	public class NumberKey extends Keyframe {
		
		/**
		 * @private 
		 */
		alternativa3d var _value:Number = 0;
		/**
		 * @private 
		 */
		alternativa3d var next:NumberKey;		

		/**
		 * Creates a NumberKey object.
		 */
		public function NumberKey() {
		}

		/**
		 * Sets interpolated value.
		 */
		public function interpolate(a:NumberKey, b:NumberKey, c:Number):void {
			_value = (1 - c)*a._value + c*b._value;
		}

		/**
		 * @inheritDoc 
		 */
		override public function get value():Object {
			return _value;
		}

		/**
		 * @inheritDoc 
		 */
		override public function set value(v:Object):void {
			_value = Number(v);
		}

		/**
		 * @inheritDoc 
		 */
		override alternativa3d function get nextKeyFrame():Keyframe {
			return next;
		}
		
		/**
		 * @inheritDoc 
		 */
		override alternativa3d function set nextKeyFrame(value:Keyframe):void {
			next = NumberKey(value);
		}

	}
}
