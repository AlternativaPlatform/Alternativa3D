/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {
	import alternativa.engine3d.alternativa3d;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class Transform3D {
		
		public var a:Number = 1;
		public var b:Number = 0;
		public var c:Number = 0;
		public var d:Number = 0;

		public var e:Number = 0;
		public var f:Number = 1;
		public var g:Number = 0;
		public var h:Number = 0;

		public var i:Number = 0;
		public var j:Number = 0;
		public var k:Number = 1;
		public var l:Number = 0;
		
		public function identity():void {
			a = 1;
			b = 0;
			c = 0;
			d = 0;
			e = 0;
			f = 1;
			g = 0;
			h = 0;
			i = 0;
			j = 0;
			k = 1;
			l = 0;
		}
		
		public function compose(x:Number, y:Number, z:Number, rotationX:Number, rotationY:Number, rotationZ:Number, scaleX:Number, scaleY:Number, scaleZ:Number):void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*scaleX;
			var sinXscaleY:Number = sinX*scaleY;
			var cosXscaleY:Number = cosX*scaleY;
			var cosXscaleZ:Number = cosX*scaleZ;
			var sinXscaleZ:Number = sinX*scaleZ;
			a = cosZ*cosYscaleX;
			b = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			c = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			d = x;
			e = sinZ*cosYscaleX;
			f = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			g = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			h = y;
			i = -sinY*scaleX;
			j = cosY*sinXscaleY;
			k = cosY*cosXscaleZ;
			l = z;
		}

		public function composeInverse(x:Number, y:Number, z:Number, rotationX:Number, rotationY:Number, rotationZ:Number, scaleX:Number, scaleY:Number, scaleZ:Number):void {
			var cosX:Number = Math.cos(rotationX);
			var sinX:Number = Math.sin(-rotationX);
			var cosY:Number = Math.cos(rotationY);
			var sinY:Number = Math.sin(-rotationY);
			var cosZ:Number = Math.cos(rotationZ);
			var sinZ:Number = Math.sin(-rotationZ);
			var sinXsinY:Number = sinX*sinY;
			var cosYscaleX:Number = cosY/scaleX;
			var cosXscaleY:Number = cosX/scaleY;
			var sinXscaleZ:Number = sinX/scaleZ;
			var cosXscaleZ:Number = cosX/scaleZ;
			a = cosZ*cosYscaleX;
			b = -sinZ*cosYscaleX;
			c = sinY/scaleX;
			d = -a*x - b*y - c*z;
			e = sinZ*cosXscaleY + sinXsinY*cosZ/scaleY;
			f = cosZ*cosXscaleY - sinXsinY*sinZ/scaleY;
			g = -sinX*cosY/scaleY;
			h = -e*x - f*y - g*z;
			i = sinZ*sinXscaleZ - cosZ*sinY*cosXscaleZ;
			j = cosZ*sinXscaleZ + sinY*sinZ*cosXscaleZ;
			k = cosY*cosXscaleZ;
			l = -i*x - j*y - k*z;
		}
		
		public function invert():void {
			var ta:Number = a;
			var tb:Number = b;
			var tc:Number = c;
			var td:Number = d;
			var te:Number = e;
			var tf:Number = f;
			var tg:Number = g;
			var th:Number = h;
			var ti:Number = i;
			var tj:Number = j;
			var tk:Number = k;
			var tl:Number = l;
			var det:Number = 1/(-tc*tf*ti + tb*tg*ti + tc*te*tj - ta*tg*tj - tb*te*tk + ta*tf*tk);
			a = (-tg*tj + tf*tk)*det;
			b = (tc*tj - tb*tk)*det;
			c = (-tc*tf + tb*tg)*det;
			d = (td*tg*tj - tc*th*tj - td*tf*tk + tb*th*tk + tc*tf*tl - tb*tg*tl)*det;
			e = (tg*ti - te*tk)*det;
			f = (-tc*ti + ta*tk)*det;
			g = (tc*te - ta*tg)*det;
			h = (tc*th*ti - td*tg*ti + td*te*tk - ta*th*tk - tc*te*tl + ta*tg*tl)*det;
			i = (-tf*ti + te*tj)*det;
			j = (tb*ti - ta*tj)*det;
			k = (-tb*te + ta*tf)*det;
			l = (td*tf*ti - tb*th*ti - td*te*tj + ta*th*tj + tb*te*tl - ta*tf*tl)*det;
		}
		
		public function initFromVector(vector:Vector.<Number>):void {
			a = vector[0];
			b = vector[1];
			c = vector[2];
			d = vector[3];
			e = vector[4];
			f = vector[5];
			g = vector[6];
			h = vector[7];
			i = vector[8];
			j = vector[9];
			k = vector[10];
			l = vector[11];
		}
		
		public function append(transform:Transform3D):void {
			var ta:Number = a;
			var tb:Number = b;
			var tc:Number = c;
			var td:Number = d;
			var te:Number = e;
			var tf:Number = f;
			var tg:Number = g;
			var th:Number = h;
			var ti:Number = i;
			var tj:Number = j;
			var tk:Number = k;
			var tl:Number = l;
			a = transform.a*ta + transform.b*te + transform.c*ti;
			b = transform.a*tb + transform.b*tf + transform.c*tj;
			c = transform.a*tc + transform.b*tg + transform.c*tk;
			d = transform.a*td + transform.b*th + transform.c*tl + transform.d;
			e = transform.e*ta + transform.f*te + transform.g*ti;
			f = transform.e*tb + transform.f*tf + transform.g*tj;
			g = transform.e*tc + transform.f*tg + transform.g*tk;
			h = transform.e*td + transform.f*th + transform.g*tl + transform.h;
			i = transform.i*ta + transform.j*te + transform.k*ti;
			j = transform.i*tb + transform.j*tf + transform.k*tj;
			k = transform.i*tc + transform.j*tg + transform.k*tk;
			l = transform.i*td + transform.j*th + transform.k*tl + transform.l;
		}

		public function prepend(transform:Transform3D):void {
			var ta:Number = a;
			var tb:Number = b;
			var tc:Number = c;
			var td:Number = d;
			var te:Number = e;
			var tf:Number = f;
			var tg:Number = g;
			var th:Number = h;
			var ti:Number = i;
			var tj:Number = j;
			var tk:Number = k;
			var tl:Number = l;
			a = ta*transform.a + tb*transform.e + tc*transform.i;
			b = ta*transform.b + tb*transform.f + tc*transform.j;
			c = ta*transform.c + tb*transform.g + tc*transform.k;
			d = ta*transform.d + tb*transform.h + tc*transform.l + td;
			e = te*transform.a + tf*transform.e + tg*transform.i;
			f = te*transform.b + tf*transform.f + tg*transform.j;
			g = te*transform.c + tf*transform.g + tg*transform.k;
			h = te*transform.d + tf*transform.h + tg*transform.l + th;
			i = ti*transform.a + tj*transform.e + tk*transform.i;
			j = ti*transform.b + tj*transform.f + tk*transform.j;
			k = ti*transform.c + tj*transform.g + tk*transform.k;
			l = ti*transform.d + tj*transform.h + tk*transform.l + tl;

		}

		public function combine(transformA:Transform3D, transformB:Transform3D):void {
			a = transformA.a*transformB.a + transformA.b*transformB.e + transformA.c*transformB.i;
			b = transformA.a*transformB.b + transformA.b*transformB.f + transformA.c*transformB.j;
			c = transformA.a*transformB.c + transformA.b*transformB.g + transformA.c*transformB.k;
			d = transformA.a*transformB.d + transformA.b*transformB.h + transformA.c*transformB.l + transformA.d;
			e = transformA.e*transformB.a + transformA.f*transformB.e + transformA.g*transformB.i;
			f = transformA.e*transformB.b + transformA.f*transformB.f + transformA.g*transformB.j;
			g = transformA.e*transformB.c + transformA.f*transformB.g + transformA.g*transformB.k;
			h = transformA.e*transformB.d + transformA.f*transformB.h + transformA.g*transformB.l + transformA.h;
			i = transformA.i*transformB.a + transformA.j*transformB.e + transformA.k*transformB.i;
			j = transformA.i*transformB.b + transformA.j*transformB.f + transformA.k*transformB.j;
			k = transformA.i*transformB.c + transformA.j*transformB.g + transformA.k*transformB.k;
			l = transformA.i*transformB.d + transformA.j*transformB.h + transformA.k*transformB.l + transformA.l;
		}

		public function calculateInversion(source:Transform3D):void {
			var ta:Number = source.a;
			var tb:Number = source.b;
			var tc:Number = source.c;
			var td:Number = source.d;
			var te:Number = source.e;
			var tf:Number = source.f;
			var tg:Number = source.g;
			var th:Number = source.h;
			var ti:Number = source.i;
			var tj:Number = source.j;
			var tk:Number = source.k;
			var tl:Number = source.l;
			var det:Number = 1/(-tc*tf*ti + tb*tg*ti + tc*te*tj - ta*tg*tj - tb*te*tk + ta*tf*tk);
			a = (-tg*tj + tf*tk)*det;
			b = (tc*tj - tb*tk)*det;
			c = (-tc*tf + tb*tg)*det;
			d = (td*tg*tj - tc*th*tj - td*tf*tk + tb*th*tk + tc*tf*tl - tb*tg*tl)*det;
			e = (tg*ti - te*tk)*det;
			f = (-tc*ti + ta*tk)*det;
			g = (tc*te - ta*tg)*det;
			h = (tc*th*ti - td*tg*ti + td*te*tk - ta*th*tk - tc*te*tl + ta*tg*tl)*det;
			i = (-tf*ti + te*tj)*det;
			j = (tb*ti - ta*tj)*det;
			k = (-tb*te + ta*tf)*det;
			l = (td*tf*ti - tb*th*ti - td*te*tj + ta*th*tj + tb*te*tl - ta*tf*tl)*det;
		}

		public function copy(source:Transform3D):void {
			a = source.a;
			b = source.b;
			c = source.c;
			d = source.d;
			e = source.e;
			f = source.f;
			g = source.g;
			h = source.h;
			i = source.i;
			j = source.j;
			k = source.k;
			l = source.l;
		}

		public function toString():String {
			return "[Transform3D" +
				" a:" + a.toFixed(3) + " b:" + b.toFixed(3) + " c:" + a.toFixed(3) + " d:" + d.toFixed(3) +
				" e:" + e.toFixed(3) + " f:" + f.toFixed(3) + " g:" + a.toFixed(3) + " h:" + h.toFixed(3) +
				" i:" + i.toFixed(3) + " j:" + j.toFixed(3) + " k:" + a.toFixed(3) + " l:" + l.toFixed(3) + "]";
		}

	}
}
