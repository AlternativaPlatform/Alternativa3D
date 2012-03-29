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
	 * Animation tree node. Animation in Alternativa3D is built over the blend tree.
	 * This tree is intended for combining a set of animations and keeping unambiguous status
	 * of each property being animated in every frame. E.g. there can be independent animations
	 * for legs and hands, that will be presented by the nodes of blend tree. With the help of blenders,
	 * derived from <code>AnimationNode</code> you can change or blend nodes of blend tree. Every tree animation
	 * is controlled by <code>AnimationController</code>. <code>AnimationNode</code> instance have to be a root element of the tree.
	 *
	 */
	public class AnimationNode {

		/**
		 * @private 
		 */
		alternativa3d var _isActive:Boolean = false;

		/**
		 * @private 
		 */
		alternativa3d var _parent:AnimationNode;
		/**
		 * @private 
		 */
		alternativa3d var controller:AnimationController;

		/**
		 * Animation speed.
		 */
		public var speed:Number = 1;
		
		/**
		 * Determines if the animation is active.
		 */
		public function get isActive():Boolean {
			return _isActive && controller != null;
		}

		/**
		 * Parent of this node in animation tree hierarchy.
		 */
		public function get parent():AnimationNode {
			return _parent;
		}


		/**
		 * @private 
		 */
		alternativa3d function update(elapsed:Number, weight:Number):void {
		}
		
		/**
		 * @private 
		 */
		alternativa3d function setController(value:AnimationController):void {
			this.controller = value;
		}

		/**
		 * @private 
		 */
		alternativa3d function addNode(node:AnimationNode):void {
			if (node._parent != null) {
				node._parent.removeNode(node);
			}
			node._parent = this;
			node.setController(controller);
		}

		/**
		 * @private 
		 */
		alternativa3d function removeNode(node:AnimationNode):void {
			node.setController(null);
			node._isActive = false;
			node._parent = null;
		}

	}
}
