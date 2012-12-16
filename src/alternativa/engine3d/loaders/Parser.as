/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.core.Object3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Base class for classes, that perform parsing of scenes of different formats.
	 */
	public class Parser {

		/**
		 * List of root objects. Root objects are objects, that have no parents.
		 * @see alternativa.engine3d.core.Object3D
		 */
		public var hierarchy:Vector.<Object3D>;
		/**
		 * List of objects, that are got after parsing.
		 * @see alternativa.engine3d.core.Object3D
		 */
		public var objects:Vector.<Object3D>;

		/**
		 * Array of animations.
		 */
		public var animations:Vector.<AnimationClip>;

		/**
		 * List of all materials assigned to objects, that are got after parsing.
		 * @see alternativa.engine3d.loaders.ParserMaterial
		 */
		public var materials:Vector.<ParserMaterial>;


		/**
		 * @private
		 */
		alternativa3d var layersMap:Dictionary;
        /**
         * @private
         */
		alternativa3d var layers:Vector.<String>;
        /**
         * @private
         */
		alternativa3d var compressedBuffers:Boolean = false;


		/**
		 * Returns object from array <code>objects</code> by name.
		 */
		public function getObjectByName(name:String):Object3D {
			for each (var object:Object3D in objects) {
				if (object.name == name) return object;
			}
			return null;
		}

		/**
		 * Returns name of layer for specified object.
		 */
		public function getLayerByObject(object:Object3D):String {
			return layersMap[object];
		}

		/**
		 * Erases all links to external objects.
		 */
		public function clean():void {
			hierarchy = null;
			objects = null;
			materials = null;
			animations = null;
			layersMap = null;
		}

		/**
		 * @private
		 */
		alternativa3d function init():void {
			hierarchy = new Vector.<Object3D>();
			objects = new Vector.<Object3D>();
			materials = new Vector.<ParserMaterial>();
			animations = new Vector.<AnimationClip>();
			layersMap = new Dictionary(true);
		}
	}
}
