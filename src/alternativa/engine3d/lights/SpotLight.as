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
	 * OmniLight is an attenuated light source placed at one point and spreads outward in  a coned direction.
	 *
	 * Lightning direction defines by z-axis of  OmniLight.
	 * You can use lookAt() to make DirectionalLight point at given coordinates.
	 */
	public class SpotLight extends Light3D {

		/**
		 * Distance from which falloff starts.
		 */
		public var attenuationBegin:Number;

		/**
		 * Distance from at which falloff is complete.
		 */
		public var attenuationEnd:Number;

		/**
		 * Adjusts the angle of a light's cone.
		 */
		public var hotspot:Number;

		/**
		 * Adjusts the angle of a light's falloff. For photometric lights, the Field angle is comparable
		 * to the Falloff angle. It is the angle at which the light's intensity has fallen to zero.
		 */
		public var falloff:Number;

		/**
		 * Creates a new SpotLight instance.
		 * @param color Light color.
		 * @param attenuationBegin Distance from which falloff starts.
		 * @param attenuationEnd Distance from at which falloff is complete.
		 * @param hotspot Adjusts the angle of a light's cone. The Hotspot value is measured in radians.
		 * @param falloff Adjusts the angle of a light's falloff. The Falloff value is measured in radians.
		 */
		public function SpotLight(color:uint, attenuationBegin:Number, attenuationEnd:Number, hotspot:Number, falloff:Number) {
			this.type = SPOT;
			this.color = color;
			this.attenuationBegin = attenuationBegin;
			this.attenuationEnd = attenuationEnd;
			this.hotspot = hotspot;
			this.falloff = falloff;
			calculateBoundBox();
		}

		/**
		 * @private 
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			var r:Number = (falloff < Math.PI) ? Math.sin(falloff*0.5)*attenuationEnd : attenuationEnd;
			var bottom:Number = (falloff < Math.PI) ? 0 : Math.cos(falloff*0.5)*attenuationEnd;
			boundBox.minX = -r;
			boundBox.minY = -r;
			boundBox.minZ = bottom;
			boundBox.maxX = r;
			boundBox.maxY = r;
			boundBox.maxZ = attenuationEnd;
		}

		/**
		 * Set direction of the light direction to the given coordinates..
		 */
		public function lookAt(x:Number, y:Number, z:Number):void {
			var dx:Number = x - this.x;
			var dy:Number = y - this.y;
			var dz:Number = z - this.z;
			rotationX = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy)) - Math.PI/2;
			rotationY = 0;
			rotationZ = -Math.atan2(dx, dy);
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function checkBound(targetObject:Object3D):Boolean {
			var minX:Number = boundBox.minX;
			var minY:Number = boundBox.minY;
			var minZ:Number = boundBox.minZ;
			var maxX:Number = boundBox.maxX;
			var maxY:Number = boundBox.maxY;
			var maxZ:Number = boundBox.maxZ;
			var sum:Number;
			var pro:Number;
			// Half sizes of the source's boundbox
			var w:Number = (maxX - minX)*0.5;
			var l:Number = (maxY - minY)*0.5;
			var h:Number = (maxZ - minZ)*0.5;
			// Half-vectors of the source's boundbox
			var ax:Number = lightToObjectTransform.a*w;
			var ay:Number = lightToObjectTransform.e*w;
			var az:Number = lightToObjectTransform.i*w;
			var bx:Number = lightToObjectTransform.b*l;
			var by:Number = lightToObjectTransform.f*l;
			var bz:Number = lightToObjectTransform.j*l;
			var cx:Number = lightToObjectTransform.c*h;
			var cy:Number = lightToObjectTransform.g*h;
			var cz:Number = lightToObjectTransform.k*h;
			// Half sizes of the boundboxes
			var objectBB:BoundBox = targetObject.boundBox;
			var hw:Number = (objectBB.maxX - objectBB.minX)*0.5;
			var hl:Number = (objectBB.maxY - objectBB.minY)*0.5;
			var hh:Number = (objectBB.maxZ - objectBB.minZ)*0.5;
			// Vector between centers of the bounboxes
			var dx:Number = lightToObjectTransform.a*(minX + w) + lightToObjectTransform.b*(minY + l) + lightToObjectTransform.c*(minZ + h) + lightToObjectTransform.d - objectBB.minX - hw;
			var dy:Number = lightToObjectTransform.e*(minX + w) + lightToObjectTransform.f*(minY + l) + lightToObjectTransform.g*(minZ + h) + lightToObjectTransform.h - objectBB.minY - hl;
			var dz:Number = lightToObjectTransform.i*(minX + w) + lightToObjectTransform.j*(minY + l) + lightToObjectTransform.k*(minZ + h) + lightToObjectTransform.l - objectBB.minZ - hh;

			// X of the object
			sum = 0;
			if (ax >= 0) sum += ax; else sum -= ax;
			if (bx >= 0) sum += bx; else sum -= bx;
			if (cx >= 0) sum += cx; else sum -= cx;
			sum += hw;
			if (dx >= 0) sum -= dx;
			sum += dx;
			if (sum <= 0) return false;
			// Y of the object
			sum = 0;
			if (ay >= 0) sum += ay; else sum -= ay;
			if (by >= 0) sum += by; else sum -= by;
			if (cy >= 0) sum += cy; else sum -= cy;
			sum += hl;
			if (dy >= 0) sum -= dy; else sum += dy;
			if (sum <= 0) return false;
			// Z of the object
			sum = 0;
			if (az >= 0) sum += az; else sum -= az;
			if (bz >= 0) sum += bz; else sum -= bz;
			if (cz >= 0) sum += cz; else sum -= cz;
			sum += hl;
			if (dz >= 0) sum -= dz; else sum += dz;
			if (sum <= 0) return false;
			// X of the source
			sum = 0;
			pro = lightToObjectTransform.a*ax + lightToObjectTransform.e*ay + lightToObjectTransform.i*az;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.a*bx + lightToObjectTransform.e*by + lightToObjectTransform.i*bz;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.a*cx + lightToObjectTransform.e*cy + lightToObjectTransform.i*cz;
			if (pro >= 0) sum += pro; else sum -= pro;
			if (lightToObjectTransform.a >= 0) sum += lightToObjectTransform.a*hw; else sum -= lightToObjectTransform.a*hw;
			if (lightToObjectTransform.e >= 0) sum += lightToObjectTransform.e*hl; else sum -= lightToObjectTransform.e*hl;
			if (lightToObjectTransform.i >= 0) sum += lightToObjectTransform.i*hh; else sum -= lightToObjectTransform.i*hh;
			pro = lightToObjectTransform.a*dx + lightToObjectTransform.e*dy + lightToObjectTransform.i*dz;
			if (pro >= 0) sum -= pro; else sum += pro;
			if (sum <= 0) return false;
			// Y of the source
			sum = 0;
			pro = lightToObjectTransform.b*ax + lightToObjectTransform.f*ay + lightToObjectTransform.j*az;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.b*bx + lightToObjectTransform.f*by + lightToObjectTransform.j*bz;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.b*cx + lightToObjectTransform.f*cy + lightToObjectTransform.j*cz;
			if (pro >= 0) sum += pro; else sum -= pro;
			if (lightToObjectTransform.b >= 0) sum += lightToObjectTransform.b*hw; else sum -= lightToObjectTransform.b*hw;
			if (lightToObjectTransform.f >= 0) sum += lightToObjectTransform.f*hl; else sum -= lightToObjectTransform.f*hl;
			if (lightToObjectTransform.j >= 0) sum += lightToObjectTransform.j*hh; else sum -= lightToObjectTransform.j*hh;
			pro = lightToObjectTransform.b*dx + lightToObjectTransform.f*dy + lightToObjectTransform.j*dz;
			if (pro >= 0) sum -= pro;
			sum += pro;
			if (sum <= 0) return false;
			// Z of the source
			sum = 0;
			pro = lightToObjectTransform.c*ax + lightToObjectTransform.g*ay + lightToObjectTransform.k*az;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.c*bx + lightToObjectTransform.g*by + lightToObjectTransform.k*bz;
			if (pro >= 0) sum += pro; else sum -= pro;
			pro = lightToObjectTransform.c*cx + lightToObjectTransform.g*cy + lightToObjectTransform.k*cz;
			if (pro >= 0) sum += pro; else sum -= pro;
			if (lightToObjectTransform.c >= 0) sum += lightToObjectTransform.c*hw; else sum -= lightToObjectTransform.c*hw;
			if (lightToObjectTransform.g >= 0) sum += lightToObjectTransform.g*hl; else sum -= lightToObjectTransform.g*hl;
			if (lightToObjectTransform.k >= 0) sum += lightToObjectTransform.k*hh; else sum -= lightToObjectTransform.k*hh;
			pro = lightToObjectTransform.c*dx + lightToObjectTransform.g*dy + lightToObjectTransform.k*dz;
			if (pro >= 0) sum -= pro; else sum += pro;
			if (sum <= 0) return false;
			// TODO: checking on random axises
			return true;
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:SpotLight = new SpotLight(color, attenuationBegin, attenuationEnd, hotspot, falloff);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
