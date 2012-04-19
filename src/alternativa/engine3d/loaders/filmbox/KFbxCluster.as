package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: Class for clusters (links).
	 * A cluster, or link, is an entity acting on a geometry (KFbxGeometry). More precisely, the cluster acts on a subset of the geometry's control points. For each control point that the cluster acts on, the intensity of the cluster's action is modulated by a weight. The link mode (ELinkMode) specifies how the weights are taken into account.
	 */
	public class KFbxCluster { // extends KFbxSubDeformer {
		public var Indexes:Vector.<Number> = new Vector.<Number>;
		public var Weights:Vector.<Number> = new Vector.<Number>;
		public var Transform:Vector.<Number> = Vector.<Number>([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
		public var TransformLink:Vector.<Number> = Vector.<Number>([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

		// связь с джоинтом
		public var jointNode:KFbxNode;
	}
}
