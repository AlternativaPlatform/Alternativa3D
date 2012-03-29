/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.resources.ExternalTextureResource;

	/**
	 * @private
	 */
	public class DaeEffect extends DaeElement {
		
		public static var commonAlways:Boolean = false;
		
		use namespace collada;
	
		private var effectParams:Object;
		private var commonParams:Object;
		private var techniqueParams:Object;
	
		private var diffuse:DaeEffectParam;
		private var ambient:DaeEffectParam;
		private var transparent:DaeEffectParam;
		private var transparency:DaeEffectParam;
		private var bump:DaeEffectParam;
		private var reflective:DaeEffectParam;
		private var emission:DaeEffectParam;
		private var specular:DaeEffectParam;
	
		public function DaeEffect(data:XML, document:DaeDocument) {
			super(data, document);
	
			// image's are declared at <effect>
			constructImages();
		}
	
		private function constructImages():void {
			var list:XMLList = data..image;
			for each (var element:XML in list) {
				var image:DaeImage = new DaeImage(element, document);
				if (image.id != null) {
					document.images[image.id] = image;
				}
			}
		}
	
		override protected function parseImplementation():Boolean {
			var element:XML;
			var param:DaeParam;
			effectParams = new Object();
			for each (element in data.newparam) {
				param = new DaeParam(element, document);
				effectParams[param.sid] = param;
			}
			commonParams = new Object();
			for each (element in data.profile_COMMON.newparam) {
				param = new DaeParam(element, document);
				commonParams[param.sid] = param;
			}
			techniqueParams = new Object();
			var technique:XML = data.profile_COMMON.technique[0];
			if (technique != null) {
				for each (element in technique.newparam) {
					param = new DaeParam(element, document);
					techniqueParams[param.sid] = param;
				}
			}
			var shader:XML = data.profile_COMMON.technique.*.(localName() == "constant" || localName() == "lambert" || localName() == "phong" || localName() == "blinn")[0];
			if (shader != null) {
				var diffuseXML:XML = null;
				if (shader.localName() == "constant") {
					diffuseXML = shader.emission[0];
				} else {
					diffuseXML = shader.diffuse[0];
					var emissionXML:XML = shader.emission[0];
					if (emissionXML != null) {
						emission = new DaeEffectParam(emissionXML, this);
					}
				}
				if (diffuseXML != null) {
					diffuse = new DaeEffectParam(diffuseXML, this);
				}
				if (shader.localName() == "phong" || shader.localName() == "blinn") {
					var specularXML:XML = shader.specular[0];
					if (specularXML != null) {
						specular = new DaeEffectParam(specularXML, this);
					}
				}
				var transparentXML:XML = shader.transparent[0];
				if (transparentXML != null) {
					transparent = new DaeEffectParam(transparentXML, this);
				}
				var transparencyXML:XML = shader.transparency[0];
				if (transparencyXML != null) {
					transparency = new DaeEffectParam(transparencyXML, this);
				}
				var ambientXML:XML = shader.ambient[0];
				if(ambientXML != null) {
					ambient = new DaeEffectParam(ambientXML, this);
				}
				var reflectiveXML:XML = shader.reflective[0];
				if(reflectiveXML != null) {
					reflective = new DaeEffectParam(reflectiveXML, this);
				}
			}
			var bumpXML:XML = data.profile_COMMON.technique.extra.technique.(hasOwnProperty("@profile") && @profile == "OpenCOLLADA3dsMax").bump[0];
			if (bumpXML != null) {
				bump = new DaeEffectParam(bumpXML, this);
			}
			return true;
		}

		internal function getParam(name:String, setparams:Object):DaeParam {
			var param:DaeParam = setparams[name];
			if (param != null) {
				return param;
			}
			param = techniqueParams[name];
			if (param != null) {
				return param;
			}
			param = commonParams[name];
			if (param != null) {
				return param;
			}
			return effectParams[name];
		}
	
		private function float4ToUint(value:Array, alpha:Boolean = true):uint {
			var r:uint = (value[0] * 255);
			var g:uint = (value[1] * 255);
			var b:uint = (value[2] * 255);
			if (alpha) {
				var a:uint = (value[3] * 255);
				return (a << 24) | (r << 16) | (g << 8) | b;
			} else {
				return (r << 16) | (g << 8) | b;
			}
		}
	
		/**
		 * Returns material of the engine with given parameters.
		 * Call <code>parse()</code> before using.
		 */
		public function getMaterial(setparams:Object):ParserMaterial {
			if (diffuse != null) {
				var material:ParserMaterial = new ParserMaterial();
				if (diffuse) {
					pushMap(material, diffuse, setparams);
				}
				if (specular != null) {
					pushMap(material, specular, setparams);
				}
				
				if (emission != null) {
					pushMap(material, emission, setparams);
				}
				if (transparency != null) {
					material.transparency = transparency.getFloat(setparams);
				}
				if (transparent != null) {
					pushMap(material, transparent, setparams);
				}
				if (bump != null) {
					pushMap(material, bump, setparams);
				}
				if (ambient) {
					pushMap(material, ambient, setparams);	
				}
				if (reflective) {
					pushMap(material, reflective, setparams);
				}
				return material;
			}
			return null;
		}
		
		private function pushMap(material:ParserMaterial, param:DaeEffectParam, setparams:Object):void {
			var color:Array = param.getColor(setparams);
			
			if(color != null){
				material.colors[cloneString(param.data.localName())] = float4ToUint(color, true);
			}
			else {
				var image:DaeImage = param.getImage(setparams);
				if(image != null){
					material.textures[cloneString(param.data.localName())] = new ExternalTextureResource(cloneString(image.init_from));
				}
			}
		}

		/**
		 * Name of texture channel for main map of object.
		 * Call <code>parse()</code> before using.
		 */
		public function get mainTexCoords():String {
			var channel:String = null;
			channel = (channel == null && diffuse != null) ? diffuse.texCoord : channel;
			channel = (channel == null && transparent != null) ? transparent.texCoord : channel;
			channel = (channel == null && bump != null) ? bump.texCoord : channel;
			channel = (channel == null && emission != null) ? emission.texCoord : channel;
			channel = (channel == null && specular != null) ? specular.texCoord : channel;
			return channel;
		}

	}
}
