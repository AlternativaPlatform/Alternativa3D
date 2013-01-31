/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.loaders.ParserMaterial;

	/**
	 * @private
	 */
	public class DaeMaterial extends DaeElement {
	
		use namespace collada;
	
		/**
		 * Material of engine.
		 * Call <code>parse()</code> before using.
		 */
		public var material:ParserMaterial;
	
		/**
		 * Name of texture channel for color map of object.
		 * Call <code>parse()</code> before using.
		 */
		public var mainTexCoords:String;
	
		/**
		 * If <code>true</code>material is in use.
		 */
		public var used:Boolean = false;
	
		public function DaeMaterial(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		private function parseSetParams():Object {
			var params:Object = {};
			var list:XMLList = data.instance_effect.setparam;
			for each (var element:XML in list) {
				var param:DaeParam = new DaeParam(element, document);
				params[param.ref] = param;
			}
			return params;
		}
	
		private function get effectURL():XML {
			return data.instance_effect.@url[0];
		}
	
		override protected function parseImplementation():Boolean {
			var effect:DaeEffect = document.findEffect(effectURL);
			if (effect != null) {
				effect.parse();
				material = effect.getMaterial(parseSetParams());
				mainTexCoords = effect.mainTexCoords;
				if (material != null) {
					material.name = cloneString(name);
				}
				return true;
			}
			return false;
		}
	
	}
}
