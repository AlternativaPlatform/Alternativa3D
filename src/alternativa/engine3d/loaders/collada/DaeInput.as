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
	public class DaeInput extends DaeElement {
	
		use namespace collada;
	
		public function DaeInput(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		public function get semantic():String {
			var attribute:XML = data.@semantic[0];
			return (attribute == null) ? null : attribute.toString();
		}
	
		public function get source():XML {
			return data.@source[0];
		}
	
		// todo: profiler shows that offset getter is seriously abused in DaePrimitive's fillGeometry
		private var _offset:int = -1;
		public function get offset():int {
			if (_offset < 0) {
				var attr:XML = data.@offset[0];
				_offset = (attr == null) ? 0 : parseInt(attr.toString(), 10);
			}
			return _offset;
		}
	
		public function get setNum():int {
			var attr:XML = data.@set[0];
			return (attr == null) ? 0 : parseInt(attr.toString(), 10);
		}
	
		/**
		 * If DaeSource, located at the link source, is type of Number and
		 * number of components is not less than specified number, then this method will return it.
		 *
		 */
		public function prepareSource(minComponents:int):DaeSource {
			var source:DaeSource = document.findSource(this.source);
			if (source != null) {
				source.parse();
				if (source.numbers != null && source.stride >= minComponents) {
					return source;
				} else {
				}
			} else {
				document.logger.logNotFoundError(data.@source[0]);
			}
			return null;
		}
	
	}
}
