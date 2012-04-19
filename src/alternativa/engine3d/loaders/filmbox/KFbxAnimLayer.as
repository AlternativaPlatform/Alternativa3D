package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: The animation layer is a collection of animation curve nodes.

	 Its purpose is to store a variable number of KFbxAnimCurveNodes. The class provides different states flags (bool properties), an animatable weight, and the blending mode flag to indicate how the data on this layer is interacting with the data of the other layers during the evaluation.

	 */
	public class KFbxAnimLayer extends KFbxAnimCurveNode {
		// TODO blending support

		/** в V6 один получается 1 слой на KFbxNode, но curveNode-ы не привязаны к нему. */
		public function fixV6():void {
			fixV6CurveNodes(this);
		}

		private function fixV6CurveNodes(parent:KFbxAnimCurveNode):void {
			if (parent.node) {
				for each (var child:KFbxAnimCurveNode in parent.curveNodes) {
					if (child.curveNodes.length > 0) {
						child.node = parent.node;
						fixV6CurveNodes(child);
					}
				}
			}
		}
	}
}
