/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	import flash.utils.ByteArray;

	/**
	 * @private
	 */
	public class DaeElement {
	
		use namespace collada;
	
		public var document:DaeDocument;
	
		public var data:XML;
	
		/**
		 * -1 - not parsed, 0 - parsed with error, 1 - parsed without error.
		 */
		private var _parsed:int = -1;
	
		private static var _byteArray:ByteArray = new ByteArray();
		
		public function DaeElement(data:XML, document:DaeDocument) {
			this.document = document;
			this.data = data;
		}
	
		public function cloneString(str:String):String {
			if(str == null) return null;
			_byteArray.position = 0;
			_byteArray.writeUTF(str);
			_byteArray.position = 0;
			var res:String =  _byteArray.readUTF();
			return res;
		}
		
		/**
		 * Performs pre-setting of object.
		 * @return <code>false</code> on error.
		 */
		public function parse():Boolean {
			// -1 - not parsed, 0 - parsed with error, 1 - parsed without error.
			if (_parsed < 0) {
				_parsed = parseImplementation() ? 1 : 0;
				return _parsed != 0;
			}
			return _parsed != 0;
		}
	
		/**
		 * Overridden method <code>parse()</code>.
		 */
		protected function parseImplementation():Boolean {
			return true;
		}
	
		/**
		 * Returns array of String values.
		 */
		protected function parseStringArray(element:XML):Array {
			return element.text().toString().split(/\s+/);
		}
	
		protected function parseNumbersArray(element:XML):Array {
			var arr:Array = element.text().toString().split(/\s+/);
			for (var i:int = 0, count:int = arr.length; i < count; i++) {
				var value:String = arr[i];
				if (value.indexOf(",") != -1) {
					value = value.replace(/,/, ".");
				}
				arr[i] = parseFloat(value);
			}
			return arr;
		}
	
		protected function parseIntsArray(element:XML):Array {
			var arr:Array = element.text().toString().split(/\s+/);
			for (var i:int = 0, count:int = arr.length; i < count; i++) {
				var value:String = arr[i];
				arr[i] = parseInt(value, 10);
			}
			return arr;
		}
	
		protected function parseNumber(element:XML):Number {
			var value:String = element.toString().replace(/,/, ".");
			return parseFloat(value);
		}
	
		public function get id():String {
			var idXML:XML = data.@id[0];
			return (idXML == null) ? null : idXML.toString();
		}
	
		public function get sid():String {
			var attr:XML = data.@sid[0];
			return (attr == null) ? null : attr.toString();
		}
	
		public function get name():String {
			var nameXML:XML = data.@name[0];
			return (nameXML == null) ? null : nameXML.toString();
		}
	
	}
}
