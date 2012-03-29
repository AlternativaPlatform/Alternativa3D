/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.keys.NumberKey;
	import alternativa.engine3d.animation.keys.NumberTrack;
	import alternativa.engine3d.animation.keys.Track;

	use namespace alternativa3d;
	/**
	 * @private
	 */
	public class DaeChannel extends DaeElement {
	
		static public const PARAM_UNDEFINED:String = "undefined";
		static public const PARAM_TRANSLATE_X:String = "x";
		static public const PARAM_TRANSLATE_Y:String = "y";
		static public const PARAM_TRANSLATE_Z:String = "z";
		static public const PARAM_SCALE_X:String = "scaleX";
		static public const PARAM_SCALE_Y:String = "scaleY";
		static public const PARAM_SCALE_Z:String = "scaleZ";
		static public const PARAM_ROTATION_X:String = "rotationX";
		static public const PARAM_ROTATION_Y:String = "rotationY";
		static public const PARAM_ROTATION_Z:String = "rotationZ";
		static public const PARAM_TRANSLATE:String = "translate";
		static public const PARAM_SCALE:String = "scale";
		static public const PARAM_MATRIX:String = "matrix";
	
		/**
		 * Animation track with keys.
		 * Call <code>parse()</code> before using.
		 */
		public var tracks:Vector.<Track>;

		/**
		 * Type of animated parameter. It can be one of DaeChannel.PARAM_*. values.
		 * * Call <code>parse()</code> before using.
		 */
		public var animatedParam:String = PARAM_UNDEFINED;
		/**
		 * Key of animated object.
		 */
		public var animName:String;
	
		public function DaeChannel(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		/**
		 * Returns a node  for  which the animation is destined.
		 */
		public function get node():DaeNode {
			var targetXML:XML = data.@target[0];
			if (targetXML != null) {
				var targetParts:Array = targetXML.toString().split("/");
				// First part of item id
				var node:DaeNode = document.findNodeByID(targetParts[0]);
				if (node != null) {
					// Last part is transformed item
					targetParts.pop();
					for (var i:int = 1, count:int = targetParts.length; i < count; i++) {
						var sid:String = targetParts[i];
						node = node.getNodeBySid(sid);
						if (node == null) {
							return null;
						}
					}
					return node;
				}
			}
			return null;
		}
	
		override protected function parseImplementation():Boolean {
			parseTransformationType();
			parseSampler();
			return true;
		}
	
		private function parseTransformationType():void {
			var targetXML:XML = data.@target[0];
			if (targetXML == null) return;
	
			// Split the path on parts
			var targetParts:Array = targetXML.toString().split("/");
			var sid:String = targetParts.pop();
			var sidParts:Array = sid.split(".");
			var sidPartsCount:int = sidParts.length;
	
			//Define the type of property
			var transformationXML:XML;
			var node:DaeNode = this.node;
			if (node == null) {
				return;
			}
			animName = node.animName;
			var children:XMLList = node.data.children();
			for (var i:int = 0, count:int = children.length(); i < count; i++) {
				var child:XML = children[i];
				var attr:XML = child.@sid[0];
				if (attr != null && attr.toString() == sidParts[0]) {
					transformationXML = child;
					break;
				}
			}
			// TODO:: case with brackets (just in case)
			var transformationName:String = (transformationXML != null) ? transformationXML.localName() as String : null;
			if (sidPartsCount > 1) {
				var componentName:String = sidParts[1];
				switch (transformationName) {
					case "translate":
						switch (componentName) {
							case "X":
								animatedParam = PARAM_TRANSLATE_X;
								break;
							case "Y":
								animatedParam = PARAM_TRANSLATE_Y;
								break;
							case "Z":
								animatedParam = PARAM_TRANSLATE_Z;
								break;
						}
						break;
					case "rotate": {
						var axis:Array = parseNumbersArray(transformationXML);
						// TODO:: look for the maximum value
						switch (axis.indexOf(1)) {
							case 0:
								animatedParam = PARAM_ROTATION_X;
								break;
							case 1:
								animatedParam = PARAM_ROTATION_Y;
								break;
							case 2:
								animatedParam = PARAM_ROTATION_Z;
								break;
						}
						break;
					}
					case "scale":
						switch (componentName) {
							case "X":
								animatedParam = PARAM_SCALE_X;
								break;
							case "Y":
								animatedParam = PARAM_SCALE_Y;
								break;
							case "Z":
								animatedParam = PARAM_SCALE_Z;
								break;
						}
						break;
				}
			} else {
				switch (transformationName) {
					case "translate":
						animatedParam = PARAM_TRANSLATE;
						break;
					case "scale":
						animatedParam = PARAM_SCALE;
						break;
					case "matrix":
						animatedParam = PARAM_MATRIX;
						break;
				}
			}
		}

		private function parseSampler():void {
			var sampler:DaeSampler = document.findSampler(data.@source[0]);
			if (sampler != null) {
				sampler.parse();
				if (animatedParam == PARAM_MATRIX) {
					tracks = Vector.<Track>([sampler.parseTransformationTrack(animName)]);
					return;
				}
				if (animatedParam == PARAM_TRANSLATE) {
					tracks = sampler.parsePointsTracks(animName, "x", "y", "z");
					return;
				}
 				if (animatedParam == PARAM_SCALE) {
					tracks = sampler.parsePointsTracks(animName, "scaleX", "scaleY", "scaleZ");
					return;
 				}
				if (animatedParam == PARAM_ROTATION_X || animatedParam == PARAM_ROTATION_Y || animatedParam == PARAM_ROTATION_Z) {
					var track:NumberTrack = sampler.parseNumbersTrack(animName, animatedParam);
					// Convert degrees to radians
					var toRad:Number = Math.PI/180;
					for (var key:NumberKey = track.keyList; key != null; key = key.next) {
						key._value *= toRad;
					}
					tracks = Vector.<Track>([track]);
					return;
				}
				if (animatedParam == PARAM_TRANSLATE_X || animatedParam == PARAM_TRANSLATE_Y || animatedParam == PARAM_TRANSLATE_Z || animatedParam == PARAM_SCALE_X || animatedParam == PARAM_SCALE_Y || animatedParam == PARAM_SCALE_Z) {
					tracks = Vector.<Track>([sampler.parseNumbersTrack(animName, animatedParam)]);
				}
			} else {
				document.logger.logNotFoundError(data.@source[0]);
			}
		}

	}
}
