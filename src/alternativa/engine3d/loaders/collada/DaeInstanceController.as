/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import flash.utils.Dictionary;

	/**
	 * @private
	 */
	public class DaeInstanceController extends DaeElement {
	
		use namespace collada;

		public var node:DaeNode;

		/**
		 * List of top-level joints, which have common parent.  (List of top-level joints, that have the common parent)
		 * Call <code>parse()</code> befire using.
		 */
		public var topmostJoints:Vector.<DaeNode>;

		public function DaeInstanceController(data:XML, document:DaeDocument, node:DaeNode) {
			super(data, document);
			this.node = node;
		}

		override protected function parseImplementation():Boolean {
			var controller:DaeController = this.controller;
			if (controller != null) {
				topmostJoints = controller.findRootJointNodes(this.skeletons);
				if (topmostJoints != null && topmostJoints.length > 1) {
					replaceNodesByTopmost(topmostJoints);
				}
			}
			return topmostJoints != null;
		}

		/**
		 * Replaces each node in the list with its parent (the parent must be the same for all others node's or be a scene)
		 * @param nodes not empty array of nodes.
		 */
		private function replaceNodesByTopmost(nodes:Vector.<DaeNode>):void {
			var i:int;
			var node:DaeNode, parent:DaeNode;
			var numNodes:int = nodes.length;
			var parents:Dictionary = new Dictionary();
			for (i = 0; i < numNodes; i++) {
				node = nodes[i];
				for (parent = node.parent; parent != null; parent = parent.parent) {
					if (parents[parent]) {
						parents[parent]++;
					} else {
						parents[parent] = 1;
					}
				}
			}
			// Replase node with its parent if it has the same parent with each other node or has no parent at all
			for (i = 0; i < numNodes; i++) {
				node = nodes[i];
				while ((parent = node.parent) != null && (parents[parent] != numNodes)) {
					node = node.parent;
				}
				nodes[i] = node;
			}
		}

		private function get controller():DaeController {
			var controller:DaeController = document.findController(data.@url[0]);
			if (controller == null) {
				document.logger.logNotFoundError(data.@url[0]);
			}
			return controller;
		}

		private function get skeletons():Vector.<DaeNode> {
			var list:XMLList = data.skeleton;
			if (list.length() > 0) {
				var skeletons:Vector.<DaeNode> = new Vector.<DaeNode>();
				for (var i:int = 0, count:int = list.length(); i < count; i++) {
					var skeletonXML:XML = list[i];
					var skel:DaeNode = document.findNode(skeletonXML.text()[0]);
					if (skel != null) {
						skeletons.push(skel);
					} else {
						document.logger.logNotFoundError(skeletonXML);
					}
				}
				return skeletons;
			}
			return null;
		}

		public function parseSkin(materials:Object):DaeObject {
			var controller:DaeController = this.controller;
			if (controller != null) {
				controller.parse();
				return controller.parseSkin(materials, topmostJoints, this.skeletons);
			}
			return null;
		}

	}
}
