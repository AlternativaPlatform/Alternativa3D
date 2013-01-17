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
	public class SourceVariable extends Variable {
		public var relative:RelativeVariable;

		override public function get size():uint {
			if (relative) {
				return 0;
			}
			return super.size;
		}

		public function SourceVariable(source:String) {
			var strType:String = String(source.match(/[catsoiv]/g)[0]);

			var regmask:uint;

			var relreg:Array = source.match(/\[.*\]/g);
			var isRel:Boolean = relreg.length > 0;
			if (isRel) {
				source = source.replace(relreg[0], "0");
			} else {
				index = parseInt(source.match(/\d+/g)[0], 10);
			}

			var swizzle:Array = source.match(/\.[xyzw]{1,4}/);

			var maskmatch:String = swizzle ? swizzle[0]:null;
			if (maskmatch) {
				regmask = 0;
				var cv:int;
				var maskLength:uint = maskmatch.length;
				for (var i:int = 1; i < maskLength; i++) {
					cv = maskmatch.charCodeAt(i) - X_CHAR_CODE;
					if (cv == -1) cv = 3;
					regmask |= cv << ( ( i - 1 ) << 1 );
				}
				for ( ; i <= 4; i++ )
					regmask |= cv << ( ( i - 1 ) << 1 );
				// repeat last
			} else {
				regmask = 0xe4;
				// id swizzle or mask
			}
			lowerCode = (regmask << 24) | index;

			switch(strType) {
				case "a":
					type = VariableType.ATTRIBUTE;
					break;
				case "c":
					type = VariableType.CONSTANT;
					break;
				case "t":
					type = VariableType.TEMPORARY;
					break;
				case "o":
					type = VariableType.OUTPUT;
					break;
				case "v":
					type = VariableType.VARYING;
					break;
				case "i":
					type = VariableType.INPUT;
					break;
				default :
					throw new ArgumentError('Wrong source register type, must be "a" or "c" or "t" or "o" or "v" or "i", var = ' + source);
					break;
			}
			upperCode = type;
			if (isRel) {
				relative = new RelativeVariable(relreg[0]);
				lowerCode |= relative.lowerCode;
				upperCode |= relative.upperCode;
				isRelative = true;
			}
		}

		override public function writeToByteArray(byteCode:ByteArray, newIndex:int, newType:int, offset:int = 0):void {
			if (relative == null) {
				super.writeToByteArray(byteCode, newIndex, newType, offset);
			} else {
				byteCode.position = position + 2;
			}
			byteCode.position = position + offset + 4;
			byteCode.writeByte(newType);
		}

	}
}
