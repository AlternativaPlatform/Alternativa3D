/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;

	/**
	 * @private
	 */
	public class DaeGeometry extends DaeElement {
	
		use namespace collada;
		use namespace alternativa3d;

		internal var geometryVertices:Vector.<DaeVertex>;
		public var primitives:Vector.<DaePrimitive>;
		internal var geometry:Geometry;
		
		private var vertices:DaeVertices;

		public function DaeGeometry(data:XML, document:DaeDocument) {
			super(data, document);

			/**
			* Items sources, vertices are declared in the <geometry>.
			* You should create sources in DaeDocument, not here.
			*/
			constructVertices();
		}

		private function constructVertices():void {
			var verticesXML:XML = data.mesh.vertices[0];
			if (verticesXML != null) {
				vertices = new DaeVertices(verticesXML, document);
				document.vertices[vertices.id] = vertices;
				// set primitives early for ParserCollada's parseAsync
				parsePrimitives();
			}
		}

		override protected function parseImplementation():Boolean {
			if (vertices != null) {

				vertices.parse();
				var numVertices:int = vertices.positions.numbers.length/vertices.positions.stride;
				geometry = new Geometry();
				geometryVertices = new Vector.<DaeVertex>(numVertices);
				var i:int;
				var p:DaePrimitive;
				var channels:uint = 0;
				for (i = 0; i < primitives.length; i++) {
					p = primitives[i];
					p.parse();
					if (p.verticesEquals(vertices)) {
						numVertices = geometryVertices.length;
						channels |= p.fillGeometry(geometry, geometryVertices);
					} else {
						// Error, Vertices of another geometry can not be used
					}
				}
				
				var attributes:Array = new Array(3);
				attributes[0] = VertexAttributes.POSITION;
				attributes[1] = VertexAttributes.POSITION;
				attributes[2] = VertexAttributes.POSITION;
				var index:int = 3;
				if (channels & DaePrimitive.NORMALS) {
					attributes[index++] = VertexAttributes.NORMAL;
					attributes[index++] = VertexAttributes.NORMAL;
					attributes[index++] = VertexAttributes.NORMAL;
				}
				if (channels & DaePrimitive.TANGENT4) {
					attributes[index++] = VertexAttributes.TANGENT4;
					attributes[index++] = VertexAttributes.TANGENT4;
					attributes[index++] = VertexAttributes.TANGENT4;
					attributes[index++] = VertexAttributes.TANGENT4;
				}
				for (i = 0; i < 8; i++) {
					if (channels & DaePrimitive.TEXCOORDS[i]) {
						attributes[index++] = VertexAttributes.TEXCOORDS[i];
						attributes[index++] = VertexAttributes.TEXCOORDS[i];
					}
				}

				geometry.addVertexStream(attributes);

				numVertices = geometryVertices.length;
				geometry._numVertices = numVertices;
				
				var attributeValues:Array = [];

				for (i = 0; i < numVertices; i++) {
					var vertex:DaeVertex = geometryVertices[i];
					if (vertex != null) {
						var values:Vector.<Number> = attributeValues[VertexAttributes.POSITION];
						if(!values) values = attributeValues[VertexAttributes.POSITION] = new Vector.<Number>(numVertices*VertexAttributes.STRIDES[VertexAttributes.POSITION]);
						values[i*3] = vertex.x;
						values[i*3+1] = vertex.y;
						values[i*3+2] = vertex.z;
						if (vertex.normal != null) {
							values = attributeValues[VertexAttributes.NORMAL];
							if(!values) values = attributeValues[VertexAttributes.NORMAL] = new Vector.<Number>(numVertices*VertexAttributes.STRIDES[VertexAttributes.NORMAL]);
							values[i*3] = vertex.normal.x;
							values[i*3+1] = vertex.normal.y;
							values[i*3+2] = vertex.normal.z;
						}
						if (vertex.tangent != null) {
							values = attributeValues[VertexAttributes.TANGENT4];
							if(!values) values = attributeValues[VertexAttributes.TANGENT4] = new Vector.<Number>(numVertices*VertexAttributes.STRIDES[VertexAttributes.TANGENT4]);
							values[i*4] = vertex.tangent.x;
							values[i*4+1] = vertex.tangent.y;
							values[i*4+2] = vertex.tangent.z;
							values[i*4+3] = vertex.tangent.w;
						}
						var texCoords:uint = 0;
						for (var j:int = 0; j < vertex.uvs.length; j+=2) {
							values = attributeValues[VertexAttributes.TEXCOORDS[texCoords]];
							if(!values) values = attributeValues[VertexAttributes.TEXCOORDS[texCoords]] = new Vector.<Number>(numVertices*VertexAttributes.STRIDES[VertexAttributes.TEXCOORDS[texCoords]]);
							values[i*2] = vertex.uvs[j];
							values[i*2+1] = vertex.uvs[j+1];
							texCoords++;
						}
					}
				}
				
				var attributeValuesLength:uint = attributeValues.length;
				for(i = 0; i<attributeValuesLength; i++) {
					var data:Vector.<Number> = attributeValues[i];
					if(data) {
						geometry.setAttributeValues(i, data);
					}
				}
				
				return true;
			}
			return false;
		}

		private function parsePrimitives():void {
			primitives = new Vector.<DaePrimitive>();
			var children:XMLList = data.mesh.children();

			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				switch (child.localName()) {
					case "polygons":
					case "polylist":
					case "triangles":
					case "trifans":
					case "tristrips":
						var p:DaePrimitive = new DaePrimitive(child, document);
						primitives.push(p);
						break;
				}
			}
		}

		/**
		 * Creates geometry and returns it as mesh.
		 * Call <code>parse()</code> before using.
		 * @param materials Dictionary of materials
		 */
		public function parseMesh(materials:Object):Mesh {
			if (data.mesh.length() > 0) {
				var mesh:Mesh = new Mesh();
				mesh.geometry = geometry;
				for (var i:int = 0; i < primitives.length; i++) {
					var p:DaePrimitive = primitives[i];
					var instanceMaterial:DaeInstanceMaterial = materials[p.materialSymbol];
					var material:ParserMaterial;
					if (instanceMaterial != null) {
						var daeMaterial:DaeMaterial = instanceMaterial.material;
						if (daeMaterial != null) {
							daeMaterial.parse();
							material = daeMaterial.material;
							daeMaterial.used = true;
						}
					}
					mesh.addSurface(material, p.indexBegin, p.numTriangles);
				}
				mesh.calculateBoundBox();
				return mesh;
			}
			return null;
		}
	}
}
