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
	public class DestinationVariable extends Variable {

		public function DestinationVariable(source:String) {
			var strType:String = source.match(/[tovi]/)[0];
			index = parseInt(source.match(/\d+/)[0], 10);
			var swizzle:Array = source.match(/\.[xyzw]{1,4}/);
			var regmask:uint;
			var maskmatch:String = swizzle ? swizzle[0] : null;
			if (maskmatch != null) {
				regmask = 0;
				var cv:int; 
				var maskLength:uint = maskmatch.length;
				// If first char is point, then skip
				for (var i:int = 1; i < maskLength; i++) {
					cv = maskmatch.charCodeAt(i) - X_CHAR_CODE;
					if (cv == -1) cv = 3;
					regmask |= 1 << cv;
				}
			} else {
				regmask = 0xf; // id swizzle or mask						
			}
			lowerCode = (regmask << 16) | index;
			
			switch(strType){
				case "t":
					lowerCode |= 0x2000000;
					type = 2;
					break;
				case "o":
					lowerCode |= 0x3000000;
					type = 3;
					break;
				case "v":
					lowerCode |= 0x4000000;
					type = 4;
					break;
				case "i":
					lowerCode |= 0x6000000;
					type = 6;
					break;
				default :
					throw new ArgumentError("Wrong destination register type, must be \"t\" or \"o\" or \"v\", var = " + source);
					break;
			}
		}

		override public function writeToByteArray(byteCode:ByteArray, newIndex:int, newType:int, offset:int = 0):void {
			byteCode.position = position + offset;
			
			byteCode.writeUnsignedInt((lowerCode & ~(0xf00ffff)) | newIndex | (newType << 24));
		}
		
	}
}
