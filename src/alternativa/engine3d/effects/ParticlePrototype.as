/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 *
 */
package alternativa.engine3d.effects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Transform3D;

	import flash.geom.Vector3D;

	use namespace alternativa3d;
	
	/**
	 * @private
	 */
	public class ParticlePrototype {
		
		// Atlas
		public var atlas:TextureAtlas;
		
		// Blend
		private var blendSource:String;
		private var blendDestination:String;
		
		// If <code>true</code>, then play animation
		private var animated:Boolean;
		
		// Size
		private var width:Number;
		private var height:Number;
		
		// Key frames of animation.
		private var timeKeys:Vector.<Number> = new Vector.<Number>();
		private var rotationKeys:Vector.<Number> = new Vector.<Number>();
		private var scaleXKeys:Vector.<Number> = new Vector.<Number>();
		private var scaleYKeys:Vector.<Number> = new Vector.<Number>();
		private var redKeys:Vector.<Number> = new Vector.<Number>();
		private var greenKeys:Vector.<Number> = new Vector.<Number>();
		private var blueKeys:Vector.<Number> = new Vector.<Number>();
		private var alphaKeys:Vector.<Number> = new Vector.<Number>();
		private var keysCount:int = 0;
		
		public function ParticlePrototype(width:Number, height:Number, atlas:TextureAtlas, animated:Boolean = false, blendSource:String = "sourceAlpha", blendDestination:String = "oneMinusSourceAlpha") {
			this.width = width;
			this.height = height;
			this.atlas = atlas;
			this.animated = animated;
			this.blendSource = blendSource;
			this.blendDestination = blendDestination;
		}
		
		public function addKey(time:Number, rotation:Number = 0, scaleX:Number = 1, scaleY:Number = 1, red:Number = 1, green:Number = 1, blue:Number = 1, alpha:Number = 1):void {
			var lastIndex:int = keysCount - 1;
			if (keysCount > 0 && time <= timeKeys[lastIndex]) throw new Error("Keys must be successively.");
			timeKeys[keysCount] = time;
			rotationKeys[keysCount] = rotation;
			scaleXKeys[keysCount] = scaleX;
			scaleYKeys[keysCount] = scaleY;
			redKeys[keysCount] = red;
			greenKeys[keysCount] = green;
			blueKeys[keysCount] = blue;
			alphaKeys[keysCount] = alpha;
			keysCount++;
		}
		
		public function createParticle(effect:ParticleEffect, time:Number, position:Vector3D, rotation:Number = 0, scaleX:Number = 1, scaleY:Number = 1, alpha:Number = 1, firstFrame:int = 0):void {
			var b:int = keysCount - 1;
			if (atlas.diffuse._texture != null && keysCount > 1 && time >= timeKeys[0] && time < timeKeys[b]) {

				for (b = 1; b < keysCount; b++) {
					if (time < timeKeys[b]) {
						var systemScale:Number = effect.system.scale;
						var effectScale:Number = effect.scale;
						var transform:Transform3D = effect.system.localToCameraTransform;
						var wind:Vector3D = effect.system.wind;
						var gravity:Vector3D = effect.system.gravity;
						// Interpolation
						var a:int = b - 1;
						var t:Number = (time - timeKeys[a])/(timeKeys[b] - timeKeys[a]);
						// Frame calculation
						var pos:int = firstFrame + (animated ? time*atlas.fps : 0);
						if (atlas.loop) {
							pos = pos%atlas.rangeLength;
							if (pos < 0) pos += atlas.rangeLength;
						} else {
							if (pos < 0) pos = 0;
							if (pos >= atlas.rangeLength) pos = atlas.rangeLength - 1;
						}
						pos += atlas.rangeBegin;
						var col:int = pos%atlas.columnsCount;
						var row:int = pos/atlas.columnsCount;
						// Particle creation
						var particle:Particle = Particle.create();
						particle.diffuse = atlas.diffuse._texture;
						particle.opacity = (atlas.opacity != null) ? atlas.opacity._texture : null;
						particle.blendSource = blendSource;
						particle.blendDestination = blendDestination;
						var cx:Number = effect.keyPosition.x + position.x*effectScale;
						var cy:Number = effect.keyPosition.y + position.y*effectScale;
						var cz:Number = effect.keyPosition.z + position.z*effectScale;
						particle.x = cx*transform.a + cy*transform.b + cz*transform.c + transform.d;
						particle.y = cx*transform.e + cy*transform.f + cz*transform.g + transform.h;
						particle.z = cx*transform.i + cy*transform.j + cz*transform.k + transform.l;
						var rot:Number = rotationKeys[a] + (rotationKeys[b] - rotationKeys[a])*t;
						particle.rotation = (scaleX*scaleY > 0) ? (rotation + rot) : (rotation - rot);
						particle.width = systemScale*effectScale*scaleX*width*(scaleXKeys[a] + (scaleXKeys[b] - scaleXKeys[a])*t);
						particle.height = systemScale*effectScale*scaleY*height*(scaleYKeys[a] + (scaleYKeys[b] - scaleYKeys[a])*t);
						particle.originX = atlas.originX;
						particle.originY = atlas.originY;
						particle.uvScaleX = 1/atlas.columnsCount;
						particle.uvScaleY = 1/atlas.rowsCount;
						particle.uvOffsetX = col/atlas.columnsCount;
						particle.uvOffsetY = row/atlas.rowsCount;
						particle.red = redKeys[a] + (redKeys[b] - redKeys[a])*t;
						particle.green = greenKeys[a] + (greenKeys[b] - greenKeys[a])*t;
						particle.blue = blueKeys[a] + (blueKeys[b] - blueKeys[a])*t;
						particle.alpha = alpha*(alphaKeys[a] + (alphaKeys[b] - alphaKeys[a])*t);
						particle.next = effect.particleList;
						effect.particleList = particle;
						break;
					}
				}
			}
		}
		
		public function get lifeTime():Number {
			var lastIndex:int = keysCount - 1;
			return timeKeys[lastIndex];
		}
		
	}
}
