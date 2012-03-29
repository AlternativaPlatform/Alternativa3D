/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials.compiler {

	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3DProgramType;

	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * @private
	 * Shader procedure
	 */
	public class Procedure {

		// Name of procedure
		public var name:String;

		alternativa3d static const crc32Table:Vector.<uint> = createCRC32Table();

		private static function createCRC32Table():Vector.<uint> {
			var crc_table:Vector.<uint> =  new Vector.<uint>(256);
			var crc:uint, i:int, j:int;
			for (i = 0; i < 256; i++) {
				crc = i;
				for (j = 0; j < 8; j++)
					crc = crc & 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;

				crc_table[i] = crc;
			}
			return crc_table;
		}

		alternativa3d var crc32:uint = 0;

		/**
		 * Code of procedure.
		 */
		public var byteCode:ByteArray = new ByteArray();
		public var variablesUsages:Vector.<Vector.<Variable>> = new Vector.<Vector.<Variable>>();

		/**
		 * Number of instruction slots in a procedure.
		 */
		public var slotsCount:int = 0;

		/**
		 * Number of strings in a procedure.
		 */
		public var commandsCount:int = 0;

		alternativa3d var reservedConstants:uint = 0;

		/**
		 * Creates a new Procedure instance.
		 *
		 * @param array Array of AGAL strings
		 */
		public function Procedure(array:Array = null, name:String = null) {
			byteCode.endian = Endian.LITTLE_ENDIAN;
			this.name = name;
			if (array != null) {
				compileFromArray(array);
			}
		}

		public function getByteCode(type:String):ByteArray {
			var result:ByteArray = new ByteArray();
			result.endian = Endian.LITTLE_ENDIAN;
			result.writeByte(0xa0);
			result.writeUnsignedInt(0x1);		// AGAL version, big endian, bit pattern will be 0x01000000
			result.writeByte(0xa1);				// tag program id
			result.writeByte((type == Context3DProgramType.FRAGMENT) ? 1 : 0);	// vertex or fragment
			result.writeBytes(byteCode);
			return result;
		}

		private function addVariableUsage(v:Variable):void {
			var vars:Vector.<Variable> = variablesUsages[v.type];
			var index:int = v.index;
			if (index >= vars.length) {
				vars.length = index + 1;
			} else {
				v.next = vars[index];
			}
			vars[index] = v;
		}

		/**
		 * Sets  name and size of variable
		 *
		 * @param type Type of variable. One of  <code>VariableType</code> constants.
		 * @param index Index of variable at shader code.
		 * @param name Assigned variable name.
		 * @param size Size of variable in vectors.
		 *
		 * @see VariableType
		 */
		public function assignVariableName(type:uint, index:uint, name:String, size:uint = 1):void {
			var v:Variable = variablesUsages[type][index];
			while (v != null) {
				v.size = size;
				v.name = name;
				v = v.next;
			}
		}

		/**
		 * Compiles shader from the string.
		 */
		public function compileFromString(source:String):void {
			var commands:Array = source.split("\n");
			compileFromArray(commands);
		}

		/**
		 * Compiles shader from the array of strings.
		 */
		public function compileFromArray(source:Array):void {
			for (var i:int = 0; i < 7; i++) {
				variablesUsages[i] = new Vector.<Variable>();
			}
			byteCode.length = 0;
			commandsCount = 0;
			slotsCount = 0;

			var declarationStrings:Vector.<String> = new Vector.<String>();
			var count:int = source.length;
			for (i = 0; i < count; i++) {
				var cmd:String = source[i];
				var declaration:Array = cmd.match(/# *[acvs]\d{1,3} *= *[a-zA-Z0-9_]*/i);
				if (declaration != null && declaration.length > 0) {
					declarationStrings.push(declaration[0]);
				} else {
					writeCommand(cmd);
				}
			}
			for (i = 0,count = declarationStrings.length; i < count; i++) {
				var decArray:Array = declarationStrings[i].split("=");
				var regType:String = decArray[0].match(/[acvs]/i);
				var varIndex:int = int(decArray[0].match(/\d{1,3}/i));
				var varName:String = decArray[1].match(/[a-zA-Z0-9]*/i);
				switch (regType.toLowerCase()) {
					case "a":
						assignVariableName(VariableType.ATTRIBUTE, varIndex, varName);
						break;
					case "c":
						assignVariableName(VariableType.CONSTANT, varIndex, varName);
						break;
					case "v":
						assignVariableName(VariableType.VARYING, varIndex, varName);
						break;
					case "s":
						assignVariableName(VariableType.SAMPLER, varIndex, varName);
						break;
				}
			}
			crc32 = createCRC32(byteCode);
		}

		public function assignConstantsArray(registersCount:uint = 1):void {
			reservedConstants = registersCount;
		}

		private function writeCommand(source:String):void {
			var commentIndex:int = source.indexOf("//");
			if (commentIndex >= 0) {
				source = source.substr(0, commentIndex);
			}
			// mov vt0, v0
			// mov vt0, v0, vc1
			// mov vt0.xy, a0.xy, vc1.xy
			// mov vt0.xy, a0.xy, vc1.xy
			// mov vt0.xy, v0[va1.x + 2], vc[va0.x + 2]
			// mov op, v0[va1.x + 2], vc[va0.x + 2]
			// tex t0, v0, s0 <2d, linear>

			// Errors:
			//1) Merged commands
			//2) Syntax errors
			//-- incorrect number of operands
			//-- unknown commands
			//-- unknown registers
			//-- unknown constructions
			//3) Using of unwritable registers
			//-- in vertex shader (va0, c0, s0);
			//-- in fragment shader (v0, va0, c0, s0);
			//4) Using of unreadable registers
			//-- in vertex shader (v0, s0);
			//-- in fragment shader (va0);
			//5) Deny write into the input registers
			//6) Mismatch the size of types of registers
			//7) Relative addressing in the fragment shader is not possible
			//-- You can not use it for recording
			//-- Offset is out of range [0..255]
			//8) Flow errors
			//-- unused variable
			//-- using of uninitialized variable
			//-- using of partially uninitialized variable
			//-- function is not return value
			//9) Restrictions
			//-- too many commands
			//-- too many constants
			//-- too many textures
			//-- too many temporary variables
			//-- too many interpolated values
			// You can not use kil in fragment shader

			var operands:Array = source.match(/[A-Za-z]+(((\[.+\])|(\d+))(\.[xyzw]{1,4})?(\ *\<.*>)?)?/g);

			// It is possible not use the input parameter. It is optimization of the linker
			// Determine the size of constant

			if (operands.length < 2) {
				return;
			}
			var opCode:String = operands[0];
			var destination:Variable;
			var source1:SourceVariable;
			var source2:Variable;
			if (opCode == "kil") {
				source1 = new SourceVariable(operands[1]);
			} else {
				destination = new DestinationVariable(operands[1]);
				source1 = new SourceVariable(operands[2]);
				addVariableUsage(destination);
			}
			addVariableUsage(source1);

			var type:uint;
			switch (opCode) {
				case "mov":
					type = CommandType.MOV;
					slotsCount++;
					break;
				case "add":
					type = CommandType.ADD;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "sub":
					type = CommandType.SUB;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "mul":
					type = CommandType.MUL;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "div":
					type = CommandType.DIV;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "rcp":
					type = CommandType.RCP;
					slotsCount++;
					break;
				case "min":
					type = CommandType.MIN;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "max":
					type = CommandType.MAX;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "frc":
					type = CommandType.FRC;
					slotsCount++;
					break;
				case "sqt":
					type = CommandType.SQT;
					slotsCount++;
					break;
				case "rsq":
					type = CommandType.RSQ;
					slotsCount++;
					break;
				case "pow":
					type = CommandType.POW;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount += 3;
					break;
				case "log":
					type = CommandType.LOG;
					slotsCount++;
					break;
				case "exp":
					type = CommandType.EXP;
					slotsCount++;
					break;
				case "nrm":
					type = CommandType.NRM;
					slotsCount += 3;
					break;
				case "sin":
					type = CommandType.SIN;
					slotsCount += 8;
					break;
				case "cos":
					type = CommandType.COS;
					slotsCount += 8;
					break;
				case "crs":
					type = CommandType.CRS;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount += 2;
					break;
				case "dp3":
					type = CommandType.DP3;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "dp4":
					type = CommandType.DP4;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "abs":
					type = CommandType.ABS;
					slotsCount++;
					break;
				case "neg":
					type = CommandType.NEG;
					slotsCount++;
					break;
				case "sat":
					type = CommandType.SAT;
					slotsCount++;
					break;
				case "m33":
					type = CommandType.M33;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount += 3;
					break;
				case "m44":
					type = CommandType.M44;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount += 4;
					break;
				case "m34":
					type = CommandType.M34;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount += 3;
					break;
				case "kil":
					type = CommandType.KIL;
					slotsCount++;
					break;
				case "tex":
					type = CommandType.TEX;
					source2 = new SamplerVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "sge":
					type = CommandType.SGE;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "slt":
					type = CommandType.SLT;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "seq":
					type = CommandType.SEQ;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				case "sne":
					type = CommandType.SNE;
					source2 = new SourceVariable(operands[3]);
					addVariableUsage(source2);
					slotsCount++;
					break;
				default:
					break;
			}
			// Fill of byteCode of command
			byteCode.writeUnsignedInt(type);
			if (destination != null) {
				destination.position = byteCode.position;
				byteCode.writeUnsignedInt(destination.lowerCode);
			} else {
				byteCode.writeUnsignedInt(0);
			}
			source1.position = byteCode.position;
			if (source1.relative != null) {
				addVariableUsage(source1.relative);
				source1.relative.position = byteCode.position;
			}
			byteCode.writeUnsignedInt(source1.lowerCode);
			byteCode.writeUnsignedInt(source1.upperCode);
			if (source2 != null) {
				var s2v:SourceVariable = source2 as SourceVariable;
				source2.position = byteCode.position;
				if (s2v != null && s2v.relative != null) {
					addVariableUsage(s2v.relative);
					s2v.relative.position = s2v.position;
				}
				byteCode.writeUnsignedInt(source2.lowerCode);
				byteCode.writeUnsignedInt(source2.upperCode);
			} else {
				byteCode.position = (byteCode.length += 8);
			}
			commandsCount++;
		}

		/**
		 * Creates and returns an instance of procedure from array of strings.
		 */
		public static function compileFromArray(source:Array, name:String = null):Procedure {
			var proc:Procedure = new Procedure(source, name);
			return proc;
		}

		/**
		 * Creates  and returns an instance of procedure from string.
		 */
		public static function compileFromString(source:String, name:String = null):Procedure {
			var proc:Procedure = new Procedure(null, name);
			proc.compileFromString(source);
			return proc;
		}

		/**
		 * Create an instance of procedure.
		 */
		public function newInstance():Procedure {
			var res:Procedure = new Procedure();
			res.byteCode = this.byteCode;
			res.variablesUsages = this.variablesUsages;
			res.slotsCount = this.slotsCount;
			res.reservedConstants = this.reservedConstants;
			res.commandsCount = this.commandsCount;
			res.name = name;
			return res;
		}




		alternativa3d static function createCRC32(byteCode:ByteArray):uint {
			byteCode.position = 0;
			var len:uint = byteCode.length;
			var crc:uint = 0xFFFFFFFF;
			while (len--) {
				var byte:int = byteCode.readByte();
				crc = crc32Table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
			}
			return crc ^ 0xFFFFFFFF;
		}
	}

}
