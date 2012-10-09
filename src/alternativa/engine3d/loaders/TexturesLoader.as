/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.loaders.events.TexturesLoaderEvent;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.ExternalTextureResource;

	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * Dispatches after complete loading of all textures.
	 * @eventType flash.events.TexturesLoaderEvent.COMPLETE
	 */
	[Event(name="complete",type="alternativa.engine3d.loaders.events.TexturesLoaderEvent")]

	/**
	 * An object that downloads textures by their reference and upload them into the <code>Context3D</code>
	 */
	public class TexturesLoader extends EventDispatcher {

		/**
		 * A <code>Context3D</code> to which resources wil be loaded.
		 */
		public var context:Context3D;

		private var textures:Object = {};
		private var bitmapDatas:Object = {};
		private var byteArrays:Object = {};

		private var currentBitmapDatas:Vector.<BitmapData>;
		private var currentUrl:String;

		private var resources:Vector.<ExternalTextureResource>;
		private var counter:int = 0;
		private var createTexture3D:Boolean;
		private var needBitmapData:Boolean;

		private var loaderCompressed:URLLoader;
		private var isATF:Boolean;
		private var atfRegExp:RegExp = new RegExp(/\.atf/i);

		/**
		 * Creates a new TexturesLoader instance.
		 * @param context – A <code>Context3D</code> to which resources wil be loaded.
		 */
		public function TexturesLoader(context:Context3D) {
			this.context = context;
		}

		/**
		 * @private
		 */
		public function getTexture(url:String):TextureBase {
			return textures[url];
		}

		private function loadCompressed(url:String):void {
			loaderCompressed = new URLLoader();
			loaderCompressed.dataFormat = URLLoaderDataFormat.BINARY;
			loaderCompressed.addEventListener(Event.COMPLETE, loadNext);
			loaderCompressed.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
			loaderCompressed.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
			loaderCompressed.load(new URLRequest(url));
		}

		/**
		 * Loads a resource.
		 * @param resource
		 * @param createTexture3D Create texture on uploading
		 * @param needBitmapData If <code>true</code>, keeps <code>BitmapData</code> after uploading textures into a context.
		 */
		public function loadResource(resource:ExternalTextureResource, createTexture3D:Boolean = true, needBitmapData:Boolean = true):void {
			if (resources != null) {
				throw new Error("Cannot start new load while loading");
			}
			this.createTexture3D = createTexture3D;
			this.needBitmapData = needBitmapData;
			resources = Vector.<ExternalTextureResource>([resource]);
			currentBitmapDatas = new Vector.<BitmapData>(1);
			//currentTextures3D = new Vector.<Texture>(1);
			loadNext();
		}

		/**
		 * Loads list of textures
		 * @param resources   List of <code>ExternalTextureResource</code> each of them has link to texture file which needs to be downloaded.
		 * @param createTexture3D Create texture on uploading.
		 * @param needBitmapData If <code>true</code>, keeps <code>BitmapData</code> after uploading textures into a context.
		 */
		public function loadResources(resources:Vector.<ExternalTextureResource>, createTexture3D:Boolean = true, needBitmapData:Boolean = true):void {
			if (this.resources != null) {
				throw new Error("Cannot start new load while loading");
			}
			this.createTexture3D = createTexture3D;
			this.needBitmapData = needBitmapData;
			this.resources = resources;
			currentBitmapDatas = new Vector.<BitmapData>(resources.length);
			loadNext();
		}

		/**
		 * Clears links to all data stored in this <code>TexturesLoader</code> instance. (List of downloaded textures)
		 */
		public function clean():void {
			if (resources != null) {
				throw new Error("Cannot clean while loading");
			}
			textures = {};
			bitmapDatas = {};
		}

		/**
		 * Clears links to all data stored in this <code>TexturesLoader</code> instance and removes it from the context.
		 */
		public function cleanAndDispose():void {
			if (resources != null) {
				throw new Error("Cannot clean while loading");
			}
			textures = {};
			for each (var b:BitmapData in bitmapDatas) {
				b.dispose();
			}
			bitmapDatas = {};
		}

		/**
		 * Removes texture resources from <code>Context3D</code>.
		 * @param urls List of links to resources, that should be removed.
		 */
		public function dispose(urls:Vector.<String>):void {
			for (var i:int = 0; i < urls.length; i++) {
				var url:String = urls[i];
				var bmd:BitmapData = bitmapDatas[url] as BitmapData;
				//if (bmd) {
				delete bitmapDatas[url];
				bmd.dispose();
				//}
			}
		}

		private function loadNext(e:Event = null):void {
//			trace("[NEXT]", e);
			var bitmapData:BitmapData;
			var byteArray:ByteArray;
			var texture3D:TextureBase;

			if (e != null && !(e is ErrorEvent)) {
				if (isATF) {
					byteArray = e.target.data;
					byteArrays[currentUrl] = byteArray;
					try {
						texture3D = addCompressedTexture(byteArray);
						resources[counter - 1].data = texture3D;
					} catch (err:Error) {
						//					throw new Error("loadNext:: " + err.message  + " " + currentUrl);
						trace("loadNext:: " + err.message + " " + currentUrl);
					}
				} else {
					bitmapData = e.target.content.bitmapData;
					bitmapDatas[currentUrl] = bitmapData;
					currentBitmapDatas[counter - 1] = bitmapData;
					if (createTexture3D) {
						try {
							texture3D = addTexture(bitmapData);
							resources[counter - 1].data = texture3D;
						} catch (err:Error) {
							throw new Error("loadNext:: " + err.message + " " + currentUrl);
						}
					}
					if (!needBitmapData) {
						bitmapData.dispose();
					}
				}
				resources[counter - 1].data = texture3D;
			} else if (e is ErrorEvent) {
				trace("Missing: " + currentUrl);
			}

			if (counter < resources.length) {
				currentUrl = resources[counter++].url;
				if (currentUrl != null) {
					atfRegExp.lastIndex = currentUrl.lastIndexOf(".");
					isATF = currentUrl.match(atfRegExp) != null;
				}

				if (isATF) {
					if (createTexture3D) {
						texture3D = textures[currentUrl];
						if (texture3D == null) {
							byteArray = byteArrays[currentUrl];
							if (byteArray) {
								texture3D = addCompressedTexture(byteArray);
								resources[counter - 1].data = texture3D;
								//bitmapDatas[currentUrl] = bitmapData;
								loadNext();
							} else {
								loadCompressed(currentUrl);
							}
						} else {
							resources[counter - 1].data = texture3D;
							loadNext();
						}
					}
				} else {
					if (needBitmapData) {
						bitmapData = bitmapDatas[currentUrl];
						if (bitmapData) {
							currentBitmapDatas[counter - 1] = bitmapData;
							if (createTexture3D) {
								texture3D = textures[currentUrl];
								if (texture3D == null) {
									texture3D = addTexture(bitmapData);
								}
								resources[counter - 1].data = texture3D;
							}
							loadNext();
						} else {
							load(currentUrl);
						}
					} else if (createTexture3D) {
						texture3D = textures[currentUrl];
						if (texture3D == null) {
							bitmapData = bitmapDatas[currentUrl];
							if (bitmapData) {
								texture3D = addTexture(bitmapData);
								resources[counter - 1].data = texture3D;
								loadNext();
							} else {
								load(currentUrl);
							}
						} else {
							resources[counter - 1].data = texture3D;
							loadNext();
						}
					}
				}
			} else {
				onTexturesLoad();
			}
		}

		private function load(url:String):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
			loader.load(new URLRequest(url));
		}

		private function onTexturesLoad():void {
//			trace("[LOADED]");
			counter = 0;
			var bmds:Vector.<BitmapData> = currentBitmapDatas;
			var reses:Vector.<ExternalTextureResource> = resources;
			currentBitmapDatas = null;
			resources = null;
			dispatchEvent(new TexturesLoaderEvent(TexturesLoaderEvent.COMPLETE, bmds, reses));
		}

		private function addTexture(value:BitmapData):Texture {
			var texture:Texture = context.createTexture(value.width, value.height, Context3DTextureFormat.BGRA, false);
			texture.uploadFromBitmapData(value, 0);
			BitmapTextureResource.createMips(texture, value);
			textures[currentUrl] = texture;
			return texture;
		}

		private function addCompressedTexture(value:ByteArray):TextureBase {
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
				Texture(texture).uploadCompressedTextureFromByteArray(value, 0);
			} else {
				texture = context.createCubeTexture(1 << value.readByte(), format, false);
				CubeTexture(texture).uploadCompressedTextureFromByteArray(value, 0)
			}
			textures[currentUrl] = texture;
			return texture;
		}

	}
}
