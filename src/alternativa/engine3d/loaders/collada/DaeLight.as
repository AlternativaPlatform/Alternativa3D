/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {

	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.SpotLight;

	/**
	 * @private 
	 */
	public class DaeLight extends DaeElement {

		use namespace collada;

		public function DaeLight(data:XML, document:DaeDocument) {
			super(data, document);
		}

		private function float4ToUint(value:Array):uint {
			var r:uint = (value[0] * 255);
			var g:uint = (value[1] * 255);
			var b:uint = (value[2] * 255);
			return (r << 16) | (g << 8) | b | 0xFF000000;
		}

		public function get revertDirection():Boolean {
			var info:XML = data.technique_common.children()[0];
			return (info == null) ? false : (info.localName() == "directional" || info.localName() == "spot");
		}

		public function parseLight():Light3D { 
			var info:XML = data.technique_common.children()[0];
			var extra:XML = data.extra.technique.(@profile[0] == "OpenCOLLADA3dsMax").light[0];
			var light:Light3D = null;
			if (info != null) {
				var color:uint = float4ToUint(parseNumbersArray(info.color[0]));
				var constantAttenuationXML:XML;
				var linearAttenuationXML:XML;
				var linearAttenuation:Number = 0;
				var attenuationStart:Number = 0;
				var attenuationEnd:Number = 1;
				switch (info.localName()) {
					case "ambient":
						light = new AmbientLight(color);
						break;
					case "directional":
						var dLight:DirectionalLight = new DirectionalLight(color);
						light = dLight;
						break;
					case "point":
						if (extra != null) {
							attenuationStart = parseNumber(extra.attenuation_far_start[0]);
							attenuationEnd = parseNumber(extra.attenuation_far_end[0]);
						} else {
							constantAttenuationXML = info.constant_attenuation[0];
							linearAttenuationXML = info.linear_attenuation[0];
							if (constantAttenuationXML != null) {
								attenuationStart = -parseNumber(constantAttenuationXML);
							}
							if (linearAttenuationXML != null) {
								linearAttenuation = parseNumber(linearAttenuationXML);
							}
							if (linearAttenuation > 0) {
								attenuationEnd = 1/linearAttenuation + attenuationStart;
							} else {
								attenuationEnd = attenuationStart + 1;
							}
						}
						var oLight:OmniLight = new OmniLight(color, attenuationStart, attenuationEnd);
						light = oLight;
						break;
					case "spot":
						var hotspot:Number = 0;
						var fallof:Number = Math.PI/4;
						const DEG2RAD:Number = Math.PI/180;
						if (extra != null) {
							attenuationStart = parseNumber(extra.attenuation_far_start[0]);
							attenuationEnd = parseNumber(extra.attenuation_far_end[0]);
							hotspot = DEG2RAD * parseNumber(extra.hotspot_beam[0]);
							fallof = DEG2RAD * parseNumber(extra.falloff[0]);
						} else {
							constantAttenuationXML = info.constant_attenuation[0];
							linearAttenuationXML = info.linear_attenuation[0];
							if (constantAttenuationXML != null) {
								attenuationStart = -parseNumber(constantAttenuationXML);
							}
							if (linearAttenuationXML != null) {
								linearAttenuation = parseNumber(linearAttenuationXML);
							}
							if (linearAttenuation > 0) {
								attenuationEnd = 1/linearAttenuation + attenuationStart;
							} else {
								attenuationEnd = attenuationStart + 1;
							}
						}
						var sLight:SpotLight = new SpotLight(color, attenuationStart, attenuationEnd, hotspot, fallof);
						light = sLight;
						break;
				}
			}
			if (extra != null) {
				light.intensity = parseNumber(extra.multiplier[0]);
			}
			return light;
		}

	}
}
