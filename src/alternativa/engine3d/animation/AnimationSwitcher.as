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
	 * The animation switcher performs animation blending and active animation switching.
     *
	 */
	public class AnimationSwitcher extends AnimationNode {

		/**
		 * @private 
		 */
		private var _numAnimations:int = 0;
		/**
		 * @private 
		 */
		private var _animations:Vector.<AnimationNode> = new Vector.<AnimationNode>();
		/**
		 * @private 
		 */
		private var _weights:Vector.<Number> = new Vector.<Number>();
		/**
		 * @private 
		 */
		private var _active:AnimationNode;
		/**
		 * @private 
		 */
		private var fadingSpeed:Number = 0;

		/**
		 * @private
		 */
		override alternativa3d function update(elapsed:Number, weight:Number):void {
			// TODO : make fade if it required only
			var interval:Number = speed * elapsed;
			var fade:Number = fadingSpeed * interval;
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:AnimationNode = _animations[i];
				var w:Number = _weights[i];
				if (animation == _active) {
					w += fade;
					w = (w >= 1) ? 1 : w;
					animation.update(interval, weight * w);
					_weights[i] = w; 
				} else {
					w -= fade;
					if (w > 0) {
						animation.update(interval, weight * w);
						_weights[i] = w; 
					} else {
						animation._isActive = false;
						_weights[i] = 0; 
					}
				}
			}
		}

		/**
		 * The current active animation. To change active animation use <code>activate()</code>.
		 *
		 * @see #activate()
		 */
		public function get active():AnimationNode {
			return _active;
		}

		/**
		 * Activates specified animation during given time interval. All the rest animations fade out.
		 *
		 * @param animation Animation which is set as active.
		 * @param time The time interval during which the animation becomes fully active (i.e. has full weight).
		 */
		public function activate(animation:AnimationNode, time:Number = 0):void {
			if (animation._parent != this) {
				throw new Error("Animation is not child of this blender");
			}
			_active = animation;
			animation._isActive = true;
			if (time <= 0) {
				for (var i:int = 0; i < _numAnimations; i++) {
					if (_animations[i] == animation) {
						_weights[i] = 1;
					} else {
						_weights[i] = 0;
						_animations[i]._isActive = false;
					}
				}
				fadingSpeed = 0;
			} else {
				fadingSpeed = 1/time;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function setController(value:AnimationController):void {
			this.controller = value;
			for (var i:int = 0; i < _numAnimations; i++) {
				var animation:AnimationNode = _animations[i];
				animation.setController(controller);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function removeNode(node:AnimationNode):void {
			removeAnimation(node);
		}

		/**
		 * Adds a new animation.
		 * 
		 * @param animation The animation node to add.
		 * @return Added animation.
		 */
		public function addAnimation(animation:AnimationNode):AnimationNode {
			if (animation == null) {
				throw new Error("Animation cannot be null");
			}
			if (animation._parent == this) {
				throw new Error("Animation already exist in blender");
			}
			_animations[_numAnimations] = animation;
			if (_numAnimations == 0) {
				_active = animation;
				animation._isActive = true;
				_weights[_numAnimations] = 1;
			} else {
				_weights[_numAnimations] = 0;
			}
			_numAnimations++;
			addNode(animation);
			return animation;
		}

		/**
		 * Removes child animation node.
		 *  
		 * @param animation Animation node to remove.
		 */
		public function removeAnimation(animation:AnimationNode):AnimationNode {
			var index:int = _animations.indexOf(animation);
			if (index < 0) throw new ArgumentError("Animation not found");
			_numAnimations--;
			var j:int = index + 1;
			while (index < _numAnimations) {
				_animations[index] = _animations[j];
				index++;
				j++;
			}
			_animations.length = _numAnimations;
			_weights.length = _numAnimations;
			if (_active == animation) {
				if (_numAnimations > 0) {
					_active = _animations[int(_numAnimations - 1)];
					_weights[int(_numAnimations - 1)] = 1;
				} else {
					_active = null;
				}
			}
			super.removeNode(animation);
			return animation;
		}

		/**
		 * Returns the child animation  that exists at the specified index.
		 * 
		 * @param index The index position of the child object.
		 */
		public function getAnimationAt(index:int):AnimationNode {
			return _animations[index];
		}

		/**
		 * Returns number of animations.
		 */
		public function numAnimations():int {
			return _numAnimations;
		}

	}
}
