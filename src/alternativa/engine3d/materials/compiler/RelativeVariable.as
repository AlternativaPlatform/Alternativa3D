/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials.compiler
{
	import flash.utils.ByteArray;

	/**
	 * @private 
	 */
	public class RelativeVariable extends Variable {

		public function RelativeVariable(source:String) {
			var relname:Array = source.match( /[A-Za-z]/g );
			index = parseInt(source.match(/\d+/g)[0], 10);
			switch(relname[0]){
				case "a":
					type = VariableType.ATTRIBUTE;
					break;
				case "c":
					type = VariableType.CONSTANT;
					break;
				case "t":
					type = VariableType.TEMPORARY;
					break;
				case "i":
					type = VariableType.INPUT;
					break;
			}
			var selmatch:Array = source.match(/(\.[xyzw]{1,1})/);						
			if (selmatch.length == 0) {
				throw new Error("error: bad index register select"); 						
			}
			var relsel:int = selmatch[0].charCodeAt(1) - X_CHAR_CODE;
			if (relsel == -1) relsel = 3;
			var relofs:Array = source.match(/\+\d{1,3}/g);
			var reloffset:int = 0;
			if (relofs.length > 0) {
				reloffset = parseInt(relofs[0], 10);
			}
			if (reloffset < 0 || reloffset > 255) {
				throw new Error("Error: index offset " + reloffset + " out of bounds. [0..255]"); 							
			} 

			lowerCode = reloffset << 16 | index;
			upperCode |= type << 8;
			upperCode |=  relsel << 16;
			upperCode |= 1 << 31;
		}

		override public function writeToByteArray(byteCode:ByteArray, newIndex:int, newType:int, offset:int = 0):void {
			byteCode.position = position + offset;
			byteCode.writeShort(newIndex);
			byteCode.position = position + offset + 5;
			byteCode.writeByte(newType);
		}

	}
}
