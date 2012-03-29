/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.core.Object3D;
	import alternativa.types.Long;

	import flash.utils.Dictionary;

	/**
	 * @private
	 */
	public class IncrementalIDGenerator implements IIDGenerator {

		private var lastID:uint = 0;
		private var objects:Dictionary;

		public function IncrementalIDGenerator() {
			objects = new Dictionary(true);
		}

		public function getID(object:Object3D):Long {
			var result:Long = objects[object];
			if (result == null) {
				result = objects[object] = Long.fromInt(lastID); lastID++;
			}
			return result;
		}
	}
}
