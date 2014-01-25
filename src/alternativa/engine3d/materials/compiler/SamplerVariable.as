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
	public class SamplerVariable extends Variable {
		
		public function SamplerVariable(source:String) {
			var strType:String = String(source.match(/[si]/g)[0]);
			switch(strType){
				case "s":
					upperCode = VariableType.SAMPLER;
					break;
				case "i":
					upperCode = VariableType.INPUT;
					break;
			}
			index = parseInt(source.match(/\d+/g)[0], 10);
			lowerCode = index;
			var optsi:int = source.search(/<.*>/g);
			var opts:Array;
			if (optsi != -1) {
				opts = source.substring(optsi).match(/(\w+)/g);
			}
			type = upperCode;
			//upperInt = 5; // type 5 
			var optsLength:uint = opts.length;
			for (var i:int = 0; i < optsLength; i++) {
				var op:String = opts[i]; 
				switch(op){
					case "rgba":
						upperCode &= ~(0xf00);
						break;
					case "dxt1":
						upperCode &= ~(0xf00);
						upperCode |= 0x100;
						break;
					case "dxt5":
						upperCode &= ~(0xf00);
						upperCode |= 0x200;
						break;
					case "video":
						upperCode &= ~(0xf00);
						upperCode |= 0x300;
						break;
					case "2d":
						upperCode &= ~(0xf000);
						break;
					case "3d":
						upperCode &= ~(0xf000);
						upperCode |= 0x2000;
						break;
					case "cube":
						upperCode &= ~(0xf000);
						upperCode |= 0x1000;
						break;
					case "mipnearest":
						upperCode &= ~(0xf000000);
						upperCode |= 0x1000000;
						break;
					case "miplinear":
						upperCode &= ~(0xf000000);
						upperCode |= 0x2000000;
						break;
					case "mipnone":
					case "nomip":
						upperCode &= ~(0xf000000);
						break;
					case "nearest":
						upperCode &= ~(0xf0000000);
						break;
					case "linear":
						upperCode &= ~(0xf0000000);
						upperCode |= 0x10000000;
						break;
					case "centroid":
						upperCode |= 0x100000000;
						break;
					case "single":
						upperCode |= 0x200000000;
						break;
					case "depth":
						upperCode |= 0x400000000;
						break;
					case "repeat":
					case "wrap":
						upperCode &= ~(0xf00000);
						upperCode |= 0x100000;
						break;
					case "clamp":
						upperCode &= ~(0xf00000);
						break;
					default:
						//Texture LOD bias, usage example tex t0, v1, s0 <2d,repeat,linear,miplinear,bias40>
						if(op.indexOf("bias")>-1) {
							var bias:int = int(op.slice(4,op.length)) << 16;
							lowerCode &= ~(0xff0000);
							lowerCode |= bias;
						}
				}
			}
		}

		override public function writeToByteArray(byteCode:ByteArray, newIndex:int, newType:int, offset:int = 0):void {
			super.writeToByteArray(byteCode, newIndex, newType, offset);
		}

	}
}
