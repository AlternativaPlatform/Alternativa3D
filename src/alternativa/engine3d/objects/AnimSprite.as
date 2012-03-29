/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;

	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Animated sprite. Instances of <code>Material</code> use as frames for animation. Playing the animation can be done through changing <code>frame</code> property.
	 * I. e.
     * <code>animSprite.frame++;</code><br />
     * <code>camera.render(context3D)</code><br />
	 */
	public class AnimSprite extends Sprite3D {
		private var _materials:Vector.<Material>;
		private var _frame:int = 0;
		private var _loop:Boolean = false;

		/**
		 * Creates a new AnimSprite instance.
		 * @param width Width.
		 * @param height Height.
		 * @param materials List of  materials.
		 * @param loop If <code>true</code>, Loops animation.
		 * @param frame Current frame.
		 * @see alternativa.engine3d.materials.Material
		 */
		public function AnimSprite(width:Number, height:Number, materials:Vector.<Material> = null, loop:Boolean = false, frame:int = 0) {
			super(width, height);
			_materials = materials;
			_loop = loop;
			this.frame = frame;
		}

		/**
		 * List of  materials.
		 */
		public function get materials():Vector.<Material> {
			return _materials;
		}

		/**
		 * @private
		 */
		public function set materials(value:Vector.<Material>):void {
			_materials = value;
			if (value != null) {
				frame = _frame;
			} else {
				material = null;
			}
		}

		/**
		 *  In case of <code>true</code>, when <code>frame</code>  takes    value greater than length of materials list, it switches to begin.
		 *  Otherwise the value of <code>frame</code> property will equal <code>materials.length-1</code> after setting greater value.
		 * @see #frame
		 * @see #materials
		 */
		public function get loop():Boolean {
			return _loop;
		}

		/**
		 * @private
		 */
		public function set loop(value:Boolean):void {
			_loop = value;
			frame = _frame;
		}

		/**
		 *  Current frame of animation.  While rendering, the material to draw AnimSprite will taken from materials list according to value of this property.
		 * @see #loop
		 * @see #materials
		 */
		public function get frame():int {
			return _frame;
		}

		/**
		 * @private
		 */
		public function set frame(value:int):void {
			_frame = value;
			if (_materials != null) {
				var materialsLength:int = _materials.length;
				var index:int = _frame;
				if (_frame < 0) {
					var mod:int = _frame%materialsLength;
					index = (_loop && mod != 0) ? (mod + materialsLength) : 0;
				} else if (_frame > materialsLength - 1) {
					index = _loop ? (_frame%materialsLength) : (materialsLength - 1);
				}
				material = _materials[index];
			}
		}

		/**
		 * @private
		 */
		alternativa3d override function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (materials != null) {
				for each (var material:Material in materials) {
					if (material != null) material.fillResources(resources, resourceType);
				}
			}
			super.fillResources(resources, hierarchy, resourceType);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:AnimSprite = new AnimSprite(width, height);
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var src:AnimSprite = source as AnimSprite;
			_materials = src._materials;
			_loop = src._loop;
			_frame = src._frame;
		}
	}
}
