/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeArray extends DaeElement {
	
		use namespace collada;
	
		/**
		 * Array of String values.
		 * Call <code>parse()</code> before using.
		 */
		public var array:Array;
	
		public function DaeArray(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		public function get type():String {
			return String(data.localName());
		}
	
		override protected function parseImplementation():Boolean {
			array = parseStringArray(data);
			var countXML:XML = data.@count[0];
			if (countXML != null) {
				var count:int = parseInt(countXML.toString(), 10);
				if (array.length < count) {
					document.logger.logNotEnoughDataError(data.@count[0]);
					return false;
				} else {
					array.length = count;
					return true;
				}
			}
			return false;
		}
	
	}
}
