/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.keys.TransformKey;
	import alternativa.engine3d.core.Object3D;

	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * @private 
	 */
	public class AnimationState {
		
		public var useCount:int = 0;
		
		public var transform:TransformKey = new TransformKey();
		public var transformWeightSum:Number = 0;

		public var numbers:Object = {};
		public var numberWeightSums:Object = {};
		

		public function AnimationState() {
		}

		public function reset():void {
			transformWeightSum = 0;
			for (var key:String in numbers) {
				delete numbers[key];
				delete numberWeightSums[key];
			}
		}

		public function addWeightedTransform(key:TransformKey, weight:Number):void {
			transformWeightSum += weight;
			transform.interpolate(transform, key, weight/transformWeightSum);
		}

		public function addWeightedNumber(property:String, value:Number, weight:Number):void {
			var sum:Number = numberWeightSums[property];
			if (sum == sum) {
				sum += weight;
				weight /= sum;
				var current:Number = numbers[property];
				numbers[property] = (1 - weight)*current + weight*value;
				numberWeightSums[property] = sum;
			} else {
				numbers[property] = value;
				numberWeightSums[property] = weight;
			}
		}

		public function apply(object:Object3D):void {
			if (transformWeightSum > 0) {
				object._x = transform.x;
				object._y = transform.y;
				object._z = transform.z;
				setEulerAngles(transform.rotation, object);
				object._scaleX = transform.scaleX;
				object._scaleY = transform.scaleY;
				object._scaleZ = transform.scaleZ;
				object.transformChanged = true;
			}

			var sum:Number, weight:Number;			
			for (var key:String in numbers) {
				switch (key) {
					case 'x':
						sum = numberWeightSums['x'];
						weight = sum/(sum + transformWeightSum);
						object.x = (1 - weight)*object.x + weight*numbers['x'];
						break;
					case 'y':
						sum = numberWeightSums['y'];
						weight = sum/(sum + transformWeightSum);
						object.y = (1 - weight)*object.y + weight*numbers['y'];
						break;
					case 'z':
						sum = numberWeightSums['z'];
						weight = sum/(sum + transformWeightSum);
						object.z = (1 - weight)*object.z + weight*numbers['z'];
						break;
					case 'rotationX':
						sum = numberWeightSums['rotationX'];
						weight = sum/(sum + transformWeightSum);
						object.rotationX = (1 - weight)*object.rotationX + weight*numbers['rotationX'];
						break;
					case 'rotationY':
						sum = numberWeightSums['rotationY'];
						weight = sum/(sum + transformWeightSum);
						object.rotationY = (1 - weight)*object.rotationY + weight*numbers['rotationY'];
						break;
					case 'rotationZ':
						sum = numberWeightSums['rotationZ'];
						weight = sum/(sum + transformWeightSum);
						object.rotationZ = (1 - weight)*object.rotationZ + weight*numbers['rotationZ'];
						break;
					case 'scaleX':
						sum = numberWeightSums['scaleX'];
						weight = sum/(sum + transformWeightSum);
						object.scaleX = (1 - weight)*object.scaleX + weight*numbers['scaleX'];
						break;
					case 'scaleY':
						sum = numberWeightSums['scaleY'];
						weight = sum/(sum + transformWeightSum);
						object.scaleY = (1 - weight)*object.scaleY + weight*numbers['scaleY'];
						break;
					case 'scaleZ':
						sum = numberWeightSums['scaleZ'];
						weight = sum/(sum + transformWeightSum);
						object.scaleZ = (1 - weight)*object.scaleZ + weight*numbers['scaleZ'];
						break;
					default :
						object[key] = numbers[key];
						break;
				}
			}
		}

		public function applyObject(object:Object):void {
			if (transformWeightSum > 0) {
				object.x = transform.x;
				object.y = transform.y;
				object.z = transform.z;
				setEulerAnglesObject(transform.rotation, object);
				object.scaleX = transform.scaleX;
				object.scaleY = transform.scaleY;
				object.scaleZ = transform.scaleZ;
			}

			var sum:Number, weight:Number;
			for (var key:String in numbers) {
				switch (key) {
					case 'x':
						sum = numberWeightSums['x'];
						weight = sum/(sum + transformWeightSum);
						object.x = (1 - weight)*object.x + weight*numbers['x'];
						break;
					case 'y':
						sum = numberWeightSums['y'];
						weight = sum/(sum + transformWeightSum);
						object.y = (1 - weight)*object.y + weight*numbers['y'];
						break;
					case 'z':
						sum = numberWeightSums['z'];
						weight = sum/(sum + transformWeightSum);
						object.z = (1 - weight)*object.z + weight*numbers['z'];
						break;
					case 'rotationX':
						sum = numberWeightSums['rotationX'];
						weight = sum/(sum + transformWeightSum);
						object.rotationX = (1 - weight)*object.rotationX + weight*numbers['rotationX'];
						break;
					case 'rotationY':
						sum = numberWeightSums['rotationY'];
						weight = sum/(sum + transformWeightSum);
						object.rotationY = (1 - weight)*object.rotationY + weight*numbers['rotationY'];
						break;
					case 'rotationZ':
						sum = numberWeightSums['rotationZ'];
						weight = sum/(sum + transformWeightSum);
						object.rotationZ = (1 - weight)*object.rotationZ + weight*numbers['rotationZ'];
						break;
					case 'scaleX':
						sum = numberWeightSums['scaleX'];
						weight = sum/(sum + transformWeightSum);
						object.scaleX = (1 - weight)*object.scaleX + weight*numbers['scaleX'];
						break;
					case 'scaleY':
						sum = numberWeightSums['scaleY'];
						weight = sum/(sum + transformWeightSum);
						object.scaleY = (1 - weight)*object.scaleY + weight*numbers['scaleY'];
						break;
					case 'scaleZ':
						sum = numberWeightSums['scaleZ'];
						weight = sum/(sum + transformWeightSum);
						object.scaleZ = (1 - weight)*object.scaleZ + weight*numbers['scaleZ'];
						break;
					default :
						object[key] = numbers[key];
						break;
				}
			}
		}

		private function setEulerAngles(quat:Vector3D, object:Object3D):void {
			var qi2:Number = 2*quat.x*quat.x;
			var qj2:Number = 2*quat.y*quat.y;
			var qk2:Number = 2*quat.z*quat.z;
			var qij:Number = 2*quat.x*quat.y;
			var qjk:Number = 2*quat.y*quat.z;
			var qki:Number = 2*quat.z*quat.x;
			var qri:Number = 2*quat.w*quat.x;
			var qrj:Number = 2*quat.w*quat.y;
			var qrk:Number = 2*quat.w*quat.z;

			var aa:Number = 1 - qj2 - qk2;
			var bb:Number = qij - qrk;
			var ee:Number = qij + qrk;
			var ff:Number = 1 - qi2 - qk2;
			var ii:Number = qki - qrj;
			var jj:Number = qjk + qri;
			var kk:Number = 1 - qi2 - qj2;

			if (-1 < ii && ii < 1) {
				object._rotationX = Math.atan2(jj, kk);
				object._rotationY = -Math.asin(ii);
				object._rotationZ = Math.atan2(ee, aa);
			} else {
				object._rotationX = 0;
				object._rotationY = (ii <= -1) ? Math.PI : -Math.PI;
				object._rotationY *= 0.5;
				object._rotationZ = Math.atan2(-bb, ff);
			}
		}

		private function setEulerAnglesObject(quat:Vector3D, object:Object):void {
			var qi2:Number = 2*quat.x*quat.x;
			var qj2:Number = 2*quat.y*quat.y;
			var qk2:Number = 2*quat.z*quat.z;
			var qij:Number = 2*quat.x*quat.y;
			var qjk:Number = 2*quat.y*quat.z;
			var qki:Number = 2*quat.z*quat.x;
			var qri:Number = 2*quat.w*quat.x;
			var qrj:Number = 2*quat.w*quat.y;
			var qrk:Number = 2*quat.w*quat.z;

			var aa:Number = 1 - qj2 - qk2;
			var bb:Number = qij - qrk;
			var ee:Number = qij + qrk;
			var ff:Number = 1 - qi2 - qk2;
			var ii:Number = qki - qrj;
			var jj:Number = qjk + qri;
			var kk:Number = 1 - qi2 - qj2;

			if (-1 < ii && ii < 1) {
				object.rotationX = Math.atan2(jj, kk);
				object.rotationY = -Math.asin(ii);
				object.rotationZ = Math.atan2(ee, aa);
			} else {
				object.rotationX = 0;
				object.rotationY = (ii <= -1) ? Math.PI : -Math.PI;
				object.rotationY *= 0.5;
				object.rotationZ = Math.atan2(-bb, ff);
			}
		}


	}
}
