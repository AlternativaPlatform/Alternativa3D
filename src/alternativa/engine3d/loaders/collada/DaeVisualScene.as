/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeVisualScene extends DaeElement {
	
		use namespace collada;
	
		public var nodes:Vector.<DaeNode>;
	
		public function DaeVisualScene(data:XML, document:DaeDocument) {
			super(data, document);
	
			// nodes are declared in <visual_scene>.
			constructNodes();
		}
	
		public function constructNodes():void {
			var nodesList:XMLList = data.node;
			var count:int = nodesList.length();
			nodes = new Vector.<DaeNode>(count);
			for (var i:int = 0; i < count; i++) {
				var node:DaeNode = new DaeNode(nodesList[i], document, this);
				if (node.id != null) {
					document.nodes[node.id] = node;
				}
				nodes[i] = node;
			}
		}
	
	}
}
