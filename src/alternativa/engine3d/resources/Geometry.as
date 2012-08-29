/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.VertexStream;

	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;
	/**
	 * Resource, that stores data about geometry of object. All data are stored for each vertex.
	 * So, you can set any set of parameters. And this set will be defined for each vertex of geometry.
	 * It will be useful to divide parameters by some vertexBuffers in order to update these data at
	 * memory of GPU, independently of each other (vertexBuffer  can be updated at once only).
	 * For this, you can store groups of parameters in different streams. Based on them vertexBuffers will be formed on uploading to GPU.
	 * When new stream is formed, are specified the parameters, that will be stored in it.
	 *
	 * @example This code creates stream on properties: x,y,z,u,v and forms a triangle by three vertices.
	 * <listing version="3.0">
	 * var attributes:Array = new Array();
	 * attributes[0] = VertexAttributes.POSITION;
	 * attributes[1] = VertexAttributes.POSITION;
	 * attributes[2] = VertexAttributes.POSITION;
	 * attributes[3] = VertexAttributes.TEXCOORDS[0];
	 * attributes[4] = VertexAttributes.TEXCOORDS[0];
	 * var geometry = new Geometry();
	 * geometry.addVertexStream(attributes);
	 * geometry.numVertices = 3;
	 * geometry.setAttributeValues(VertexAttributes.POSITION, new &lt;Number&gt;[x1,y1,z1,x2,y2,z2,x3,y3,z3]);
	 * geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], new &lt;Number&gt;[u1,v1,u2,v2,u3,v3]);
	 * geometry.indices = Vector.&lt;uint&gt;([0,1,2]);
	 * </listing>
	 * To get access to data, you can use method <code>getAttributeValues</code> by parameter name, e.g.:
	 * <code>geometry.getAttributeValues(VertexAttributes.POSITION)</code>
	 * returns vector from coordinates: &lt;Number&gt;[x1,y1,z1,x2,y2,z2,x3,y3,z3].
	 */
	public class Geometry extends Resource {

		/**
		 * @private
		 */
		alternativa3d var _vertexStreams:Vector.<VertexStream> = new Vector.<VertexStream>();
		
		/**
		 * @private
		 */
		alternativa3d var _indexBuffer:IndexBuffer3D;

		/**
		 * @private
		 */
		alternativa3d var _numVertices:int;
		
		/**
		 * @private
		 */
		alternativa3d var _indices:Vector.<uint> = new Vector.<uint>();

		/**
		 * @private
		 */
		alternativa3d var _attributesStreams:Vector.<VertexStream> = new Vector.<VertexStream>();

		/**
		 * @private
		 */
		alternativa3d var _attributesOffsets:Vector.<int> = new Vector.<int>();

		private var _attributesStrides:Vector.<int> = new Vector.<int>();

		/**
		 * Creates a new instance.
		 * @param numVertices Number of vertices.
		 */
		public function Geometry(numVertices:int = 0) {
			this._numVertices = numVertices;
		}

		/**
		 * Number of triangles, that are contained in geometry.
		 */
		public function get numTriangles():int {
			return _indices.length/3;
		}

		/**
		 * Indexes of vertices for specifying of triangles of surface.
		 * Example of specifying of surface, that consists of two triangles: <code> Vector.&lt;uint&gt;([vertex_id_1,vertex_id_2,vertex_id_3,vertex_id_4,vertex_id_5,vertex_id_6]);</code>.
		 */
		public function get indices():Vector.<uint> {
			return _indices.slice();
		}

		/**
		 * @private
		 */
		public function set indices(value:Vector.<uint>):void {
			if (value == null) {
				_indices.length = 0;
			} else {
				_indices = value.slice()
			}
		}

		/**
		 * Number of vertices of geometry.
		 */
		public function get numVertices():int {
			return _numVertices;
		}

		/**
		 * @private
		 */
		public function set numVertices(value:int):void {
			if (_numVertices != value) {
				// Change buffers.
				for each (var vBuffer:VertexStream in _vertexStreams) {
					var numMappings:int = vBuffer.attributes.length;
					vBuffer.data.length = 4*numMappings*value;
				}
				_numVertices = value;
			}
		}

		/**
		 * Calculation of vertex normals.
		 */
		public function calculateNormals():void {
			if (!hasAttribute(VertexAttributes.POSITION)) throw new Error("Vertices positions is required to calculate normals");
			var normals:Array = new Array();
			var positionsStream:VertexStream = _attributesStreams[VertexAttributes.POSITION];
			var positionsData:ByteArray = positionsStream.data;
			var positionsOffset:int = _attributesOffsets[VertexAttributes.POSITION]*4;
			var stride:int = positionsStream.attributes.length*4;
			var numIndices:int = _indices.length;
			var normal:Vector3D;
			var i:int;
			// Normals calculations
			for (i = 0; i < numIndices; i += 3) {
				var vertIndexA:int = _indices[i];
				var vertIndexB:int = _indices[i + 1];
				var vertIndexC:int = _indices[i + 2];
				// v1
				positionsData.position = vertIndexA*stride + positionsOffset;
				var ax:Number = positionsData.readFloat();
				var ay:Number = positionsData.readFloat();
				var az:Number = positionsData.readFloat();

				// v2
				positionsData.position = vertIndexB*stride + positionsOffset;
				var bx:Number = positionsData.readFloat();
				var by:Number = positionsData.readFloat();
				var bz:Number = positionsData.readFloat();

				// v3
				positionsData.position = vertIndexC*stride + positionsOffset;
				var cx:Number = positionsData.readFloat();
				var cy:Number = positionsData.readFloat();
				var cz:Number = positionsData.readFloat();

				// v2-v1
				var abx:Number = bx - ax;
				var aby:Number = by - ay;
				var abz:Number = bz - az;

				// v3-v1
				var acx:Number = cx - ax;
				var acy:Number = cy - ay;
				var acz:Number = cz - az;

				var normalX:Number = acz*aby - acy*abz;
				var normalY:Number = acx*abz - acz*abx;
				var normalZ:Number = acy*abx - acx*aby;

				var normalLen:Number = Math.sqrt(normalX*normalX + normalY*normalY + normalZ*normalZ);

				if (normalLen > 0) {
					normalX /= normalLen;
					normalY /= normalLen;
					normalZ /= normalLen;
				} else {
					trace("degenerated triangle", i/3);
				}

				// v1 normal
				normal = normals[vertIndexA];

				if (normal == null) {
					normals[vertIndexA] = new Vector3D(normalX, normalY, normalZ);
				} else {
					normal.x += normalX;
					normal.y += normalY;
					normal.z += normalZ;
				}

				// v2 normal
				normal = normals[vertIndexB];

				if (normal == null) {
					normals[vertIndexB] = new Vector3D(normalX, normalY, normalZ);
				} else {
					normal.x += normalX;
					normal.y += normalY;
					normal.z += normalZ;
				}

				// v3 normal
				normal = normals[vertIndexC];

				if (normal == null) {
					normals[vertIndexC] = new Vector3D(normalX, normalY, normalZ);
				} else {
					normal.x += normalX;
					normal.y += normalY;
					normal.z += normalZ;
				}
			}

			if (hasAttribute(VertexAttributes.NORMAL)) {
				var normalsOffset:int = _attributesOffsets[VertexAttributes.NORMAL]*4;
				var normalsStream:VertexStream = _attributesStreams[VertexAttributes.NORMAL];
				var normalsBuffer:ByteArray = normalsStream.data;
				var normalsBufferStride:uint = normalsStream.attributes.length*4;
				for (i = 0; i < _numVertices; i++) {
					normal = normals[i];
					normalsBuffer.position = i*normalsBufferStride + normalsOffset;
					if (normal != null) {
						// vertex not in face
						normal.normalize();
						normalsBuffer.writeFloat(normal.x);
						normalsBuffer.writeFloat(normal.y);
						normalsBuffer.writeFloat(normal.z);
					} else {
						normalsBuffer.writeFloat(0);
						normalsBuffer.writeFloat(0);
						normalsBuffer.writeFloat(1);
					}
				}
			} else {
				// Write normals to ByteArray
				var resultByteArray:ByteArray = new ByteArray();
				resultByteArray.endian = Endian.LITTLE_ENDIAN;
				for (i = 0; i < _numVertices; i++) {
					normal = normals[i];
					resultByteArray.writeBytes(positionsData, i*stride, stride);
					if (normal != null) {
						normal.normalize();
						resultByteArray.writeFloat(normal.x);
						resultByteArray.writeFloat(normal.y);
						resultByteArray.writeFloat(normal.z);
					} else {
						resultByteArray.writeFloat(0);
						resultByteArray.writeFloat(0);
						resultByteArray.writeFloat(1);
					}
				}
				positionsStream.attributes.push(VertexAttributes.NORMAL);
				positionsStream.attributes.push(VertexAttributes.NORMAL);
				positionsStream.attributes.push(VertexAttributes.NORMAL);

				positionsStream.data = resultByteArray;
				positionsData.clear();

				_attributesOffsets[VertexAttributes.NORMAL] = stride/4;
				_attributesStreams[VertexAttributes.NORMAL] = positionsStream;
				_attributesStrides[VertexAttributes.NORMAL] = 3;
			}

		}

		/**
		 * Calculation of tangents and bi-normals. Normals of geometry must be calculated.
		 */
		public function calculateTangents(uvChannel:int):void {
			if (!hasAttribute(VertexAttributes.POSITION)) throw new Error("Vertices positions is required to calculate normals");
			if (!hasAttribute(VertexAttributes.NORMAL)) throw new Error("Vertices normals is required to calculate tangents, call calculateNormals first");
			if (!hasAttribute(VertexAttributes.TEXCOORDS[uvChannel])) throw new Error("Specified uv channel does not exist in geometry");

			var tangents:Array = new Array();

			var positionsStream:VertexStream = _attributesStreams[VertexAttributes.POSITION];
			var positionsData:ByteArray = positionsStream.data;
			var positionsOffset:int = _attributesOffsets[VertexAttributes.POSITION]*4;
			var positionsStride:int = positionsStream.attributes.length*4;

			var normalsStream:VertexStream = _attributesStreams[VertexAttributes.NORMAL];
			var normalsData:ByteArray = normalsStream.data;
			var normalsOffset:int = _attributesOffsets[VertexAttributes.NORMAL]*4;
			var normalsStride:int = normalsStream.attributes.length*4;

			var uvsStream:VertexStream = _attributesStreams[VertexAttributes.TEXCOORDS[uvChannel]];
			var uvsData:ByteArray = uvsStream.data;
			var uvsOffset:int = _attributesOffsets[VertexAttributes.TEXCOORDS[uvChannel]]*4;
			var uvsStride:int = uvsStream.attributes.length*4;

			var numIndices:int = _indices.length;
			var normal:Vector3D;
			var tangent:Vector3D;
			var i:int;

			for (i = 0; i < numIndices; i += 3) {
				var vertIndexA:int = _indices[i];
				var vertIndexB:int = _indices[i + 1];
				var vertIndexC:int = _indices[i + 2];

				// a.xyz
				positionsData.position = vertIndexA*positionsStride + positionsOffset;
				var ax:Number = positionsData.readFloat();
				var ay:Number = positionsData.readFloat();
				var az:Number = positionsData.readFloat();

				// b.xyz
				positionsData.position = vertIndexB*positionsStride + positionsOffset;
				var bx:Number = positionsData.readFloat();
				var by:Number = positionsData.readFloat();
				var bz:Number = positionsData.readFloat();

				// c.xyz
				positionsData.position = vertIndexC*positionsStride + positionsOffset;
				var cx:Number = positionsData.readFloat();
				var cy:Number = positionsData.readFloat();
				var cz:Number = positionsData.readFloat();

				// a.uv
				uvsData.position = vertIndexA*uvsStride + uvsOffset;
				var au:Number = uvsData.readFloat();
				var av:Number = uvsData.readFloat();

				// b.uv
				uvsData.position = vertIndexB*uvsStride + uvsOffset;
				var bu:Number = uvsData.readFloat();
				var bv:Number = uvsData.readFloat();

				// c.uv
				uvsData.position = vertIndexC*uvsStride + uvsOffset;
				var cu:Number = uvsData.readFloat();
				var cv:Number = uvsData.readFloat();

				// a.nrm
				normalsData.position = vertIndexA*normalsStride + normalsOffset;
				var anx:Number = normalsData.readFloat();
				var any:Number = normalsData.readFloat();
				var anz:Number = normalsData.readFloat();

				// b.nrm
				normalsData.position = vertIndexB*normalsStride + normalsOffset;
				var bnx:Number = normalsData.readFloat();
				var bny:Number = normalsData.readFloat();
				var bnz:Number = normalsData.readFloat();

				// c.nrm
				normalsData.position = vertIndexC*normalsStride + normalsOffset;
				var cnx:Number = normalsData.readFloat();
				var cny:Number = normalsData.readFloat();
				var cnz:Number = normalsData.readFloat();

				// v2-v1
				var abx:Number = bx - ax;
				var aby:Number = by - ay;
				var abz:Number = bz - az;

				// v3-v1
				var acx:Number = cx - ax;
				var acy:Number = cy - ay;
				var acz:Number = cz - az;

				var abu:Number = bu - au;
				var abv:Number = bv - av;

				var acu:Number = cu - au;
				var acv:Number = cv - av;

				var r:Number = 1/(abu*acv - acu*abv);

				var tangentX:Number = r*(acv*abx - acx*abv);
				var tangentY:Number = r*(acv*aby - abv*acy);
				var tangentZ:Number = r*(acv*abz - abv*acz);

				tangent = tangents[vertIndexA];

				if (tangent == null) {
					tangents[vertIndexA] = new Vector3D(
							tangentX - anx*(anx*tangentX + any*tangentY + anz*tangentZ),
							tangentY - any*(anx*tangentX + any*tangentY + anz*tangentZ),
							tangentZ - anz*(anx*tangentX + any*tangentY + anz*tangentZ));

				} else {
					tangent.x += tangentX - anx*(anx*tangentX + any*tangentY + anz*tangentZ);
					tangent.y += tangentY - any*(anx*tangentX + any*tangentY + anz*tangentZ);
					tangent.z += tangentZ - anz*(anx*tangentX + any*tangentY + anz*tangentZ);
				}

				tangent = tangents[vertIndexB];

				if (tangent == null) {
					tangents[vertIndexB] = new Vector3D(
							tangentX - bnx*(bnx*tangentX + bny*tangentY + bnz*tangentZ),
							tangentY - bny*(bnx*tangentX + bny*tangentY + bnz*tangentZ),
							tangentZ - bnz*(bnx*tangentX + bny*tangentY + bnz*tangentZ));

				} else {
					tangent.x += tangentX - bnx*(bnx*tangentX + bny*tangentY + bnz*tangentZ);
					tangent.y += tangentY - bny*(bnx*tangentX + bny*tangentY + bnz*tangentZ);
					tangent.z += tangentZ - bnz*(bnx*tangentX + bny*tangentY + bnz*tangentZ);
				}

				tangent = tangents[vertIndexC];

				if (tangent == null) {
					tangents[vertIndexC] = new Vector3D(
							tangentX - cnx*(cnx*tangentX + cny*tangentY + cnz*tangentZ),
							tangentY - cny*(cnx*tangentX + cny*tangentY + cnz*tangentZ),
							tangentZ - cnz*(cnx*tangentX + cny*tangentY + cnz*tangentZ));

				} else {
					tangent.x += tangentX - cnx*(cnx*tangentX + cny*tangentY + cnz*tangentZ);
					tangent.y += tangentY - cny*(cnx*tangentX + cny*tangentY + cnz*tangentZ);
					tangent.z += tangentZ - cnz*(cnx*tangentX + cny*tangentY + cnz*tangentZ);
				}

			}

			if (hasAttribute(VertexAttributes.TANGENT4)) {
				var tangentsOffset:int = _attributesOffsets[VertexAttributes.TANGENT4]*4;
				var tangentsStream:VertexStream = _attributesStreams[VertexAttributes.TANGENT4];
				var tangentsBuffer:ByteArray = tangentsStream.data;
				var tangentsBufferStride:uint = tangentsStream.attributes.length*4;
				for (i = 0; i < _numVertices; i++) {
					tangent = tangents[i];
					tangentsBuffer.position = i*tangentsBufferStride + tangentsOffset;
					if (tangent != null) {
						tangent.normalize();
						tangentsBuffer.writeFloat(tangent.x);
						tangentsBuffer.writeFloat(tangent.y);
						tangentsBuffer.writeFloat(tangent.z);
						tangentsBuffer.writeFloat(-1);
					} else {
						tangentsBuffer.writeFloat(1);
						tangentsBuffer.writeFloat(0);
						tangentsBuffer.writeFloat(0);
						tangentsBuffer.writeFloat(-1);
					}
				}
			} else {
				// Write normals to ByteArray
				var resultByteArray:ByteArray = new ByteArray();
				resultByteArray.endian = Endian.LITTLE_ENDIAN;
				for (i = 0; i < _numVertices; i++) {
					tangent = tangents[i];
					resultByteArray.writeBytes(positionsData, i*positionsStride, positionsStride);
					if (tangent != null) {
						tangent.normalize();
						resultByteArray.writeFloat(tangent.x);
						resultByteArray.writeFloat(tangent.y);
						resultByteArray.writeFloat(tangent.z);
						resultByteArray.writeFloat(-1);
					} else {
						resultByteArray.writeFloat(1);
						resultByteArray.writeFloat(0);
						resultByteArray.writeFloat(0);
						resultByteArray.writeFloat(-1);
					}
				}
				positionsStream.attributes.push(VertexAttributes.TANGENT4);
				positionsStream.attributes.push(VertexAttributes.TANGENT4);
				positionsStream.attributes.push(VertexAttributes.TANGENT4);
				positionsStream.attributes.push(VertexAttributes.TANGENT4);

				positionsStream.data = resultByteArray;
				positionsData.clear();

				_attributesOffsets[VertexAttributes.TANGENT4] = positionsStride/4;
				_attributesStreams[VertexAttributes.TANGENT4] = positionsStream;
				_attributesStrides[VertexAttributes.TANGENT4] = 4;
			}
		}

		/**
		 * Adds a stream for set of parameters, that can be updated independently of the other sets of parameters.
		 * @param attributes List of parameters. Types of parameters are get from <code>VertexAttributes</code>.
		 * @return Index of stream, that has been created.
		 */
		public function addVertexStream(attributes:Array):int {
			var numMappings:int = attributes.length;
			if (numMappings < 1) {
				throw new Error("Must be at least one attribute ​​to create the buffer.");
			}
			var vBuffer:VertexStream = new VertexStream();
			var newBufferIndex:int = _vertexStreams.length;
			var attribute:uint = attributes[0];
			var stride:int = 1;
			for (var i:int = 1; i <= numMappings; i++) {
				var next:uint = (i < numMappings) ? attributes[i] : 0;
				if (next != attribute) {
					// Last item will enter here forcibly.
					if (attribute != 0) {
						if (attribute < _attributesStreams.length && _attributesStreams[attribute] != null) {
							throw new Error("Attribute " + attribute + " already used in this geometry.");
						}
						var numStandartFloats:int = VertexAttributes.getAttributeStride(attribute);
						if (numStandartFloats != 0 && numStandartFloats != stride) {
							throw new Error("Standard attributes must be predefined size.");
						}
						if (_attributesStreams.length < attribute) {
							_attributesStreams.length = attribute + 1;
							_attributesOffsets.length = attribute + 1;
							_attributesStrides.length = attribute + 1;
						}
						var startIndex:int = i - stride;
						_attributesStreams[attribute] = vBuffer;
						_attributesOffsets[attribute] = startIndex;
						_attributesStrides[attribute] = stride;
					}
					stride = 1;
				} else {
					stride++;
				}
				attribute = next;
			}
			vBuffer.attributes = attributes.slice();
			//			vBuffer.data = new Vector.<Number>(numMappings*_numVertices);
			vBuffer.data = new ByteArray();
			vBuffer.data.endian = Endian.LITTLE_ENDIAN;
			vBuffer.data.length = 4*numMappings*_numVertices;
			_vertexStreams[newBufferIndex] = vBuffer;
			return newBufferIndex;
		}

		/**
		 * Number of vertex-streams.
		 */
		public function get numVertexStreams():int {
			return _vertexStreams.length;
		}

		/**
		 * returns mapping of stream by index.
		 * @param index index of stream.
		 * @return mapping.
		 */
		public function getVertexStreamAttributes(index:int):Array {
			return _vertexStreams[index].attributes.slice();
		}

		/**
		 * Check the existence of attribute in all streams.
		 * @param attribute Attribute, that is checked.
		 * @return
		 */
		public function hasAttribute(attribute:uint):Boolean {
			return attribute < _attributesStreams.length && _attributesStreams[attribute] != null;
		}

		/**
		 * Returns index of stream, that contains needed attribute.
		 *
		 * @param attribute
		 *
		 * @return -1 if attribute is not found.
		 */
		public function findVertexStreamByAttribute(attribute:uint):int {
			var vBuffer:VertexStream = (attribute < _attributesStreams.length) ? _attributesStreams[attribute] : null;
			if (vBuffer != null) {
				for (var i:int = 0; i < _vertexStreams.length; i++) {
					if (_vertexStreams[i] == vBuffer) {
						return i;
					}
				}
			}
			return -1;
		}

		/**
		 * Offset of attribute at stream, with which this attribute is stored. You can find index of stream using <code>findVertexStreamByAttribute</code>.
		 *
		 * @param attribute Type of attribute. List of types of attributes placed at <code>VertexAttributes</code>.
		 * @return Offset.
		 *
		 * @see #findVertexStreamByAttribute
		 * @see VertexAttributes
		 */
		public function getAttributeOffset(attribute:uint):int {
			var vBuffer:VertexStream = (attribute < _attributesStreams.length) ? _attributesStreams[attribute] : null;
			if (vBuffer == null) {
				throw new Error("Attribute not found.");
			}
			return _attributesOffsets[attribute];
		}

		/**
		 * Sets value for attribute.
		 * If buffer has not been initialized, then it initialized with zeros automatically.
		 *
		 * @param attribute
		 * @param values
		 */
		public function setAttributeValues(attribute:uint, values:Vector.<Number>):void {
			var vBuffer:VertexStream = (attribute < _attributesStreams.length) ? _attributesStreams[attribute] : null;
			if (vBuffer == null) {
				throw new Error("Attribute not found.");
			}
			var stride:int = _attributesStrides[attribute];
			if (values == null || values.length != stride*_numVertices) {
				throw new Error("Values count must be the same.");
			}
			var numMappings:int = vBuffer.attributes.length;
			var data:ByteArray = vBuffer.data;
			var offset:int = _attributesOffsets[attribute];
			// Copy values
			for (var i:int = 0; i < _numVertices; i++) {
				var srcIndex:int = stride*i;
				data.position = 4*(numMappings*i + offset);
				for (var j:int = 0; j < stride; j++) {
					data.writeFloat(values[int(srcIndex + j)]);
				}
			}
		}

		public function getAttributeValues(attribute:uint):Vector.<Number> {
			var vBuffer:VertexStream = (attribute < _attributesStreams.length) ? _attributesStreams[attribute] : null;
			if (vBuffer == null) {
				throw new Error("Attribute not found.");
			}
			var data:ByteArray = vBuffer.data;
			var stride:int = _attributesStrides[attribute];
			var result:Vector.<Number> = new Vector.<Number>(stride*_numVertices);
			var numMappings:int = vBuffer.attributes.length;
			var offset:int = _attributesOffsets[attribute];
			// Copy values
			for (var i:int = 0; i < _numVertices; i++) {
				data.position = 4*(numMappings*i + offset);
				var dstIndex:int = stride*i;
				for (var j:int = 0; j < stride; j++) {
					result[int(dstIndex + j)] = data.readFloat();
				}
			}
			return result;
		}

		/**
		 * Check for existence of resource in video memory.
		 */
		override public function get isUploaded():Boolean {
			return _indexBuffer != null;
		}

		/**
		 * @inheritDoc
		 */
		override public function upload(context3D:Context3D):void {
			var vBuffer:VertexStream;
			var i:int;
			var numBuffers:int = _vertexStreams.length;
			if (_indexBuffer != null) {
				// Clear old resources
				_indexBuffer.dispose();
				_indexBuffer = null;
				for (i = 0; i < numBuffers; i++) {
					vBuffer = _vertexStreams[i];
					vBuffer.buffer.dispose();
					vBuffer.buffer = null;
				}
			}
			if (_indices.length <= 0 || _numVertices <= 0) {
				return;
			}

			for (i = 0; i < numBuffers; i++) {
				vBuffer = _vertexStreams[i];
				var numMappings:int = vBuffer.attributes.length;
				var data:ByteArray = vBuffer.data;
				if (data == null) {
					throw new Error("Cannot upload without vertex buffer data.");
				}
				vBuffer.buffer = context3D.createVertexBuffer(_numVertices, numMappings);
				vBuffer.buffer.uploadFromByteArray(data, 0, 0, _numVertices);
			}
			var numIndices:int = _indices.length;
			_indexBuffer = context3D.createIndexBuffer(numIndices);
			_indexBuffer.uploadFromVector(_indices, 0, numIndices);
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void {
			if (_indexBuffer != null) {
				_indexBuffer.dispose();
				_indexBuffer = null;
				var numBuffers:int = _vertexStreams.length;
				for (var i:int = 0; i < numBuffers; i++) {
					var vBuffer:VertexStream = _vertexStreams[i];
					vBuffer.buffer.dispose();
					vBuffer.buffer = null;
				}
			}
		}

		/**
		 * Updates values of index-buffer in video memory.
		 * @param data List of values.
		 * @param startOffset Offset.
		 * @param count Count of updated values.
		 */
		public function updateIndexBufferInContextFromVector(data:Vector.<uint>, startOffset:int, count:int):void {
			if (_indexBuffer == null) {
				throw new Error("Geometry must be uploaded.");
			}
			_indexBuffer.uploadFromVector(data, startOffset, count);
		}

		/**
		 * Updates values of index-buffer in video memory.
		 * @param data Data
		 * @param startOffset Offset
		 * @param count Number of updated values.
		 */
		public function updateIndexBufferInContextFromByteArray(data:ByteArray, byteArrayOffset:int, startOffset:int, count:int):void {
			if (_indexBuffer == null) {
				throw new Error("Geometry must be uploaded.");
			}
			_indexBuffer.uploadFromByteArray(data, byteArrayOffset, startOffset, count);
		}

		/**
		 * Updates values of vertex-buffer in video memory.
		 * @param data List of values.
		 * @param startVertex Offset.
		 * @param numVertices Number of updated values.
		 */
		public function updateVertexBufferInContextFromVector(index:int, data:Vector.<Number>, startVertex:int, numVertices:int):void {
			if (_indexBuffer == null) {
				throw new Error("Geometry must be uploaded.");
			}
			_vertexStreams[index].buffer.uploadFromVector(data, startVertex, numVertices);
		}

		/**
		 * Updates values of vertex-buffer in video memory.
		 * @param data Data
		 * @param startVertex Offset.
		 * @param numVertices Number of updated values.
		 */
		public function updateVertexBufferInContextFromByteArray(index:int, data:ByteArray, byteArrayOffset:int, startVertex:int, numVertices:int):void {
			if (_indexBuffer == null) {
				throw new Error("Geometry must be uploaded.");
			}
			_vertexStreams[index].buffer.uploadFromByteArray(data, byteArrayOffset, startVertex, numVertices);
		}

		alternativa3d function intersectRay(origin:Vector3D, direction:Vector3D, indexBegin:uint, numTriangles:uint):RayIntersectionData {
			var ox:Number = origin.x;
			var oy:Number = origin.y;
			var oz:Number = origin.z;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			var dz:Number = direction.z;

			var nax:Number;
			var nay:Number;
			var naz:Number;
			var nau:Number;
			var nav:Number;

			var nbx:Number;
			var nby:Number;
			var nbz:Number;
			var nbu:Number;
			var nbv:Number;

			var ncx:Number;
			var ncy:Number;
			var ncz:Number;
			var ncu:Number;
			var ncv:Number;

			var nrmX:Number;
			var nrmY:Number;
			var nrmZ:Number;

			var point:Vector3D;
			var minTime:Number = 1e+22;
			var posAttribute:int = VertexAttributes.POSITION;
			var uvAttribute:int = VertexAttributes.TEXCOORDS[0];
			var positionStream:VertexStream;
			if (VertexAttributes.POSITION >= _attributesStreams.length || (positionStream = _attributesStreams[posAttribute]) == null) {
				throw new Error("Raycast require POSITION attribute");
			}
			var positionBuffer:ByteArray = positionStream.data;
			// Offset of position attribute.
			const positionOffset:uint = _attributesOffsets[posAttribute]*4;
			// Length of vertex on bytes.
			var stride:uint = positionStream.attributes.length*4;

			var uvStream:VertexStream;
			var hasUV:Boolean = uvAttribute < _attributesStreams.length && (uvStream = _attributesStreams[uvAttribute]) != null;
			var uvBuffer:ByteArray;
			var uvOffset:uint;
			var uvStride:uint;
			if (hasUV) {
				uvBuffer = uvStream.data;
				uvOffset = _attributesOffsets[uvAttribute]*4;
				uvStride = uvStream.attributes.length*4;
			}

			if (numTriangles*3 > indices.length) {
				throw new ArgumentError("index is out of bounds");
			}
			for (var i:int = indexBegin, count:int = indexBegin + numTriangles*3; i < count; i += 3) {
				var indexA:uint = indices[i];
				var indexB:uint = indices[int(i + 1)];
				var indexC:uint = indices[int(i + 2)];
				positionBuffer.position = indexA*stride + positionOffset;
				var ax:Number = positionBuffer.readFloat();
				var ay:Number = positionBuffer.readFloat();
				var az:Number = positionBuffer.readFloat();
				var au:Number;
				var av:Number;
				positionBuffer.position = indexB*stride + positionOffset;
				var bx:Number = positionBuffer.readFloat();
				var by:Number = positionBuffer.readFloat();
				var bz:Number = positionBuffer.readFloat();
				var bu:Number;
				var bv:Number;

				positionBuffer.position = indexC*stride + positionOffset;
				var cx:Number = positionBuffer.readFloat();
				var cy:Number = positionBuffer.readFloat();
				var cz:Number = positionBuffer.readFloat();
				var cu:Number;
				var cv:Number;

				if (hasUV) {
					uvBuffer.position = indexA*uvStride + uvOffset;
					au = uvBuffer.readFloat();
					av = uvBuffer.readFloat();

					uvBuffer.position = indexB*uvStride + uvOffset;
					bu = uvBuffer.readFloat();
					bv = uvBuffer.readFloat();

					uvBuffer.position = indexC*uvStride + uvOffset;
					cu = uvBuffer.readFloat();
					cv = uvBuffer.readFloat();
				}

				var abx:Number = bx - ax;
				var aby:Number = by - ay;
				var abz:Number = bz - az;
				var acx:Number = cx - ax;
				var acy:Number = cy - ay;
				var acz:Number = cz - az;
				var normalX:Number = acz*aby - acy*abz;
				var normalY:Number = acx*abz - acz*abx;
				var normalZ:Number = acy*abx - acx*aby;
				var len:Number = normalX*normalX + normalY*normalY + normalZ*normalZ;
				if (len > 0.001) {
					len = 1/Math.sqrt(len);
					normalX *= len;
					normalY *= len;
					normalZ *= len;
				}
				var dot:Number = dx*normalX + dy*normalY + dz*normalZ;
				if (dot < 0) {
					var offset:Number = ox*normalX + oy*normalY + oz*normalZ - (ax*normalX + ay*normalY + az*normalZ);
					if (offset > 0) {
						var time:Number = -offset/dot;
						if (point == null || time < minTime) {
							var rx:Number = ox + dx*time;
							var ry:Number = oy + dy*time;
							var rz:Number = oz + dz*time;
							abx = bx - ax;
							aby = by - ay;
							abz = bz - az;
							acx = rx - ax;
							acy = ry - ay;
							acz = rz - az;
							if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ >= 0) {
								abx = cx - bx;
								aby = cy - by;
								abz = cz - bz;
								acx = rx - bx;
								acy = ry - by;
								acz = rz - bz;
								if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ >= 0) {
									abx = ax - cx;
									aby = ay - cy;
									abz = az - cz;
									acx = rx - cx;
									acy = ry - cy;
									acz = rz - cz;
									if ((acz*aby - acy*abz)*normalX + (acx*abz - acz*abx)*normalY + (acy*abx - acx*aby)*normalZ >= 0) {
										if (time < minTime) {
											minTime = time;
											if (point == null) point = new Vector3D();
											point.x = rx;
											point.y = ry;
											point.z = rz;
											nax = ax;
											nay = ay;
											naz = az;
											nau = au;
											nav = av;
											nrmX = normalX;
											nbx = bx;
											nby = by;
											nbz = bz;
											nbu = bu;
											nbv = bv;
											nrmY = normalY;
											ncx = cx;
											ncy = cy;
											ncz = cz;
											ncu = cu;
											ncv = cv;
											nrmZ = normalZ;
										}
									}
								}
							}
						}
					}
				}
			}
			if (point != null) {
				var res:RayIntersectionData = new RayIntersectionData();
				res.point = point;
				res.time = minTime;
				if (hasUV) {
					// Calculation of UV.
					abx = nbx - nax;
					aby = nby - nay;
					abz = nbz - naz;
					var abu:Number = nbu - nau;
					var abv:Number = nbv - nav;

					acx = ncx - nax;
					acy = ncy - nay;
					acz = ncz - naz;
					var acu:Number = ncu - nau;
					var acv:Number = ncv - nav;

					// Calculation of uv-transformation matrix.
					var det:Number = -nrmX*acy*abz + acx*nrmY*abz + nrmX*aby*acz - abx*nrmY*acz - acx*aby*nrmZ + abx*acy*nrmZ;
					var ima:Number = (-nrmY*acz + acy*nrmZ)/det;
					var imb:Number = (nrmX*acz - acx*nrmZ)/det;
					var imc:Number = (-nrmX*acy + acx*nrmY)/det;
					var imd:Number = (nax*nrmY*acz - nrmX*nay*acz - nax*acy*nrmZ + acx*nay*nrmZ + nrmX*acy*naz - acx*nrmY*naz)/det;
					var ime:Number = (nrmY*abz - aby*nrmZ)/det;
					var imf:Number = (-nrmX*abz + abx*nrmZ)/det;
					var img:Number = (nrmX*aby - abx*nrmY)/det;
					var imh:Number = (nrmX*nay*abz - nax*nrmY*abz + nax*aby*nrmZ - abx*nay*nrmZ - nrmX*aby*naz + abx*nrmY*naz)/det;
					var ma:Number = abu*ima + acu*ime;
					var mb:Number = abu*imb + acu*imf;
					var mc:Number = abu*imc + acu*img;
					var md:Number = abu*imd + acu*imh + nau;
					var me:Number = abv*ima + acv*ime;
					var mf:Number = abv*imb + acv*imf;
					var mg:Number = abv*imc + acv*img;
					var mh:Number = abv*imd + acv*imh + nav;
					// UV
					res.uv = new Point(ma*point.x + mb*point.y + mc*point.z + md, me*point.x + mf*point.y + mg*point.z + mh);
				}

				return res;
			} else {
				return null;
			}
		}

		/**
		 * @private
		 */
		alternativa3d function getVertexBuffer(attribute:int):VertexBuffer3D {
			if (attribute < _attributesStreams.length) {
				var stream:VertexStream = _attributesStreams[attribute];
				return stream != null ? stream.buffer : null;
			} else {
				return null;
			}
		}

		/**
		 * @private
		 */
		alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			var vBuffer:VertexStream = (VertexAttributes.POSITION < _attributesStreams.length) ? _attributesStreams[VertexAttributes.POSITION] : null;
			if (vBuffer == null) {
				throw new Error("Cannot calculate BoundBox without data.");
			}
			var offset:int = _attributesOffsets[VertexAttributes.POSITION];
			var numMappings:int = vBuffer.attributes.length;
			var data:ByteArray = vBuffer.data;

			for (var i:int = 0; i < _numVertices; i++) {
				data.position = 4*(numMappings*i + offset);
				var vx:Number = data.readFloat();
				var vy:Number = data.readFloat();
				var vz:Number = data.readFloat();
				var x:Number, y:Number, z:Number;
				if (transform != null) {
					x = transform.a*vx + transform.b*vy + transform.c*vz + transform.d;
					y = transform.e*vx + transform.f*vy + transform.g*vz + transform.h;
					z = transform.i*vx + transform.j*vy + transform.k*vz + transform.l;
				} else {
					x = vx;
					y = vy;
					z = vz;
				}
				if (x < boundBox.minX) boundBox.minX = x;
				if (x > boundBox.maxX) boundBox.maxX = x;
				if (y < boundBox.minY) boundBox.minY = y;
				if (y > boundBox.maxY) boundBox.maxY = y;
				if (z < boundBox.minZ) boundBox.minZ = z;
				if (z > boundBox.maxZ) boundBox.maxZ = z;
			}
		}

	}
}
