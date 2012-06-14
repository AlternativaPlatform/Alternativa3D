/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.lights {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;

	use namespace alternativa3d;

	/**
	 * OmniLight is an attenuated light source placed at one point and spreads outward in all directions.
	 *
	 */
	public class OmniLight extends Light3D {

		/**
		 * Distance from which falloff starts.
		 */
		public var attenuationBegin:Number;

		/**
		 * Distance from at which falloff is complete.
		 */
		public var attenuationEnd:Number;

		/**
		 * Creates a OmniLight object.
		 * @param color Light color.
		 * @param attenuationBegin Distance from which falloff starts.
		 * @param attenuationEnd Distance from at which falloff is complete.
		 */
		public function OmniLight(color:uint, attenuationBegin:Number, attenuationEnd:Number) {
			this.type = OMNI;
			this.color = color;
			this.attenuationBegin = attenuationBegin;
			this.attenuationEnd = attenuationEnd;
			calculateBoundBox();
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (transform != null) {

			} else {
				if (-attenuationEnd < boundBox.minX) boundBox.minX = -attenuationEnd;
				if (attenuationEnd > boundBox.maxX) boundBox.maxX = attenuationEnd;
				if (-attenuationEnd < boundBox.minY) boundBox.minY = -attenuationEnd;
				if (attenuationEnd > boundBox.maxY) boundBox.maxY = attenuationEnd;
				if (-attenuationEnd < boundBox.minZ) boundBox.minZ = -attenuationEnd;
				if (attenuationEnd > boundBox.maxZ) boundBox.maxZ = attenuationEnd;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function checkBound(targetObject:Object3D):Boolean {
			var rScale:Number = Math.sqrt(lightToObjectTransform.a*lightToObjectTransform.a + lightToObjectTransform.e*lightToObjectTransform.e + lightToObjectTransform.i*lightToObjectTransform.i);
			rScale += Math.sqrt(lightToObjectTransform.b*lightToObjectTransform.b + lightToObjectTransform.f*lightToObjectTransform.f + lightToObjectTransform.j*lightToObjectTransform.j);
			rScale += Math.sqrt(lightToObjectTransform.c*lightToObjectTransform.c + lightToObjectTransform.g*lightToObjectTransform.g + lightToObjectTransform.k*lightToObjectTransform.k);
			rScale /= 3;
			rScale *= attenuationEnd;
			rScale *= rScale;
			var len:Number = 0;
			var bb:BoundBox = targetObject.boundBox;
			var minX:Number = bb.minX;
			var minY:Number = bb.minY;
			var minZ:Number = bb.minZ;
			var maxX:Number = bb.maxX;
			var px:Number = lightToObjectTransform.d;
			var py:Number = lightToObjectTransform.h;
			var pz:Number = lightToObjectTransform.l;

			var maxY:Number = bb.maxY;
			var maxZ:Number = bb.maxZ;
			if (px < minX) {
				if (py < minY) {
					if (pz < minZ) {
						len = (minX - px)*(minX - px) + (minY - py)*(minY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (minX - px)*(minX - px) + (minY - py)*(minY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (minX - px)*(minX - px) + (minY - py)*(minY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py < maxY) {
					if (pz < minZ) {
						len = (minX - px)*(minX - px) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (minX - px)*(minX - px);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (minX - px)*(minX - px) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py > maxY) {
					if (pz < minZ) {
						len = (minX - px)*(minX - px) + (maxY - py)*(maxY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (minX - px)*(minX - px) + (maxY - py)*(maxY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (minX - px)*(minX - px) + (maxY - py)*(maxY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				}
			} else if (px < maxX) {
				if (py < minY) {
					if (pz < minZ) {
						len = (minY - py)*(minY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (minY - py)*(minY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (minY - py)*(minY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py < maxY) {
					if (pz < minZ) {
						len = (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						return true;
					} else if (pz > maxZ) {
						len = (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py > maxY) {
					if (pz < minZ) {
						len = (maxY - py)*(maxY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (maxY - py)*(maxY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (maxY - py)*(maxY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				}
			} else if (px > maxX) {
				if (py < minY) {
					if (pz < minZ) {
						len = (maxX - px)*(maxX - px) + (minY - py)*(minY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (maxX - px)*(maxX - px) + (minY - py)*(minY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (maxX - px)*(maxX - px) + (minY - py)*(minY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py < maxY) {
					if (pz < minZ) {
						len = (maxX - px)*(maxX - px) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (maxX - px)*(maxX - px);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (maxX - px)*(maxX - px) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				} else if (py > maxY) {
					if (pz < minZ) {
						len = (maxX - px)*(maxX - px) + (maxY - py)*(maxY - py) + (minZ - pz)*(minZ - pz);
						return len < rScale;
					} else if (pz < maxZ) {
						len = (maxX - px)*(maxX - px) + (maxY - py)*(maxY - py);
						return len < rScale;
					} else if (pz > maxZ) {
						len = (maxX - px)*(maxX - px) + (maxY - py)*(maxY - py) + (maxZ - pz)*(maxZ - pz);
						return len < rScale;
					}
				}
			}
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:OmniLight = new OmniLight(color, attenuationBegin, attenuationEnd);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
