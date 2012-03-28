package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;

	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class ShadowsSystem {

		private static const MAX_SHADOWMAPS:int = 3;
//		private static const MAX_SHADOWMAPS:int = 4;

		public var renderers:Vector.<ShadowRenderer> = new Vector.<ShadowRenderer>();
		
		private var containers:Dictionary = new Dictionary();
		
		public function ShadowsSystem() {
		}

		private var numShadowed:int;

		private var numActiveRenderers:int;
		private var activeRenderers:Vector.<ShadowRenderer> = new Vector.<ShadowRenderer>();

		private var maxShadows:int;
		
		public function update(root:Object3D):void {
			if (renderers.length == 0) return;
			numActiveRenderers = 0;
			var num:int = renderers.length;
			for (var i:int = 0; i < num; i++) {
				var renderer:ShadowRenderer = renderers[i];
				renderer.update();
				if (renderer.active) {
					activeRenderers[numActiveRenderers] = renderer;
					numActiveRenderers++;
				}
			}
			// Пробегаемся иерархически по объектам и проверяем наложение на них тени
			if (root.transformChanged) root.composeTransforms();
			root.localToGlobalTransform.copy(root.transform);
			numShadowed = 0;
			maxShadows = 0;
			recursive(root);
//			trace("SHADOWED:", numShadowed, ":", maxShadows);
		}
		
		private function recursive(object:Object3D):void {
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				var value:Vector.<ShadowRenderer> = null;
				var numRenderers:int = 0;
				if (child.visible) {
					if (child.transformChanged) child.composeTransforms();
					child.localToGlobalTransform.combine(object.localToGlobalTransform, child.transform);
					for (var i:int = 0; i < numActiveRenderers; i++) {
						var renderer:ShadowRenderer = activeRenderers[i];
						if (child.useShadow) {
							if (child.boundBox == null || renderer.cullReciever(child.boundBox, child)) {
								numShadowed++;
								if (value == null) {
									value = containers[child];
									if (value == null) {
										value = new Vector.<ShadowRenderer>();
										containers[child] = value;
									} else {
										value.length = 0;
									}
								}
								value[numRenderers] = renderer;
								numRenderers++;
							}
						}
					}
					recursive(child);
				}
				setRenderers(child, value, numRenderers);
			}
		}

		private function setRenderers(object:Object3D, renderers:Vector.<ShadowRenderer>, numShadowRenderers:int):void {
			if (numShadowRenderers > maxShadows) maxShadows = numShadowRenderers;
			if (numShadowRenderers > MAX_SHADOWMAPS) {
				numShadowRenderers = MAX_SHADOWMAPS;
				renderers.length = MAX_SHADOWMAPS;
			}
			object.shadowRenderers = renderers;
			object.numShadowRenderers = numShadowRenderers;
		}

	}
}
