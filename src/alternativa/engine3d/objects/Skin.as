/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.VertexStream;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.resources.Geometry;

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * Skin is a <code>Mesh</code> which can have a skeleton besides surfaces. The skeleton is a hierarchy of bones, represented by <code>Joint</code> class.
	 * Each bone can be linked with set of vertices, thus, position of the bone will affect to position of linked vertices. Set of  positions of all skeleton bones
	 * defines a pose which also defines pose of skin's surfaces. Character animation implements through making sequence of such poses.
	 * If number of bones which affect one surface more than fixed number, skin would not be drawn.
	 * "Fixed number" defines by the material of given surface, look documentation of the material class for it.
	 * To avoid this problem use <code>Skin.divide()</code> method.
	 *
	 * If you creates a skeleton within a code, make sure that each bone added to:
	 * 1) skin hierarchy with <code>addChild()</code> method,
	 * 2) <code>renderedJoints</code> property which represented by  <code>Vector.&lt;Joint&gt;.</code>
	 *
	 *   Link of a vertex and a bone stores in vertex data of <code>VertexAttributes.JOINTS</code> type.
	 *   Vertex buffer point to a joint with following form: index of the joint within  <code>renderedJoints</code> multiplied with 3.
	 *   It is done so in order to avoid this multiplication within vertex shader for each frame.
	 *
	 *  @see alternativa.engine3d.core.VertexAttributes#JOINTS
     *  @see alternativa.engine3d.objects.Joint
	 *  @see #divide()
	 */
	public class Skin extends Mesh {

		/**
		 * @private
		 */
		alternativa3d var _renderedJoints:Vector.<Joint>;

		/**
		 * @private
		 */
		alternativa3d var surfaceJoints:Vector.<Vector.<Joint>>;

		/**
		 * @private 
		 */
		alternativa3d var surfaceTransformProcedures:Vector.<Procedure>;

		/**
		 * @private 
		 */
		alternativa3d var surfaceDeltaTransformProcedures:Vector.<Procedure>;

		/**
		 * @private
		 */
		alternativa3d var maxInfluences:int = 0;

		// key = maxInfluences | numJoints << 16
		private static var _transformProcedures:Dictionary = new Dictionary();
		// Cashing of procedures on number of influence
		private static var _deltaTransformProcedures:Vector.<Procedure> = new Vector.<Procedure>(9);

		/**
		 * Creates a new Skin instance.
		 * @param maxInfluences  Max number of bones that can affect one vertex.
		 */
		public function Skin(maxInfluences:int) {
			this.maxInfluences = maxInfluences;

			surfaceJoints = new Vector.<Vector.<Joint>>();
			surfaceTransformProcedures = new Vector.<Procedure>();
			surfaceDeltaTransformProcedures = new Vector.<Procedure>();
		}

		public function calculateBindingMatrices():void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				var joint:Joint = child as Joint;
				if (joint != null) {
					if (joint.transformChanged) {
						joint.composeTransforms();
					}
					joint.bindPoseTransform.copy(joint.inverseTransform);
					joint.calculateBindingMatrices();
				}
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function addSurface(material:Material, indexBegin:uint, numTriangles:uint):Surface {
			surfaceJoints[_surfacesLength] = _renderedJoints;
			surfaceTransformProcedures[_surfacesLength] = transformProcedure;
			surfaceDeltaTransformProcedures[_surfacesLength] = deltaTransformProcedure;
			return super.addSurface(material, indexBegin, numTriangles);
		}

		private function divideSurface(limit:uint, iterations:uint, surface:Surface, jointsOffsets:Vector.<uint>, jointBufferVertexSize:uint, inVertices:ByteArray, outVertices:ByteArray, outIndices:Vector.<uint>, outSurfaces:Vector.<Surface>, outJointsMaps:Vector.<Dictionary>):uint {
			var indexBegin:uint = surface.indexBegin;
			var indexCount:uint = surface.numTriangles*3;
			var i:int, j:int, count:int, jointsLength:int, index:uint;
			var indices:Vector.<uint> = geometry._indices;
			var groups:Dictionary = new Dictionary();
			var group:Dictionary;

			var key:*, key2:*;
			var jointIndex:uint;
			var weight:Number;
			for (i = indexBegin,count = indexBegin + indexCount; i < count; i += 3) {
				group = groups[i] = new Dictionary();
				var jointsGroupLength:uint = 0;
				for (var n:int = 0; n < 3; n++) {
					index = indices[int(i + n)];
					for (j = 0,jointsLength = jointsOffsets.length; j < jointsLength; j++) {
						inVertices.position = jointBufferVertexSize*index + jointsOffsets[j];
						jointIndex = uint(inVertices.readFloat());
						weight = inVertices.readFloat();
						if (weight > 0) {
							group[jointIndex] = true;
						}
					}
				}
				for (key in group) {
					jointsGroupLength++;
				}
				if (jointsGroupLength > limit) {
					throw new Error("Unable to divide Skin.");
				}
			}
			var localNumJoints:uint;

			var facesGroups:Dictionary = optimizeGroups(groups, limit, iterations);
			var newIndex:uint = 0;
			var newIndexBegin:uint;
			for (key in facesGroups) {
				var faces:Dictionary = facesGroups[key];
				localNumJoints = 0;
				group = groups[key];
				for (key2 in group) {
					if (group[key2] is Boolean) {
						group[key2] = 3*localNumJoints++;
					}
				}
				var locatedIndices:Dictionary = new Dictionary();
				for (key2 in faces) {
					for (i = 0; i < 3; i++) {
						index = indices[int(key2 + i)];
						if (locatedIndices[index] != null) {
							outIndices.push(locatedIndices[index]);
							continue;
						}
						locatedIndices[index] = newIndex;
						outIndices.push(newIndex++);
						outVertices.writeBytes(inVertices, index*jointBufferVertexSize, jointBufferVertexSize);
						outVertices.position -= jointBufferVertexSize;
						var origin:uint = outVertices.position;
						var sumWeight:Number = 0;
						// reindexation of bones
						for (j = 0; j < jointsLength; j++) {
							outVertices.position = origin + jointsOffsets[j];
							jointIndex = uint(outVertices.readFloat());
							weight = outVertices.readFloat();
							outVertices.position -= 8;
							if (weight > 0) {
								outVertices.writeFloat(group[jointIndex]);
								outVertices.writeFloat(weight);
								sumWeight += weight;
							}
						}
						// normalization of weights
						if (sumWeight != 1) {
							for (j = 0; j < jointsLength; j++) {
								outVertices.position = origin + jointsOffsets[j] + 4;
								weight = outVertices.readFloat();
								if (weight > 0) {
									outVertices.position -= 4;
									outVertices.writeFloat(weight/sumWeight);
								}
							}
						}
						outVertices.position = origin + jointBufferVertexSize;
					}
				}
				var resSurface:Surface = new Surface();
				resSurface.object = this;
				resSurface.material = surface.material;
				resSurface.indexBegin = newIndexBegin;
				resSurface.numTriangles = (outIndices.length - newIndexBegin)/3;
				outSurfaces.push(resSurface);
				outJointsMaps.push(group);
				newIndexBegin = outIndices.length;
			}
			return newIndex;
		}

		/**
		 * Union of  groups.
		 * @groups Set of groups for merging.
		 * @limit  Max number of joints per group.
		 * @iterations Number of algorythm iteration (more iterations - better result).
		 */
		private function optimizeGroups(groups:Dictionary, limit:uint, iterations:uint = 1):Dictionary {
			var key:*;
			var inKey:*;
			var facesGroups:Dictionary = new Dictionary();
			for (var i:int = 1; i < iterations + 1; i++) {
				var minLike:Number = 1 - i/iterations;
				for (key in groups) {
					var group1:Dictionary = groups[key];
					for (inKey in groups) {
						if (key == inKey) continue;
						var group2:Dictionary = groups[inKey];
						var like:Number = calculateLikeFactor(group1, group2, limit);
						if (like >= minLike) {
							delete groups[inKey];
							for (var copyKey:* in group2) {
								group1[copyKey] = true;
							}
							var indices:Dictionary = facesGroups[key];
							if (indices == null) {
								indices = facesGroups[key] = new Dictionary();
								indices[key] = true;
							}

							var indices2:Dictionary = facesGroups[inKey];
							if (indices2 != null) {
								delete facesGroups[inKey];
								for (copyKey in indices2) {
									indices[copyKey] = true;
								}
							} else {
								indices[inKey] = true;
							}
						}
					}
				}
			}
			return facesGroups;
		}

		// Calculates "level of similarity"   of two groups
		private function calculateLikeFactor(group1:Dictionary, group2:Dictionary, limit:uint):Number {
			var key:*;
			var unionCount:uint;
			var intersectCount:uint;
			var group1Count:uint;
			var group2Count:uint;
			for (key in group1) {
				unionCount++;
				if (group2[key] != null) {
					intersectCount++;
				}
				group1Count++;
			}
			for (key in group2) {
				if (group1[key] == null) {
					unionCount++
				}
				group2Count++;
			}
			if (unionCount > limit) return -1;
			return intersectCount/unionCount;
		}

		/**
		 * Subdivides skin surfaces. It can be useful in case of impossibility to render a skin due to too big number of bones affected to one surface. (In this case appropriate exception will generated).
		 * @param limit No more than <code>limit</code> of bones can have its own surface. I.e. if skin instance has 6 joints and <code>limit = 3</code>,
		 * it will divided into 2 surface and if <code>limit = 6</code> - into 6 surfaces.
		 * @param iterations Number of iterations. Increase accuracy and execution time.
		 */
		public function divide(limit:uint, iterations:uint = 1):void {
			if (_renderedJoints == null || maxInfluences <= 0) return;
			// Checking: are all joints at one vertex-buffer?
			var jointsBuffer:int = geometry.findVertexStreamByAttribute(VertexAttributes.JOINTS[0]);
			var jointsOffsets:Vector.<uint> = new Vector.<uint>();
			var jointOffset:int = 0;
			if (jointsBuffer >= 0) {
				jointOffset = geometry.getAttributeOffset(VertexAttributes.JOINTS[0])*4;
				jointsOffsets.push(jointOffset);
				jointsOffsets.push(jointOffset + 8);
			} else {
				throw new Error("Cannot divide skin, joints[0] must be binded");
			}
			var jbTest:int = geometry.findVertexStreamByAttribute(VertexAttributes.JOINTS[1]);
			if (jbTest >= 0) {
				jointOffset = geometry.getAttributeOffset(VertexAttributes.JOINTS[1])*4;
				jointsOffsets.push(jointOffset);
				jointsOffsets.push(jointOffset + 8);
				if (jointsBuffer != jbTest) {
					throw new Error("Cannot divide skin, all joinst must be in the same buffer");
				}
			}

			jbTest = geometry.findVertexStreamByAttribute(VertexAttributes.JOINTS[2]);

			if (jbTest >= 0) {
				jointOffset = geometry.getAttributeOffset(VertexAttributes.JOINTS[2])*4;
				jointsOffsets.push(jointOffset);
				jointsOffsets.push(jointOffset + 8);
				if (jointsBuffer != jbTest) {
					throw new Error("Cannot divide skin, all joinst must be in the same buffer");
				}
			}

			jbTest = geometry.findVertexStreamByAttribute(VertexAttributes.JOINTS[3]);

			if (jbTest >= 0) {
				jointOffset = geometry.getAttributeOffset(VertexAttributes.JOINTS[3])*4;
				jointsOffsets.push(jointOffset);
				jointsOffsets.push(jointOffset + 8);
				if (jointsBuffer != jbTest) {
					throw new Error("Cannot divide skin, all joinst must be in the same buffer");
				}
			}
			var outSurfaces:Vector.<Surface> = new Vector.<Surface>();
			var totalVertices:ByteArray = new ByteArray();
			totalVertices.endian = Endian.LITTLE_ENDIAN;
			var totalIndices:Vector.<uint> = new Vector.<uint>();
			var totalIndicesLength:uint = 0;
			var lastMaxIndex:uint = 0;
			var key:*;
			var lastSurfaceIndex:uint = 0;
			var lastIndicesCount:uint = 0;
			surfaceJoints.length = 0;
			var jointsBufferNumMappings:int = geometry._vertexStreams[jointsBuffer].attributes.length;
			var jointsBufferData:ByteArray = geometry._vertexStreams[jointsBuffer].data;
			for (var i:int = 0; i < _surfacesLength; i++) {
				var outIndices:Vector.<uint> = new Vector.<uint>();
				var outVertices:ByteArray = new ByteArray();
				var outJointsMaps:Vector.<Dictionary> = new Vector.<Dictionary>();
				outVertices.endian = Endian.LITTLE_ENDIAN;
				var maxIndex:uint = divideSurface(limit, iterations, _surfaces[i], jointsOffsets,
					jointsBufferNumMappings*4, jointsBufferData, outVertices, outIndices, outSurfaces, outJointsMaps);
				for (var j:int = 0, count:int = outIndices.length; j < count; j++) {
					totalIndices[totalIndicesLength++] = lastMaxIndex + outIndices[j];
				}

				for (j = 0,count = outJointsMaps.length; j < count; j++) {
					var maxJoints:uint = 0;
					var vec:Vector.<Joint> = surfaceJoints[j + lastSurfaceIndex] = new Vector.<Joint>();
					var joints:Dictionary = outJointsMaps[j];
					for (key in joints) {
						var index:uint = uint(joints[key]/3);
						if (vec.length < index) vec.length = index + 1;
						vec[index] = _renderedJoints[uint(key/3)];
						maxJoints++;
					}
				}
				for (j = lastSurfaceIndex; j < outSurfaces.length; j++) {
					outSurfaces[j].indexBegin += lastIndicesCount;

				}
				lastSurfaceIndex += outJointsMaps.length;
				lastIndicesCount += outIndices.length;
				totalVertices.writeBytes(outVertices, 0, outVertices.length);
				lastMaxIndex += maxIndex;
			}
			_surfaces = outSurfaces;
			_surfacesLength = outSurfaces.length;
			surfaceTransformProcedures.length = _surfacesLength;
			surfaceDeltaTransformProcedures.length = _surfacesLength;
			calculateSurfacesProcedures();
			var newGeometry:Geometry = new Geometry();
			newGeometry._indices = totalIndices;
			
			for (i = 0; i < geometry._vertexStreams.length; i++) {
				var attributes:Array = geometry._vertexStreams[i].attributes;
				newGeometry.addVertexStream(attributes);
				if (i == jointsBuffer) {
					newGeometry._vertexStreams[i].data = totalVertices;
				} else {
					var data:ByteArray = new ByteArray();
					data.endian = Endian.LITTLE_ENDIAN;
					data.writeBytes(geometry._vertexStreams[i].data);
					newGeometry._vertexStreams[i].data = data;
				}
			}
			newGeometry._numVertices = totalVertices.length/(newGeometry._vertexStreams[0].attributes.length << 2);
			geometry = newGeometry;
		}

		/**
		 * @private
		 */
		alternativa3d function calculateJointsTransforms(root:Object3D):void {
			for (var child:Object3D = root.childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				// Write transformToSkin matrix to localToGlobalTransform property
				child.localToGlobalTransform.combine(root.localToGlobalTransform, child.transform);
				if (child is Joint) {
					Joint(child).calculateTransform();
				}
				calculateJointsTransforms(child);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				// Write transformToSkin matrix to localToGlobalTransform property
				child.localToGlobalTransform.copy(child.transform);
				if (child is Joint) {
					Joint(child).calculateTransform();
				}
				calculateJointsTransforms(child);
			}
			var vertexSurface:Dictionary = new Dictionary();
			var indices:Vector.<uint> = geometry._indices;
			// Fill the map vertex-surface
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				for (var j:int = surface.indexBegin, count:int = surface.indexBegin + surface.numTriangles*3; j < count; j++) {
					vertexSurface[indices[j]] = i;
				}
			}
			var joints:Vector.<Joint>;
			var positions:VertexStream = geometry._attributesStreams[VertexAttributes.POSITION];
			var positionOffset:int = geometry._attributesOffsets[VertexAttributes.POSITION]*4;
			var jointsStreams:Vector.<VertexStream> = new Vector.<VertexStream>();
			var jointsOffsets:Vector.<int> = new Vector.<int>();
			for (i = 0; i < 4; i++) {
				if (geometry.hasAttribute(VertexAttributes.JOINTS[i])) {
					jointsStreams.push(geometry._attributesStreams[VertexAttributes.JOINTS[i]]);
					jointsOffsets.push(geometry._attributesOffsets[VertexAttributes.JOINTS[i]]*4);
				}
			}
			var jointsStreamsLength:uint = jointsStreams.length;
			for (i = 0; i < geometry._numVertices; i++) {
				joints = surfaceJoints[vertexSurface[i]];
				var buffer:ByteArray = positions.data;
				buffer.position = positionOffset + i*positions.attributes.length*4;

				var x:Number = buffer.readFloat();
				var y:Number = buffer.readFloat();
				var z:Number = buffer.readFloat();
				var ox:Number = 0;
				var oy:Number = 0;
				var oz:Number = 0;
				var tx:Number, ty:Number, tz:Number;
				for (j = 0; j < jointsStreamsLength; j++) {
					buffer = jointsStreams[j].data;
					buffer.position = jointsOffsets[j] + i*jointsStreams[j].attributes.length*4;
					var jointIndex1:int = buffer.readFloat();
					var jointWeight1:Number = buffer.readFloat();
					var jointIndex2:int = buffer.readFloat();
					var jointWeight2:Number = buffer.readFloat();
					var joint:Joint;
					var trm:Transform3D;
					if (jointWeight1 > 0) {
						joint = joints[int(jointIndex1/3)];
						trm = joint.jointTransform;
						tx = x*trm.a + y*trm.b + z*trm.c + trm.d;
						ty = x*trm.e + y*trm.f + z*trm.g + trm.h;
						tz = x*trm.i + y*trm.j + z*trm.k + trm.l;
						ox += tx*jointWeight1;
						oy += ty*jointWeight1;
						oz += tz*jointWeight1;
					}
					if (jointWeight2 > 0) {
						joint = joints[int(jointIndex2/3)];
						trm = joint.jointTransform;
						tx = x*trm.a + y*trm.b + z*trm.c + trm.d;
						ty = x*trm.e + y*trm.f + z*trm.g + trm.h;
						tz = x*trm.i + y*trm.j + z*trm.k + trm.l;
						ox += tx*jointWeight2;
						oy += ty*jointWeight2;
						oz += tz*jointWeight2;
					}
				}

				if (transform != null) {
					tx = ox*transform.a + oy*transform.b + oz*transform.c + transform.d;
					ty = ox*transform.e + oy*transform.f + oz*transform.g + transform.h;
					tz = ox*transform.i + oy*transform.j + oz*transform.k + transform.l;
					ox = tx; oy = ty; oz = tz;
				}

				if (ox < boundBox.minX) {
					boundBox.minX = ox;
				}

				if (oy < boundBox.minY) {
					boundBox.minY = oy;
				}

				if (oz < boundBox.minZ) {
					boundBox.minZ = oz;
				}

				if (ox > boundBox.maxX) {
					boundBox.maxX = ox;
				}

				if (oy > boundBox.maxY) {
					boundBox.maxY = oy;
				}

				if (oz > boundBox.maxZ) {
					boundBox.maxZ = oz;
				}
			}
		}

		/**
		 * @private
		 */
		public function get renderedJoints():Vector.<Joint> {
			return _renderedJoints;
		}

		/**
		 * @private
		 */
		public function set renderedJoints(value:Vector.<Joint>):void {
			//If skin is not divided, change number of bonesfor each surface
			for (var i:int = 0; i < _surfacesLength; i++) {
				if (surfaceJoints[i] == _renderedJoints) {
					surfaceJoints[i] = value;
				}
			}
			_renderedJoints = value;

			calculateSurfacesProcedures();
		}

		/**
		 * @private
		 * Recalculate procedures of surface transformation with respect to number of bones and their influences.
		 */
		alternativa3d function calculateSurfacesProcedures():void {
			var numJoints:int = _renderedJoints != null ? _renderedJoints.length : 0;
			transformProcedure = calculateTransformProcedure(maxInfluences, numJoints);
			deltaTransformProcedure = calculateDeltaTransformProcedure(maxInfluences);
			for (var i:int = 0; i < _surfacesLength; i++) {
				numJoints = surfaceJoints[i] != null ? surfaceJoints[i].length : 0;
				surfaceTransformProcedures[i] = calculateTransformProcedure(maxInfluences, numJoints);
				surfaceDeltaTransformProcedures[i] = calculateDeltaTransformProcedure(maxInfluences);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			if (geometry == null) return;
			// Calculate joints matrices
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				// Write transformToSkin matrix to localToGlobalTransform property
				child.localToGlobalTransform.copy(child.transform);
				if (child is Joint) {
					Joint(child).calculateTransform();
				}
				calculateJointsTransforms(child);
			}

			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				transformProcedure = surfaceTransformProcedures[i];
				deltaTransformProcedure = surfaceDeltaTransformProcedures[i];
				if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow);

				/*var destination:DrawUnit = surface.getDrawUnit(camera, geometry, lights, lightsLength);
				if (destination == null) continue;
				camera.renderer.addDrawUnit(destination);
				setTransformConstants(destination, surface, destination.program.vertexShader, camera);*/
				// Mouse events
				if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
			}
		}

		/**
		 * @private 
		 */
		override alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			var i:int, count:int;
			for (i = 0; i < maxInfluences; i += 2) {
				var attribute:int = VertexAttributes.JOINTS[i >> 1];
				drawUnit.setVertexBufferAt(vertexShader.getVariableIndex("joint" + i.toString()), geometry.getVertexBuffer(attribute), geometry._attributesOffsets[attribute], VertexAttributes.FORMATS[attribute]);
			}
			var surfaceIndex:int = _surfaces.indexOf(surface);
			var joints:Vector.<Joint> = surfaceJoints[surfaceIndex];
			for (i = 0,count = joints.length; i < count; i++) {
				var joint:Joint = joints[i];
				drawUnit.setVertexConstantsFromTransform(i*3, joint.jointTransform);
			}
		}

		private function calculateTransformProcedure(maxInfluences:int, numJoints:int):Procedure {
			var res:Procedure = _transformProcedures[maxInfluences | (numJoints << 16)];
			if (res != null) return res;
			res = _transformProcedures[maxInfluences | (numJoints << 16)] = new Procedure(null, "SkinTransformProcedure");
			var array:Array = [];
			var j:int = 0;
			for (var i:int = 0; i < maxInfluences; i ++) {
				var joint:int = int(i/2);
				if (i%2 == 0) {
					if (i == 0) {
						array[j++] = "m34 t0.xyz, i0, c[a" + joint + ".x]";
						array[j++] = "mul o0, t0.xyz, a" + joint + ".y";
					} else {
						array[j++] = "m34 t0.xyz, i0, c[a" + joint + ".x]";
						array[j++] = "mul t0.xyz, t0.xyz, a" + joint + ".y";
						array[j++] = "add o0, o0, t0.xyz";
					}
				} else {
					array[j++] = "m34 t0.xyz, i0, c[a" + joint + ".z]";
					array[j++] = "mul t0.xyz, t0.xyz, a" + joint + ".w";
					array[j++] = "add o0, o0, t0.xyz";
				}
			}
			array[j++] = "mov o0.w, i0.w";
			res.compileFromArray(array);
			res.assignConstantsArray(numJoints*3);
			for (i = 0; i < maxInfluences; i += 2) {
				res.assignVariableName(VariableType.ATTRIBUTE, int(i/2), "joint" + i);
			}
			return res;
		}

		private function calculateDeltaTransformProcedure(maxInfluences:int):Procedure {
			var res:Procedure = _deltaTransformProcedures[maxInfluences];
			if (res != null) return res;
			res = new Procedure(null, "SkinDeltaTransformProcedure");
			_deltaTransformProcedures[maxInfluences] = res;
			var array:Array = [];
			var j:int = 0;
			for (var i:int = 0; i < maxInfluences; i ++) {
				var joint:int = int(i/2);
				if (i%2 == 0) {
					if (i == 0) {
						array[j++] = "m33 t0.xyz, i0, c[a" + joint + ".x]";
						array[j++] = "mul o0, t0.xyz, a" + joint + ".y";
					} else {
						array[j++] = "m33 t0.xyz, i0, c[a" + joint + ".x]";
						array[j++] = "mul t0.xyz, t0.xyz, a" + joint + ".y";
						array[j++] = "add o0, o0, t0.xyz";
					}
				} else {
					array[j++] = "m33 t0.xyz, i0, c[a" + joint + ".z]";
					array[j++] = "mul t0.xyz, t0.xyz, a" + joint + ".w";
					array[j++] = "add o0, o0, t0.xyz";
				}
			}
			array[j++] = "mov o0.w, i0.w";
			array[j++] = "nrm o0.xyz, o0.xyz";
			res.compileFromArray(array);
			for (i = 0; i < maxInfluences; i += 2) {
				res.assignVariableName(VariableType.ATTRIBUTE, int(i/2), "joint" + i);
			}
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Skin = new Skin(maxInfluences);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var skin:Skin = Skin(source);
			this.maxInfluences = skin.maxInfluences;
			if (skin._renderedJoints != null) {
				// Clone renderedJoints
				this._renderedJoints = cloneJointsVector(skin._renderedJoints, skin);
			}
			this.transformProcedure = skin.transformProcedure;
			this.deltaTransformProcedure = skin.deltaTransformProcedure;
			for (var i:int = 0; i < _surfacesLength; i++) {
				surfaceJoints[i] = cloneJointsVector(skin.surfaceJoints[i], skin);
				surfaceTransformProcedures[i] = skin.surfaceTransformProcedures[i];
				surfaceDeltaTransformProcedures[i] = skin.surfaceDeltaTransformProcedures[i];
			}
		}

		private function cloneJointsVector(joints:Vector.<Joint>, skin:Skin):Vector.<Joint> {
			var count:int = joints.length;
			var result:Vector.<Joint> = new Vector.<Joint>();
			for (var i:int = 0; i < count; i++) {
				var joint:Joint = joints[i];
				result[i] = Joint(findClonedJoint(joint, skin, this));
			}
			return result;
		}

		private function findClonedJoint(joint:Joint, parentSource:Object3D, parentDest:Object3D):Object3D {
			for (var srcChild:Object3D = parentSource.childrenList, dstChild:Object3D = parentDest.childrenList; srcChild != null; srcChild = srcChild.next, dstChild = dstChild.next) {
				if (srcChild == joint) {
					return dstChild;
				}
				if (srcChild.childrenList != null) {
					var j:Object3D = findClonedJoint(joint, srcChild, dstChild);
					if (j != null) return j;
				}
			}
			return null;
		}

	}
}
