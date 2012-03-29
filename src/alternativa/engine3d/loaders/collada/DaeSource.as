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
	public class DaeSource extends DaeElement {
	
		use namespace collada;
	
		/**
		 * Types of arrays.
		 */
		private const FLOAT_ARRAY:String = "float_array";
		private const INT_ARRAY:String = "int_array";
		private const NAME_ARRAY:String = "Name_array";

		/**
		 * Array of Number items.
		 * Call <code>parse()</code> before using.
		 */
		public var numbers:Vector.<Number>;
		/**
		 * Array of int items.
		 * Call <code>parse()</code> before using.
		 */
		public var ints:Vector.<int>;
		/**
		 * Array of string items.
		 * Call <code>parse()</code> before using.
		 */
	
		public var names:Vector.<String>;
		/**
		 * Size in bytes of one number or int element
		 * Call <code>parse()</code> before using.
		 */
		public var stride:int;
	
		public function DaeSource(data:XML, document:DaeDocument) {
			super(data, document);
	
			// array declares within in <source>.
			constructArrays();
		}
	
		private function constructArrays():void {
			var children:XMLList = data.children();
			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				switch (child.localName()) {
					case FLOAT_ARRAY :
					case INT_ARRAY   :
					case NAME_ARRAY  :
						var array:DaeArray = new DaeArray(child, document);
						if (array.id != null) {
							document.arrays[array.id] = array;
						}
						break;
				}
			}
		}
	
		private function get accessor():XML {
			return data.technique_common.accessor[0];
		}
	
		override protected function parseImplementation():Boolean {
			var accessor:XML = this.accessor;
			if (accessor != null) {
				var arrayXML:XML = accessor.@source[0];
				var array:DaeArray = (arrayXML == null) ? null : document.findArray(arrayXML);
				if (array != null) {
					var countXML:String = accessor.@count[0];
					if (countXML != null) {
						var count:int = parseInt(countXML.toString(), 10);
						var offsetXML:XML = accessor.@offset[0];
						var strideXML:XML = accessor.@stride[0];
						var offset:int = (offsetXML == null) ? 0 : parseInt(offsetXML.toString(), 10);
						var stride:int = (strideXML == null) ? 1 : parseInt(strideXML.toString(), 10);
						array.parse();
						if (array.array.length < (offset + (count*stride))) {
							document.logger.logNotEnoughDataError(accessor);
							return false;
						}
						this.stride = parseArray(offset, count, stride, array.array, array.type);
						return true;
					}
				} else {
					document.logger.logNotFoundError(arrayXML);
				}
			}
			return false;
		}
	
		private function numValidParams(params:XMLList):int {
			var res:int = 0;
			for (var i:int = 0, count:int = params.length(); i < count; i++) {
				if (params[i].@name[0] != null) {
					res++;
				}
			}
			return res;
		}
	
		private function parseArray(offset:int, count:int, stride:int, array:Array, type:String):int {
			var params:XMLList = this.accessor.param;
			var arrStride:int = Math.max(numValidParams(params), stride);
			switch (type) {
				case FLOAT_ARRAY:
					numbers = new Vector.<Number>(int(arrStride*count));
					break;
				case INT_ARRAY:
					ints = new Vector.<int>(int(arrStride*count));
					break;
				case NAME_ARRAY:
					names = new Vector.<String>(int(arrStride*count));
					break;
			}
			var curr:int = 0;
			for (var i:int = 0; i < arrStride; i++) {
				// Only parameters which have name field should be read
				var param:XML = params[i];
				if (param == null || param.hasOwnProperty("@name")) {
					var j:int;
					switch (type) {
						case FLOAT_ARRAY:
							for (j = 0; j < count; j++) {
								var value:String = array[int(offset + stride*j + i)];
								if (value.indexOf(",") != -1) {
									value = value.replace(/,/, ".");
								}
								numbers[int(arrStride*j + curr)] = parseFloat(value);
							}
							break;
						case INT_ARRAY:
							for (j = 0; j < count; j++) {
								ints[int(arrStride*j + curr)] = parseInt(array[int(offset + stride*j + i)], 10);
							}
							break;
						case NAME_ARRAY:
							for (j = 0; j < count; j++) {
								names[int(arrStride*j + curr)] = array[int(offset + stride*j + i)];
							}
							break;
	
					}
					curr++;
				}
			}
			return arrStride;
		}
	
	}
}
