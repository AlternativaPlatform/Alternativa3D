/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Base class for all materials. Material defines, in which way surface will be visualized.
	 */
	public class Material {

		/**
		 * Name of the material
		 */
		public var name:String;
		
		/**
		 * @private 
		 */
		alternativa3d static const _projectProcedure:Procedure = getProjectProcedure();

		private static function getProjectProcedure():Procedure {
			var res:Procedure = new Procedure(["m44 o0, i0, c0"], "projectProcedure");
			res.assignVariableName(VariableType.CONSTANT, 0, "cProjMatrix", 4);
			return res;
		}

		public function Material() {
		}

		/**
		 * @private 
		 */
		alternativa3d function appendPositionTransformProcedure(transformProcedure:Procedure, vertexShader:Linker):String {
			vertexShader.declareVariable("tTransformedPosition");
			vertexShader.addProcedure(transformProcedure);
			vertexShader.setInputParams(transformProcedure, "aPosition");
			vertexShader.setOutputParams(transformProcedure, "tTransformedPosition");
			return "tTransformedPosition";
		}

		/**
		 * Gather resources used by material for uploading into context3D.
		 * 
		 * @param resourceType Gather the resources given type only.
		 * @return Vector consists of resources.
		 * @see flash.display.Stage3D
		 */
		public function getResources(resourceType:Class = null):Vector.<Resource> {
			var res:Vector.<Resource> = new Vector.<Resource>();
			var dict:Dictionary = new Dictionary();
			var count:int = 0;
			fillResources(dict, resourceType);
			for (var key:* in dict) {
				res[count++] = key as Resource;
			}
			return res;
		}

		/**
		 * @private 
		 */
		alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void {
		}

		/**
		 * @private 
		 */
		alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
		}

		/**
		 * Duplicates an instance of a Material.
		 * @return A new Material object that is identical to the original.
		 */
		public function clone():Material {
			var res:Material = new Material();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * Duplicates basic properties.  Invoked by<code>clone()</code>.
		 * @param source Source of properties to be copied from.
		 */
		protected function clonePropertiesFrom(source:Material):void {
			name = source.name;
		}

	}
}
