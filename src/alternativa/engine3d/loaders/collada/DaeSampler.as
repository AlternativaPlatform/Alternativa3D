/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.animation.keys.NumberTrack;
	import alternativa.engine3d.animation.keys.Track;
	import alternativa.engine3d.animation.keys.TransformTrack;

	import flash.geom.Matrix3D;

	use namespace collada;

	/**
	 * @private
	 */
	public class DaeSampler extends DaeElement {
	
		private var times:Vector.<Number>;
		private var values:Vector.<Number>;
		private var timesStride:int;
		private var valuesStride:int;
	
		public function DaeSampler(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		override protected function parseImplementation():Boolean {
			var inputsList:XMLList = data.input;
	
			var inputSource:DaeSource;
			var outputSource:DaeSource;
			for (var i:int = 0, count:int = inputsList.length(); i < count; i++) {
				var input:DaeInput = new DaeInput(inputsList[i], document);
				var semantic:String = input.semantic;
				if (semantic != null) {
					switch (semantic) {
						case "INPUT" :
							inputSource = input.prepareSource(1);
							if (inputSource != null) {
								times = inputSource.numbers;
								timesStride = inputSource.stride;
							}
							break;
						case "OUTPUT" :
							outputSource = input.prepareSource(1);
							if (outputSource != null) {
								values = outputSource.numbers;
								valuesStride = outputSource.stride;
							}
							break;
					}
				}
			}
			return true;
		}
	
		public function parseNumbersTrack(objectName:String, property:String):NumberTrack {
			if (times != null && values != null && timesStride > 0) {
				var track:NumberTrack = new NumberTrack(objectName, property);
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					track.addKey(times[int(timesStride*i)], values[int(valuesStride*i)]);
				}
				// TODO:: Exceptions with indices
				return track;
			}
			return null;
		}
	
		public function parseTransformationTrack(objectName:String):Track {
			if (times != null && values != null && timesStride != 0) {
				var track:TransformTrack = new TransformTrack(objectName);
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					var index:int = valuesStride*i;
					var matrix:Matrix3D = new Matrix3D(Vector.<Number>([values[index], values[index + 4], values[index + 8], values[index + 12],
						values[index + 1], values[index + 5], values[index + 9],  values[index + 13],
						values[index + 2], values[index + 6], values[index + 10], values[index + 14],
						values[index + 3] ,values[index + 7], values[index + 11], values[index + 15]]));
					track.addKey(times[i*timesStride], matrix);
				}
				return track;
			}
			return null;
		}
	
		public function parsePointsTracks(objectName:String, xProperty:String, yProperty:String, zProperty:String):Vector.<Track> {
			if (times != null && values != null && timesStride != 0) {
				var xTrack:NumberTrack = new NumberTrack(objectName, xProperty);
				xTrack.object = objectName;
				var yTrack:NumberTrack = new NumberTrack(objectName, yProperty);
				yTrack.object = objectName;
				var zTrack:NumberTrack = new NumberTrack(objectName, zProperty);
				zTrack.object = objectName;
				var count:int = times.length/timesStride;
				for (var i:int = 0; i < count; i++) {
					var index:int = i*valuesStride;
					var time:Number = times[i*timesStride];
					xTrack.addKey(time, values[index]);
					yTrack.addKey(time, values[index + 1]);
					zTrack.addKey(time, values[index + 2]);
				}
				return Vector.<Track>([xTrack, yTrack, zTrack]);
				// TODO:: Exceptions with indices
			}
			return null;
		}
	
	}
}
