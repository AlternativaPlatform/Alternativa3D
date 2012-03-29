/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.effects {

	import flash.display3D.textures.TextureBase;

	/**
	 * @private
	 */
	public class Particle {
		
		public var diffuse:TextureBase;
		public var opacity:TextureBase;
		public var blendSource:String;
		public var blendDestination:String;
		
		public var x:Number;
		public var y:Number;
		public var z:Number;
		public var rotation:Number;
		
		public var width:Number;
		public var height:Number;
		public var originX:Number;
		public var originY:Number;
		
		public var uvScaleX:Number;
		public var uvScaleY:Number;
		public var uvOffsetX:Number;
		public var uvOffsetY:Number;
		
		public var red:Number;
		public var green:Number;
		public var blue:Number;
		public var alpha:Number;
		
		public var next:Particle;
		
		static public var collector:Particle;
	
		static public function create():Particle {
			var res:Particle;
			if (collector != null) {
				res = collector;
				collector = collector.next;
				res.next = null;
			} else {
				//trace("new Particle");
				res = new Particle();
			}
			return res;
		}
		
	}
}
