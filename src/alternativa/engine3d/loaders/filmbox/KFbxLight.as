package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: This node attribute contains methods for accessing the properties of a light..
	 */
	public class KFbxLight extends KFbxNodeAttribute {
		public var Color:Vector.<Number> = Vector.<Number>([1, 1, 1]);
		/** Percents? Blender uses 0..200 range. */
		public var Intensity:Number = 100;

		public function getIntensity():Number {
			return Intensity*1e-2;
		}


		/** Outer cone, degrees. */
		public var Coneangle:Number = 45;
		/** Inner cone, degrees. Blender does not write this value (hence -1 default). */
		public var HotSpot:Number = -1;

		/** 0 point, 1 directional, 2 spot, 3 blender hemi (?.. investigating), -1 ambient */
		public var LightType:Number = -1;

		/** 0 none, 1 linear, 2 quadratic, 3 cubic */
		public var DecayType:Number = 0;
		public var DecayStart:Number = 50;

		/* not supported by alternativa
		 //		public var EnableNearAttenuation:Number = 0;
		 public var NearAttenuationStart:Number = 0;
		 public var NearAttenuationEnd:Number = 0; */

		//		public var EnableFarAttenuation:Number = 0;
		public var FarAttenuationStart:Number = 0;
		public var FarAttenuationEnd:Number = 0;
	}
}
