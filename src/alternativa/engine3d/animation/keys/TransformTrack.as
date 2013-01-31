/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation.keys {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.AnimationState;

	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * A track which animates object transformation.
	 */
	public class TransformTrack extends Track {

		private var keyList:TransformKey;

		private var _lastKey:TransformKey;

		/**
		 * @private
		 */
		override alternativa3d function get keyFramesList():Keyframe {
			return keyList;
		}

		/**
		 * @private
		 */
		override alternativa3d function set keyFramesList(value:Keyframe):void {
			keyList = TransformKey(value);
		}


		/**
		 * @private
		 */
		override alternativa3d function get lastKey():Keyframe {
			return _lastKey;
		}

		/**
		 * @private
		 */
		override alternativa3d function set lastKey(value:Keyframe):void {
			_lastKey = TransformKey(value);
		}

		/**
		 * Creates a TransformTrack object.
		 */
		public function TransformTrack(object:String) {
			this.object = object;
		}

		/**
		 * Adds new keyframe. Keyframes stores ordered by its time property.
		 *
		 * @param time time of the new keyframe.
		 * @param matrix value of property for the new keyframe.
		 * @return added keyframe.
		 */
		public function addKey(time:Number, matrix:Matrix3D):TransformKey {
			var key:TransformKey = new TransformKey();
			key._time = time;
			var components:Vector.<Vector3D> = matrix.decompose(Orientation3D.QUATERNION);
			key.x = components[0].x;
			key.y = components[0].y;
			key.z = components[0].z;
			key.rotation = components[1];
			key.scaleX = components[2].x;
			key.scaleY = components[2].y;
			key.scaleZ = components[2].z;
			addKeyToList(key);
			return key;
		}

		/**
		 * Adds new keyframe and initialize it by transformation components.
		 *  Keyframes stores ordered by its time property.
		 *
		 * @param time time of the new keyframe.
		 * @return added keyframe.
		 */
		public function addKeyComponents(time:Number, x:Number = 0, y:Number = 0, z:Number = 0, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0, scaleX:Number = 1, scaleY:Number = 1, scaleZ:Number = 1):TransformKey {
			var key:TransformKey = new TransformKey();
			key._time = time;
			key.x = x;
			key.y = y;
			key.z = z;
			key.rotation = createQuatFromEuler(rotationX, rotationY, rotationZ);
			key.scaleX = scaleX;
			key.scaleY = scaleY;
			key.scaleZ = scaleZ;
			addKeyToList(key);
			return key;
		}

		/**
		 * @private
		 *
		 * Multiplies quat by additive from right: quat = quat * additive.
		 *
		 */
		private function appendQuat(quat:Vector3D, additive:Vector3D):void {
			var ww:Number = additive.w*quat.w - additive.x*quat.x - additive.y*quat.y - additive.z*quat.z;
			var xx:Number = additive.w*quat.x + additive.x*quat.w + additive.y*quat.z - additive.z*quat.y;
			var yy:Number = additive.w*quat.y + additive.y*quat.w + additive.z*quat.x - additive.x*quat.z;
			var zz:Number = additive.w*quat.z + additive.z*quat.w + additive.x*quat.y - additive.y*quat.x;
			quat.w = ww;
			quat.x = xx;
			quat.y = yy;
			quat.z = zz;
		}

		/**
		 * @private
		 */
		private function normalizeQuat(quat:Vector3D):void {
			var d:Number = quat.w*quat.w + quat.x*quat.x + quat.y*quat.y + quat.z*quat.z;
			if (d == 0) {
				quat.w = 1;
			} else {
				d = 1/Math.sqrt(d);
				quat.w *= d;
				quat.x *= d;
				quat.y *= d;
				quat.z *= d;
			}
		}

		/**
		 * @private
		 */
		private function setQuatFromAxisAngle(quat:Vector3D, x:Number, y:Number, z:Number, angle:Number):void {
			quat.w = Math.cos(0.5*angle);
			var k:Number = Math.sin(0.5*angle)/Math.sqrt(x*x + y*y + z*z);
			quat.x = x*k;
			quat.y = y*k;
			quat.z = z*k;
		}

		/**
		 * @private
		 */
		private static var tempQuat:Vector3D = new Vector3D();

		/**
		 * @private
		 */
		private function createQuatFromEuler(x:Number, y:Number, z:Number):Vector3D {
			var result:Vector3D = new Vector3D();
			setQuatFromAxisAngle(result, 1, 0, 0, x);

			setQuatFromAxisAngle(tempQuat, 0, 1, 0, y);
			appendQuat(result, tempQuat);
			normalizeQuat(result);

			setQuatFromAxisAngle(tempQuat, 0, 0, 1, z);
			appendQuat(result, tempQuat);
			normalizeQuat(result);
			return result;
		}

		/**
		 * @private
		 */
		private static var temp:TransformKey = new TransformKey();

        private var recentKey:TransformKey = null;

		/**
		 * @private
		 */
		override alternativa3d function blend(time:Number, weight:Number, state:AnimationState):void {
			var prev:TransformKey;
			var next:TransformKey;

			if (recentKey != null && recentKey.time < time) {
				prev = recentKey;
				next = recentKey.next;
			} else {
				next = keyList;
			}
			while (next != null && next._time < time) {
				prev = next;
				next = next.next;
			}

			if (prev != null) {
				if (next != null) {
					temp.interpolate(prev, next, (time - prev._time)/(next._time - prev._time));
					state.addWeightedTransform(temp, weight);
				} else {
					state.addWeightedTransform(prev, weight);
				}
				recentKey = prev;
			} else {
				if (next != null) {
					state.addWeightedTransform(next, weight);
				}
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function createKeyFrame():Keyframe {
			return new TransformKey();
		}

		/**
		 * @private
		 */
		override alternativa3d function interpolateKeyFrame(dest:Keyframe, a:Keyframe, b:Keyframe, value:Number):void {
			TransformKey(dest).interpolate(TransformKey(a), TransformKey(b), value);
		}

		/**
		 * @inheritDoc
		 */
		override public function slice(start:Number, end:Number = Number.MAX_VALUE):Track {
			var track:TransformTrack = new TransformTrack(object);
			sliceImplementation(track, start, end);
			return track;
		}

	}
}
