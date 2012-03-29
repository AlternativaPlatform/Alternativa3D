/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials.compiler {

	import flash.utils.ByteArray;

	/**
	 * @private 
	 */
	public class Variable {

		protected static const X_CHAR_CODE:Number =  "x".charCodeAt(0);

		public var name:String;
		// Index of register.
		public var index:int;
		// Type of VariableType register.
		public var type:uint;
		// Location of calling for variable in byte code.
		public var position:uint = 0;
		// Next calling for variable with the same index.
		public var next:Variable;

		public var lowerCode:uint;
		public var upperCode:uint;
		public var isRelative:Boolean;
		private var _size:uint = 1;

		private static var collector:Variable;

		public static function create():Variable {
			if(collector == null){
				collector = new Variable();
			}
			var output:Variable = collector;
			collector = collector.next;
			output.next = null;
			return output;
		}

		public function dispose():void {
			next = collector;
			collector = this;
		}

		public function Variable()	{
		}

		public function get size():uint {
			return _size;
		}

		public function set size(value:uint):void {
			_size = value;
		}
		
		public function writeToByteArray(byteCode:ByteArray, newIndex:int, newType:int, offset:int = 0):void {
			byteCode.position = position + offset;
			byteCode.writeShort(newIndex);
		}

	}
}
