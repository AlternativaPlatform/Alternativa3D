/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */
package alternativa.engine3d.utils {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.objects.Mesh;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;
	public class Object3DUtils {
		private static const toRootTransform : Transform3D = new Transform3D();
		private static const fromRootTransform : Transform3D = new Transform3D();

		/*
		 * Performs calculation of bound box of objects hierarchy branch.
		 */
		public static function calculateHierarchyBoundBox(object : Object3D, boundBoxSpace : Object3D = null, result : BoundBox = null) : BoundBox {
			if (result == null) result = new BoundBox();

			if (boundBoxSpace != null && object != boundBoxSpace) {
				// Calculate transfer matrix from object to provided space.
				var objectRoot : Object3D;
				var toSpaceTransform : Transform3D = null;

				if (object.transformChanged) object.composeTransforms();
				toRootTransform.copy(object.transform);
				var root : Object3D = object;
				while (root._parent != null) {
					root = root._parent;
					if (root.transformChanged) root.composeTransforms();
					toRootTransform.append(root.transform);
					if (root == boundBoxSpace) {
						// Matrix has been composed.
						toSpaceTransform = toRootTransform;
					}
				}
				objectRoot = root;
				if (toSpaceTransform == null) {
					// Transfer matrix from root to needed space.
					if (boundBoxSpace.transformChanged) boundBoxSpace.composeTransforms();
					fromRootTransform.copy(boundBoxSpace.inverseTransform);
					root = boundBoxSpace;
					while (root._parent != null) {
						root = root._parent;
						if (root.transformChanged) root.composeTransforms();
						fromRootTransform.prepend(root.inverseTransform);
					}
					if (objectRoot == root) {
						toRootTransform.append(fromRootTransform);
						toSpaceTransform = toRootTransform;
					} else {
						throw new ArgumentError("Object and boundBoxSpace must be located in the same hierarchy.");
					}
				}
				updateBoundBoxHierarchically(object, result, toSpaceTransform);
			} else {
				updateBoundBoxHierarchically(object, result);
			}
			return result;
		}

		/**
		 * @private
		 * Calculates hierarchical bound.
		 */
		alternativa3d static function updateBoundBoxHierarchically(object : Object3D, boundBox : BoundBox, transform : Transform3D = null) : void {
			object.updateBoundBox(boundBox, transform);
			for (var child : Object3D = object.childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				child.localToCameraTransform.copy(child.transform);
				if (transform != null) child.localToCameraTransform.append(transform);
				updateBoundBoxHierarchically(child, boundBox, child.localToCameraTransform);
			}
		}

		/**
		 * Local to local method. Handly for 3D editors.
		 * @param source
		 * @param target
		 * @param addSourceToTarget
		 * @return void
		 */
		private static const matrix : Matrix3D = new Matrix3D();
		private static const vector : Vector.<Number> = new Vector.<Number>();
		private static const transform : Transform3D = new Transform3D();

		public static function localToLocal(source : Object3D, target : Object3D = null, addSourceToTarget : Boolean = true) : void {
			if (target == null || source == null) return;
			var k : uint = 0;
			transform.identity();
			if (source.transformChanged) source.composeTransforms();
			transform.copy(source.transform);
			var parent : Object3D = source;
			while (parent.parent != null) {
				parent = parent.parent;
				if (parent == target) {
					k = 0;
					vector[k++] = transform.a;
					vector[k++] = transform.e;
					vector[k++] = transform.i;
					vector[k++] = 0;
					vector[k++] = transform.b;
					vector[k++] = transform.f;
					vector[k++] = transform.j;
					vector[k++] = 0;
					vector[k++] = transform.c;
					vector[k++] = transform.g;
					vector[k++] = transform.k;
					vector[k++] = 0;
					vector[k++] = transform.d;
					vector[k++] = transform.h;
					vector[k++] = transform.l;
					vector[k++] = 1;
					matrix.rawData = vector;
					source.matrix = matrix;
					target.addChild(source);
					return;
				}
				if (parent.transformChanged) parent.composeTransforms();
				transform.append(parent.transform);
			}
			if (target == null) return;
			target.composeTransforms();
			var pathItem : Object3D = target;
			var path : Vector.<Object3D> = new Vector.<Object3D>();

			while (pathItem.parent != null) {
				path.push(pathItem);
				pathItem = pathItem.parent;
			}

			var i : int;
			var length : int = path.length;
			for (i = length - 1; i >= 0; i--) {
				pathItem = path[i];
				pathItem.composeTransforms();
				transform.append(pathItem.inverseTransform);
			}
			k = 0;
			vector[k++] = transform.a;
			vector[k++] = transform.e;
			vector[k++] = transform.i;
			vector[k++] = 0;
			vector[k++] = transform.b;
			vector[k++] = transform.f;
			vector[k++] = transform.j;
			vector[k++] = 0;
			vector[k++] = transform.c;
			vector[k++] = transform.g;
			vector[k++] = transform.k;
			vector[k++] = 0;
			vector[k++] = transform.d;
			vector[k++] = transform.h;
			vector[k++] = transform.l;
			vector[k++] = 1;
			matrix.rawData = vector;
			source.matrix = matrix;
			if (addSourceToTarget) target.addChild(source);
		}

		private static var localOrigin : Vector3D = new Vector3D();
		private static var localDirection : Vector3D = new Vector3D();

		public static function calculateMouseInObjectSpace(camera : Camera3D, view : View, obj : Object3D) : RayIntersectionData {
			camera.calculateRay(localOrigin, localDirection, view.mouseX, view.mouseY);
			obj.composeTransforms();
			var root : Object3D = obj;
			while (root.parent != null) {
				root = root.parent;
				root.composeTransforms();
				obj.transform.append(root.transform);
			}
			obj.transform.invert();
			var ox : Number = localOrigin.x;
			var oy : Number = localOrigin.y;
			var oz : Number = localOrigin.z;
			var dx : Number = localDirection.x;
			var dy : Number = localDirection.y;
			var dz : Number = localDirection.z;
			localOrigin.x = obj.transform.a * ox + obj.transform.b * oy + obj.transform.c * oz + obj.transform.d;
			localOrigin.y = obj.transform.e * ox + obj.transform.f * oy + obj.transform.g * oz + obj.transform.h;
			localOrigin.z = obj.transform.i * ox + obj.transform.j * oy + obj.transform.k * oz + obj.transform.l;
			localDirection.x = obj.transform.a * dx + obj.transform.b * dy + obj.transform.c * dz;
			localDirection.y = obj.transform.e * dx + obj.transform.f * dy + obj.transform.g * dz;
			localDirection.z = obj.transform.i * dx + obj.transform.j * dy + obj.transform.k * dz;
			obj.composeTransforms();
			var data : RayIntersectionData = obj.intersectRay(localOrigin, localDirection);
			if (data) {
				return data;
			}
			return null;
		}

		public static function applyMeshTransform(mesh : Mesh) : void {
			vector.length = 0;
			const positions : Vector.<Number> = mesh.geometry.getAttributeValues(VertexAttributes.POSITION, vector);
			const length : uint = positions.length;
			const transform : Transform3D = mesh.transform;
			for (var i : uint = 0; i < length; i += 3) {
				const x : Number = positions[i];
				const y : Number = positions[i + 1];
				const z : Number = positions[i + 2];
				positions[i] = transform.a * x + transform.b * y + transform.c * z + transform.d;
				positions[i + 1] = transform.e * x + transform.f * y + transform.g * z + transform.h;
				positions[i + 2] = transform.i * x + transform.j * y + transform.k * z + transform.l;
			}
			mesh.x = 0;
			mesh.y = 0;
			mesh.z = 0;
			mesh.scaleX = 1;
			mesh.scaleY = 1;
			mesh.scaleZ = 1;
			mesh.rotationX = 0;
			mesh.rotationY = 0;
			mesh.rotationZ = 0;
			mesh.composeTransforms();
			mesh.geometry.setAttributeValues(VertexAttributes.POSITION, positions);
			mesh.geometry.calculateNormals();
			mesh.geometry.calculateTangents(0);
			mesh.boundBox.reset();
			mesh.updateBoundBox(mesh.boundBox);
			vector.length = 0;
		}
	}
}
