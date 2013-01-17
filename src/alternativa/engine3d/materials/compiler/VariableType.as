/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials.compiler {

	/**
	 * @private
	 * Types of shader variables
	 */
	public class VariableType {

		/**
		 * Input attribute of vertex.
		 */
		public static const ATTRIBUTE:uint = 0;
		/**
		 * Constant.
		 */
		public static const CONSTANT:uint = 1;
		/**
		 * Temporary variable.
		 */
		public static const TEMPORARY:uint = 2;
		/**
		 * Output variable.
		 */
		public static const OUTPUT:uint = 3;
		/**
		 * Interpolated variable.
		 */
		public static const VARYING:uint = 4;
		/**
		 * Texture.
		 */
		public static const SAMPLER:uint = 5;
		/**
		 * Depth variable.
		 */
		public static const DEPTH:uint = 6;
		/**
		 * Input variable.
		 */
		public static const INPUT:uint = 7;
		
		public static const TYPE_NAMES:Vector.<String> = Vector.<String>(
			["attribute", "constant", "temporary", "output", "varying", "sampler", "depth", "input"]
		);
		public function VariableType() {
		}
		
	}
}
