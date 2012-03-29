/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.effects {

	import alternativa.engine3d.resources.TextureResource;

	/**
	 * @private
	 */
	public class TextureAtlas {
		
		public var diffuse:TextureResource;
		public var opacity:TextureResource;
		public var columnsCount:int;
		public var rowsCount:int;
		public var rangeBegin:int;
		public var rangeLength:int;
		public var fps:int;
		public var loop:Boolean;
		public var originX:Number;
		public var originY:Number;
		
		public function TextureAtlas(diffuse:TextureResource, opacity:TextureResource = null, columnsCount:int = 1, rowsCount:int = 1, rangeBegin:int = 0, rangeLength:int = 1, fps:int = 30, loop:Boolean = false, originX:Number = 0.5, originY:Number = 0.5) {
			this.diffuse = diffuse;
			this.opacity = opacity;
			this.columnsCount = columnsCount;
			this.rowsCount = rowsCount;
			this.rangeBegin = rangeBegin;
			this.rangeLength = rangeLength;
			this.fps = fps;
			this.loop = loop;
			this.originX = originX;
			this.originY = originY;
		}

	}
}
