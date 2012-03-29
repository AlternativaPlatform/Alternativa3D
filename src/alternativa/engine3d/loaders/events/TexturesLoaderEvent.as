/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.events {

	import alternativa.engine3d.resources.ExternalTextureResource;

	import flash.display.BitmapData;
	import flash.events.Event;

	/**
	 * The Event is dispatched when  <code>TexturesLoader</code>  complete loading of  textures.
	 *
	 * @see alternativa.engine3d.loaders.TexturesLoader
	 */
	public class TexturesLoaderEvent extends Event {
		/**
		 * Value for <code>type</code> property .
		 */
		public static const COMPLETE:String = "complete";

		private var bitmapDatas:Vector.<BitmapData>;
		private var textures:Vector.<ExternalTextureResource>;

		public function TexturesLoaderEvent(type:String, bitmapDatas:Vector.<BitmapData>, textures:Vector.<ExternalTextureResource>) {
			this.bitmapDatas = bitmapDatas;
			this.textures = textures;
			super(type, false, false);
		}

		/**
		 * Returns the list of loaded images. Method returns the list only when method <code>TexturesLoader.loadResource()</code> is called
		 * and <code>TexturesLoader.loadResources()</code> with <code>needBitmapData</code> is set to <code>true</code>.
		 *
		 * @see alternativa.engine3d.loaders.TexturesLoader#loadResource()
		 * @see alternativa.engine3d.loaders.TexturesLoader#loadResources()
		 */
		public function getBitmapDatas():Vector.<BitmapData> {
			return bitmapDatas;
		}

		/**
		 * Returns the list of loaded textures. Method returns the list only when method <code>TexturesLoader.loadResource()</code> is called
		 * and <code>TexturesLoader.loadResources()</code> with <code>needBitmapData</code> is set to <code>true</code>.
		 *
		 * @see alternativa.engine3d.loaders.TexturesLoader#loadResource()
		 * @see alternativa.engine3d.loaders.TexturesLoader#loadResources()
		 * @see alternativa.engine3d.resources.ExternalTextureResource
		 */
		public function getTextures():Vector.<ExternalTextureResource> {
			return textures;
		}

		/**
		 * Returns copy of object.
		 */
		override public function clone():Event {
			return new TexturesLoaderEvent(type, bitmapDatas, textures);
		}

	}
}
