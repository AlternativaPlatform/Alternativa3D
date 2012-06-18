/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.objects.Surface;

	use namespace alternativa3d;
	
	/**
	 * Base class for shadows.
	 */
	public class Shadow {

		/**
		 * @private
		 */
		alternativa3d static const NONE_MODE:int = 0;
		/**
		 * @private
		 */
		alternativa3d static const SIMPLE_MODE:int = 1;
		/**
		 * @private
		 */
		alternativa3d static const PCF_MODE:int = 2;

		/**
		 * Debug mode.
		 */
		public var debug:Boolean = false;

		/**
		 * @private
		 * Key for processing in materials.
		 */
		alternativa3d var type:int = 0;

		/**
		 * @private
		 */
		alternativa3d var _light:Light3D;

		/**
		 * @private
		 * inputs: position
		 */
		alternativa3d var vertexShadowProcedure:Procedure;
		
		/**
		 * @private
		 * outputs: shadow intensity
		 */
		alternativa3d var fragmentShadowProcedure:Procedure;

		/**
		 * @private
		 */
		alternativa3d function process(camera:Camera3D):void {
		}

		/**
		 * @private
		 */
		alternativa3d function setup(drawUnit:DrawUnit, vertexLinker:Linker, fragmentLinker:Linker, surface:Surface):void {
		}

	}
}
