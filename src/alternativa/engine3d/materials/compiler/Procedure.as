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

			const decPattern:RegExp = /# *[acvs]\d{1,3} *= *[a-zA-Z0-9_]*/i;
			const rpnPattern:RegExp = /[tivo]\d+(\.[xyzw]{1,4})? *=/;

			var declarationStrings:Vector.<String> = new Vector.<String>();
			var count:int = source.length;
			for (i = 0; i < count; i++) {
				var cmd:String = source[i];
				var declaration:Array = cmd.match(decPattern);
				if (declaration != null && declaration.length > 0) {
					declarationStrings.push(declaration[0]);
				} else {
					if (rpnPattern.test(cmd)) {
						writeRPNExpression(cmd);
					} else {
						writeAGALExpression(cmd);
					}
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

		private function writeRPNExpression(source:String):void {
			// 1) Output in the same variable
			// 2) Check for errors and complex expressions
			// 3) Compile through AGAL
			// 4) Only +-/* operators and one assignment =
			// 5) output mask supported for : (.x, .y, .z, .w, .xy, .xyz, .xyzw)
			// 6) swizzle supported
			// 7) swizzle handled like in AGAL compiler

			// TODO: handle swizzle smartly (.zw -> .zwzw)
			// TODO: implement operators inputs size check
			// TODO: implement operators auto output size
			// TODO: implement operators output swizzle
			// TODO: minimize output temporaries count (sort operators by priority)
			// TODO: write to ByteArray directly
			// TODO: implement negate unary operator (-x)
			// TODO: implement tex (tex2D, texCube) in any form
			// TODO: implement groups and complex expressions
			// TODO: support additional output masks
			// TODO: optimize variables components usage (sort by swizzles length)
			// TODO: optimize
			// TODO: implement alternate assignments

			var commentIndex:int = source.indexOf("//");
			if (commentIndex >= 0) {
				source = source.substr(0, commentIndex);
			}
			var operands:Array = source.match(/[a-z]+(((\[.+\])|(\d+))(\.[xyzw]{1,4})?)?|[+\-*\/=(),]/g);
			var numOperands:int = operands.length;
			if (numOperands < 3) return;
			if (operands[1] != "=") {
				throw new Error("Syntax error");
			}
			var i:int;
			var output:String = operands[0];
			var maskIndex:int = output.lastIndexOf(".");
			var outputMaskLen:int = (maskIndex >= 0) ? output.length - maskIndex - 1 : 4;
			if (outputMaskLen != 1 && maskIndex >= 0) {
				// check mask
				const X_CHAR_CODE:int = "x".charCodeAt(0);
				for (i = 0; i < outputMaskLen; i++) {
					var code:int = (i == 3) ? X_CHAR_CODE -1 : X_CHAR_CODE + i;	// .w
					if (output.charCodeAt(maskIndex + i + 1) != code) {
						throw new Error("Output mask with such type not supported " + output + ".");
					}
				}
			}
			var outputVar:String = (maskIndex >= 0) ? output.substr(0, maskIndex) : output;
			if (outputMaskLen == 4) output = outputVar;

			var operators:Vector.<CommandType> = new Vector.<CommandType>();
			var variables:Vector.<String> = new Vector.<String>();
			function getPriority(command:CommandType):int {
				return command.priority;
			}
			function getSwizzleLen(value:String):uint {
				var i:int = value.lastIndexOf(".");
				return (i < 0 ? 4 : value.length - i - 1);
			}
			function writeCommand(command:CommandType, numInputs:int, operandIndex:int, isLastOperator:Boolean):void {
				if (numInputs != command.numInputs) {
					throw new Error("Syntax error. Operator " + command.id + " inputs count wrong. Expected " + command.numInputs + ".");
				}
				var b:String = (numInputs > 1) ? variables.pop() : null;
				var a:String = variables.pop();
				if (a == null || (numInputs > 1 && b == null)) throw new Error("Syntax error. Variable expected after " + command + ".");
				// Check can we use output for writing
				var i:int;
				for (i = 0; i < variables.length; i++) {
					if (variables[i].indexOf(output) >= 0) {
						// output already used
						throw new Error("Expression is too complex. Groups unsupported.");
					}
				}
				for (i = operandIndex + 1; i < numOperands; i++) {
					if (operands[i].indexOf(output) >= 0) {
						// output is used as source
						throw new Error("Expression is too complex. Output used as source.");
					}
				}
				var maxSwizzle:uint;
				if (numInputs <= 1) {
					maxSwizzle = getSwizzleLen(a);
				} else {
					var aSwizzleLen:uint = getSwizzleLen(a);
					var bSwizzleLen:uint = getSwizzleLen(b);
					if (aSwizzleLen != bSwizzleLen && aSwizzleLen != 1 && bSwizzleLen != 1) {
						throw new Error("Variables size mistmatch " + a + " and " + b + ".");
					}
					maxSwizzle = (aSwizzleLen > bSwizzleLen) ? aSwizzleLen : bSwizzleLen;
				}
				if (maxSwizzle > outputMaskLen || (isLastOperator && maxSwizzle != outputMaskLen && maxSwizzle != 1)) {
					throw new Error("Expression differs in size with output " + output + ".");
				}
				var out:String = output;
				if (!isLastOperator && maxSwizzle != outputMaskLen) {
					// TODO: use same components like in variables (.zw + .zw -> .zw)
					if (maxSwizzle == 1) {
						out = outputVar + ".x";
					} else if (maxSwizzle == 2) {
						out = outputVar + ".xy";
					} else if (maxSwizzle == 3) {
						out = outputVar + ".xyz";
					}
				}
				if (numInputs > 1) {
					writeAGALExpression(command.id + " " + out + " " + a + " " + b);
				} else {
					writeAGALExpression(command.id + " " + out + " " + a);
				}
				variables.push(out);
			}
			var operand:String;
			if (numOperands == 3) {
				operand = operands[2];
				if (getSwizzleLen(operand) != outputMaskLen && getSwizzleLen(operand) != 1) {
					throw new Error("Expression differs in size with output " + output + ".");
				}
				writeAGALExpression("mov " + output + " " + operand);
			}
			var command:CommandType;
			var wasVariable:Boolean = false;
			for (i = 2; i < numOperands; i++) {
				operand = operands[i];
				switch (operand) {
					case "+":
					case "-":
					case "*":
					case "/":
						if (!wasVariable) throw new Error("Syntax error. Variable expected before " + operand + ".");
						command = CommandType.commands[operand];
						// process operators from stack while their priority is higher or equal
						while (operators.length > 0 && getPriority(operators[operators.length - 1]) >= getPriority(command)) {
							writeCommand(operators.pop(), 2, i, false);
						}
						operators.push(command);
						wasVariable = false;
						break;
					case ")":
					case ",":
						if (!wasVariable) throw new Error("Syntax error. Variable expected before " + operand + ".");
						command = CommandType.commands[operand];
						// process all commands before until comma or left bracket
						while (operators.length > 0 && getPriority(operators[operators.length - 1]) > getPriority(command)) {
							writeCommand(operators.pop(), 2, i, false);
						}
						if (operand == ",") {
							operators.push(command);
							wasVariable = false;
						} else {
							// count all commas until function
							var numParams:int = 1;
							while ((command = operators.pop()) != null && command.priority != 0) {
								numParams++;
							}
							writeCommand(command, numParams, i, i == numOperands - 1);
							wasVariable = true;
						}
						break;
					default:
						if (wasVariable) throw new Error("Syntax error. Operator expected before " + operand + ".");

						command = CommandType.commands[operand];
						if (command != null) {
							// is command
							// test bracket
							if (i + 1 >= numOperands || operands[i + 1] != "(") {
								throw new Error("Syntax error. Expected bracket after " + operand + ".");
							}
							operators.push(command);
							i++;	// skip bracket
//							wasVariable = false;
						} else {
							// is variable
							variables.push(operand);
							wasVariable = true;
						}
						break;
				}
			}
			// process remained operators
			while ((command = operators.pop()) != null) {
				writeCommand(command, 2, numOperands, operators.length == 0);
			}
			if (variables.length > 1) throw new Error("Syntax error. Unknown novel error.");
		}

		private const agalParser:RegExp = /[A-Za-z]+(((\[.+\])|(\d+))(\.[xyzw]{1,4})?(\ *\<.*>)?)?/g;
		private function writeAGALExpression(source:String):void {
			var commentIndex:int = source.indexOf("//");
			if (commentIndex >= 0) {
				source = source.substr(0, commentIndex);
			}
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

			var operands:Array = source.match(agalParser);

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
					// TODO: throw error - unknown command
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
				source2.position = byteCode.position;
				var s2v:SourceVariable = source2 as SourceVariable;
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
