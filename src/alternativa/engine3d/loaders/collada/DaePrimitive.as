/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.Geometry;

	use namespace collada;

	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class DaePrimitive extends DaeElement {
		
		internal static const NORMALS:int = 1;
		internal static const TANGENT4:int = 2;
		internal static const TEXCOORDS:Vector.<uint> = Vector.<uint>([8, 16, 32, 64, 128, 256, 512, 1024]);

		internal var verticesInput:DaeInput;
		internal var texCoordsInputs:Vector.<DaeInput>;
		internal var normalsInput:DaeInput;
		internal var biNormalsInputs:Vector.<DaeInput>;
		internal var tangentsInputs:Vector.<DaeInput>;

		internal var indices:Vector.<uint>;
		internal var inputsStride:int;

		public var indexBegin:int;
		public var numTriangles:int;

		public function DaePrimitive(data:XML, document:DaeDocument) {
			super(data, document);
		}

		override protected function parseImplementation():Boolean {
			parseInputs();
			parseIndices();
			return true;
		}

		private function get type():String {
			return data.localName() as String;
		}

		private function parseInputs():void {
			texCoordsInputs = new Vector.<DaeInput>();
			tangentsInputs = new Vector.<DaeInput>();
			biNormalsInputs = new Vector.<DaeInput>();
			var inputsList:XMLList = data.input;
			var maxInputOffset:int = 0;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "VERTEX" :
							if (verticesInput == null) {
								verticesInput = input;
							}
							break;
						case "TEXCOORD" :
							texCoordsInputs.push(input);
							break;
						case "NORMAL":
							if (normalsInput == null) {
								normalsInput = input;
							}
							break;
						case "TEXTANGENT":
							tangentsInputs.push(input);
							break;
						case "TEXBINORMAL":
							biNormalsInputs.push(input);
							break;
					}
				}
				var offset:int = input.offset;
				maxInputOffset = (offset > maxInputOffset) ? offset : maxInputOffset;
			}
			inputsStride = maxInputOffset + 1;
		}

		private function parseIndices():void {
			indices = new Vector.<uint>();
			var array:Array;
			var vcount:Vector.<int> = new Vector.<int>();
			var i:int = 0;
			var count:int = 0;
			switch (data.localName()) {
				case "polylist":
				case "polygons":
					var vcountXML:XMLList = data.vcount;
					array = parseStringArray(vcountXML[0]);
					for (i = 0,count = array.length; i < count; i++) {
						vcount.push(parseInt(array[i]));
					}
				case "triangles":
					var pList:XMLList = data.p;
					for (i = 0,count = pList.length(); i < count; i++) {
						array = parseStringArray(pList[i]);
						for (var j:int = 0; j < array.length; j++) {
							indices.push(parseInt(array[j], 10));
						}
						if (vcount.length > 0) {
							indices = triangulate(indices, vcount);
						}

					}
					break;

			}
		}

		private function triangulate(input:Vector.<uint>, vcount:Vector.<int>):Vector.<uint> {
			var res:Vector.<uint> = new Vector.<uint>();
			var indexIn:uint, indexOut:uint = 0;
			var i:int, j:int, k:int, count:int;
			for (i = 0,count = vcount.length; i < count; i++) {
				var verticesCount:int = vcount[i];
				var attributesCount:int = verticesCount*inputsStride;
				if (verticesCount == 3) {
					for (j = 0; j < attributesCount; j++,indexIn++,indexOut++) {
						res[indexOut] = input[indexIn];
					}
				} else {
					for (j = 1; j < verticesCount - 1; j++) {
						// 0 - vertex
						for (k = 0; k < inputsStride; k++,indexOut++) {
							res[indexOut] = input[int(indexIn + k)];
						}
						// 1 - vertex
						for (k = 0; k < inputsStride; k++,indexOut++) {
							res[indexOut] = input[int(indexIn + inputsStride*j + k)];
						}
						// 2 - vertex
						for (k = 0; k < inputsStride; k++,indexOut++) {
							res[indexOut] = input[int(indexIn + inputsStride*(j + 1) + k)];
						}
					}
					indexIn += inputsStride*verticesCount;
				}
			}
			return res;
		}

		public function fillGeometry(geometry:Geometry, vertices:Vector.<DaeVertex>):uint {
			if (verticesInput == null) {
				// Error
				return 0;
			}
			verticesInput.parse();

			var numIndices:int = indices.length;

			var daeVertices:DaeVertices = document.findVertices(verticesInput.source);
			if (daeVertices == null) {
				document.logger.logNotFoundError(verticesInput.source);
				return 0;
			}
			daeVertices.parse();

			var positionSource:DaeSource = daeVertices.positions;
			var vertexStride:int = 3;	// XYZ

			var mainSource:DaeSource = positionSource;
			var mainInput:DaeInput = verticesInput;

			var tangentSource:DaeSource;
			var binormalSource:DaeSource;

			var channels:uint = 0;
			var normalSource:DaeSource;
			var inputOffsets:Vector.<int> = new Vector.<int>();
			inputOffsets.push(verticesInput.offset);
			if (normalsInput != null) {
				normalSource = normalsInput.prepareSource(3);
				inputOffsets.push(normalsInput.offset);
				vertexStride += 3;
				channels |= NORMALS;
				if (tangentsInputs.length > 0 && biNormalsInputs.length > 0) {
					tangentSource = tangentsInputs[0].prepareSource(3);
					inputOffsets.push(tangentsInputs[0].offset);
					binormalSource = biNormalsInputs[0].prepareSource(3);
					inputOffsets.push(biNormalsInputs[0].offset);
					vertexStride += 4;
					channels |= TANGENT4;
				}
			}
			var textureSources:Vector.<DaeSource> = new Vector.<DaeSource>();
			var numTexCoordsInputs:int = texCoordsInputs.length;
			if (numTexCoordsInputs > 8) {
				// TODO: Warning
				numTexCoordsInputs = 8;
			}
			for (var i:int = 0; i < numTexCoordsInputs; i++) {
				var s:DaeSource = texCoordsInputs[i].prepareSource(2);
				textureSources.push(s);
				inputOffsets.push(texCoordsInputs[i].offset);
				vertexStride += 2;
				channels |= TEXCOORDS[i];
			}

			var verticesLength:int = vertices.length;
			
			// Make geometry data
			var index:uint;
			var vertex:DaeVertex;

			indexBegin = geometry._indices.length;
			for (i = 0; i < numIndices; i += inputsStride) {
				index = indices[int(i + mainInput.offset)];

				vertex = vertices[index];
				if (vertex == null || !isEqual(vertex, indices, i, inputOffsets)) {
					if (vertex != null) {
						// Add to end
						index = verticesLength++;
					}
					vertex = new DaeVertex();
					vertices[index] = vertex;
					vertex.vertexInIndex = indices[int(i + verticesInput.offset)];
					vertex.addPosition(positionSource.numbers, vertex.vertexInIndex, positionSource.stride, document.unitScaleFactor);

					if (normalSource != null) {
						vertex.addNormal(normalSource.numbers, indices[int(i + normalsInput.offset)], normalSource.stride);
						
					}
					if (tangentSource != null) {
						vertex.addTangentBiDirection(tangentSource.numbers, indices[int(i + tangentsInputs[0].offset)], tangentSource.stride, binormalSource.numbers, indices[int(i + biNormalsInputs[0].offset)], binormalSource.stride);
					}
					for (var j:int = 0; j < textureSources.length; j++) {
						vertex.appendUV(textureSources[j].numbers, indices[int(i + texCoordsInputs[j].offset)], textureSources[j].stride);
					}
				}
				vertex.vertexOutIndex = index;
				geometry._indices.push(index);
			}
			numTriangles = (geometry._indices.length - indexBegin)/3;
			return channels;
		}

		private function isEqual(vertex:DaeVertex, indices:Vector.<uint>, index:int, offsets:Vector.<int>):Boolean {
			var numOffsets:int = offsets.length;
			for (var j:int = 0; j < numOffsets; j++) {
				if (vertex.indices[j] != indices[int(index + offsets[j])]) {
					return false;
				}
			}
			return true;
		}
		
		private function findInputBySet(inputs:Vector.<DaeInput>, setNum:int):DaeInput {
			for (var i:int = 0, numInputs:int = inputs.length; i < numInputs; i++) {
				var input:DaeInput = inputs[i];
				if (input.setNum == setNum) {
					return input;
				}
			}
			return null;
		}

		/**
		 * Returns array of texture channels data. First element stores channel with mainSetNum.
		 */
		private function getTexCoordsDatas(mainSetNum:int):Vector.<VertexChannelData> {
			var mainInput:DaeInput = findInputBySet(texCoordsInputs, mainSetNum);
			var i:int;
			var numInputs:int = texCoordsInputs.length;
			var datas:Vector.<VertexChannelData> = new Vector.<VertexChannelData>();
			for (i = 0; i < numInputs; i++) {
				var texCoordsInput:DaeInput = texCoordsInputs[i];
				var texCoordsSource:DaeSource = texCoordsInput.prepareSource(2);
				if (texCoordsSource != null) {
					var data:VertexChannelData = new VertexChannelData(texCoordsSource.numbers, texCoordsSource.stride, texCoordsInput.offset, texCoordsInput.setNum);
					if (texCoordsInput == mainInput) {
						datas.unshift(data);
					} else {
						datas.push(data);
					}
				}
			}
			return (datas.length > 0) ? datas : null;
		}

		/**
		 * Compare vertices of  the privitive  with given  at <code>otherVertices</code> parameter vertices.
		 * Call <code>parse()</code> before using.
		 */
		public function verticesEquals(otherVertices:DaeVertices):Boolean {
			var vertices:DaeVertices = document.findVertices(verticesInput.source);
			if (vertices == null) {
				document.logger.logNotFoundError(verticesInput.source);
			}
			return vertices == otherVertices;
		}

		public function get materialSymbol():String {
			var attr:XML = data.@material[0];
			return (attr == null) ? null : attr.toString();
		}

	}
}

import flash.geom.Point;

class VertexChannelData {
	public var values:Vector.<Number>;
	public var stride:int;
	public var offset:int;
	public var index:int;
	public var channel:Vector.<Point>;
	public var inputSet:int;

	public function VertexChannelData(values:Vector.<Number>, stride:int, offset:int, inputSet:int = 0) {
		this.values = values;
		this.stride = stride;
		this.offset = offset;
		this.inputSet = inputSet;
	}

}
