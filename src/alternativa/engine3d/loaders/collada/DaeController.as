/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.*;
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.resources.Geometry;

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	use namespace collada;
	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DaeController extends DaeElement {

		private var jointsBindMatrices:Vector.<Vector.<Number> >;
		private var vcounts:Array;
		private var indices:Array;
		private var jointsInput:DaeInput;
		private var weightsInput:DaeInput;
		private var inputsStride:int;
		private var geometry:Geometry;
		private var primitives:Vector.<DaePrimitive>;
		private var maxJointsPerVertex:int = 0;
		private var bindShapeMatrix:Vector.<Number>;

		public function DaeController(data:XML, document:DaeDocument) {
			super(data, document);

			// sources creates inside the DaeDocument. It should not be here.
		}

		private function get daeGeometry():DaeGeometry {
			var geom:DaeGeometry = document.findGeometry(data.skin.@source[0]);
			if (geom == null) {
				document.logger.logNotFoundError(data.@source[0]);
			}
			return geom;
		}

		override protected function parseImplementation():Boolean {
			var vertexWeightsXML:XML = this.data.skin.vertex_weights[0];
			if (vertexWeightsXML == null) {
				return false;
			}
			var vcountsXML:XML = vertexWeightsXML.vcount[0];
			if (vcountsXML == null) {
				return false;
			}
			vcounts = parseIntsArray(vcountsXML);
			var indicesXML:XML = vertexWeightsXML.v[0];
			if (indicesXML == null) {
				return false;
			}
			indices = parseIntsArray(indicesXML);
			parseInputs();
			parseJointsBindMatrices();
			var i:int, j:int;
			for (i = 0; i < vcounts.length; i++) {
				var count:int = vcounts[i];
				if (maxJointsPerVertex < count) maxJointsPerVertex = count;
			}

			var geom:DaeGeometry = this.daeGeometry;
			bindShapeMatrix = getBindShapeMatrix();
			if (geom != null) {
				geom.parse();
				var vertices:Vector.<DaeVertex> = geom.geometryVertices;
				var source:Geometry = geom.geometry;
				var localMaxJointsPerVertex:int = (maxJointsPerVertex%2 != 0) ? maxJointsPerVertex + 1 : maxJointsPerVertex;

				// Create geometry
				this.geometry = new Geometry();
				this.geometry._indices = source._indices.slice();
				var attributes:Array = source.getVertexStreamAttributes(0);
				var numSourceAttributes:int = attributes.length;

				var index:int = numSourceAttributes;
				for (i = 0; i < localMaxJointsPerVertex; i += 2) {
					var attribute:int = VertexAttributes.JOINTS[int(i/2)];
					attributes[int(index++)] = attribute;
					attributes[int(index++)] = attribute;
					attributes[int(index++)] = attribute;
					attributes[int(index++)] = attribute;
				}

				var numMappings:int = attributes.length;

				var sourceData:ByteArray = source._vertexStreams[0].data;
				var data:ByteArray = new ByteArray();
				data.endian = Endian.LITTLE_ENDIAN;
				data.length = 4*numMappings*source._numVertices;
				// Copy source data
				sourceData.position = 0;
				for (i = 0; i < source._numVertices; i++) {
					data.position = 4*numMappings*i;
					for (j = 0; j < numSourceAttributes; j++) {
						data.writeFloat(sourceData.readFloat());
					}
				}

				// Copy weights and joints
				var byteArray:ByteArray = createVertexBuffer(vertices, localMaxJointsPerVertex);
				byteArray.position = 0;
				for (i = 0; i < source._numVertices; i++) {
					data.position = 4*(numMappings*i + numSourceAttributes);
					for (j = 0; j < localMaxJointsPerVertex; j++) {
						data.writeFloat(byteArray.readFloat());
						data.writeFloat(byteArray.readFloat());
					}
				}

				this.geometry.addVertexStream(attributes);
				this.geometry._vertexStreams[0].data = data;
				this.geometry._numVertices = source._numVertices;
				transformVertices(this.geometry);
				primitives = geom.primitives;
			}
			return true;
		}

		private function transformVertices(geometry:Geometry):void {
			var data:ByteArray = geometry._vertexStreams[0].data;
			var numMappings:int = geometry._vertexStreams[0].attributes.length;

			// TODO: Normalize normal and tangent after transformation
			// TODO: Transform normal with transpose inverted matrix
			var normalOffset:int = (geometry.hasAttribute(VertexAttributes.NORMAL))?geometry.getAttributeOffset(VertexAttributes.NORMAL):-1;
			var tangentOffset:int = (geometry.hasAttribute(VertexAttributes.TANGENT4))?geometry.getAttributeOffset(VertexAttributes.TANGENT4):-1;

			for (var i:int = 0; i < geometry._numVertices; i++) {
				data.position = 4*numMappings*i;
				var x:Number = data.readFloat();
				var y:Number = data.readFloat();
				var z:Number = data.readFloat();
				data.position -= 12;
				data.writeFloat(x*bindShapeMatrix[0] + y*bindShapeMatrix[1] + z*bindShapeMatrix[2] + bindShapeMatrix[3]);
				data.writeFloat(x*bindShapeMatrix[4] + y*bindShapeMatrix[5] + z*bindShapeMatrix[6] + bindShapeMatrix[7]);
				data.writeFloat(x*bindShapeMatrix[8] + y*bindShapeMatrix[9] + z*bindShapeMatrix[10] + bindShapeMatrix[11]);

				var tmpX:Number;
				var tmpY:Number;
				var tmpZ:Number;
				var tmpLen:Number;

				if (normalOffset>=0){
					data.position = 4*(numMappings*i + normalOffset);
					var normalX:Number = data.readFloat();
					var normalY:Number = data.readFloat();
					var normalZ:Number = data.readFloat();

					tmpX = normalX*bindShapeMatrix[0] + normalY*bindShapeMatrix[1] + normalZ*bindShapeMatrix[2];
					tmpY = normalX*bindShapeMatrix[4] + normalY*bindShapeMatrix[5] + normalZ*bindShapeMatrix[6];
					tmpZ = normalX*bindShapeMatrix[8] + normalY*bindShapeMatrix[9] + normalZ*bindShapeMatrix[10];
					tmpLen = Math.sqrt(tmpX*tmpX + tmpY*tmpY + tmpZ*tmpZ);

					data.position -= 12;
					data.writeFloat((tmpLen > 0.0001) ? tmpX/tmpLen : 0);
					data.writeFloat((tmpLen > 0.0001) ? tmpY/tmpLen : 0);
					data.writeFloat((tmpLen > 0.0001) ? tmpZ/tmpLen : 1);
				}

				if (tangentOffset>=0){
					data.position = 4*(numMappings*i + tangentOffset);
					var tangentX:Number = data.readFloat();
					var tangentY:Number = data.readFloat();
					var tangentZ:Number = data.readFloat();
					var tangentW:Number = data.readFloat();

					tmpX = tangentX*bindShapeMatrix[0] + tangentY*bindShapeMatrix[1] + tangentZ*bindShapeMatrix[2];
					tmpY = tangentX*bindShapeMatrix[4] + tangentY*bindShapeMatrix[5] + tangentZ*bindShapeMatrix[6];
					tmpZ = tangentX*bindShapeMatrix[8] + tangentY*bindShapeMatrix[9] + tangentZ*bindShapeMatrix[10];
					tmpLen = Math.sqrt(tmpX*tmpX + tmpY*tmpY + tmpZ*tmpZ);

					data.position -= 16;
					data.writeFloat((tmpLen > 0.0001) ? tmpX/tmpLen : 0);
					data.writeFloat((tmpLen > 0.0001) ? tmpY/tmpLen : 0);
					data.writeFloat((tmpLen > 0.0001) ? tmpZ/tmpLen : 1);
					data.writeFloat((tangentW < 0) ? -1 : 1);
				}
			}
		}

		private function createVertexBuffer(vertices:Vector.<DaeVertex>, localMaxJointsPerVertex:int):ByteArray {
			var jointsOffset:int = jointsInput.offset;
			var weightsOffset:int = weightsInput.offset;
			var weightsSource:DaeSource = weightsInput.prepareSource(1);
			var weights:Vector.<Number> = weightsSource.numbers;
			var weightsStride:int = weightsSource.stride;
			var i:int, count:int;
			var verticesDict:Dictionary = new Dictionary();
			var byteArray:ByteArray = new ByteArray();
			// Reserve required number of bytes
			byteArray.length = vertices.length*localMaxJointsPerVertex*8;
			byteArray.endian = Endian.LITTLE_ENDIAN;

			for (i = 0,count = vertices.length; i < count; i++) {
				var vertex:DaeVertex = vertices[i];
				if (vertex == null) continue;
				var vec:Vector.<uint> = verticesDict[vertex.vertexInIndex];
				if (vec == null) {
					vec = verticesDict[vertex.vertexInIndex] = new Vector.<uint>();
				}
				vec.push(vertex.vertexOutIndex);
			}

			var vertexIndex:int = 0;
			var vertexOutIndices:Vector.<uint>;
			for (i = 0,count = vcounts.length; i < count; i++) {
				var jointsPerVertex:int = vcounts[i];
				vertexOutIndices = verticesDict[i];
				for (var j:int = 0; j < vertexOutIndices.length; j++) {
					byteArray.position = vertexOutIndices[j]*localMaxJointsPerVertex*8;
					// Loop on joints
					for (var k:int = 0; k < jointsPerVertex; k++) {
						var index:int = inputsStride*(vertexIndex + k);
						var jointIndex:int = indices[int(index + jointsOffset)];
						if (jointIndex >= 0) {
							// Save joint index, multiplied  with three
							byteArray.writeFloat(jointIndex*3);
							var weightIndex:int = indices[int(index + weightsOffset)];
							byteArray.writeFloat(weights[int(weightsStride*weightIndex)]);
						} else {
							byteArray.position += 8;
						}
					}
				}
				vertexIndex += jointsPerVertex;
			}
			byteArray.position = 0;
			return byteArray;
		}

		private function parseInputs():void {
			var inputsList:XMLList = data.skin.vertex_weights.input;
			var maxInputOffset:int = 0;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "JOINT" :
							if (jointsInput == null) {
								jointsInput = input;
							}
							break;
						case "WEIGHT" :
							if (weightsInput == null) {
								weightsInput = input;
							}
							break;
					}
				}
				var offset:int = input.offset;
				maxInputOffset = (offset > maxInputOffset) ? offset : maxInputOffset;
			}
			inputsStride = maxInputOffset + 1;
		}

		/**
		 * Parses inverse matrices for joints and saves them to a vector.
		 */
		private function parseJointsBindMatrices():void {
			var jointsXML:XML = data.skin.joints.input.(@semantic == "INV_BIND_MATRIX")[0];
			if (jointsXML != null) {
				var jointsSource:DaeSource = document.findSource(jointsXML.@source[0]);
				if (jointsSource != null) {
					if (jointsSource.parse() && jointsSource.numbers != null && jointsSource.stride >= 16) {
						var stride:int = jointsSource.stride;
						var count:int = jointsSource.numbers.length/stride;
						jointsBindMatrices = new Vector.<Vector.<Number> >(count);
						for (var i:int = 0; i < count; i++) {
							var index:int = stride*i;
							var matrix:Vector.<Number> = new Vector.<Number>(16);
							jointsBindMatrices[i] = matrix;
							for (var j:int = 0; j < 16; j++) {
								matrix[j] = jointsSource.numbers[int(index + j)];
							}
						}
					}
				} else {
					document.logger.logNotFoundError(jointsXML.@source[0]);
				}
			}
		}

		/**
		 * Returns geometry with the joints and controller for the joints.
		 * Call <code>parse()</code> before using.
		 */
		public function parseSkin(materials:Object, topmostJoints:Vector.<DaeNode>, skeletons:Vector.<DaeNode>):DaeObject {
			var skinXML:XML = data.skin[0];
			if (skinXML != null) {
				bindShapeMatrix = getBindShapeMatrix();
				var numJoints:int = jointsBindMatrices.length;
				var skin:Skin = new Skin(maxJointsPerVertex);
				skin.geometry = this.geometry;
				var joints:Vector.<DaeObject> = addJointsToSkin(skin, topmostJoints, findNodes(skeletons));
				setJointsBindMatrices(joints);

				skin.renderedJoints = collectRenderedJoints(joints, numJoints);

				if (primitives != null) {
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
						skin.addSurface(material, p.indexBegin, p.numTriangles);
					}
				}
				skin.calculateBoundBox();
				return new DaeObject(skin, mergeJointsClips(skin, joints));
			}
			return null;
		}

		private function collectRenderedJoints(joints:Vector.<DaeObject>, numJoints:int):Vector.<Joint> {
			var result:Vector.<Joint> = new Vector.<Joint>();
			for (var i:int = 0; i < numJoints; i++) {
				result[i] = Joint(joints[i].object);
			}
			return result;
		}

		/**
		 * Unites animations of joints into the  single animation, if required.
		 */
		private function mergeJointsClips(skin:Skin, joints:Vector.<DaeObject>):AnimationClip {
			if (!hasJointsAnimation(joints)) {
				return null;
			}
			var result:AnimationClip = new AnimationClip();
			var resultObjects:Array = [skin];
			for (var i:int = 0, count:int = joints.length; i < count; i++) {
				var animatedObject:DaeObject = joints[i];
				var clip:AnimationClip = animatedObject.animation;
				if (clip != null) {
					for (var t:int = 0; t < clip.numTracks; t++) {
						result.addTrack(clip.getTrackAt(t));
					}
				} else {
					// Creates empty track for the joint.
					result.addTrack(animatedObject.jointNode.createStaticTransformTrack());
				}
				var object:Object3D = animatedObject.object;
				object.name = animatedObject.jointNode.animName;
				resultObjects.push(object);
			}
			result._objects = resultObjects;
			return result;
		}

		private function hasJointsAnimation(joints:Vector.<DaeObject>):Boolean {
			for (var i:int = 0, count:int = joints.length; i < count; i++) {
				var object:DaeObject = joints[i];
				if (object.animation != null) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Set inverse matrices to joints.
		 */
		private function setJointsBindMatrices(animatedJoints:Vector.<DaeObject>):void {
			for (var i:int = 0, count:int = jointsBindMatrices.length; i < count; i++) {
				var animatedJoint:DaeObject = animatedJoints[i];
				var bindMatrix:Vector.<Number> = jointsBindMatrices[i];
//				bindMatrix[3]; //*= document.unitScaleFactor;
//				bindMatrix[7];// *= document.unitScaleFactor;
//				bindMatrix[11];// *= document.unitScaleFactor;
				Joint(animatedJoint.object).setBindPoseMatrix(bindMatrix);
			}
		}

		/**
		 * Creates a hierarchy of joints and adds them to skin.
		 * @return vector of joints with animation, which was added to skin.
		 * If you have added the auxiliary joint, then length of vector will differ from length of nodes vector.
		 */
		private function addJointsToSkin(skin:Skin, topmostJoints:Vector.<DaeNode>, nodes:Vector.<DaeNode>):Vector.<DaeObject> {
			// Dictionary, in which key is  a node and value is a position in nodes vector
			var nodesDictionary:Dictionary = new Dictionary();
			var count:int = nodes.length;
			var i:int;
			for (i = 0; i < count; i++) {
				nodesDictionary[nodes[i]] = i;
			}
			var animatedJoints:Vector.<DaeObject> = new Vector.<DaeObject>(count);
			var numTopmostJoints:int = topmostJoints.length;
			for (i = 0; i < numTopmostJoints; i++) {
				var topmostJoint:DaeNode = topmostJoints[i];
				var animatedJoint:DaeObject = addRootJointToSkin(skin, topmostJoint, animatedJoints, nodesDictionary);
				addJointChildren(Joint(animatedJoint.object), animatedJoints, topmostJoint, nodesDictionary);
			}
			return animatedJoints;
		}

		/**
		 * Adds root joint to skin.
		 */
		private function addRootJointToSkin(skin:Skin, node:DaeNode, animatedJoints:Vector.<DaeObject>, nodes:Dictionary):DaeObject {
			var joint:Joint = new Joint();
			joint.name = cloneString(node.name);
			skin.addChild(joint);
			var animatedJoint:DaeObject = node.applyAnimation(node.applyTransformations(joint));
			animatedJoint.jointNode = node;
			if (node in nodes) {
				animatedJoints[nodes[node]] = animatedJoint;
			} else {
				// Add at the end
				animatedJoints.push(animatedJoint);
			}
			return animatedJoint;
		}

		/**
		 * Creates a hierarchy of child joints and add them to parent joint.
		 * @param parent Parent joint.
		 * @param animatedJoints Vector of joints to which created joints will added.
		 * Auxiliary joints will be added to the end of the vector, if it's necessary.
		 * @param parentNode Node of parent joint
		 * @param nodes Dictionary.  Key is a node of joint. And  value is an index of joint in animatedJoints vector
		 */
		private function addJointChildren(parent:Joint, animatedJoints:Vector.<DaeObject>, parentNode:DaeNode, nodes:Dictionary):void {
			var object:DaeObject;
			var children:Vector.<DaeNode> = parentNode.nodes;
			for (var i:int = 0, count:int = children.length; i < count; i++) {
				var child:DaeNode = children[i];
				var joint:Joint;
				if (child in nodes) {
					joint = new Joint();
					joint.name = cloneString(child.name);
					object = child.applyAnimation(child.applyTransformations(joint));
					object.jointNode = child;
					animatedJoints[nodes[child]] = object;
					parent.addChild(joint);
					addJointChildren(joint, animatedJoints, child, nodes);
				} else {
					// If node is not a joint
					if (hasJointInDescendants(child, nodes)) {
						// If one of the children is a joint,  there is need to create auxiliary joint instead of this node.
						joint = new Joint();
						joint.name = cloneString(child.name);
						object = child.applyAnimation(child.applyTransformations(joint));
						object.jointNode = child;
						// Add new joint to the end
						animatedJoints.push(object);
						parent.addChild(joint);
						addJointChildren(joint, animatedJoints, child, nodes);
					}
				}
			}
		}

		private function hasJointInDescendants(parentNode:DaeNode, nodes:Dictionary):Boolean {
			var children:Vector.<DaeNode> = parentNode.nodes;
			for (var i:int = 0, count:int = children.length; i < count; i++) {
				var child:DaeNode = children[i];
				if (child in nodes || hasJointInDescendants(child, nodes)) {
					return true;
				}
			}
			return false;
		}

		/**
		 * Transforms all object vertices with the BindShapeMatrix from collada.
		 */
		private function getBindShapeMatrix():Vector.<Number> {
			var matrixXML:XML = data.skin.bind_shape_matrix[0];
			var res:Vector.<Number> = new Vector.<Number>(16, true);
			if (matrixXML != null) {
				var matrix:Array = parseStringArray(matrixXML);
				for (var i:int = 0; i < matrix.length; i++) {
					res[i] = Number(matrix[i]);
				}
			}
			return res;
		}

		/**
		 * Returns <code>true</code> if joint hasn't parent joint.
		 * @param node Joint node
		 * @param nodes Dictionary. It items are the nodes keys.
		 */
		private function isRootJointNode(node:DaeNode, nodes:Dictionary):Boolean {
			for (var parent:DaeNode = node.parent; parent != null; parent = parent.parent) {
				if (parent in nodes) {
					return false;
				}
			}
			return true;
		}

		public function findRootJointNodes(skeletons:Vector.<DaeNode>):Vector.<DaeNode> {
			var nodes:Vector.<DaeNode> = findNodes(skeletons);
			var i:int = 0;
			var count:int = nodes.length;
			if (count > 0) {
				var nodesDictionary:Dictionary = new Dictionary();
				for (i = 0; i < count; i++) {
					nodesDictionary[nodes[i]] = i;
				}
				var rootNodes:Vector.<DaeNode> = new Vector.<DaeNode>();
				for (i = 0; i < count; i++) {
					var node:DaeNode = nodes[i];
					if (isRootJointNode(node, nodesDictionary)) {
						rootNodes.push(node);
					}
				}
				return rootNodes;
			}
			return null;
		}

		/**
		 * Find node by Sid on sceletons vector.
		 */
		private function findNode(nodeName:String, skeletons:Vector.<DaeNode>):DaeNode {
			var count:int = skeletons.length;
			for (var i:int = 0; i < count; i++) {
				var node:DaeNode = skeletons[i].getNodeBySid(nodeName);
				if (node != null) {
					return node;
				}
			}
			return null;
		}

		/**
		 * Returns the vector of joint nodes.
		 */
		private function findNodes(skeletons:Vector.<DaeNode>):Vector.<DaeNode> {
			var jointsXML:XML = data.skin.joints.input.(@semantic == "JOINT")[0];
			if (jointsXML != null) {
				var jointsSource:DaeSource = document.findSource(jointsXML.@source[0]);
				if (jointsSource != null) {
					if (jointsSource.parse() && jointsSource.names != null) {
						var stride:int = jointsSource.stride;
						var count:int = jointsSource.names.length/stride;
						var nodes:Vector.<DaeNode> = new Vector.<DaeNode>(count);
						for (var i:int = 0; i < count; i++) {
							var node:DaeNode = findNode(jointsSource.names[int(stride*i)], skeletons);
							if (node == null) {
								// Error: no node.
							}
							nodes[i] = node;
						}
						return nodes;
					}
				} else {
					document.logger.logNotFoundError(jointsXML.@source[0]);
				}
			}
			return null;
		}

	}
}
