package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private простое дерево, на листочках ключи KFbxAnimCurve
	 */
	public class KFbxAnimCurveNode {
		public var node:KFbxNode;

		public var channel:String;
		public var curveNodes:Vector.<KFbxAnimCurveNode> = new Vector.<KFbxAnimCurveNode>();

		public function collectNodes(nodes:Vector.<KFbxNode>):void {
			for each (var curveNode:KFbxAnimCurveNode in curveNodes) {
				if (curveNode.node) {
					if (nodes.indexOf(curveNode.node) < 0) {
						nodes.push(curveNode.node);
					}
				}
				curveNode.collectNodes(nodes);
			}
		}

		public function collectCurves(curves:Vector.<KFbxAnimCurveNode>, targetNode:KFbxNode):void {
			for each (var curveNode:KFbxAnimCurveNode in curveNodes) {
				if (curveNode.node == targetNode) {
					if (curveNode.curveNodes.length > 0) {
						// if children are not bound to node...
						if (curveNode.curveNodes [0].node == null) {
							// ...collect it...
							curves.push(curveNode);
						} else {
							// ...else keep drilling
							curveNode.collectCurves(curves, targetNode);
						}
					}
				}
			}
		}

		// KFbxAnimCurve:
		public var KeyTime:Vector.<Number> = new Vector.<Number>();
		public var KeyValueFloat:Vector.<Number> = new Vector.<Number>();

		public function interpolateValue(t:Number):Number {
			for (var i:int = 1, n:int = KeyTime.length; i < n; i++) {
				if (t > KeyTime [int(i)]) continue;
				// linear for now, TODO
				var c:Number = ( KeyTime [int(i)] - t )/( KeyTime [int(i)] - KeyTime [int(i - 1)] );
				return KeyValueFloat [int(i)]*(1 - c) + KeyValueFloat [int(i - 1)]*c;
			}
			return KeyValueFloat [int(n - 1)];
		}
	}
}
