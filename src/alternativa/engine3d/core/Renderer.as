/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;

	use namespace alternativa3d;

	/**
	 * @private 
	 */
	public class Renderer {

		public static const SKY:int = 10;

		public static const OPAQUE:int = 20;

		public static const OPAQUE_OVERHEAD:int = 25;

		public static const DECALS:int = 30;

		public static const TRANSPARENT_SORT:int = 40;

		public static const NEXT_LAYER:int = 50;

		alternativa3d var camera:Camera3D;

		/**
		 * @private
		 */
		alternativa3d var segmentsPriorities:Vector.<DrawSegment> = new Vector.<DrawSegment>();

		// Key - context, value - properties.
//		protected static var properties:Dictionary = new Dictionary(true);
//		protected var _context3D:Context3D;
//		protected var _contextProperties:RendererContext3DProperties;

		alternativa3d var contextProgram:Program3D = null;
		alternativa3d var contextBlendModeSource:String = null;
		alternativa3d var contextBlendModeDestination:String = null;
		alternativa3d var contextCulling:String = null;
		alternativa3d var contextPtojectionTransform:Transform3D = null;

		alternativa3d var vbMask:uint = 0;

		alternativa3d function addSegment(segment:DrawSegment, priority:int):void {
			// Increase array of priorities, if it is necessary
			if (priority >= segmentsPriorities.length) segmentsPriorities.length = priority + 1;
			// Add
			segment.next = segmentsPriorities[priority];
			segmentsPriorities[priority] = segment;
		}

		alternativa3d function render(context3D:Context3D):void {
//			updateContext3D(context3D);

			// TODO: Sort transparent parts
			// TODO: Sort surfaces by shader, geometry, textures

			// Render segments
			var prioritiesLength:int = segmentsPriorities.length;
			for (var i:int = 0; i < prioritiesLength; i++) {
				var list:DrawSegment = segmentsPriorities[i];
				if (list != null) {
					switch (i) {
						case Renderer.SKY:
							context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
							break;
						case Renderer.OPAQUE:
							context3D.setDepthTest(true, Context3DCompareMode.LESS);
							break;
						case Renderer.OPAQUE_OVERHEAD:
							context3D.setDepthTest(false, Context3DCompareMode.EQUAL);
							break;
						case Renderer.DECALS:
							context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
							break;
						case Renderer.TRANSPARENT_SORT:
							if (list.next != null) list = sortByAverageZ(list);
							context3D.setDepthTest(false, Context3DCompareMode.LESS);
							break;
						case Renderer.NEXT_LAYER:
							context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
							break;
					}
					// Rendering
					while (list != null) {
						var next:DrawSegment = list.next;
						list.surface.material.draw(context3D, camera, list);
						// Send to collector
						DrawSegment.destroy(list);
						list = next;
					}
					segmentsPriorities[i] = null;
				}
			}
//			_contextProperties.culling = null;
//			_contextProperties.blendSource = null;
//			_contextProperties.blendDestination = null;
//			_contextProperties.program = null;
		}

		alternativa3d function drawTriangles(context:Context3D, geometry:Geometry, surface:Surface):void{
			camera.numDraws++;
			camera.numTriangles += surface.numTriangles;
			context.drawTriangles(geometry._indexBuffer, surface.indexBegin, surface.numTriangles);
		}

		alternativa3d function updateProgram(context:Context3D, program:ShaderProgram):void{
			if (contextProgram != program.program) {
				contextProgram = program.program;
				context.setProgram(program.program);
			}
		}

		alternativa3d function updateCulling(context:Context3D, culling:String ):void{
			if (contextCulling != culling) {
				contextCulling = culling;
				context.setCulling(culling);
			}
		}

		alternativa3d function updateBlendFactor(context:Context3D, source:String, destination:String):void{
			if (contextBlendModeSource != source || contextBlendModeDestination != destination) {
				contextBlendModeSource = source;
				contextBlendModeDestination = destination;
				context.setBlendFactors(source, destination);
			}
		}

		alternativa3d function updateProjectionTransform(context:Context3D, variableIndex:int, projectionTransform:Transform3D):void{
			if (contextPtojectionTransform != projectionTransform){
				contextPtojectionTransform = projectionTransform;
				camera.setProjectionConstants(context, variableIndex, contextPtojectionTransform);
			}
		}

//		protected function updateContext3D(value:Context3D):void {
//			if (_context3D != value) {
//				_contextProperties = properties[value];
//				if (_contextProperties == null) {
//					_contextProperties = new RendererContext3DProperties();
//					properties[value] = _contextProperties;
//				}
//				_context3D = value;
//			}
//		}

		alternativa3d function sortByAverageZ(list:DrawSegment, direction:Boolean = true):DrawSegment {
			var left:DrawSegment = list;
			var right:DrawSegment = list.next;
			while (right != null && right.next != null) {
				list = list.next;
				right = right.next.next;
			}
			right = list.next;
			list.next = null;
			if (left.next != null) {
				left = sortByAverageZ(left, direction);
			}
			if (right.next != null) {
				right = sortByAverageZ(right, direction);
			}
			var flag:Boolean = direction ? (left.object.localToCameraTransform.l > right.object.localToCameraTransform.l) : (left.object.localToCameraTransform.l < right.object.localToCameraTransform.l);
			if (flag) {
				list = left;
				left = left.next;
			} else {
				list = right;
				right = right.next;
			}
			var last:DrawSegment = list;
			while (true) {
				if (left == null) {
					last.next = right;
					return list;
				} else if (right == null) {
					last.next = left;
					return list;
				}
				if (flag) {
					if (direction ? (left.object.localToCameraTransform.l > right.object.localToCameraTransform.l) : (left.object.localToCameraTransform.l < right.object.localToCameraTransform.l)) {
						last = left;
						left = left.next;
					} else {
						last.next = right;
						last = right;
						right = right.next;
						flag = false;
					}
				} else {
					if (direction ? (left.object.localToCameraTransform.l < right.object.localToCameraTransform.l) : (left.object.localToCameraTransform.l > right.object.localToCameraTransform.l)) {
						last = right;
						right = right.next;
					} else {
						last.next = left;
						last = left;
						left = left.next;
						flag = true;
					}
				}
			}
			return null;
		}

		// TODO: remove this methods
		alternativa3d function createDrawUnit(object:Object3D, program:Program3D, iBuffer:IndexBuffer3D, indexBegin:int, numTriangles:int, shader:ShaderProgram = null):DrawUnit {
			return null;
		}
		alternativa3d function addDrawUnit(drawUnit:DrawUnit, priority:int):void {
		}

	}
}
