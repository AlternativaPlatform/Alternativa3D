/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.alternativa3d;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DaeVertices extends DaeElement {

		use namespace collada;

		/**
		 *   Source of vertex coordinates data. Stores coordinates in <code>numbers</code> array.
		 * <code>stride</code> property of source  is not less than three.
		 * Call <code>parse()</code> before using.
		 */
		public var positions:DaeSource;
		//private var texCoords:Vector.<DaeSource>;

		public function DaeVertices(data:XML, document:DaeDocument) {
			super(data, document);
		}

		override protected function parseImplementation():Boolean {
			// Get array of vertex coordinates.
			var inputXML:XML = data.input.(@semantic == "POSITION")[0];
			if (inputXML != null) {
				positions = (new DaeInput(inputXML, document)).prepareSource(3);
				if (positions != null) {
					return true;
				}
			}
			return false;
		}
	
	}
}
