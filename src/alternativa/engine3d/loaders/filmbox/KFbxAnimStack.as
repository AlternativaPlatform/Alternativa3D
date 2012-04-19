package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: The Animation stack is a collection of animation layers.

	 The Fbx document can have one or more animation stacks. Each stack can be viewed as one "take" in the previous versions of the FBX SDK. The "stack" terminology comes from the fact that the object contains 1 to n animation layers that are evaluated according to their blending modes to produce a resulting animation for a given attribute.

	 */
	public class KFbxAnimStack {
		public var layers:Vector.<KFbxAnimLayer> = new Vector.<KFbxAnimLayer>();
	}
}
