/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.compiler.CommandType;
	import alternativa.engine3d.materials.compiler.VariableType;

	import avmplus.getQualifiedSuperclassName;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getDefinitionByName;

	/**
	 * @private
	 */
	public class A3DUtils {

		public static const NONE:int = 0;
		public static const DXT1:int = 1;
		public static const ETC1:int = 2;
		public static const PVRTC:int = 3;
		
		private static const DXT1Data:ByteArray = getDXT1();
		private static const PVRTCData:ByteArray = getPVRTC();
		private static const ETC1Data:ByteArray = getETC1();

		private static function getDXT1():ByteArray {
			var DXT1Data:Vector.<int> = Vector.<int>([65,84,70,0,2,71,2,2,2,3,0,0,12,0,0,0,16,0,0,85,105,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,10,87,77,80,72,79,84,79,0,25,0,192,122,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,224,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,16,0,0,85,105,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,10,87,77,80,72,79,84,79,0,25,0,192,122,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,224,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,16,0,0,85,105,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,10,87,77,80,72,79,84,79,0,25,0,192,122,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,224,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,7,143,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
			return getData(DXT1Data);
		}

		private static function getETC1():ByteArray {
			var ETC1Data:Vector.<int> = Vector.<int>([65,84,70,0,2,104,2,2,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,0,0,0,16,0,0,0,255,252,0,0,0,0,12,0,0,0,16,0,0,127,233,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,208,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,7,143,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,0,0,0,16,0,0,0,255,252,0,0,0,0,12,0,0,0,16,0,0,127,233,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,208,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,0,0,0,16,0,0,0,255,252,0,0,0,0,12,0,0,0,16,0,0,127,233,56,0,0,0,0,0,157,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,1,0,0,0,129,188,4,0,1,0,0,0,2,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,66,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,0,0,1,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,208,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,114,0,4,0]);
			return getData(ETC1Data);
		}

		private static function getPVRTC():ByteArray {
			var PVRTCData:Vector.<int> = Vector.<int>([65,84,70,0,2,173,2,2,2,3,0,0,0,0,0,0,0,0,13,0,0,0,16,0,0,0,104,190,153,255,0,0,0,0,15,91,0,0,16,0,0,102,12,228,2,255,225,0,0,0,0,0,223,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,2,0,0,0,129,188,4,0,1,0,0,0,4,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,132,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,1,0,3,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,165,192,0,7,227,99,186,53,197,40,185,134,182,32,130,98,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,143,192,120,64,6,16,34,52,192,196,65,132,90,98,68,16,17,68,60,91,8,48,76,35,192,97,132,71,76,33,164,97,1,2,194,12,19,8,240,29,132,24,38,17,224,48,194,35,166,16,210,48,128,128,24,68,121,132,52,204,32,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,16,0,0,0,233,56,90,0,0,0,0,12,0,0,0,16,0,0,127,237,210,0,0,0,0,0,155,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,2,0,0,0,129,188,4,0,1,0,0,0,4,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,64,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,1,0,3,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17,200,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,16,0,0,0,233,56,90,0,0,0,0,12,0,0,0,16,0,0,127,237,210,0,0,0,0,0,155,73,73,188,1,8,0,0,0,5,0,1,188,1,0,16,0,0,0,74,0,0,0,128,188,4,0,1,0,0,0,2,0,0,0,129,188,4,0,1,0,0,0,4,0,0,0,192,188,4,0,1,0,0,0,90,0,0,0,193,188,4,0,1,0,0,0,64,0,0,0,0,0,0,0,36,195,221,111,3,78,254,75,177,133,61,119,118,141,201,9,87,77,80,72,79,84,79,0,25,0,192,120,0,1,0,3,96,0,160,0,10,0,0,160,0,0,0,4,111,255,0,1,0,0,1,0,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17,200,0,0,0,0,0,0,0,0,0,0]);
			return getData(PVRTCData);
		}

		private static function getData(source:Vector.<int>):ByteArray {
			var result:ByteArray = new ByteArray();
			for (var i:int = 0, length:int = source.length; i < length; i++) {
				result.writeByte(source[i]);
			}
			return result;
		}

		public static function getSizeFromATF(byteArray:ByteArray, size:Point):void {
			byteArray.position = 7;
			var w:int = byteArray.readByte();
			var h:int = byteArray.readByte();
			size.x = 1 << w;
			size.y = 1 << h;
			byteArray.position = 0;
		}

		public static function getSupportedTextureFormat(context3D:Context3D):int {
			var testTexture:Texture = context3D.createTexture(4, 4, Context3DTextureFormat.COMPRESSED, false);
			var result:int = NONE;
			try {
				testTexture.uploadCompressedTextureFromByteArray(DXT1Data, 0);
				result = DXT1;
			} catch(e:Error) {
				result = NONE;
			}
			if (result == NONE) {
				try {
					testTexture.uploadCompressedTextureFromByteArray(PVRTCData, 0);
					result = PVRTC;
				} catch(e:Error) {
					result = NONE;
				}
			}
			if (result == NONE) {
				try {
					testTexture.uploadCompressedTextureFromByteArray(ETC1Data, 0);
					result = ETC1;
				} catch(e:Error) {
					result = NONE;
				}
			}
			testTexture.dispose();
			return result;
		}

		public static function vectorNumberToByteArray(vector:Vector.<Number>):ByteArray {
			var result:ByteArray = new ByteArray();
			result.endian = Endian.LITTLE_ENDIAN;
			for (var i:int = 0; i < vector.length; i++) {
				result.writeFloat(vector[i]);
			}
			result.position = 0;
			return result;
		}

		public static function byteArrayToVectorUint(byteArray:ByteArray):Vector.<uint> {
			var result:Vector.<uint> = new Vector.<uint>();
			var length:uint = 0;
			byteArray.position = 0;
			byteArray.endian = Endian.LITTLE_ENDIAN;
			while (byteArray.bytesAvailable > 0) {
				result[length++] = byteArray.readUnsignedShort();
			}
			return result;
		}

		public static function createVertexBufferFromByteArray(context:Context3D, byteArray:ByteArray, numVertices:uint, stride:uint = 3):VertexBuffer3D {
			if (context == null) {
				throw new ReferenceError("context is not set");
			}
			var buffer:VertexBuffer3D = context.createVertexBuffer(numVertices, stride);
			buffer.uploadFromByteArray(byteArray, 0, 0, numVertices);
			return buffer;
		}

		public static function createVertexBufferFromVector(context:Context3D, vector:Vector.<Number>, numVertices:uint, stride:uint = 3):VertexBuffer3D {
			if (context == null) {
				throw new ReferenceError("context is not set");
			}
			var buffer:VertexBuffer3D = context.createVertexBuffer(numVertices, stride);

			var byteArray:ByteArray = A3DUtils.vectorNumberToByteArray(vector);
			buffer.uploadFromByteArray(byteArray, 0, 0, numVertices);
			return buffer;
		}

		public static function createTextureFromByteArray(context:Context3D, byteArray:ByteArray, width:Number, height:Number, format:String):Texture {
			if (context == null) {
				throw new ReferenceError("context is not set");
			}
			var texture:Texture = context.createTexture(width, height, format, false);
			texture.uploadCompressedTextureFromByteArray(byteArray, 0);

			return texture;
		}

		public static function createIndexBufferFromByteArray(context:Context3D, byteArray:ByteArray, numIndices:uint):IndexBuffer3D {
			if (context == null) {
				throw new ReferenceError("context is not set");
			}
			var buffer:IndexBuffer3D = context.createIndexBuffer(numIndices);
			buffer.uploadFromByteArray(byteArray, 0, 0, numIndices);

			return buffer;
		}

		public static function createIndexBufferFromVector(context:Context3D, vector:Vector.<uint>, numIndices:int = -1):IndexBuffer3D {
			if (context == null) {
				throw new ReferenceError("context is not set");
			}
			var count:uint = numIndices > 0 ? numIndices : vector.length;
			var buffer:IndexBuffer3D = context.createIndexBuffer(count);
			buffer.uploadFromVector(vector, 0, count);

			var byteArray:ByteArray = new ByteArray();
			byteArray.endian = Endian.LITTLE_ENDIAN;
			for (var i:int = 0; i < count; i++) {
				byteArray.writeInt(vector[i]);
			}
			byteArray.position = 0;

			buffer.uploadFromVector(vector, 0, count);

			return buffer;
		}

		// Disassembler
		private static var programType:Vector.<String> = Vector.<String>(["VERTEX", "FRAGMENT"]);
		private static var samplerDimension:Vector.<String> = Vector.<String>(["2D", "cube", "3D"]);
		private static var samplerWraping:Vector.<String> = Vector.<String>(["clamp", "repeat"]);
		private static var samplerMipmap:Vector.<String> = Vector.<String>(["mipnone", "mipnearest", "miplinear"]);
		private static var samplerFilter:Vector.<String> = Vector.<String>(["nearest", "linear"]);
		private static var swizzleType:Vector.<String> = Vector.<String>(["x", "y", "z", "w"]);
		private static var twoOperandsCommands:Dictionary;

		// TODO: option to turn off auto-prefixes
		public static function disassemble(byteCode:ByteArray):String {
			if (!twoOperandsCommands) {
				twoOperandsCommands = new Dictionary();
				twoOperandsCommands[0x1] = true;
				twoOperandsCommands[0x2] = true;
				twoOperandsCommands[0x3] = true;
				twoOperandsCommands[0x4] = true;
				twoOperandsCommands[0x6] = true;
				twoOperandsCommands[0xb] = true;
				twoOperandsCommands[0x11] = true;
				twoOperandsCommands[0x12] = true;
				twoOperandsCommands[0x13] = true;
				twoOperandsCommands[0x17] = true;
				twoOperandsCommands[0x18] = true;
				twoOperandsCommands[0x19] = true;
				twoOperandsCommands[0x26] = true;
				twoOperandsCommands[0x28] = true;
				twoOperandsCommands[0x29] = true;
				twoOperandsCommands[0x2a] = true;
				twoOperandsCommands[0x2c] = true;
				twoOperandsCommands[0x2d] = true;
			}
			var res:String = "";
			byteCode.position = 0;
			if (byteCode.bytesAvailable < 7) {
				return "error in byteCode header";
			}

			res += "magic = " + byteCode.readUnsignedByte().toString(16);
			res += "\nversion = " + byteCode.readInt().toString(10);
			res += "\nshadertypeid = " + byteCode.readUnsignedByte().toString(16);
			var pType:String = programType[byteCode.readByte()];
			res += "\nshadertype = " + pType;
			res += "\nsource\n";
			pType = pType.substring(0, 1).toLowerCase();
			var lineNumber:uint = 1;
			while (byteCode.bytesAvailable - 24 >= 0) {
				res += (lineNumber++).toString() + ": " + getCommand(byteCode, pType) + "\n";
			}
			if (byteCode.bytesAvailable > 0) {
				res += "\nunexpected byteCode length. extra bytes:" + byteCode.bytesAvailable;
			}
			return res;
		}

		private static function getCommand(byteCode:ByteArray, programType:String):String {
			var cmd:uint = byteCode.readUnsignedInt();
			var command:String = CommandType.COMMAND_NAMES[cmd];
			var result:String;
			var destNumber:uint = byteCode.readUnsignedShort();
			var swizzle:uint = byteCode.readByte();
			var s:String = "";
			var destSwizzle:uint = 4;
			if (swizzle < 15) {
				s += ".";
				s += ((swizzle & 0x1) > 0) ? "x" : "";
				s += ((swizzle & 0x2) > 0) ? "y" : "";
				s += ((swizzle & 0x4) > 0) ? "z" : "";
				s += ((swizzle & 0x8) > 0) ? "w" : "";
				destSwizzle = s.length - 1;
			}

			var sourceSwizzleLimit:int = destSwizzle;
			if (cmd == CommandType.TEX) {
				sourceSwizzleLimit = 2;
			} else if (cmd == CommandType.DP3) {
				sourceSwizzleLimit = 3;
			} else if (cmd == CommandType.DP4) {
				sourceSwizzleLimit = 4;
			}

			var destType:String = VariableType.TYPE_NAMES[byteCode.readUnsignedByte()].charAt(0);
			result = command + " " + attachProgramPrefix(destType, programType) + destNumber.toString() + s + ", ";
			result += attachProgramPrefix(getSourceVariable(byteCode, sourceSwizzleLimit), programType);

			if (twoOperandsCommands[cmd]) {
				if (cmd == CommandType.TEX || cmd == CommandType.TED) {
					result += ", " + attachProgramPrefix(getSamplerVariable(byteCode), programType);
				} else {
					result += ", " + attachProgramPrefix(getSourceVariable(byteCode, sourceSwizzleLimit), programType);
				}
			} else {
				byteCode.readDouble();
			}
			
			if (cmd == CommandType.ELS || cmd == CommandType.EIF) {
				result = " " + command;
			}
			return result;
		}

		private static function attachProgramPrefix(variable:String, programType:String):String {
			var char:uint = variable.charCodeAt(0);
			if (char == "o".charCodeAt(0)) {
				return variable + (programType == "f" ? "c" : "p");
			} else if (char == "d".charCodeAt(0)) {
				return "o"+variable;
			} else if (char != "v".charCodeAt(0)) {
				return programType + variable;
			}
			return variable;
		}

		private static function getSamplerVariable(byteCode:ByteArray):String {
			var number:uint = byteCode.readUnsignedInt();
			byteCode.readByte();
			var dim:uint = byteCode.readByte() >> 4;
			var wraping:uint = byteCode.readByte() >> 4;
			var n:uint = byteCode.readByte();
			return "s" + number.toString() + " <" + samplerDimension[dim] + ", " + samplerWraping[wraping]
					+ ", " + samplerFilter[(n >> 4) & 0xf] + ", " + samplerMipmap[n & 0xf] + ">";
		}

		private static function getSourceVariable(byteCode:ByteArray, swizzleLimit:uint):String {
			var s1Number:uint = byteCode.readUnsignedShort();
			var offset:uint = byteCode.readUnsignedByte();
			var s:String = getSourceSwizzle(byteCode.readUnsignedByte(), swizzleLimit);

			var s1Type:String = VariableType.TYPE_NAMES[byteCode.readUnsignedByte()].charAt(0);
			var indexType:String = VariableType.TYPE_NAMES[byteCode.readUnsignedByte()].charAt(0);
			var comp:String = swizzleType[byteCode.readUnsignedByte()];

			if (byteCode.readUnsignedByte() > 0) {
				return	 s1Type + "[" + indexType + s1Number.toString() + "." + comp + ((offset > 0) ? ("+" + offset.toString()) : "") + "]" + s;
			}
			return s1Type + s1Number.toString() + s;
		}

		private static function getSourceSwizzle(swizzle:uint, swizzleLimit:uint = 4):String {
			var s:String = "";
			if (swizzle != 0xe4) {
				s += ".";
				s += swizzleType[(swizzle & 0x3)];
				s += swizzleType[(swizzle >> 2) & 0x3];
				s += swizzleType[(swizzle >> 4) & 0x3];
				s += swizzleType[(swizzle >> 6) & 0x3];
				s = swizzleLimit < 4 ? s.substring(0, swizzleLimit + 1) : s;
			}
			return s;
		}

		alternativa3d static function checkParent(child:Class, parent:Class):Boolean {
			var current:Class = child;
			if (parent == null) return true;
			while (true) {
				if (current == parent) return true;
				var className:String = getQualifiedSuperclassName(current);
				if (className != null) {
					current = getDefinitionByName(className) as Class;
				} else return false;
			}
			return false;
		}

	}
}
