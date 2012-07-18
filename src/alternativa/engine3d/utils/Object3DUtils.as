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
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class Object3DUtils {

		private static const toRootTransform:Transform3D = new Transform3D();
		private static const fromRootTransform:Transform3D = new Transform3D();
		
		/**
		 * @public
		 * Convert Degress to Radians and Radians to Degrees
		 */

		public static function toRadians(degrees:Number):Number{
			return degrees * Math.PI / 180;
		}
		
		public static function toDegrees(radians:Number):Number{
			return radians * 180 / Math.PI;
		}


		/**
		 * @private
		 * Performs calculation of bound box of objects hierarchy branch.
		 */
		public static function calculateHierarchyBoundBox(object:Object3D, boundBoxSpace:Object3D = null, result:BoundBox = null):BoundBox {
			if (result == null) result = new BoundBox();

			if (boundBoxSpace != null && object != boundBoxSpace) {
				// Calculate transfer matrix from object to provided space.
				var objectRoot:Object3D;
				var toSpaceTransform:Transform3D = null;

				if (object.transformChanged) object.composeTransforms();
				toRootTransform.copy(object.transform);
				var root:Object3D = object;
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
		alternativa3d static function updateBoundBoxHierarchically(object:Object3D, boundBox:BoundBox, transform:Transform3D = null):void {
			object.updateBoundBox(boundBox, transform);
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				child.localToCameraTransform.copy(child.transform);
				if (transform != null) child.localToCameraTransform.append(transform);
				updateBoundBoxHierarchically(child, boundBox, child.localToCameraTransform);
			}
		}

	}
}
