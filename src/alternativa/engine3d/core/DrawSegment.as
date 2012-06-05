package alternativa.engine3d.core {

	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	public class DrawSegment {

		public var object:Object3D;
		public var surface:Surface;
		public var geometry:Geometry;
		// TODO: use uint hash instead of program
		public var program:ShaderProgram;
		public var transformProcedure:Procedure;
		public var deltaTransformProcedure:Procedure;

		public var next:DrawSegment;

		private static var collector:DrawSegment;

		public static function create(object:Object3D, surface:Surface, geometry:Geometry, program:ShaderProgram):DrawSegment {
			var res:DrawSegment;
			if (collector != null) {
				res = collector;
				collector = collector.next;
				res.next = null;
			} else {
				//trace("new DrawUnit");
				res = new DrawSegment();
			}
			res.object = object;
			res.surface = surface;
			res.geometry = geometry;
			res.program = program;
			return res;
		}

		public static function destroy(element:DrawSegment):void {
			element.object = null;
			element.surface = null;
			element.geometry = null;
			element.program =  null;
			element.transformProcedure = null;
			element.deltaTransformProcedure = null;
			element.next = collector;
			collector = element;
		}

	}
}
