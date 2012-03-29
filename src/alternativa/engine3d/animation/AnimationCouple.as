/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;

	use namespace alternativa3d;

	/**
	 * Blends two animations according to the balance value.
	 * Mixes two animations with the given percentage. Any of <code>AnimationClip</code>,
	 * <code>AnimationSwitcher</code>, <code>AnimationCouple</code> classes can be blended.
	 */
	public class AnimationCouple extends AnimationNode {

		/**
		 * @private 
		 */
		private var _left:AnimationNode;
		/**
		 * @private 
		 */
		private var _right:AnimationNode;

		/**
		 * The balance is a value in [0, 1] interval which specifies weight coefficient for each animation.
		 * The first (left) animation gets weight of (1 - balance) and the second (right) one gets weigth of balance.
		 */
		public var balance:Number = 0.5;

		/**
		 * @private
		 */
		override alternativa3d function update(elapsed:Number, weight:Number):void {
			var w:Number = (balance <= 0) ? 0 : ((balance >= 1) ? 1 : balance);
			if (_left == null) {
				_right.update(elapsed*speed, weight);
			} else if (_right == null) {
				_left.update(elapsed*speed, weight);
			} else {
				_left.update(elapsed*speed, (1 - w)*weight);
				_right.update(elapsed*speed, w*weight);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function setController(value:AnimationController):void {
			this.controller = value;
			if (_left != null) {
				_left.setController(value);
			} 
			if (_right != null) {
				_right.setController(value);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function addNode(node:AnimationNode):void {
			super.addNode(node);
			node._isActive = true;
		}

		/**
		 * @private
		 */
		override alternativa3d function removeNode(node:AnimationNode):void {
			if (_left == node) {
				_left = null;
			} else {
				_right = null;
			}
			super.removeNode(node);
		}

		/**
		 * The first animation.
		 */
		public function get left():AnimationNode {
			return _left;
		}

		/**
		 * @private 
		 */
		public function set left(value:AnimationNode):void {
			if (value != _left) {
				if (value._parent == this) {
					throw new Error("Animation already exists in  blender");
				}
				if (_left != null) {
					removeNode(_left);
				}
				_left = value;
				if (value != null) {
					addNode(value);
				}
			}
		}

		/**
		 * The second animation.
		 */		
		public function get right():AnimationNode {
			return _right;
		}

		/**
		 * @private 
		 */
		public function set right(value:AnimationNode):void {
			if (value != _right) {
				if (value._parent == this) {
					throw new Error("Animation already exists in blender");
				}
				if (_right != null) {
					removeNode(_right);
				}
				_right = value;
				if (value != null) {
					addNode(value);
				}
			}
		}

	}
}
