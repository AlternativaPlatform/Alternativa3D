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
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * @private
	 * Dynamic shader linker
	 */
	public class Linker {

		/**
		 * Data after linking.
		 */
		public var data:ByteArray = null;

		/**
		 * Number of used slots.
		 */
		public var slotsCount:int = 0;
		/**
		 * Number of lines of the shader code.
		 */
		public var commandsCount:int = 0;

		/**
		 * Linker type. Can be vertex of fragment.
		 */
		public var type:String;

		private var procedures:Vector.<Procedure> = new Vector.<Procedure>();

		/**
		 * @private
		 * Variables after linking.
		 */
		alternativa3d var _linkedVariables:Object;

		// Dictionary of temporary variables at this linker. Key is a name of variable, value is a variable.
		private var _localVariables:Object = new Object();
		
		// Key - procedure, value - array of strings.
		private var _inputParams:Dictionary = new Dictionary();
		// Key - procedure, value - array of strings.
		private var _outputParams:Dictionary = new Dictionary();

		// Counters of variables by types
		private var _locals:Vector.<uint> = new Vector.<uint>(6, true);

		private var samplers:Object = new Object();

		private var _varyings:Object = new Object();

		/**
		 * Creates a new Linker instance.
		 *
		 * @param programType Type of shader.
		 */
		public function Linker(programType:String) {
			type = programType;
		}

		/**
		 * Clears a content.
		 */
		public function clear():void {
			data = null;
			_locals[0] = _locals[1] = _locals[2] = _locals[3] = _locals[4] = _locals[5] = 0;
			procedures.length = 0;
			_varyings = new Object();
			samplers = new Object();

			commandsCount = 0;
			slotsCount = 0;
			_linkedVariables = null;

			_inputParams = new Dictionary();
			_outputParams = new Dictionary();
		}
		
		/**
		 * Adds a new shader procedure.
		 *
		 * @param procedure Procedure to add.
		 *
		 * @see Procedure
		 */
		public function addProcedure(procedure:Procedure, ...args):void {
			for each(var v:Variable in procedure.variablesUsages[VariableType.VARYING]) {
				if (v == null) continue;
				var nv:Variable = _varyings[v.name] = new Variable();
				nv.name = v.name;
				nv.type = v.type;
				nv.index = -1;
			}
			procedures.push(procedure);
			_inputParams[procedure] = args;
			data = null;
		}
		
		/**
		 * Declaration of variable of given type.
		 *
		 * @param name Name of variable
		 * @param type Type of variable. Should be one of  the  VariableType constants. The default value is Temporary variable.
		 *
		 * @see VariableType
		 */
		public function declareVariable(name:String, type:uint = 2):void {
			var v:Variable = new Variable();
			v.index = -1;
			v.type = type;
			v.name = name;
			_localVariables[name] = v;
			if (v.type == VariableType.VARYING) {
				_varyings[v.name] = v;
			}
			data = null;
		}

		public function declareSampler(output:String, uv:String, sampler:String, options:String):void {
			if (_localVariables[uv] == null) {
				throw new ArgumentError("Undefined variable " + uv);
			}

			if (_localVariables[sampler] == null) {
				throw new ArgumentError("Undefined variable " + sampler);
			}

			if (_localVariables[output] == null) {
				declareVariable(output, 2);
			}
			data = null;
		}

		/**
		 * Setting of input parameters of procedure.
		 *
		 * @param procedure A procedure to which  parameters will be set.
		 * @param args Names of variables, separated by the comma, that are passed into the procedure.
		 * Variables must be previously declared, using the method <code>declareVariable()</code>.
		 *
		 * @see #declareVariable()
		 */
		public function setInputParams(procedure:Procedure, ...args):void {
			_inputParams[procedure] = args;
			data = null;
		}

		/**
		 * Setting of output parameters of procedure.
		 *
		 * @param procedure  A procedure to which  parameters will be set.
		 * @param args Names of variables, separated by the comma, that are passed into the procedure.
		 * Variables must be previously declared, using the method declareVariable().
		 *
		 * @see #declareVariable()
		 */
		public function setOutputParams(procedure:Procedure, ...args):void {
			_outputParams[procedure] = args;
			data = null;
		}

		/**
		 * Returns of index of variable after the linking.
		 *
		 * @param name Name of variable.
		 * @return Its index for sending to Context3D
		 */
		public function getVariableIndex(name:String):int {
			if (_linkedVariables == null) throw new Error("Not linked");
			var variable:Variable = _linkedVariables[name];
			if (variable == null) {
				throw new Error('Variable "' + name + '" not found');
			}
			return variable.index;
		}

		/**
		 * Returns index of variable or <code>-1</code> there is no variable with such name.
		 */
		public function findVariable(name:String):int {
			if (_linkedVariables == null) throw new Error("Has not linked");
			var variable:Variable = _linkedVariables[name];
			if (variable == null) {
				return -1;
			}
			return variable.index;
		}

		/**
		 * Returns the existence of this variable in linked code.
		 * @param name Name of variable
		 */
		public function containsVariable(name:String):Boolean {
			if (_linkedVariables == null) throw new Error("Not linked");
			return _linkedVariables[name] != null;
		}

		/**
		 * Linking of procedures to one shader.
		 */
		public function link():void {
			if (data != null) return;

			var v:Variable;
			var variables:Object = _linkedVariables = new Object();
			var p:Procedure;
			var i:int, j:int;
			var nv:Variable;
			for each (v in _localVariables) {
				nv = variables[v.name] = new Variable();
				nv.index = -1;
				nv.type = v.type;
				nv.name = v.name;
				nv.size = v.size;
			}
			data = new ByteArray();
			data.endian = Endian.LITTLE_ENDIAN;
			data.writeByte(0xa0);
			data.writeUnsignedInt(0x1);		// AGAL version, big endian, bit pattern will be 0x01000000
			data.writeByte(0xa1);				// tag program id
			data.writeByte((type == Context3DProgramType.FRAGMENT) ? 1 : 0);	// vertex or fragment
			
			commandsCount = 0;
			slotsCount = 0;

			_locals[0] = 0;
			_locals[1] = 0;
			_locals[2] = 0;
			_locals[3] = 0;
			_locals[4] = 0;
			_locals[5] = 0;
			// First iteration - collecting of variables.
			for each (p in procedures) {
				var iLength:int = p.variablesUsages.length;
				_locals[1] += p.reservedConstants;
				for (i = 0; i < iLength; i++) {
					var vector:Vector.<Variable> = p.variablesUsages[i];
					var jLength:int = vector.length;
					for (j = 0; j < jLength; j++) {
						v = vector[j];
						if (v == null || v.name == null) continue;
						if (v.name == null && i != 2 && i != 6 && i != 3) {
							throw new Error("Linkage error: Noname variable. Procedure =  " + p.name + ", type = " + i.toString() + ", index = " + j.toString());
						}
						nv = variables[v.name] = new Variable();
						nv.index = -1;
						nv.type = v.type;
						nv.name = v.name;
						nv.size = v.size;
					}
				}
			}

			for each (p in procedures) {
				// Changing of inputs
				var offset:int = data.length;
				data.position = data.length;
				data.writeBytes(p.byteCode, 0, p.byteCode.length);
				var input:Array = _inputParams[p];
				var output:Array = _outputParams[p];
				var param:String;
				var numParams:int;
				if (input != null) {
					numParams = input.length;
					for (j = 0; j < numParams; j++) {
						param = input[j];
						v = variables[param];
						if (v == null) {
							throw new Error("Input parameter not set. paramName = " + param);
						}
						if (p.variablesUsages[6].length > j) {
							var inParam:Variable = p.variablesUsages[6][j];
							if (inParam == null) {
								throw new Error("Input parameter set, but not exist in code. paramName = " + param + ", register = i" + j.toString());
							}
							if (v.index < 0) {
								v.index = _locals[v.type];
								_locals[v.type] += v.size;
							}
							while (inParam != null) {
								inParam.writeToByteArray(data, v.index, v.type, offset);
								inParam = inParam.next;
							}
						}

					}
				}
				if (output != null) {
					// Output parameters
					numParams = output.length;
					for (j = 0; j < numParams; j++) {
						param = output[j];
						v = variables[param];
						if (v == null) {
							if (j == 0 && (i == procedures.length - 1)) {
								// Output variable
								continue;
							}
							throw new Error("Output parameter have not declared. paramName = " + param);
						}
						if (v.index < 0) {
							if (v.type != 2) {
								throw new Error("Wrong output type:" + VariableType.TYPE_NAMES[v.type]);
							}
							v.index = _locals[v.type];
							_locals[v.type] += v.size;
						}
						var outParam:Variable = p.variablesUsages[3][j];
						if (outParam == null) {
							throw new Error("Output parameter set, but not exist in code. paramName = " + param + ", register = i" + j.toString());
						}
						while (outParam != null) {
							outParam.writeToByteArray(data, v.index, v.type, offset);
							outParam = outParam.next;
						}
					}
				}
				var vars:Vector.<Variable> = p.variablesUsages[2];
				for (j = 0; j < vars.length; j++) {
					v = vars[j];
					if (v == null) continue;
					while (v != null) {
						v.writeToByteArray(data, v.index + _locals[2], VariableType.TEMPORARY, offset);
						v = v.next;
					}
				}

				resolveVariablesUsages(data, variables, p.variablesUsages[0], VariableType.ATTRIBUTE, offset);
				resolveVariablesUsages(data, variables, p.variablesUsages[1], VariableType.CONSTANT, offset);
				resolveVariablesUsages(data, _varyings, p.variablesUsages[4], VariableType.VARYING, offset);
				resolveVariablesUsages(data, variables, p.variablesUsages[5], VariableType.SAMPLER, offset);

				commandsCount += p.commandsCount;
				slotsCount += p.slotsCount;
			}
		}
		private function resolveVariablesUsages(code:ByteArray, variables:Object, variableUsages:Vector.<Variable>, type:uint, offset:int):void {
			for (var j:int = 0; j < variableUsages.length; j++) {
				var vUsage:Variable = variableUsages[j];
				if (vUsage == null) continue;
				if (vUsage.isRelative) continue;
				var variable:Variable = variables[vUsage.name];
				if (variable.index < 0) {
					variable.index = _locals[type];
					_locals[type] += variable.size;
				}
				while (vUsage != null) {
					vUsage.writeToByteArray(code, variable.index, variable.type, offset);
					vUsage = vUsage.next;
				}
			}
		}

		/**
		 * Returns description of procedures: name, size, input and output parameters.
		 * @return
		 */
		public function describeLinkageInfo():String {
			var str:String;
			var result:String = "LINKER:\n";
			var totalCodes:uint = 0;
			var totalCommands:uint = 0;
			for (var i:int = 0; i < procedures.length; i++) {
				var p:Procedure = procedures[i];
				if (p.name != null) {
					result += p.name + "(";
				} else {
					result += "#" + i.toString() + "(";
				}
				var args:* = _inputParams[p];
				if (args != null) {
					for each (str in args) {
						result += str + ",";
					}
					result = result.substr(0, result.length - 1);
				}
				result += ")";
				args = _outputParams[p];
				if (args != null) {
					result += "->(";
					for each (str in args) {
						result += str + ",";
					}
					result = result.substr(0, result.length - 1);
					result += ")";
				}
				result += " [IS:" + p.slotsCount.toString() + ", CMDS:" + p.commandsCount.toString() + "]\n";
				totalCodes += p.slotsCount;
				totalCommands += p.commandsCount;
			}
			result += "[IS:" + totalCodes.toString() + ", CMDS:" + totalCommands.toString() + "]\n";
			return result;
		}

		public function get varyings():Object {
			return _varyings;
		}

		public function set varyings(value:Object):void {
			_varyings = value;
			data = null;
		}

	}
}
