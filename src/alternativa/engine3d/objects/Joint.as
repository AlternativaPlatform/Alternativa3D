/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;

	import flash.geom.Matrix3D;

	use namespace alternativa3d;
	
	/**
	 * A joint uses with <code>Skin</code> as handler for set of vertices.
	 * @see alternativa.engine3d.objects.Skin
	 */
	public class Joint extends Object3D {

		/**
		 * @private
		 * A joint transform matrix. Geometry -> Joint -> Skin
		 */
		alternativa3d var jointTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var bindPoseTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d function setBindPoseMatrix(matrix:Vector.<Number>):void {
			bindPoseTransform.initFromVector(matrix);
		}

		public function get bindingMatrix():Matrix3D {
			return new Matrix3D(Vector.<Number>([
				bindPoseTransform.a, bindPoseTransform.e, bindPoseTransform.i, 0,
				bindPoseTransform.b, bindPoseTransform.f, bindPoseTransform.j, 0,
				bindPoseTransform.c, bindPoseTransform.g, bindPoseTransform.k, 0,
				bindPoseTransform.d, bindPoseTransform.h, bindPoseTransform.l, 1
			]));
		}

		public function set bindingMatrix(value:Matrix3D):void {
			var data:Vector.<Number> = value.rawData;
			bindPoseTransform.a = data[0];
			bindPoseTransform.b = data[4];
			bindPoseTransform.c = data[8];
			bindPoseTransform.d = data[12];
			bindPoseTransform.e = data[1];
			bindPoseTransform.f = data[5];
			bindPoseTransform.g = data[9];
			bindPoseTransform.h = data[13];
			bindPoseTransform.i = data[2];
			bindPoseTransform.j = data[6];
			bindPoseTransform.k = data[10];
			bindPoseTransform.l = data[14];
		}

		/**
		 * @private
		 */
		alternativa3d function calculateBindingMatrices():void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				var joint:Joint = child as Joint;
				if (joint != null) {
					if (joint.transformChanged) {
						joint.composeTransforms();
					}
					joint.bindPoseTransform.combine(bindPoseTransform, joint.inverseTransform);
					joint.calculateBindingMatrices();
				}
			}
		}


		/**
		 * @private
		 */
		alternativa3d function calculateTransform():void {
			if (bindPoseTransform != null) {
				jointTransform.combine(localToGlobalTransform, bindPoseTransform);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Joint = new Joint();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var sourceJoint:Joint = source as Joint;
			bindPoseTransform.a = sourceJoint.bindPoseTransform.a;
			bindPoseTransform.b = sourceJoint.bindPoseTransform.b;
			bindPoseTransform.c = sourceJoint.bindPoseTransform.c;
			bindPoseTransform.d = sourceJoint.bindPoseTransform.d;
			bindPoseTransform.e = sourceJoint.bindPoseTransform.e;
			bindPoseTransform.f = sourceJoint.bindPoseTransform.f;
			bindPoseTransform.g = sourceJoint.bindPoseTransform.g;
			bindPoseTransform.h = sourceJoint.bindPoseTransform.h;
			bindPoseTransform.i = sourceJoint.bindPoseTransform.i;
			bindPoseTransform.j = sourceJoint.bindPoseTransform.j;
			bindPoseTransform.k = sourceJoint.bindPoseTransform.k;
			bindPoseTransform.l = sourceJoint.bindPoseTransform.l;
		}

	}
}
