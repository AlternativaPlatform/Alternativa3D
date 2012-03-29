/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	
	/**
	 * @private
	 */
	public class DaeParam extends DaeElement {
	
		use namespace collada;
	
		public function DaeParam(data:XML, document:DaeDocument) {
			super(data, document);
		}
	
		public function get ref():String {
			var attribute:XML = data.@ref[0];
			return (attribute == null) ? null : attribute.toString();
		}
	
		public function getFloat():Number {
			var floatXML:XML = data.float[0];
			if (floatXML != null) {
				return parseNumber(floatXML);
			}
			return NaN;
		}
	
		public function getFloat4():Array {
			var element:XML = data.float4[0];
			var components:Array;
			if (element == null) {
				element = data.float3[0];
				if (element != null) {
					components = parseNumbersArray(element);
					components[3] = 1.0;
				}
			} else {
				components = parseNumbersArray(element);
			}
			return components;
		}
	
		/**
		 * Returns Sid of a parameter  type of surface. Only for sampler2D and Collada ver. 1.4
		 */
		public function get surfaceSID():String {
			var element:XML = data.sampler2D.source[0];
			return (element == null) ? null : element.text().toString();
		}
	
		public function get wrap_s():String {
			var element:XML = data.sampler2D.wrap_s[0];
			return (element == null) ? null : element.text().toString();
		}
	
		public function get image():DaeImage {
			var surface:XML = data.surface[0];
			var image:DaeImage;
			if (surface != null) {
				// Collada 1.4
				var init_from:XML = surface.init_from[0];
				if (init_from == null) {
					// Error
					return null;
				}
				image = document.findImageByID(init_from.text().toString());
			} else {
				// Collada 1.5
				var imageIDXML:XML = data.instance_image.@url[0];
				if (imageIDXML == null) {
					// error
					return null;
				}
				image = document.findImage(imageIDXML);
			}
			return image;
		}
	
	}
}
