/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.effects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.materials.compiler.Procedure;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class ParticleSystem extends Object3D {
		
		static private const limit:int = 31;
		static private var vertexBuffer:VertexBuffer3D;
		static private var indexBuffer:IndexBuffer3D;
		static private var diffuseProgram:Program3D;
		static private var opacityProgram:Program3D;
		static private var diffuseBlendProgram:Program3D;
		static private var opacityBlendProgram:Program3D;
		
		public var resolveByAABB:Boolean = true;
		
		public var gravity:Vector3D = new Vector3D(0, 0, -1);
		public var wind:Vector3D = new Vector3D();
		
		public var fogColor:int = 0;
		public var fogMaxDensity:Number = 0;
		public var fogNear:Number = 0;
		public var fogFar:Number = 0;
        /**
         * @private
         */
		alternativa3d var scale:Number = 1;
        /**
         * @private
         */
		alternativa3d var effectList:ParticleEffect;
		
		private var drawUnit:DrawUnit = null;
		private var diffuse:TextureBase = null;
		private var opacity:TextureBase = null;
		private var blendSource:String = null;
		private var blendDestination:String = null;
		private var counter:int;
		
		private var za:Number;
		private var zb:Number;
		private var fake:Vector.<Object3D> = new Vector.<Object3D>();
		private var fakeCounter:int = 0;
		
		public function ParticleSystem() {
			super();
		}
		
		private var pause:Boolean = false;
		private var stopTime:Number;
		private var subtractiveTime:Number = 0;
		
		public function stop():void {
			if (!pause) {
				stopTime = getTimer()*0.001;
				pause = true;
			}
		}
		
		public function play():void {
			if (pause) {
				subtractiveTime += getTimer()*0.001 - stopTime;
				pause = false;
			}
		}
		
		public function prevFrame():void {
			stopTime -= 0.001;
		}
		
		public function nextFrame():void {
			stopTime += 0.001;
		}
		
		public function addEffect(effect:ParticleEffect):ParticleEffect {
			// Checking on belonging
			if (effect.system != null) throw new Error("Cannot add the same effect twice.");
			// Set parameters
			effect.startTime = getTime();
			effect.system = this;
			effect.setPositionKeys(0);
			effect.setDirectionKeys(0);
			// Add
			effect.nextInSystem = effectList;
			effectList = effect;
			return effect;
		}
		
		public function getEffectByName(name:String):ParticleEffect {
			for (var effect:ParticleEffect = effectList; effect != null; effect = effect.nextInSystem) {
				if (effect.name == name) return effect;
			}
			return null;
		}
        /**
         * @private
         */
		alternativa3d function getTime():Number {
			return pause ? (stopTime - subtractiveTime) : (getTimer()*0.001 - subtractiveTime);
		}
        /**
         * @private
         */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			// Create geometry and program
			if (vertexBuffer == null) createAndUpload(camera.context3D);
			// Average size
			scale = Math.sqrt(localToCameraTransform.a*localToCameraTransform.a + localToCameraTransform.e*localToCameraTransform.e + localToCameraTransform.i*localToCameraTransform.i);
			scale += Math.sqrt(localToCameraTransform.b*localToCameraTransform.b + localToCameraTransform.f*localToCameraTransform.f + localToCameraTransform.j*localToCameraTransform.j);
			scale += Math.sqrt(localToCameraTransform.c*localToCameraTransform.c + localToCameraTransform.g*localToCameraTransform.g + localToCameraTransform.k*localToCameraTransform.k);
			scale /= 3;
			// TODO: add rotation on slope of the Z-axis in local space of camera
			// Calculate frustrum
			camera.calculateFrustum(cameraToLocalTransform);
			// Loop items
			var visibleEffectList:ParticleEffect;
			var conflictAnyway:Boolean = false;
			var time:Number = getTime();
			for (var effect:ParticleEffect = effectList, prev:ParticleEffect = null; effect != null;) {
				// Check if actual
				var effectTime:Number = time - effect.startTime;
				if (effectTime <= effect.lifeTime) {
					// Check bounds
					var culling:int = 63;
					if (effect.boundBox != null) {
						effect.calculateAABB();
						culling = effect.aabb.checkFrustumCulling(camera.frustum, 63);
					}
					if (culling >= 0) {
						// Gather the particles
						if (effect.calculate(effectTime)) {
							// Add
							if (effect.particleList != null) {
								effect.next = visibleEffectList;
								visibleEffectList = effect;
								conflictAnyway ||= effect.boundBox == null;
							}
							// Go to next effect
							prev = effect;
							effect = effect.nextInSystem;
						} else {
							// Removing
							if (prev != null) {
								prev.nextInSystem = effect.nextInSystem;
								effect = prev.nextInSystem;
							} else {
								effectList = effect.nextInSystem;
								effect = effectList;
							}
						}
					} else {
						// Go to next effect
						prev = effect;
						effect = effect.nextInSystem;
					}
				} else {
					// Removing
					if (prev != null) {
						prev.nextInSystem = effect.nextInSystem;
						effect = prev.nextInSystem;
					} else {
						effectList = effect.nextInSystem;
						effect = effectList;
					}
				}
			}
			// Gather draws
			if (visibleEffectList != null) {
				if (visibleEffectList.next != null) {
					/*if (resolveByAABB && !conflictAnyway) {
						drawAABBEffects(camera, visibleEffectList);
					} else {*/
						drawConflictEffects(camera, visibleEffectList);
					//}
				} else {
					drawParticleList(camera, visibleEffectList.particleList);
					visibleEffectList.particleList = null;
					if (camera.debug && visibleEffectList.boundBox != null && (camera.checkInDebug(this) & Debug.BOUNDS)) Debug.drawBoundBox(camera, visibleEffectList.aabb, localToCameraTransform); 
				}
				// Reset
				flush(camera);
				drawUnit = null;
				diffuse = null;
				opacity = null;
				blendSource = null;
				blendDestination = null;
				fakeCounter = 0;
			}
		}
		
		private function createAndUpload(context:Context3D):void {
			var vertices:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			for (var i:int = 0; i < limit; i++) {
				vertices.push(0,0,0, 0,0,i*4, 0,1,0, 0,1,i*4, 1,1,0, 1,1,i*4, 1,0,0, 1,0,i*4);
				indices.push(i*4, i*4 + 1, i*4 + 3, i*4 + 2, i*4 + 3, i*4 + 1);
			}
			vertexBuffer = context.createVertexBuffer(limit*4, 6);
			vertexBuffer.uploadFromVector(vertices, 0, limit*4);
			indexBuffer = context.createIndexBuffer(limit*6);
			indexBuffer.uploadFromVector(indices, 0, limit*6);
			var vertexProgram:Array = [
				// Pivot
				"mov t2, c[a1.z]", // originX, originY, width, height
				"sub t0.z, a0.x, t2.x",
				"sub t0.w, a0.y, t2.y",
				// Width and height
				"mul t0.z, t0.z, t2.z",
				"mul t0.w, t0.w, t2.w",
				// Rotation
				"mov t2, c[a1.z+1]", // x, y, z, rotation
				"mov t1.z, t2.w",
				"sin t1.x, t1.z", // sin
				"cos t1.y, t1.z", // cos
				"mul t1.z, t0.z, t1.y", // x*cos
				"mul t1.w, t0.w, t1.x", // y*sin
				"sub t0.x, t1.z, t1.w", // X
				"mul t1.z, t0.z, t1.x", // x*sin
				"mul t1.w, t0.w, t1.y", // y*cos
				"add t0.y, t1.z, t1.w", // Y
				// Translation
				"add t0.x, t0.x, t2.x",
				"add t0.y, t0.y, t2.y",
				"add t0.z, a0.z, t2.z",
				"mov t0.w, a0.w",
				// Projection
				"dp4 o0.x, t0, c124",
				"dp4 o0.y, t0, c125",
				"dp4 o0.z, t0, c126",
				"dp4 o0.w, t0, c127",
				// UV correction and passing out
				"mov t2, c[a1.z+2]", // uvScaleX, uvScaleY, uvOffsetX, uvOffsetY
				"mul t1.x, a1.x, t2.x",
				"mul t1.y, a1.y, t2.y",
				"add t1.x, t1.x, t2.z",
				"add t1.y, t1.y, t2.w",
				"mov v0, t1",
				// Passing color
				"mov v1, c[a1.z+3]", // red, green, blue, alpha
				// Passing coordinates in the camera space
				"mov v2, t0",
			];
			var fragmentDiffuseProgram:Array = [
				"tex t0, v0, s0 <2d,clamp,linear,miplinear>",
				"mul t0, t0, v1",
				// Fog
				"sub t1.w, v2.z, c1.x",
				"div t1.w, t1.w, c1.y",
				"max t1.w, t1.w, c1.z",
				"min t1.w, t1.w, c0.w",
				"sub t1.xyz, c0.xyz, t0.xyz",
				"mul t1.xyz, t1.xyz, t1.w",
				"add t0.xyz, t0.xyz, t1.xyz",
				"mov o0, t0",
			];
			var fragmentOpacityProgram:Array = [
				"tex t0, v0, s0 <2d,clamp,linear,miplinear>",
				"tex t1, v0, s1 <2d,clamp,linear,miplinear>",
				"mov t0.w, t1.x",
				"mul t0, t0, v1",
				// Fog
				"sub t1.w, v2.z, c1.x",
				"div t1.w, t1.w, c1.y",
				"max t1.w, t1.w, c1.z",
				"min t1.w, t1.w, c0.w",
				"sub t1.xyz, c0.xyz, t0.xyz",
				"mul t1.xyz, t1.xyz, t1.w",
				"add t0.xyz, t0.xyz, t1.xyz",
				"mov o0, t0",
			];
			var fragmentDiffuseBlendProgram:Array = [
				"tex t0, v0, s0 <2d,clamp,linear,miplinear>",
				"mul t0, t0, v1",
				// Fog
				"sub t1.w, v2.z, c1.x",
				"div t1.w, t1.w, c1.y",
				"max t1.w, t1.w, c1.z",
				"min t1.w, t1.w, c0.w",
				"sub t1.w, c1.w, t1.w",
				"mul t0.w, t0.w, t1.w",
				"mov o0, t0",
			];
			var fragmentOpacityBlendProgram:Array = [
				"tex t0, v0, s0 <2d,clamp,linear,miplinear>",
				"tex t1, v0, s1 <2d,clamp,linear,miplinear>",
				"mov t0.w, t1.x",
				"mul t0, t0, v1",
				// Fog
				"sub t1.w, v2.z, c1.x",
				"div t1.w, t1.w, c1.y",
				"max t1.w, t1.w, c1.z",
				"min t1.w, t1.w, c0.w",
				"sub t1.w, c1.w, t1.w",
				"mul t0.w, t0.w, t1.w",
				"mov o0, t0",
			];
			diffuseProgram = context.createProgram();
			opacityProgram = context.createProgram();
			diffuseBlendProgram = context.createProgram();
			opacityBlendProgram = context.createProgram();
			var compiledVertexProgram:ByteArray = compileProgram(Context3DProgramType.VERTEX, vertexProgram);
			diffuseProgram.upload(compiledVertexProgram, compileProgram(Context3DProgramType.FRAGMENT, fragmentDiffuseProgram));
			opacityProgram.upload(compiledVertexProgram, compileProgram(Context3DProgramType.FRAGMENT, fragmentOpacityProgram));
			diffuseBlendProgram.upload(compiledVertexProgram, compileProgram(Context3DProgramType.FRAGMENT, fragmentDiffuseBlendProgram));
			opacityBlendProgram.upload(compiledVertexProgram, compileProgram(Context3DProgramType.FRAGMENT, fragmentOpacityBlendProgram));
		}
		
		private function compileProgram(mode:String, program:Array):ByteArray {
			/*var string:String = "";
			var length:int = program.length;
			for (var i:int = 0; i < length; i++) {
				var line:String = program[i];
				string += line + ((i < length - 1) ? " \n" : "");
			}*/
			var proc:Procedure = new Procedure(program);
			return proc.getByteCode(mode);
		}
		
		private function flush(camera:Camera3D):void {
			if (fakeCounter == fake.length) fake[fakeCounter] = new Object3D();
			var object:Object3D = fake[fakeCounter];
			fakeCounter++;
			object.localToCameraTransform.l = (za + zb)/2;
			// Fill
			drawUnit.object = object;
			drawUnit.numTriangles = counter << 1;
			if (blendDestination == Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA) {
				drawUnit.program = (opacity != null) ? opacityProgram : diffuseProgram;
			} else {
				drawUnit.program = (opacity != null) ? opacityBlendProgram : diffuseBlendProgram;
			}
			// Set streams
			drawUnit.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			drawUnit.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
			// Set constants
			drawUnit.setProjectionConstants(camera, 124);
			drawUnit.setFragmentConstantsFromNumbers(0, ((fogColor >> 16) & 0xFF)/0xFF, ((fogColor >> 8) & 0xFF)/0xFF, (fogColor & 0xFF)/0xFF, fogMaxDensity);
			drawUnit.setFragmentConstantsFromNumbers(1, fogNear, fogFar - fogNear, 0, 1);
			// Set textures
			drawUnit.setTextureAt(0, diffuse);
			if (opacity != null) drawUnit.setTextureAt(1, opacity);
			// Set blending
			drawUnit.blendSource = blendSource;
			drawUnit.blendDestination = blendDestination;
			drawUnit.culling = Context3DTriangleFace.NONE;
			// Send to render
			camera.renderer.addDrawUnit(drawUnit, Renderer.TRANSPARENT_SORT);
		}
		
		private function drawParticleList(camera:Camera3D, list:Particle):void {
			// Sorting
 			if (list.next != null) list = sortParticleList(list);
			// Gather draws
			var last:Particle;
			for (var particle:Particle = list; particle != null; particle = particle.next) {
				if (counter >= limit || particle.diffuse != diffuse || particle.opacity != opacity || particle.blendSource != blendSource || particle.blendDestination != blendDestination) {
					if (drawUnit != null) flush(camera);
					drawUnit = camera.renderer.createDrawUnit(null, null, indexBuffer, 0, 0);
					diffuse = particle.diffuse;
					opacity = particle.opacity;
					blendSource = particle.blendSource;
					blendDestination = particle.blendDestination;
					counter = 0;
					za = particle.z;
				}
				// Write constants
				var offset:int = counter << 2;
				drawUnit.setVertexConstantsFromNumbers(offset++, particle.originX, particle.originY, particle.width, particle.height);
				drawUnit.setVertexConstantsFromNumbers(offset++, particle.x, particle.y, particle.z, particle.rotation);
				drawUnit.setVertexConstantsFromNumbers(offset++, particle.uvScaleX, particle.uvScaleY, particle.uvOffsetX, particle.uvOffsetY);
				drawUnit.setVertexConstantsFromNumbers(offset++, particle.red, particle.green, particle.blue, particle.alpha);
				counter++;
				zb = particle.z;
				last = particle;
			}
			// Send to the collector
			last.next = Particle.collector;
			Particle.collector = list;
		}
		
		private function sortParticleList(list:Particle):Particle {
			var left:Particle = list;
			var right:Particle = list.next;
			while (right != null && right.next != null) {
				list = list.next;
				right = right.next.next;
			}
			right = list.next;
			list.next = null;
			if (left.next != null) {
				left = sortParticleList(left);
			}
			if (right.next != null) {
				right = sortParticleList(right);
			}
			var flag:Boolean = left.z > right.z;
			if (flag) {
				list = left;
				left = left.next;
			} else {
				list = right;
				right = right.next;
			}
			var last:Particle = list;
			while (true) {
				if (left == null) {
					last.next = right;
					return list;
				} else if (right == null) {
					last.next = left;
					return list;
				}
				if (flag) {
					if (left.z > right.z) {
						last = left;
						left = left.next;
					} else {
						last.next = right;
						last = right;
						right = right.next;
						flag = false;
					}
				} else {
					if (right.z > left.z) {
						last = right;
						right = right.next;
					} else {
						last.next = left;
						last = left;
						left = left.next;
						flag = true;
					}
				}
			}
			return null;
		}
		
		private function drawConflictEffects(camera:Camera3D, effectList:ParticleEffect):void {
			var particleList:Particle;
			for (var effect:ParticleEffect = effectList; effect != null; effect = next) {
				var next:ParticleEffect = effect.next;
				effect.next = null;
				var last:Particle = effect.particleList;
				while (last.next != null) last = last.next;
				last.next = particleList;
				particleList = effect.particleList; 
				effect.particleList = null;
				if (camera.debug && effect.boundBox != null && (camera.checkInDebug(this) & Debug.BOUNDS)) Debug.drawBoundBox(camera, effect.aabb, localToCameraTransform, 0xFF0000);
			}
			drawParticleList(camera, particleList);
		}
		
	}
}
