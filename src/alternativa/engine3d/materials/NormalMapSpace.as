/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials {

	/**
	 * NormalMapSpace offers constant values that can be used for the   normalMapSpace property of materials which use normal map.
	 *
	 * @see StandardMaterial#normalMapSpace
	 */
	public class NormalMapSpace {

		/**
		 * Normal map defined in surface space, y-axis oriented on top.
		 */
		public static const TANGENT_RIGHT_HANDED:int = 0;
		/**
		 * Normal map defined in surface space, y-axis oriented on bottom.
		 */
		public static const TANGENT_LEFT_HANDED:int = 1;
		/**
		 * Normal map defined in object space.
		 */
		public static const OBJECT:int = 2;
		
	}
}
