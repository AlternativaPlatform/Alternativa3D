/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Variable;
	import alternativa.engine3d.materials.compiler.VariableType;

	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DebugDrawUnit extends DrawUnit {

		alternativa3d var shader:ShaderProgram;

		alternativa3d var vertexConstantsIndexes:Dictionary = new Dictionary(false);
		alternativa3d var fragmentConstantsIndexes:Dictionary = new Dictionary(false);

		override alternativa3d function clear():void {
			var k:*;
			for (k in vertexConstantsIndexes) {
				delete vertexConstantsIndexes[k];
			}
			for (k in fragmentConstantsIndexes) {
				delete fragmentConstantsIndexes[k];
			}
			super.clear();
		}
		
		override alternativa3d function setVertexConstantsFromVector(firstRegister:int, data:Vector.<Number>, numRegisters:int):void {
			super.setVertexConstantsFromVector(firstRegister, data, numRegisters);
			for (var i:int = 0; i < numRegisters; i++) {
				vertexConstantsIndexes[int(firstRegister + i)] = true;
			}
		}
		
		override alternativa3d function setVertexConstantsFromNumbers(firstRegister:int, x:Number, y:Number, z:Number, w:Number = 1):void {
			super.setVertexConstantsFromNumbers(firstRegister, x,  y,  z,  w);
			vertexConstantsIndexes[firstRegister] = true;
		}

		override alternativa3d function setVertexConstantsFromTransform(firstRegister:int, transform:Transform3D):void {
			super.setVertexConstantsFromTransform(firstRegister, transform);
			vertexConstantsIndexes[firstRegister] = true;
			vertexConstantsIndexes[int(firstRegister + 1)] = true;
			vertexConstantsIndexes[int(firstRegister + 2)] = true;
		}

		alternativa3d override function setProjectionConstants(camera:Camera3D, firstRegister:int, transform:Transform3D = null):void {
			super.setProjectionConstants(camera, firstRegister, transform);
			vertexConstantsIndexes[firstRegister] = true;
			vertexConstantsIndexes[int(firstRegister + 1)] = true;
			vertexConstantsIndexes[int(firstRegister + 2)] = true;
			vertexConstantsIndexes[int(firstRegister + 3)] = true;
		}

		override alternativa3d function setFragmentConstantsFromVector(firstRegister:int, data:Vector.<Number>, numRegisters:int):void {
			super.setFragmentConstantsFromVector(firstRegister, data, numRegisters);
			for (var i:int = 0; i < numRegisters; i++) {
				fragmentConstantsIndexes[int(firstRegister + i)] = true;
			}
		}

		override alternativa3d function setFragmentConstantsFromNumbers(firstRegister:int, x:Number, y:Number, z:Number, w:Number = 1):void {
			super.setFragmentConstantsFromNumbers(firstRegister, x,  y,  z,  w);
			fragmentConstantsIndexes[firstRegister] = true;
		}

		override alternativa3d function setFragmentConstantsFromTransform(firstRegister:int, transform:Transform3D):void {
			super.setFragmentConstantsFromTransform(firstRegister, transform);
			fragmentConstantsIndexes[firstRegister] = true;
			fragmentConstantsIndexes[int(firstRegister + 1)] = true;
			fragmentConstantsIndexes[int(firstRegister + 2)] = true;
		}

		public function check():void {
			if (object == null) throw new Error("Object not set.");
			if (program == null) throw new Error("Program not set.");
			if (indexBuffer == null) throw new Error("IndexBuffer not set.");

			if (shader == null) return;
			var index:int;
			var variable:Variable;
			for each (variable in shader.vertexShader._linkedVariables) {
				index = variable.index;
				if (index >= 0) {
					switch (variable.type) {
						case VariableType.ATTRIBUTE:
							if (!hasVertexBuffer(index)) {
								throw new Error("VertexBuffer " + index + " with variable name " + variable.name + " not set.");
							}
							break;
						case VariableType.CONSTANT:
							if (!vertexConstantsIndexes[index]) {
								throw new Error("Vertex Constant " + index + " with variable name " + variable.name + " not set.");
							}
							break;
					}
				}
			}
			for each (variable in shader.fragmentShader._linkedVariables) {
				index = variable.index;
				if (index >= 0) {
					switch (variable.type) {
						case VariableType.SAMPLER:
							if (!hasTexture(index)) {
								throw new Error("Sampler " + index + " with variable name " + variable.name + " not set.");
							}
							break;
						case VariableType.CONSTANT:
							if (!fragmentConstantsIndexes[index]) {
								throw new Error("Fragment Constant " + index + " with variable name " + variable.name + " not set.");
							}
							break;
					}
				}
			}
		}
		
		private function hasVertexBuffer(index:int):Boolean {
			for (var i:int = 0; i < vertexBuffersLength; i++) {
				if (vertexBuffersIndexes[i] == index) {
					return true;
				}
			}
			return false;
		}
		private function hasTexture(index:int):Boolean {
			for (var i:int = 0; i < texturesLength; i++) {
				if (texturesSamplers[i] == index) {
					return true;
				}
			}
			return false;
		}

	}
}
