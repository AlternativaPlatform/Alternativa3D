/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	import avmplus.getQualifiedClassName;

	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

	use namespace alternativa3d;

		/**
		 * A material which is assigned to each object that we got as a parsing result. This material should be treated as a debugging rather than a production one.
		 * It keeps links to all possible in Alternativa3D maps (such as light map or normal map) but can render only one of them as a diffuse like
		 * <code>TextureMaterial</code>. To make object that you get after parsing using all these maps you should create a new <code>StandardMaterial</code>
		 * and pass to them all textures. Then you can assign this material to the object.
		 * Since <code>ParserMaterial</code> sores only links to textures, you should worry about loading it. You can use <code>TexturesLoader</code> for.
		 * Can draws a Skin with no more than 41 Joints per surface. See Skin.divide() for more details.
		 *
		 * @see alternativa.engine3d.loaders.TexturesLoader
		 * @see alternativa.engine3d.materials
		 * @see alternativa.engine3d.objects.Skin#divide()
		 */
		public class ParserMaterial extends Material {
		/**
		 * List of colors, that can be assigned to each channel instead of texture. Variants: ambient, emission, diffuse, specular, shininess,  reflective, transparent, bump.
		 */
		public var colors:Object;
		/**
		 * List of <code>ExternalTextureResource</code>, that you can load with a <code>TexturesLoader</code>. Keys of objects are names of channels. Variants: ambient, emission, diffuse, specular, shininess,  reflective, transparent, bump.
		 *
		 * @see alternativa.engine3d.loaders.TexturesLoader
		 * @see alternativa.engine3d.resources.ExternalTextureResource
		 */
		public var textures:Object;
		/**
		 * Glossiness of material
		 */
		public var glossiness:Number = 0;
		/**
		 * Transparency of material
		 */
		public var transparency:Number = 0;
		/**
		 * Channel, that will be rendered. Possible options: ambient, emission, diffuse, specular, shininess,  reflective, transparent, bump.
	 	*/
		public var renderChannel:String = "diffuse";

		private var textureMaterial:TextureMaterial;
		private var fillMaterial:FillMaterial;

		public function ParserMaterial() {
			textures = {};
			colors = {};
		}

		/**
		 * @private 
		 */
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void {
			super.fillResources(resources, resourceType);
			for each(var texture:TextureResource in textures) {
				if (texture != null && A3DUtils.checkParent(getDefinitionByName(getQualifiedClassName(texture)) as Class, resourceType)) {
					resources[texture] = true;
				}

			}
		}

		/**
		 * @private 
		 */
		override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
			var colorO:Object = colors[renderChannel];
			var map:ExternalTextureResource;
			if (colorO != null) {
				if(fillMaterial == null) {
					fillMaterial = new FillMaterial(int(colorO));
				} else {
					fillMaterial.color = int(colorO);
				}
				fillMaterial.collectDraws(camera, surface, geometry, lights, lightsLength, false, objectRenderPriority);
			} else if ((map = textures[renderChannel]) != null) {
				if(textureMaterial == null) {
					textureMaterial = new TextureMaterial(map);
				} else {
					textureMaterial.diffuseMap = map;
				}
				textureMaterial.collectDraws(camera, surface, geometry, lights, lightsLength, false, objectRenderPriority);
			}
		}

	}
}
