﻿/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.resources {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.utils.*;
	
	import flash.display.BitmapData;

	use namespace alternativa3d;

	public class ColorTextureResource extends BitmapTextureResource {

		public function ColorTextureResource(color:uint, size:Number=1) {
			super(new BitmapData(size, size, false, color));
		}
	}
}
