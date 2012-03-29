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
	public class DaeInstanceMaterial extends DaeElement {
	
		use namespace collada;
	
		public function DaeInstanceMaterial(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		public function get symbol():String {
			var attribute:XML = data.@symbol[0];
			return (attribute == null) ? null : attribute.toString();
		}
	
		private function get target():XML {
			return data.@target[0];
		}
	
		public function get material():DaeMaterial {
			var mat:DaeMaterial = document.findMaterial(target);
			if (mat == null) {
				document.logger.logNotFoundError(target);
			}
			return mat;
		}
	
		public function getBindVertexInputSetNum(semantic:String):int {
			var bindVertexInputXML:XML = data.bind_vertex_input.(@semantic == semantic)[0];
			if (bindVertexInputXML == null) return 0;
			var setNumXML:XML = bindVertexInputXML.@input_set[0];
			return (setNumXML == null) ? 0 : parseInt(setNumXML.toString(), 10);
		}
	
	}
}
