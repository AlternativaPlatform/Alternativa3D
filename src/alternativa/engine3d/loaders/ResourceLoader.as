/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.ExternalTextureResource;

	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class ResourceLoader extends EventDispatcher {

		private var loadSequence:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();
		private var context:Context3D;
		private var currentIndex:int = 0;
		public var generateMips:Boolean = true;

		private static const atfRegExp:RegExp = new RegExp(/\.atf/i);

		public function ResourceLoader(generateMips:Boolean = true) {
			this.generateMips = generateMips;
		}

		public function addResource(resource:ExternalTextureResource):void {
			loadSequence.push(resource);
		}

		public function addResources(resources:Vector.<ExternalTextureResource>):void {
			for each (var resource:ExternalTextureResource in resources) {
				loadSequence.push(resource);
			}
		}

		public function load(context:Context3D):void {
			this.context = context;
			currentIndex = 0;
			loadNext();
		}

		private function loadNext():void {

			if (currentIndex < loadSequence.length) {
				var currentResource:ExternalTextureResource = loadSequence[currentIndex];
				if (currentResource.url.match(atfRegExp)) {
					var atfLoader:URLLoader = new URLLoader();
					atfLoader.dataFormat = URLLoaderDataFormat.BINARY;
					atfLoader.addEventListener(Event.COMPLETE, onATFComplete);
					atfLoader.addEventListener(IOErrorEvent.IO_ERROR, onFailed);
					atfLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFailed);
					atfLoader.load(new URLRequest(currentResource.url));
				} else {
					var bitmapLoader:Loader = new Loader();
					bitmapLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapLoaded);
					bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, onFailed);
					bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFailed);
					bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, onFailed);
					bitmapLoader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, onFailed);
					bitmapLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFailed);
					bitmapLoader.load(new URLRequest(currentResource.url));
				}
			} else {
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}

		private function getNearPowerOf2For(size:Number):Number {
			if (size && (size - 1)) {
				for (var i:int = 11; i > 0; i--) {
					if (size >= (1 << i)) {
						return 1 << i;
					}
				}
				return 0;
			} else {
				return size;
			}
		}

		private function fitTextureToSizeLimits(textureData:BitmapData):BitmapData {
			var fittedTextureData:BitmapData = textureData;
			var width:Number, height:Number;
			width = getNearPowerOf2For(fittedTextureData.width);
			height = getNearPowerOf2For(fittedTextureData.height);
			if (width != fittedTextureData.width || height != fittedTextureData.height) {
				var newBitmap:BitmapData = new BitmapData(width, height,
						fittedTextureData.transparent);
				var matrix:Matrix = new Matrix(width/fittedTextureData.width, 0, 0,
						height/fittedTextureData.height);
				newBitmap.draw(fittedTextureData, matrix);
				fittedTextureData = newBitmap;
			}
			return fittedTextureData;
		}

		private function onBitmapLoaded(e:Event):void {
			var resized:BitmapData = fitTextureToSizeLimits(e.target.content.bitmapData);
			var texture:Texture = context.createTexture(resized.width, resized.height, Context3DTextureFormat.BGRA, false);
			texture.uploadFromBitmapData(resized, 0);
			if (generateMips) {
				BitmapTextureResource.createMips(texture, resized);
			}

			var currentResource:ExternalTextureResource = loadSequence[currentIndex];
			currentResource.data = texture;
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS));
			currentIndex++;
			loadNext();
		}

		private function onFailed(e:Event):void {
			trace("Failed to load texture :", loadSequence[currentIndex].url);
			//dispatchEvent(e);
			currentIndex++;
			loadNext();
		}

		private function onATFComplete(e:Event):void {
			var value:ByteArray = e.target.data;
			value.endian = Endian.LITTLE_ENDIAN;
			value.position = 6;
			var texture:TextureBase
			var type:uint = value.readByte();
			var format:String;
			switch (type & 0x7F) {
				case 0:
					format = Context3DTextureFormat.BGRA;
					break;
				case 1:
					format = Context3DTextureFormat.BGRA;
					break;
				case 2:
					format = Context3DTextureFormat.COMPRESSED;
					break;
			}

			if ((type & ~0x7F) == 0) {
				texture = context.createTexture(1 << value.readByte(), 1 << value.readByte(), format, false);
				texture.addEventListener("textureReady", onTextureUploaded);
				Texture(texture).uploadCompressedTextureFromByteArray(value, 0, true);
			} else {
				texture = context.createCubeTexture(1 << value.readByte(), format, false);
				texture.addEventListener("textureReady", onTextureUploaded);
				CubeTexture(texture).uploadCompressedTextureFromByteArray(value, 0, true)
			}
		}

		private function onTextureUploaded(e:Event):void {
			var currentResource:ExternalTextureResource = loadSequence[currentIndex];
			currentResource.data = TextureBase(e.target);
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS));
			currentIndex++;
			loadNext();
		}

	}
}
