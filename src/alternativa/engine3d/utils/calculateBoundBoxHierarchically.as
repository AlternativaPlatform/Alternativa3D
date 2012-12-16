package alternativa.engine3d.utils {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.utils.Object3DUtils;

	use namespace alternativa3d;
	public function calculateBoundBoxHierarchically(source : Object3D) : void {
		if (source == null) return;
		if (source.boundBox == null) source.calculateBoundBox();
		Object3DUtils.updateBoundBoxHierarchically(source, source.boundBox);
	}
}
