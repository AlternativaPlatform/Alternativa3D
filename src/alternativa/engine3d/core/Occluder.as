/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.resources.Geometry;

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	use namespace alternativa3d;
	
	/**
	 * Polygonal Object3D meant for excluding from the rendering process those objects, which it shields from the camera.
	 * The Occluder has no visual representation and does not be render.
	 * The geometry should be a convex polygon.
	 */
	public class Occluder extends Object3D {
		
		private var faceList:Face;
		
		private var edgeList:Edge;
		
		private var vertexList:Vertex;
		
		private var debugWire:WireFrame;
		
		/**
		 * @private
		 */
		alternativa3d var planeList:CullingPlane;
		
		/**
		 * @private
		 */
		alternativa3d var enabled:Boolean;
		
		/**
		 * Minimal ratio of overlap area of viewport by occluder to viewport area.
		 * This property can has value from <code>0</code> to <code>1</code>.
		 */
		public var minSize:Number = 0;
		
		/**
		 * Creates form of overlap on base of re-created geometry.
		 * Geometry must be solid, closed and convex.
		 * @param geometry passed <code>Geometry</code>
		 * @param distanceThreshold Accuracy, within which the coordinates of the vertices are the same.
		 * @param weldTriangles If <code>true</code>, then related triangles, that lie in one plane, will be united in one polygon.
		 * @param angleThreshold Permissible angle in radians between normals, that allows to unite faces in one plane.
		 * @param convexThreshold Value, that decrease allowable angle between related edges of united faces.
		 * @see #destroyForm()
		 */
		public function createForm(geometry:Geometry, distanceThreshold:Number = 0, weldTriangles:Boolean = true, angleThreshold:Number = 0, convexThreshold:Number = 0):void {
			destroyForm();
			// Checking for the errors
			var geometryIndicesLength:int = geometry._indices.length;
			if (geometry._numVertices == 0 || geometryIndicesLength == 0) throw new Error("The supplied geometry is empty.");
			var vBuffer:VertexStream = (VertexAttributes.POSITION < geometry._attributesStreams.length) ? geometry._attributesStreams[VertexAttributes.POSITION] : null;
			if (vBuffer == null) throw new Error("The supplied geometry is empty.");
			var i:int;
			// Create vertices
			var vertices:Vector.<Vertex> = new Vector.<Vertex>();
			var attributesOffset:int = geometry._attributesOffsets[VertexAttributes.POSITION];
			var numMappings:int = vBuffer.attributes.length;
			var data:ByteArray = vBuffer.data;
			for (i = 0; i < geometry._numVertices; i++) {
				data.position = 4*(numMappings*i + attributesOffset);
				var vertex:Vertex = new Vertex();
				vertex.x = data.readFloat();
				vertex.y = data.readFloat();
				vertex.z = data.readFloat();
				vertices[i] = vertex;
			}
			// Create faces
			for (i = 0; i < geometryIndicesLength;) {
				var a:int = geometry._indices[i]; i++;
				var b:int = geometry._indices[i]; i++;
				var c:int = geometry._indices[i]; i++;
				var face:Face = new Face();
				face.wrapper = new Wrapper();
				face.wrapper.vertex = vertices[a];
				face.wrapper.next = new Wrapper();
				face.wrapper.next.vertex = vertices[b];
				face.wrapper.next.next = new Wrapper();
				face.wrapper.next.next.vertex = vertices[c];
				face.calculateBestSequenceAndNormal();
				face.next = faceList;
				faceList = face;
			}
			// Unite vertices
			vertexList = weldVertices(vertices, distanceThreshold);
			// Unite faces
			if (weldTriangles) weldFaces(angleThreshold, convexThreshold);
			// Calculation of edges and checking for the validity
			var error:String = calculateEdges();
			if (error != null) {
				destroyForm();
				throw new ArgumentError(error);
			}
			calculateBoundBox();
		}
		
		/**
		 * Destroys form of overlap.
		 * @see #createForm()
		 */
		public function destroyForm():void {
			faceList = null;
			edgeList = null;
			vertexList = null;
			if (debugWire != null) {
				debugWire.geometry.dispose();
				debugWire = null;
			}
		}
		
		/**
		 * @private
		 */
		override alternativa3d function calculateVisibility(camera:Camera3D):void {
			camera.occluders[camera.occludersLength] = this;
			camera.occludersLength++;
		}
		
		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			// Debug
			if (camera.debug) {
				if (camera.checkInDebug(this) & Debug.CONTENT) {
					if (debugWire == null) {
						debugWire = new WireFrame(0xFF00FF, 1, 2);
						for (var edge:Edge = edgeList; edge != null; edge = edge.next) {
							debugWire.geometry.addLine(edge.a.x, edge.a.y, edge.a.z, edge.b.x, edge.b.y, edge.b.z);
						}
						debugWire.geometry.upload(camera.context3D);
					}
					debugWire.localToCameraTransform.copy(localToCameraTransform);
					debugWire.collectDraws(camera, null, 0, false);
				}
			}
		}
		
		private function calculateEdges():String {
			var face:Face;
			var wrapper:Wrapper;
			var edge:Edge;
			// Create edges
			for (face = faceList; face != null; face = face.next) {
				// Loop of edge segments
				var a:Vertex;
				var b:Vertex;
				for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next, a = b) {
					a = wrapper.vertex;
					b = (wrapper.next != null) ? wrapper.next.vertex : face.wrapper.vertex;
					// Loop of created edges
					for (edge = edgeList; edge != null; edge = edge.next) {
						// If geometry is incorrect
						if (edge.a == a && edge.b == b) {
							return "The supplied geometry is not valid.";
						}
						// If found created edges with these vertices
						if (edge.a == b && edge.b == a) break;
					}
					if (edge != null) {
						edge.right = face;
					} else {
						edge = new Edge();
						edge.a = a;
						edge.b = b;
						edge.left = face;
						edge.next = edgeList;
						edgeList = edge;
					}
				}
			}
			// Checking for the validity
			for (edge = edgeList; edge != null; edge = edge.next) {
				// If edge consists of one face
				if (edge.left == null || edge.right == null) {
					return "The supplied geometry is non whole.";
				}
				var abx:Number = edge.b.x - edge.a.x;
				var aby:Number = edge.b.y - edge.a.y;
				var abz:Number = edge.b.z - edge.a.z;
				var crx:Number = edge.right.normalZ*edge.left.normalY - edge.right.normalY*edge.left.normalZ;
				var cry:Number = edge.right.normalX*edge.left.normalZ - edge.right.normalZ*edge.left.normalX;
				var crz:Number = edge.right.normalY*edge.left.normalX - edge.right.normalX*edge.left.normalY;
				// If bend inside
				if (abx*crx + aby*cry + abz*crz < 0) {
					//return "The supplied geometry is non convex.";
					trace("Warning: " + this + ": geometry is non convex.");
				}
			}
			return null;
		}
		
		private function weldVertices(vertices:Vector.<Vertex>, distanceThreshold:Number):Vertex {
			var vertex:Vertex;
			var verticesLength:int = vertices.length;
			// Group
			group(vertices, 0, verticesLength, 0, distanceThreshold, new Vector.<int>());
			// Change vertices
			for (var face:Face = faceList; face != null; face = face.next) {
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					if (wrapper.vertex.value != null) {
						wrapper.vertex = wrapper.vertex.value;
					}
				}
			}
			// Create new list of vertices
			var res:Vertex;
			for (var i:int = 0; i < verticesLength; i++) {
				vertex = vertices[i];
				if (vertex.value == null) {
					vertex.next = res;
					res = vertex;
				}
			}
			return res;
		}
		
		private function group(verts:Vector.<Vertex>, begin:int, end:int, depth:int, threshold:Number, stack:Vector.<int>):void {
			var i:int;
			var j:int;
			var vertex:Vertex;
			switch (depth) {
				case 0: // x
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.x;
					}
					break;
				case 1: // y
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.y;
					}
					break;
				case 2: // z
					for (i = begin; i < end; i++) {
						vertex = verts[i];
						vertex.offset = vertex.z;
					}
					break;
			}
			// Sorting
			stack[0] = begin;
			stack[1] = end - 1;
			var index:int = 2;
			while (index > 0) {
				index--;
				var r:int = stack[index];
				j = r;
				index--;
				var l:int = stack[index];
				i = l;
				vertex = verts[(r + l) >> 1];
				var median:Number = vertex.offset;
				while (i <= j) {
					var left:Vertex = verts[i];
					while (left.offset > median) {
						i++;
						left = verts[i];
					}
					var right:Vertex = verts[j];
					while (right.offset < median) {
						j--;
						right = verts[j];
					}
					if (i <= j) {
						verts[i] = right;
						verts[j] = left;
						i++;
						j--;
					}
				}
				if (l < j) {
					stack[index] = l;
					index++;
					stack[index] = j;
					index++;
				}
				if (i < r) {
					stack[index] = i;
					index++;
					stack[index] = r;
					index++;
				}
			}
			// Divide on groups further
			i = begin;
			vertex = verts[i];
			var compared:Vertex;
			for (j = i + 1; j <= end; j++) {
				if (j < end) compared = verts[j];
				if (j == end || vertex.offset - compared.offset > threshold) {
					if (depth < 2 && j - i > 1) {
						group(verts, i, j, depth + 1, threshold, stack);
					}
					if (j < end) {
						i = j;
						vertex = verts[i];
					}
				} else if (depth == 2) {
					compared.value = vertex;
				}
			}
		}
		
		private function weldFaces(angleThreshold:Number = 0, convexThreshold:Number = 0):void {
			var i:int;
			var j:int;
			var key:*;
			var sibling:Face;
			var face:Face;
			var next:Face;
			var wp:Wrapper;
			var sp:Wrapper;
			var w:Wrapper;
			var s:Wrapper;
			var wn:Wrapper;
			var sn:Wrapper;
			var wm:Wrapper;
			var sm:Wrapper;
			var vertex:Vertex;
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var abx:Number;
			var aby:Number;
			var abz:Number;
			var acx:Number;
			var acy:Number;
			var acz:Number;
			var nx:Number;
			var ny:Number;
			var nz:Number;
			var nl:Number;
			var dictionary:Dictionary;
			// Accuracy
			var digitThreshold:Number = 0.001;
			angleThreshold = Math.cos(angleThreshold) - digitThreshold;
			convexThreshold = Math.cos(Math.PI - convexThreshold) - digitThreshold;
			// Faces
			var faceSet:Dictionary = new Dictionary();
			// Map of matching vertex:faces(dictionary)
			var map:Dictionary = new Dictionary();
			for (face = faceList; face != null; face = next) {
				next = face.next;
				face.next = null;
				faceSet[face] = true;
				for (wn = face.wrapper; wn != null; wn = wn.next) {
					vertex = wn.vertex;
					dictionary = map[vertex];
					if (dictionary == null) {
						dictionary = new Dictionary();
						map[vertex] = dictionary;
					}
					dictionary[face] = true;
				}
			}
			faceList = null;
			// Island
			var island:Vector.<Face> = new Vector.<Face>();
			// Neighbors of current edge
			var siblings:Dictionary = new Dictionary();
			// Edges, that are not included to current island
			var unfit:Dictionary = new Dictionary();
			while (true) {
				// Get of first face
				face = null;
				for (key in faceSet) {
					face = key;
					delete faceSet[key];
					break;
				}
				if (face == null) break;
				// Create island
				var num:int = 0;
				island[num] = face;
				num++;
				nx = face.normalX;
				ny = face.normalY;
				nz = face.normalZ;
				for (key in unfit) {
					delete unfit[key];
				}
				for (i = 0; i < num; i++) {
					face = island[i];
					for (key in siblings) {
						delete siblings[key];
					}
					// Collect potential neighbors of face
					for (w = face.wrapper; w != null; w = w.next) {
						for (key in map[w.vertex]) {
							if (faceSet[key] && !unfit[key]) {
								siblings[key] = true;
							}
						}
					}
					for (key in siblings) {
						sibling = key;
						// If they match along the normals
						if (nx*sibling.normalX + ny*sibling.normalY + nz*sibling.normalZ >= angleThreshold) {
							// Checking on the neighborhood
							for (w = face.wrapper; w != null; w = w.next) {
								wn = (w.next != null) ? w.next : face.wrapper;
								for (s = sibling.wrapper; s != null; s = s.next) {
									sn = (s.next != null) ? s.next : sibling.wrapper;
									if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
								}
								if (s != null) break;
							}
							// Add to island
							if (w != null) {
								island[num] = sibling;
								num++;
								delete faceSet[sibling];
							}
						} else {
							unfit[sibling] = true;
						}
					}
				}
				// If island has one face
				if (num == 1) {
					face = island[0];
					face.next = faceList;
					faceList = face;
					// Unite of island
				} else {
					while (true) {
						var weld:Boolean = false;
						// Loop of island faces
						for (i = 0; i < num - 1; i++) {
							face = island[i];
							if (face != null) {
								// Try to unite current faces with others
								for (j = 1; j < num; j++) {
									sibling = island[j];
									if (sibling != null) {
										// Search for the common face
										for (w = face.wrapper; w != null; w = w.next) {
											wn = (w.next != null) ? w.next : face.wrapper;
											for (s = sibling.wrapper; s != null; s = s.next) {
												sn = (s.next != null) ? s.next : sibling.wrapper;
												if (w.vertex == sn.vertex && wn.vertex == s.vertex) break;
											}
											if (s != null) break;
										}
										// If faces is not found
										if (w != null) {
											// Expansion of union faces
											while (true) {
												wm = (wn.next != null) ? wn.next : face.wrapper;
												//for (sp = sibling.wrapper; sp.next != s && sp.next != null; sp = sp.next);
												sp = sibling.wrapper;
												while (sp.next != s && sp.next != null) sp = sp.next;
												if (wm.vertex == sp.vertex) {
													wn = wm;
													s = sp;
												} else break;
											}
											while (true) {
												//for (wp = face.wrapper; wp.next != w && wp.next != null; wp = wp.next);
												wp = face.wrapper;
												while (wp.next != w && wp.next != null) wp = wp.next;
												sm = (sn.next != null) ? sn.next : sibling.wrapper;
												if (wp.vertex == sm.vertex) {
													w = wp;
													sn = sm;
												} else break;
											}
											// First bend
											a = w.vertex;
											b = sm.vertex;
											c = wp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Second bend
											a = s.vertex;
											b = wm.vertex;
											c = sp.vertex;
											abx = b.x - a.x;
											aby = b.y - a.y;
											abz = b.z - a.z;
											acx = c.x - a.x;
											acy = c.y - a.y;
											acz = c.z - a.z;
											nx = acz*aby - acy*abz;
											ny = acx*abz - acz*abx;
											nz = acy*abx - acx*aby;
											if (nx < digitThreshold && nx > -digitThreshold && ny < digitThreshold && ny > -digitThreshold && nz < digitThreshold && nz > -digitThreshold) {
												if (abx*acx + aby*acy + abz*acz > 0) continue;
											} else {
												if (face.normalX*nx + face.normalY*ny + face.normalZ*nz < 0) continue;
											}
											nl = 1/Math.sqrt(abx*abx + aby*aby + abz*abz);
											abx *= nl;
											aby *= nl;
											abz *= nl;
											nl = 1/Math.sqrt(acx*acx + acy*acy + acz*acz);
											acx *= nl;
											acy *= nl;
											acz *= nl;
											if (abx*acx + aby*acy + abz*acz < convexThreshold) continue;
											// Unite
											weld = true;
											var newFace:Face = new Face();
											newFace.normalX = face.normalX;
											newFace.normalY = face.normalY;
											newFace.normalZ = face.normalZ;
											newFace.offset = face.offset;
											wm = null;
											for (; wn != w; wn = (wn.next != null) ? wn.next : face.wrapper) {
												sm = new Wrapper();
												sm.vertex = wn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											for (; sn != s; sn = (sn.next != null) ? sn.next : sibling.wrapper) {
												sm = new Wrapper();
												sm.vertex = sn.vertex;
												if (wm != null) {
													wm.next = sm;
												} else {
													newFace.wrapper = sm;
												}
												wm = sm;
											}
											island[i] = newFace;
											island[j] = null;
											face = newFace;
											// TODO: comment to ENG
											// Если, то собираться будет парами, иначе к одной прицепляется максимально (это чуть быстрее)
											//if (pairWeld) break;
										}
									}
								}
							}
						}
						if (!weld) break;
					}
					// Collect of united faces
					for (i = 0; i < num; i++) {
						face = island[i];
						if (face != null) {
							// Calculate the best sequence of vertices
							face.calculateBestSequenceAndNormal();
							// Add
							face.next = faceList;
							faceList = face;
						}
					}
				}
			}
		}
		
		/**
		 * @private 
		 */
		alternativa3d function transformVertices(correctionX:Number, correctionY:Number):void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				vertex.cameraX = (localToCameraTransform.a*vertex.x + localToCameraTransform.b*vertex.y + localToCameraTransform.c*vertex.z + localToCameraTransform.d)/correctionX;
				vertex.cameraY = (localToCameraTransform.e*vertex.x + localToCameraTransform.f*vertex.y + localToCameraTransform.g*vertex.z + localToCameraTransform.h)/correctionY;
				vertex.cameraZ = localToCameraTransform.i*vertex.x + localToCameraTransform.j*vertex.y + localToCameraTransform.k*vertex.z + localToCameraTransform.l;
			}
		}
		
		/**
		 * @private 
		 */
		alternativa3d function checkOcclusion(occluder:Occluder, correctionX:Number, correctionY:Number):Boolean {
			for (var plane:CullingPlane = occluder.planeList; plane != null; plane = plane.next) {
				for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
					if (plane.x*vertex.cameraX*correctionX + plane.y*vertex.cameraY*correctionY + plane.z*vertex.cameraZ > plane.offset) return false;
				}
			}
			return true;
		}
		
		/**
		 * @private 
		 */
		alternativa3d function calculatePlanes(camera:Camera3D):void {
			var a:Vertex;
			var b:Vertex;
			var c:Vertex;
			var face:Face;
			var plane:CullingPlane;
			// Clear of planes
			if (planeList != null) {
				plane = planeList;
				while (plane.next != null) plane = plane.next;
				plane.next = CullingPlane.collector;
				CullingPlane.collector = planeList;
				planeList = null;
			}
			if (faceList == null || edgeList == null) return;
			// Visibility of faces
			if (!camera.orthographic) {
				var cameraInside:Boolean = true;
				for (face = faceList; face != null; face = face.next) {
					if (face.normalX*cameraToLocalTransform.d + face.normalY*cameraToLocalTransform.h + face.normalZ*cameraToLocalTransform.l > face.offset) {
						face.visible = true;
						cameraInside = false;
					} else {
						face.visible = false;
					}
				}
				if (cameraInside) return;
			} else {
				for (a = vertexList; a != null; a = a.next) if (a.cameraZ < camera.nearClipping) return;
				for (face = faceList; face != null; face = face.next) {
					face.visible = face.normalX*cameraToLocalTransform.c + face.normalY*cameraToLocalTransform.g + face.normalZ*cameraToLocalTransform.k < 0;
				}
			}
			// Create planes by contour
			var viewSizeX:Number = camera.view._width*0.5;
			var viewSizeY:Number = camera.view._width*0.5;
			var right:Number = viewSizeX/camera.correctionX;
			var left:Number = -right;
			var bottom:Number = viewSizeY/camera.correctionY;
			var top:Number = -bottom;
			var t:Number;
			var ax:Number;
			var ay:Number;
			var az:Number;
			var bx:Number;
			var by:Number;
			var bz:Number;
			var ox:Number;
			var oy:Number;
			var lineList:CullingPlane = null;
			var square:Number = 0;
			var viewSquare:Number = viewSizeX*viewSizeY*4*2;
			var occludeAll:Boolean = true;
			for (var edge:Edge = edgeList; edge != null; edge = edge.next) {
				// If face is into the contour
				if (edge.left.visible != edge.right.visible) {
					// Define the direction (counterclockwise)
					if (edge.left.visible) {
						a = edge.a;
						b = edge.b;
					} else {
						a = edge.b;
						b = edge.a;
					}
					ax = a.cameraX;
					ay = a.cameraY;
					az = a.cameraZ;
					bx = b.cameraX;
					by = b.cameraY;
					bz = b.cameraZ;
					// Clipping
					if (culling > 3) {
						if (!camera.orthographic) {
							if (az <= -ax && bz <= -bx) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > -bx && az <= -ax) {
								t = (ax + az)/(ax + az - bx - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= -bx && az > -ax) {
								t = (ax + az)/(ax + az - bx - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= ax && bz <= bx) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > bx && az <= ax) {
								t = (az - ax)/(az - ax + bx - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= bx && az > ax) {
								t = (az - ax)/(az - ax + bx - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= -ay && bz <= -by) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > -by && az <= -ay) {
								t = (ay + az)/(ay + az - by - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= -by && az > -ay) {
								t = (ay + az)/(ay + az - by - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= ay && bz <= by) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > by && az <= ay) {
								t = (az - ay)/(az - ay + by - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= by && az > ay) {
								t = (az - ay)/(az - ay + by - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
						// Orthographic mode
						} else {
							if (ax <= left && bx <= left) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bx > left && ax <= left) {
								t = (left - ax)/(bx - ax);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bx <= left && ax > left) {
								t = (left - ax)/(bx - ax);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ax >= right && bx >= right) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bx < right && ax >= right) {
								t = (right - ax)/(bx - ax);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bx >= right && ax < right) {
								t = (right - ax)/(bx - ax);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ay <= top && by <= top) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (by > top && ay <= top) {
								t = (top - ay)/(by - ay);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (by <= top && ay > top) {
								t = (top - ay)/(by - ay);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ay >= bottom && by >= bottom) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (by < bottom && ay >= bottom) {
								t = (bottom - ay)/(by - ay);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (by >= bottom && ay < bottom) {
								t = (bottom - ay)/(by - ay);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
						}
						occludeAll = false;
					}
					// Create plane by edge
					plane = CullingPlane.create();
					plane.next = planeList;
					planeList = plane;
					if (!camera.orthographic) {
						plane.x = (b.cameraZ*a.cameraY - b.cameraY*a.cameraZ)*camera.correctionY;
						plane.y = (b.cameraX*a.cameraZ - b.cameraZ*a.cameraX)*camera.correctionX;
						plane.z = (b.cameraY*a.cameraX - b.cameraX*a.cameraY)*camera.correctionX*camera.correctionY;
						plane.offset = 0;
						if (minSize > 0 && square/viewSquare < minSize) {
							ax = ax*viewSizeX/az;
							ay = ay*viewSizeY/az;
							bx = bx*viewSizeX/bz;
							by = by*viewSizeY/bz;
							if (planeList.next == null) {
								ox = ax;
								oy = ay;
							}
							square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
							plane = plane.create();
							plane.x = ay - by;
							plane.y = bx - ax;
							plane.offset = plane.x*ax + plane.y*ay;
							plane.next = lineList;
							lineList = plane;
						}
					} else {
						plane.x = (a.cameraY - b.cameraY)*camera.correctionY;
						plane.y = (b.cameraX - a.cameraX)*camera.correctionX;
						plane.z = 0;
						plane.offset = plane.x*a.cameraX*camera.correctionX + plane.y*a.cameraY*camera.correctionY;
						if (minSize > 0 && square/viewSquare < minSize) {
							ax = ax*camera.correctionX;
							ay = ay*camera.correctionY;
							bx = bx*camera.correctionX;
							by = by*camera.correctionY;
							if (planeList.next == null) {
								ox = ax;
								oy = ay;
							}
							square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
							plane = plane.create();
							plane.x = ay - by;
							plane.y = bx - ax;
							plane.offset = plane.x*ax + plane.y*ay;
							plane.next = lineList;
							lineList = plane;
						}
					}
				}
			}
			if (planeList == null && !occludeAll) return;
			// Checking size on the display
			if (planeList != null && minSize > 0 && square/viewSquare < minSize && (culling <= 3 || !checkSquare(lineList, ox, oy, square, viewSquare, viewSizeX, viewSizeY))) {
				plane = planeList;
				while (plane.next != null) plane = plane.next;
				plane.next = CullingPlane.collector;
				CullingPlane.collector = planeList;
				planeList = null;
				if (lineList != null) {
					plane = lineList;
					while (plane.next != null) plane = plane.next;
					plane.next = CullingPlane.collector;
					CullingPlane.collector = lineList;
				}
				return;
			} else if (lineList != null) {
				plane = lineList;
				while (plane.next != null) plane = plane.next;
				plane.next = CullingPlane.collector;
				CullingPlane.collector = lineList;
			}
			// Create planes by faces.
			for (face = faceList; face != null; face = face.next) {
				if (!face.visible) continue;
				if (culling > 3) {
					occludeAll = true;
					var wrapper:Wrapper;
					for (wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
						a = wrapper.vertex;
						b = (wrapper.next != null) ? wrapper.next.vertex : face.wrapper.vertex;
						ax = a.cameraX;
						ay = a.cameraY;
						az = a.cameraZ;
						bx = b.cameraX;
						by = b.cameraY;
						bz = b.cameraZ;
						if (!camera.orthographic) {
							if (az <= -ax && bz <= -bx) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > -bx && az <= -ax) {
								t = (ax + az)/(ax + az - bx - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= -bx && az > -ax) {
								t = (ax + az)/(ax + az - bx - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= ax && bz <= bx) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > bx && az <= ax) {
								t = (az - ax)/(az - ax + bx - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= bx && az > ax) {
								t = (az - ax)/(az - ax + bx - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= -ay && bz <= -by) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > -by && az <= -ay) {
								t = (ay + az)/(ay + az - by - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= -by && az > -ay) {
								t = (ay + az)/(ay + az - by - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (az <= ay && bz <= by) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bz > by && az <= ay) {
								t = (az - ay)/(az - ay + by - bz);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bz <= by && az > ay) {
								t = (az - ay)/(az - ay + by - bz);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
						// Orthographic mode
						} else {
							if (ax <= left && bx <= left) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bx > left && ax <= left) {
								t = (left - ax)/(bx - ax);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bx <= left && ax > left) {
								t = (left - ax)/(bx - ax);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ax >= right && bx >= right) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (bx < right && ax >= right) {
								t = (right - ax)/(bx - ax);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (bx >= right && ax < right) {
								t = (right - ax)/(bx - ax);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ay <= top && by <= top) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (by > top && ay <= top) {
								t = (top - ay)/(by - ay);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (by <= top && ay > top) {
								t = (top - ay)/(by - ay);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
							if (ay >= bottom && by >= bottom) {
								if (occludeAll && by*ax - bx*ay > 0) occludeAll = false;
								continue;
							} else if (by < bottom && ay >= bottom) {
								t = (bottom - ay)/(by - ay);
								ax += (bx - ax)*t;
								ay += (by - ay)*t;
								az += (bz - az)*t;
							} else if (by >= bottom && ay < bottom) {
								t = (bottom - ay)/(by - ay);
								bx = ax + (bx - ax)*t;
								by = ay + (by - ay)*t;
								bz = az + (bz - az)*t;
							}
						}
						occludeAll = false;
						break;
					}
					if (wrapper == null && !occludeAll) continue;
				}
				// Create plane by face
				plane = CullingPlane.create();
				plane.next = planeList;
				planeList = plane;
				a = face.wrapper.vertex;
				b = face.wrapper.next.vertex;
				c = face.wrapper.next.next.vertex;
				ax = b.cameraX - a.cameraX;
				ay = b.cameraY - a.cameraY;
				az = b.cameraZ - a.cameraZ;
				bx = c.cameraX - a.cameraX;
				by = c.cameraY - a.cameraY;
				bz = c.cameraZ - a.cameraZ;
				plane.x = (bz*ay - by*az)*camera.correctionY;
				plane.y = (bx*az - bz*ax)*camera.correctionX;
				plane.z = (by*ax - bx*ay)*camera.correctionX*camera.correctionY;
				plane.offset = a.cameraX*plane.x*camera.correctionX + a.cameraY*plane.y*camera.correctionY + a.cameraZ*plane.z;
			}
		}
		
		private function checkSquare(lineList:CullingPlane, ox:Number, oy:Number, square:Number, viewSquare:Number, viewSizeX:Number, viewSizeY:Number):Boolean {
			var t:Number;
			var ax:Number;
			var ay:Number;
			var ao:Number;
			var bx:Number;
			var by:Number;
			var bo:Number;
			var plane:CullingPlane;
			// Clipping of viewport frame by projected contour edges
			if (culling & 4) {
				ax = -viewSizeX;
				ay = -viewSizeY;
				bx = -viewSizeX;
				by = viewSizeY;
				for (plane = lineList; plane != null; plane = plane.next) {
					ao = ax*plane.x + ay*plane.y - plane.offset;
					bo = bx*plane.x + by*plane.y - plane.offset;
					if (ao < 0 || bo < 0) {
						if (ao >= 0 && bo < 0) {
							t = ao/(ao - bo);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
						} else if (ao < 0 && bo >= 0) {
							t = ao/(ao - bo);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
						}
					} else break;
				}
				if (plane == null) {
					square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
					if (square/viewSquare >= minSize) return true;
				}
			}
			if (culling & 8) {
				ax = viewSizeX;
				ay = viewSizeY;
				bx = viewSizeX;
				by = -viewSizeY;
				for (plane = lineList; plane != null; plane = plane.next) {
					ao = ax*plane.x + ay*plane.y - plane.offset;
					bo = bx*plane.x + by*plane.y - plane.offset;
					if (ao < 0 || bo < 0) {
						if (ao >= 0 && bo < 0) {
							t = ao/(ao - bo);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
						} else if (ao < 0 && bo >= 0) {
							t = ao/(ao - bo);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
						}
					} else break;
				}
				if (plane == null) {
					square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
					if (square/viewSquare >= minSize) return true;
				}
			}
			if (culling & 16) {
				ax = viewSizeX;
				ay = -viewSizeY;
				bx = -viewSizeX;
				by = -viewSizeY;
				for (plane = lineList; plane != null; plane = plane.next) {
					ao = ax*plane.x + ay*plane.y - plane.offset;
					bo = bx*plane.x + by*plane.y - plane.offset;
					if (ao < 0 || bo < 0) {
						if (ao >= 0 && bo < 0) {
							t = ao/(ao - bo);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
						} else if (ao < 0 && bo >= 0) {
							t = ao/(ao - bo);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
						}
					} else break;
				}
				if (plane == null) {
					square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
					if (square/viewSquare >= minSize) return true;
				}
			}
			if (culling & 32) {
				ax = -viewSizeX;
				ay = viewSizeY;
				bx = viewSizeX;
				by = viewSizeY;
				for (plane = lineList; plane != null; plane = plane.next) {
					ao = ax*plane.x + ay*plane.y - plane.offset;
					bo = bx*plane.x + by*plane.y - plane.offset;
					if (ao < 0 || bo < 0) {
						if (ao >= 0 && bo < 0) {
							t = ao/(ao - bo);
							ax += (bx - ax)*t;
							ay += (by - ay)*t;
						} else if (ao < 0 && bo >= 0) {
							t = ao/(ao - bo);
							bx = ax + (bx - ax)*t;
							by = ay + (by - ay)*t;
						}
					} else break;
				}
				if (plane == null) {
					square += (bx - ox)*(ay - oy) - (by - oy)*(ax - ox);
					if (square/viewSquare >= minSize) return true;
				}
			}
			return false;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			for (var vertex:Vertex = vertexList; vertex != null; vertex = vertex.next) {
				var x:Number;
				var y:Number;
				var z:Number;
				if (transform != null) {
					x = transform.a*vertex.x + transform.b*vertex.y + transform.c*vertex.z + transform.d;
					y = transform.e*vertex.x + transform.f*vertex.y + transform.g*vertex.z + transform.h;
					z = transform.i*vertex.x + transform.j*vertex.y + transform.k*vertex.z + transform.l;
				} else {
					x = vertex.x;
					y = vertex.y;
					z = vertex.z;
				}
				if (x < boundBox.minX) boundBox.minX = x;
				if (x > boundBox.maxX) boundBox.maxX = x;
				if (y < boundBox.minY) boundBox.minY = y;
				if (y > boundBox.maxY) boundBox.maxY = y;
				if (z < boundBox.minZ) boundBox.minZ = z;
				if (z > boundBox.maxZ) boundBox.maxZ = z;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Occluder = new Occluder();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:Occluder = source as Occluder;
			minSize = src.minSize;
			// Clone vertices
			var vertex:Vertex;
			var face:Face;
			var lastVertex:Vertex;
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				var newVertex:Vertex = new Vertex();
				newVertex.x = vertex.x;
				newVertex.y = vertex.y;
				newVertex.z = vertex.z;
				vertex.value = newVertex;
				if (lastVertex != null) {
					lastVertex.next = newVertex;
				} else {
					vertexList = newVertex;
				}
				lastVertex = newVertex;
			}
			// Clone faces
			var lastFace:Face;
			for (face = src.faceList; face != null; face = face.next) {
				var newFace:Face = new Face();
				newFace.normalX = face.normalX;
				newFace.normalY = face.normalY;
				newFace.normalZ = face.normalZ;
				newFace.offset = face.offset;
				face.processNext = newFace;
				// Clone wrappers
				var lastWrapper:Wrapper = null;
				for (var wrapper:Wrapper = face.wrapper; wrapper != null; wrapper = wrapper.next) {
					var newWrapper:Wrapper = new Wrapper();
					newWrapper.vertex = wrapper.vertex.value;
					if (lastWrapper != null) {
						lastWrapper.next = newWrapper;
					} else {
						newFace.wrapper = newWrapper;
					}
					lastWrapper = newWrapper;
				}
				if (lastFace != null) {
					lastFace.next = newFace;
				} else {
					faceList = newFace;
				}
				lastFace = newFace;
			}
			// Clone edges
			var lastEdge:Edge;
			for (var edge:Edge = src.edgeList; edge != null; edge = edge.next) {
				var newEdge:Edge = new Edge();
				newEdge.a = edge.a.value;
				newEdge.b = edge.b.value;
				newEdge.left = edge.left.processNext;
				newEdge.right = edge.right.processNext;
				if (lastEdge != null) {
					lastEdge.next = newEdge;
				} else {
					edgeList = newEdge;
				}
				lastEdge = newEdge;
			}
			// Reset after remapping
			for (vertex = src.vertexList; vertex != null; vertex = vertex.next) {
				vertex.value = null;
			}
			for (face = src.faceList; face != null; face = face.next) {
				face.processNext = null;
			}
		}
		
	}
}

class Vertex {
	
	public var next:Vertex;
	public var value:Vertex;
	
	public var x:Number;
	public var y:Number;
	public var z:Number;
	
	public var offset:Number;
	
	public var cameraX:Number;
	public var cameraY:Number;
	public var cameraZ:Number;
	
}

class Face {
	
	public var next:Face;
	public var processNext:Face;
	
	public var normalX:Number;
	public var normalY:Number;
	public var normalZ:Number;
	public var offset:Number;
	
	public var wrapper:Wrapper;
	
	public var visible:Boolean;
	
	public function calculateBestSequenceAndNormal():void {
		if (wrapper.next.next.next != null) {
			var max:Number = -1e+22;
			var s:Wrapper;
			var sm:Wrapper;
			var sp:Wrapper;
			for (w = wrapper; w != null; w = w.next) {
				var wn:Wrapper = (w.next != null) ? w.next : wrapper;
				var wm:Wrapper = (wn.next != null) ? wn.next : wrapper;
				a = w.vertex;
				b = wn.vertex;
				c = wm.vertex;
				abx = b.x - a.x;
				aby = b.y - a.y;
				abz = b.z - a.z;
				acx = c.x - a.x;
				acy = c.y - a.y;
				acz = c.z - a.z;
				nx = acz*aby - acy*abz;
				ny = acx*abz - acz*abx;
				nz = acy*abx - acx*aby;
				nl = nx*nx + ny*ny + nz*nz;
				if (nl > max) {
					max = nl;
					s = w;
				}
			}
			if (s != wrapper) {
				//for (sm = wrapper.next.next.next; sm.next != null; sm = sm.next);
				sm = wrapper.next.next.next;
				while (sm.next != null) sm = sm.next;
				//for (sp = wrapper; sp.next != s && sp.next != null; sp = sp.next);
				sp = wrapper;
				while (sp.next != s && sp.next != null) sp = sp.next;
				sm.next = wrapper;
				sp.next = null;
				wrapper = s;
			}
		}
		var w:Wrapper = wrapper;
		var a:Vertex = w.vertex;
		w = w.next;
		var b:Vertex = w.vertex;
		w = w.next;
		var c:Vertex = w.vertex;
		var abx:Number = b.x - a.x;
		var aby:Number = b.y - a.y;
		var abz:Number = b.z - a.z;
		var acx:Number = c.x - a.x;
		var acy:Number = c.y - a.y;
		var acz:Number = c.z - a.z;
		var nx:Number = acz*aby - acy*abz;
		var ny:Number = acx*abz - acz*abx;
		var nz:Number = acy*abx - acx*aby;
		var nl:Number = nx*nx + ny*ny + nz*nz;
		if (nl > 0) {
			nl = 1/Math.sqrt(nl);
			nx *= nl;
			ny *= nl;
			nz *= nl;
			normalX = nx;
			normalY = ny;
			normalZ = nz;
		}
		offset = a.x*nx + a.y*ny + a.z*nz;
	}
		
}

class Wrapper {
	
	public var next:Wrapper;
	
	public var vertex:Vertex;
	
}

class Edge {

	public var next:Edge;

	public var a:Vertex;
	public var b:Vertex;

	public var left:Face;
	public var right:Face;

}
