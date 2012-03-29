/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {
	
	/**
	 * @private 
	 */
	public class CullingPlane {
		
		public var x:Number;
		public var y:Number;
		public var z:Number;
		public var offset:Number;
		
		public var next:CullingPlane;
		
		static public var collector:CullingPlane;
	
		static public function create():CullingPlane {
			if (collector != null) {
				var res:CullingPlane = collector;
				collector = res.next;
				res.next = null;
				return res;
			} else {
				return new CullingPlane();
			}
		}
	
		public function create():CullingPlane {
			if (collector != null) {
				var res:CullingPlane = collector;
				collector = res.next;
				res.next = null;
				return res;
			} else {
				return new CullingPlane();
			}
		}
		
	}
}
