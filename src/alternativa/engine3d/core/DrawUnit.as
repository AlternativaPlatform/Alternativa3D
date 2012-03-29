/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;

	use namespace alternativa3d;

	/**
	 * @private 
	 */
	public class DrawUnit {
		
		alternativa3d var next:DrawUnit;
		
		// Required parameters
		alternativa3d var object:Object3D;
		alternativa3d var program:Program3D;
		alternativa3d var indexBuffer:IndexBuffer3D;
		alternativa3d var firstIndex:int;
		alternativa3d var numTriangles:int;
		
		// Additional parameters
		alternativa3d var blendSource:String = Context3DBlendFactor.ONE;
		alternativa3d var blendDestination:String = Context3DBlendFactor.ZERO;
		alternativa3d var culling:String = Context3DTriangleFace.FRONT;

		// Textures
		alternativa3d var textures:Vector.<TextureBase> = new Vector.<TextureBase>();
		alternativa3d var texturesSamplers:Vector.<int> = new Vector.<int>();
		alternativa3d var texturesLength:int = 0;
		
		// Vertex buffers
		alternativa3d var vertexBuffers:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>();
		alternativa3d var vertexBuffersIndexes:Vector.<int> = new Vector.<int>();
		alternativa3d var vertexBuffersOffsets:Vector.<int> = new Vector.<int>();
		alternativa3d var vertexBuffersFormats:Vector.<String> = new Vector.<String>();
		alternativa3d var vertexBuffersLength:int = 0;
		
		// Constants
		alternativa3d var vertexConstants:Vector.<Number> = new Vector.<Number>();
		alternativa3d var vertexConstantsRegistersCount:int = 0;
		alternativa3d var fragmentConstants:Vector.<Number> = new Vector.<Number>(28*4, true);
		alternativa3d var fragmentConstantsRegistersCount:int = 0;

		public function DrawUnit() {
		}

		alternativa3d function clear():void {
			object = null;
			program = null;
			indexBuffer = null;
			blendSource = Context3DBlendFactor.ONE;
			blendDestination = Context3DBlendFactor.ZERO;
			culling = Context3DTriangleFace.FRONT;
			textures.length = 0;
			texturesLength = 0;
			vertexBuffers.length = 0;
			vertexBuffersLength = 0;
			vertexConstantsRegistersCount = 0;
			fragmentConstantsRegistersCount = 0;
		}
		
		alternativa3d function setTextureAt(sampler:int, texture:TextureBase):void {
			if (uint(sampler) > 8) throw new Error("Sampler index " + sampler + " is out of bounds.");
			if (texture == null) throw new Error("Texture is null");
			texturesSamplers[texturesLength] = sampler;
			textures[texturesLength] = texture;
			texturesLength++;
		}
		
		alternativa3d function setVertexBufferAt(index:int, buffer:VertexBuffer3D, bufferOffset:int, format:String):void {
			if (uint(index) > 8) throw new Error("VertexBuffer index " + index + " is out of bounds.");
			if (buffer == null) throw new Error("Buffer is null");
			vertexBuffersIndexes[vertexBuffersLength] = index;
			vertexBuffers[vertexBuffersLength] = buffer;
			vertexBuffersOffsets[vertexBuffersLength] = bufferOffset;
			vertexBuffersFormats[vertexBuffersLength] = format;
			vertexBuffersLength++;
		}
		
		alternativa3d function setVertexConstantsFromVector(firstRegister:int, data:Vector.<Number>, numRegisters:int):void {
			if (uint(firstRegister) > (128 - numRegisters)) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + numRegisters > vertexConstantsRegistersCount) {
				vertexConstantsRegistersCount = firstRegister + numRegisters;
				vertexConstants.length = vertexConstantsRegistersCount << 2;
			}
			for (var i:int = 0, len:int = numRegisters << 2; i < len; i++) {
				vertexConstants[offset] = data[i];
				offset++;
			}
		}
		
		alternativa3d function setVertexConstantsFromNumbers(firstRegister:int, x:Number, y:Number, z:Number, w:Number = 1):void {
			if (uint(firstRegister) > 127) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 1 > vertexConstantsRegistersCount) {
				vertexConstantsRegistersCount = firstRegister + 1;
				vertexConstants.length = vertexConstantsRegistersCount << 2;
			}
			vertexConstants[offset] = x; offset++;
			vertexConstants[offset] = y; offset++;
			vertexConstants[offset] = z; offset++;
			vertexConstants[offset] = w;
		}
		
		alternativa3d function setVertexConstantsFromTransform(firstRegister:int, transform:Transform3D):void {
			if (uint(firstRegister) > 125) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 3 > vertexConstantsRegistersCount) {
				vertexConstantsRegistersCount = firstRegister + 3;
				vertexConstants.length = vertexConstantsRegistersCount << 2;
			}
			vertexConstants[offset] = transform.a; offset++;
			vertexConstants[offset] = transform.b; offset++;
			vertexConstants[offset] = transform.c; offset++;
			vertexConstants[offset] = transform.d; offset++;
			vertexConstants[offset] = transform.e; offset++;
			vertexConstants[offset] = transform.f; offset++;
			vertexConstants[offset] = transform.g; offset++;
			vertexConstants[offset] = transform.h; offset++;
			vertexConstants[offset] = transform.i; offset++;
			vertexConstants[offset] = transform.j; offset++;
			vertexConstants[offset] = transform.k; offset++;
			vertexConstants[offset] = transform.l;
		}

		/**
		 * @private
		 */
		alternativa3d function setProjectionConstants(camera:Camera3D, firstRegister:int, transform:Transform3D = null):void {
			if (uint(firstRegister) > 124) throw new Error("Register index is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 4 > vertexConstantsRegistersCount) {
				vertexConstantsRegistersCount = firstRegister + 4;
				vertexConstants.length = vertexConstantsRegistersCount << 2;
			}
			if (transform != null) {
				vertexConstants[offset] = transform.a*camera.m0; offset++;
				vertexConstants[offset] = transform.b*camera.m0; offset++;
				vertexConstants[offset] = transform.c*camera.m0; offset++;
				vertexConstants[offset] = transform.d*camera.m0; offset++;
				vertexConstants[offset] = transform.e*camera.m5; offset++;
				vertexConstants[offset] = transform.f*camera.m5; offset++;
				vertexConstants[offset] = transform.g*camera.m5; offset++;
				vertexConstants[offset] = transform.h*camera.m5; offset++;
				vertexConstants[offset] = transform.i*camera.m10; offset++;
				vertexConstants[offset] = transform.j*camera.m10; offset++;
				vertexConstants[offset] = transform.k*camera.m10; offset++;
				vertexConstants[offset] = transform.l*camera.m10 + camera.m14; offset++;
				if (!camera.orthographic) {
					vertexConstants[offset] = transform.i; offset++;
					vertexConstants[offset] = transform.j; offset++;
					vertexConstants[offset] = transform.k; offset++;
					vertexConstants[offset] = transform.l;
				} else {
					vertexConstants[offset] = 0; offset++;
					vertexConstants[offset] = 0; offset++;
					vertexConstants[offset] = 0; offset++;
					vertexConstants[offset] = 1;
				}
			} else {
				vertexConstants[offset] = camera.m0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = camera.m5; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = camera.m10; offset++;
				vertexConstants[offset] = camera.m14; offset++;
				vertexConstants[offset] = 0; offset++;
				vertexConstants[offset] = 0; offset++;
				if (!camera.orthographic) {
					vertexConstants[offset] = 1; offset++;
					vertexConstants[offset] = 0;
				} else {
					vertexConstants[offset] = 0; offset++;
					vertexConstants[offset] = 1;
				}
			}
		}

		alternativa3d function setFragmentConstantsFromVector(firstRegister:int, data:Vector.<Number>, numRegisters:int):void {
			if (uint(firstRegister) > (28 - numRegisters)) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + numRegisters > fragmentConstantsRegistersCount) {
				fragmentConstantsRegistersCount = firstRegister + numRegisters;
			}
			for (var i:int = 0, len:int = numRegisters << 2; i < len; i++) {
				fragmentConstants[offset] = data[i];
				offset++;
			}
		}
		
		alternativa3d function setFragmentConstantsFromNumbers(firstRegister:int, x:Number, y:Number, z:Number, w:Number = 1):void {
			if (uint(firstRegister) > 27) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 1 > fragmentConstantsRegistersCount) {
				fragmentConstantsRegistersCount = firstRegister + 1;
			}
			fragmentConstants[offset] = x; offset++;
			fragmentConstants[offset] = y; offset++;
			fragmentConstants[offset] = z; offset++;
			fragmentConstants[offset] = w;
		}
		
		alternativa3d function setFragmentConstantsFromTransform(firstRegister:int, transform:Transform3D):void {
			if (uint(firstRegister) > 25) throw new Error("Register index " + firstRegister + " is out of bounds.");
			var offset:int = firstRegister << 2;
			if (firstRegister + 3 > fragmentConstantsRegistersCount) {
				fragmentConstantsRegistersCount = firstRegister + 3;
			}
			fragmentConstants[offset] = transform.a; offset++;
			fragmentConstants[offset] = transform.b; offset++;
			fragmentConstants[offset] = transform.c; offset++;
			fragmentConstants[offset] = transform.d; offset++;
			fragmentConstants[offset] = transform.e; offset++;
			fragmentConstants[offset] = transform.f; offset++;
			fragmentConstants[offset] = transform.g; offset++;
			fragmentConstants[offset] = transform.h; offset++;
			fragmentConstants[offset] = transform.i; offset++;
			fragmentConstants[offset] = transform.j; offset++;
			fragmentConstants[offset] = transform.k; offset++;
			fragmentConstants[offset] = transform.l;
		}

	}
}
