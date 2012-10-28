/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 */
package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Joint;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.CubeTexture;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Class of the shadow, that is created by one  source of light(<code>OmniLight</code>). Shadow is rendered in fixed volume.
	 * For binding of shadow to light source you need:
	 * 1) to set  instance of the <code>OmniLight</code> as a value of property <code>shadow</code> of light source;
	 * 2) to add <code>Object3D</code> to corresponding list, using the method <code>addCaster()</code>.
	 *
	 * @see #addCaster()
	 * @see alternativa.engine3d.lights.OmniLight#shadow
	 * @see #farBoundPosition
	 */

	public class OmniLightShadow extends Shadow {

		// TODO: calculate bias automaticaly
		/**
		 * Degree of correcting offset of shadow map space. It need for getting rid of self-shadowing artifacts.
		 */
		public var biasMultiplier:Number = 0.97;
		private static const DIFFERENCE_MULTIPLIER:Number = 32768;
		private static const DEBUG_TYPE:String = "Sphere";  // Box
		/**
		 * @private
		 */
		alternativa3d static var debugRadiusScale:Number = 0.2;

		private var renderer:Renderer = new Renderer();

		// radius of the light source
		private var radius:Number = 100;

		// cube map size
		private var _mapSize:Number;

		private var _pcfOffset:Number;

		private var cubeShadowMap:CubeTexture;

		// Sides cameras
		private var cameras:Vector.<Camera3D> = new Vector.<Camera3D>();

		private var debugObject:Mesh;
		private var debugMaterial:ShadowDebugMaterial;

		private var _casters:Vector.<Object3D> = new Vector.<Object3D>();

		private var actualCasters:Vector.<Object3D> = new Vector.<Object3D>();
		private var actualCastersCount:int;

		// caster -> cube face
		private var casterToEdgedCameraTransform:Transform3D = new Transform3D();
		// object -> light
		private var objectToLightTransform:Transform3D = new Transform3D();
		// casters count in edge
		private var prevActualCastersMask:int;

		private var cachedContext:Context3D;
		private var programs:Dictionary = new Dictionary();

		/**
		 * Создает экземпляр OmniLightShadow.
		 * @param mapSize Размер карты теней. Должен быть степенью 2.
		 * @param pcfOffset Смягчение границ тени.
		 */
		public function OmniLightShadow(mapSize:int = 128, pcfOffset:Number = 0) {
			sections = new SectionPlane(0x11, 0x22, 0xC); // RU
			sections.next = new SectionPlane(0x12, 0x21, 0xC);	// LU
			sections.next.next = new SectionPlane(0x14, 0x28, 0x3); // FU
			sections.next.next.next = new SectionPlane(0x18, 0x24, 0x3); // BU
			sections.next.next.next.next = new SectionPlane(0x5, 0xA, 0x30); // RF
			sections.next.next.next.next.next = new SectionPlane(0x9, 0x6, 0x30);	// RB

			this.mapSize = mapSize;
			this.pcfOffset = pcfOffset;

			vertexShadowProcedure = getVShader();
			type = _pcfOffset > 0 ? Shadow.PCF_MODE : Shadow.SIMPLE_MODE;
			fragmentShadowProcedure = _pcfOffset > 0 ? getFShaderPCF() : getFShader();

			debugMaterial = new ShadowDebugMaterial();
			debugMaterial.alpha = 0.3;

			for (var i:int = 0; i < 6; i++) {
				var cam:Camera3D = new Camera3D(radius / 1000, radius);
				cam.fov = 1.910633237;
				cameras[i] = cam;
			}

			// Left
			cameras[1].rotationY = -Math.PI / 2;
			cameras[1].scaleY = -1;
			cameras[1].composeTransforms();
			// Right
			cameras[0].rotationY = Math.PI / 2;
			cameras[0].scaleY = -1;
			cameras[0].composeTransforms();
			// Back
			cameras[3].rotationX = -Math.PI / 2;
			cameras[3].rotationZ = Math.PI;
			cameras[3].scaleX = -1;
			cameras[3].composeTransforms();
			// Front
			cameras[2].rotationX = -Math.PI / 2;
			cameras[2].scaleY = -1;
			cameras[2].composeTransforms();
			// Bottom
			cameras[5].rotationX = Math.PI;
			cameras[5].scaleX = -1;
			cameras[5].composeTransforms();
			// Top
			cameras[4].rotationX = 0;
			cameras[4].scaleY = -1;
			cameras[4].composeTransforms();
		}

		private function createDebugObject(material:Material, context:Context3D):Mesh {
			var geometry:Geometry;
			var mesh:Mesh;
			if (DEBUG_TYPE == "Box") {
				mesh = new Mesh();
				geometry = new Geometry(8);
				mesh.geometry = geometry;

				var attributes:Array = new Array();
				attributes[0] = VertexAttributes.POSITION;
				attributes[1] = VertexAttributes.POSITION;
				attributes[2] = VertexAttributes.POSITION;
				geometry.addVertexStream(attributes);

				geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([
					-1, -1, -1,
					1, -1, -1,
					1, 1, -1,
					-1, 1, -1,
					-1, -1, 1,
					1, -1, 1,
					1, 1, 1,
					-1, 1, 1]));
				geometry.indices = Vector.<uint>([
					0, 1, 2, 3, 0, 2, 2, 1, 0, 3, 2, 0,
					2, 6, 1, 1, 6, 2, 1, 6, 5, 5, 6, 1,
					6, 4, 5, 5, 4, 6, 6, 4, 7, 7, 4, 6,
					0, 7, 4, 4, 7, 0, 0, 7, 3, 3, 7, 0,
					3, 6, 2, 2, 6, 3, 3, 7, 6, 6, 7, 3,
					0, 5, 1, 1, 5, 0, 0, 4, 5, 5, 4, 0]);
				mesh.addSurface(material, 0, 24);
			} else {
				mesh = new GeoSphere(1, 4, true);
				// Create two side
				var triangles:Vector.<uint> = mesh.geometry.indices;
				var numTriangles:int = triangles.length;
				for (var i:int = 0; i < numTriangles; i += 3) {
					var a:uint = triangles[i];
					var b:uint = triangles[int(i + 1)];
					var c:uint = triangles[int(i + 2)];
					triangles.push(c, b, a);
				}
				mesh.geometry.indices = triangles;
				mesh.getSurface(0).numTriangles = triangles.length / 3;
				mesh.setMaterialToAllSurfaces(material);
			}
			mesh.geometry.upload(context);
			return mesh;
		}

		// Draw in shadow map
		override alternativa3d function process(camera:Camera3D):void {
			var i:int;
			var j:int;
			var caster:Object3D;
			var context:Context3D = camera.context3D;

			// Checking changed context
			if (context != cachedContext) {
				programs = new Dictionary();
				cubeShadowMap = null;
				cachedContext = context;
			}

			// Culling invisible casters
			if (cubeShadowMap == null) {
				cubeShadowMap = context.createCubeTexture(_mapSize, Context3DTextureFormat.BGRA, true);
				debugMaterial.cubeMap = cubeShadowMap;
				prevActualCastersMask = 63;
			}

			// Calculate parameters
			radius = OmniLight(_light).attenuationEnd;
			for (i = 0; i < 6; i++) {
				var cam:Camera3D = cameras[i];
				cam.nearClipping = radius / 1000;
				cam.farClipping = radius;
				cam.calculateProjection(1, 1);
			}

			var castersCount:int = _casters.length;
			actualCastersCount = 0;

			for (i = 0; i < castersCount; i++) {
				caster = _casters[i];

				var visible:Boolean = caster.visible;
				var parent:Object3D = caster._parent;
				while (visible && parent != null) {
					visible = parent.visible;
					parent = parent._parent;
				}

				if (visible) {
					// calculate transform matrices
					_light.lightToObjectTransform.combine(caster.cameraToLocalTransform, _light.localToCameraTransform);
					caster.localToLightTransform.combine(_light.cameraToLocalTransform, caster.localToCameraTransform);

					// collect actualCasters for light
					if (caster.boundBox == null || OmniLight(_light).checkBound(caster)) {
						actualCasters[actualCastersCount] = caster;
						actualCastersCount++;

						// Pack camera culling
						caster.culling <<= 16;
						if (caster.boundBox != null) {
							// 1 -  calculate planes in object space
							calculatePlanes(caster.localToLightTransform);
							// 2 - check object location cameras (sections)
							caster.culling |= recognizeObjectCameras(caster.boundBox);
						}
					}

					// update Skin Joints matrices
					var skin:Skin = caster as Skin;
					if (skin != null) {
						// Calculate joints matrices
						for (var child:Object3D = skin.childrenList; child != null; child = child.next) {
							if (child.transformChanged) child.composeTransforms();
							// Write transformToSkin matrix to localToGlobalTransform property
							child.localToGlobalTransform.copy(child.transform);
							if (child is Joint) {
								Joint(child).calculateTransform();
							}
							skin.calculateJointsTransforms(child);
						}
					}

					if (caster.childrenList != null) collectActualChildren(caster);
				}
			}

			// Iterate through six cameras
			for (i = 0; i < 6; i++) {
				// Cube side camera
				var edgeCamera:Camera3D = cameras[i];

				var edgeBit:int = (1 << i);
				if (actualCastersCount > 0) {
					// Настройка параметров рендеринга:
					renderer.camera = camera;
					context.setRenderToTexture(cubeShadowMap, true, 0, i);
					context.clear(1, 0, 0, 0.0);

					// Пробегаемся по кастерам
					for (j = 0; j < actualCastersCount; j++) {
						caster = actualCasters[j];

						// Проверить находится ли кастер в зоне 4-х плоскостей
						if ((caster.culling & edgeBit)) {
							// собираем матрицу перевода из кастера в пространство edgeCamera
							casterToEdgedCameraTransform.combine(edgeCamera.inverseTransform, caster.localToLightTransform);
							// Собираем драуколлы для кастера и его дочерних объектов
							collectDraws(context, caster, edgeCamera);
						}
					}

//					if (renderer.drawUnits.length == 0) context.clear(0, 0, 0, 0.0);

					// Drawing
					renderer.render(context);
					prevActualCastersMask |= edgeBit;
				}
				else {
					// Если относительно одной из камер ничего не менялось, не вызываем отрисовочный вызов

					if ((prevActualCastersMask & edgeBit)) {
						context.setRenderToTexture(cubeShadowMap, false, 0, i);
						context.clear(1, 0, 0, 0);

						prevActualCastersMask &= ~edgeBit;
					}
				}
			}
			context.setRenderToBackBuffer();

			// Unpack camera culling value
			for (j = 0; j < actualCastersCount; j++) {
				caster = actualCasters[j];
				// If there was -1, after shift it will be -1 too
				caster.culling >>= 16;
			}

			if (debug) {
				// Create debug object if needed
				if (debugObject == null) {
					debugObject = createDebugObject(debugMaterial, camera.context3D);
				}
				debugObject.scaleX = debugObject.scaleY = debugObject.scaleZ = radius * debugRadiusScale;
				debugObject.composeTransforms();

				// Формируем матрицу трансформации для debugObject
				debugObject.localToCameraTransform.combine(_light.localToCameraTransform, debugObject.transform);

				// Отрисовываем
				var debugSurface:Surface = debugObject._surfaces[0];
				debugMaterial.collectDraws(camera, debugSurface, debugObject.geometry, null, 0, false, -1);
			}
			actualCasters.length = 0;
		}

		private function collectActualChildren(root:Object3D):void {
			for (var child:Object3D = root.childrenList; child != null; child = child.next) {
				if (child.visible) {
					// calculate transform matrices
					_light.lightToObjectTransform.combine(child.cameraToLocalTransform, _light.localToCameraTransform);
					child.localToLightTransform.combine(_light.cameraToLocalTransform, child.localToCameraTransform);

					// collect actualCasters for light
					if (child.boundBox == null || OmniLight(_light).checkBound(child)) {
						actualCasters[actualCastersCount] = child;
						actualCastersCount++;

						// Pack camera culling
						child.culling <<= 16;
						if (child.boundBox != null) {
							// 1 -  calculate planes in object space
							calculatePlanes(child.localToLightTransform);
							// 2 - check object location cameras (sections)
							child.culling |= recognizeObjectCameras(child.boundBox);
						}
					}

					// update Skin Joints matrices
					var skin:Skin = child as Skin;
					if (skin != null) {
						// Calculate joints matrices
						for (var skinChild:Object3D = skin.childrenList; skinChild != null; skinChild = skinChild.next) {
							if (skinChild.transformChanged) skinChild.composeTransforms();
							// Write transformToSkin matrix to localToGlobalTransform property
							skinChild.localToGlobalTransform.copy(skinChild.transform);
							if (skinChild is Joint) {
								Joint(skinChild).calculateTransform();
							}
							skin.calculateJointsTransforms(skinChild);
						}
					}

					if (child.childrenList != null) collectActualChildren(child);
				}
			}
		}

		private var sections:SectionPlane;

		private function calculatePlanes(transform:Transform3D):void {
			// DUBFLR
			var planeRU:SectionPlane = sections;
			var planeLU:SectionPlane = sections.next;
			var planeFU:SectionPlane = sections.next.next;
			var planeBU:SectionPlane = sections.next.next.next;
			var planeRF:SectionPlane = sections.next.next.next.next;
			var planeRB:SectionPlane = sections.next.next.next.next.next;

			// 1, 0, 1
			planeRU.x = transform.a + transform.i;
			planeRU.y = transform.b + transform.j;
			planeRU.z = transform.c + transform.k;
			planeRU.offset = -(transform.d + transform.l);

			// -1, 0, 1
			planeLU.x = transform.i - transform.a;
			planeLU.y = transform.j - transform.b;
			planeLU.z = transform.k - transform.c;
			planeLU.offset = transform.d - transform.l;

			// 0, 1, 1
			planeFU.x = transform.e + transform.i;
			planeFU.y = transform.f + transform.j;
			planeFU.z = transform.g + transform.k;
			planeFU.offset = -(transform.h + transform.l);

			// 0, -1, 1
			planeBU.x = transform.i - transform.e;
			planeBU.y = transform.j - transform.f;
			planeBU.z = transform.k - transform.g;
			planeBU.offset = transform.h - transform.l;

			// 1, 1, 0
			planeRF.x = transform.a + transform.e;
			planeRF.y = transform.b + transform.f;
			planeRF.z = transform.c + transform.g;
			planeRF.offset = -(transform.d + transform.h);

			// 1, -1, 0
			planeRB.x = transform.a - transform.e;
			planeRB.y = transform.b - transform.f;
			planeRB.z = transform.c - transform.g;
			planeRB.offset = transform.h - transform.d;

			//			var ax:Number = transform.c - transform.a + transform.b;  // E
//			var ay:Number = transform.g - transform.e + transform.f;
//			var az:Number = transform.k - transform.i + transform.j;
//			var bx:Number = transform.c - transform.a - transform.b;  // H
//			var by:Number = transform.g - transform.e - transform.f;
//			var bz:Number = transform.k - transform.i - transform.j;
//			planeRU.x = bz * ay - by * az;
//			planeRU.y = bx * az - bz * ax;
//			planeRU.z = by * ax - bx * ay;
//			planeRU.offset = transform.d*planeRU.x + transform.h*planeRU.y + transform.l*planeRU.z;
//
//			ax = transform.c + transform.a - transform.b;  // D
//			ay = transform.g + transform.e - transform.f;
//			az = transform.k + transform.i - transform.j;
//			bx = transform.c + transform.a + transform.b;  // A
//			by = transform.g + transform.e + transform.f;
//			bz = transform.k + transform.i + transform.j;
//			planeLU.x = bz * ay - by * az;
//			planeLU.y = bx * az - bz * ax;
//			planeLU.z = by * ax - bx * ay;
//			planeLU.offset = transform.d*planeLU.x + transform.h*planeLU.y + transform.l*planeLU.z;
//
//			ax = transform.c - transform.a - transform.b;  // H
//			ay = transform.g - transform.e - transform.f;
//			az = transform.k - transform.i - transform.j;
//			bx = transform.c + transform.a - transform.b;  // D
//			by = transform.g + transform.e - transform.f;
//			bz = transform.k + transform.i - transform.j;
//			planeFU.x = bz * ay - by * az;
//			planeFU.y = bx * az - bz * ax;
//			planeFU.z = by * ax - bx * ay;
//			planeFU.offset = transform.d*planeFU.x + transform.h*planeFU.y + transform.l*planeFU.z;
//
//			ax = transform.c + transform.a + transform.b;  // A
//			ay = transform.g + transform.e + transform.f;
//			az = transform.k + transform.i + transform.j;
//			bx = transform.c - transform.a + transform.b;  // E
//			by = transform.g - transform.e + transform.f;
//			bz = transform.k - transform.i + transform.j;
//			planeBU.x = bz * ay - by * az;
//			planeBU.y = bx * az - bz * ax;
//			planeBU.z = by * ax - bx * ay;
//			planeBU.offset = transform.d*planeBU.x + transform.h*planeBU.y + transform.l*planeBU.z;
//
//			ax = transform.a - transform.b + transform.c;  // D
//			ay = transform.e - transform.f + transform.g;
//			az = transform.i - transform.j + transform.k;
//			bx = transform.a - transform.b - transform.c;  // C
//			by = transform.e - transform.f - transform.g;
//			bz = transform.i - transform.j - transform.k;
//			planeRF.x = bz * ay - by * az;
//			planeRF.y = bx * az - bz * ax;
//			planeRF.z = by * ax - bx * ay;
//			planeRF.offset = transform.d*planeRF.x + transform.h*planeRF.y + transform.l*planeRF.z;
//
//			ax = transform.a + transform.b - transform.c;  // B
//			ay = transform.e + transform.f - transform.g;
//			az = transform.i + transform.j - transform.k;
//			bx = transform.a + transform.b + transform.c;  // A
//			by = transform.e + transform.f + transform.g;
//			bz = transform.i + transform.j + transform.k;
//			planeRB.x = bz * ay - by * az;
//			planeRB.y = bx * az - bz * ax;
//			planeRB.z = by * ax - bx * ay;
//			planeRB.offset = transform.d*planeRB.x + transform.h*planeRB.y + transform.l*planeRB.z;
		}

		private function recognizeObjectCameras(bb:BoundBox):int {
			var culling:int = 63;
			for (var plane:SectionPlane = sections; plane != null; plane = plane.next) {
				var result:int = 0;

				if (plane.x >= 0)
					if (plane.y >= 0)
						if (plane.z >= 0) {
							if (bb.maxX * plane.x + bb.maxY * plane.y + bb.maxZ * plane.z >= plane.offset) result = plane.frontCameras;
							if (bb.minX * plane.x + bb.minY * plane.y + bb.minZ * plane.z < plane.offset) result |= plane.backCameras;
						} else {
							if (bb.maxX * plane.x + bb.maxY * plane.y + bb.minZ * plane.z >= plane.offset) result = plane.frontCameras;
							if (bb.minX * plane.x + bb.minY * plane.y + bb.maxZ * plane.z < plane.offset) result |= plane.backCameras;
						}
					else if (plane.z >= 0) {
						if (bb.maxX * plane.x + bb.minY * plane.y + bb.maxZ * plane.z >= plane.offset) result = plane.frontCameras;
						if (bb.minX * plane.x + bb.maxY * plane.y + bb.minZ * plane.z < plane.offset) result |= plane.backCameras;
					} else {
						if (bb.maxX * plane.x + bb.minY * plane.y + bb.minZ * plane.z >= plane.offset) result = plane.frontCameras;
						if (bb.minX * plane.x + bb.maxY * plane.y + bb.maxZ * plane.z < plane.offset) result |= plane.backCameras;
					}
				else if (plane.y >= 0)
					if (plane.z >= 0) {
						if (bb.minX * plane.x + bb.maxY * plane.y + bb.maxZ * plane.z >= plane.offset) result = plane.frontCameras;
						if (bb.maxX * plane.x + bb.minY * plane.y + bb.minZ * plane.z < plane.offset) result |= plane.backCameras;
					} else {
						if (bb.minX * plane.x + bb.maxY * plane.y + bb.minZ * plane.z >= plane.offset) result = plane.frontCameras;
						if (bb.maxX * plane.x + bb.minY * plane.y + bb.maxZ * plane.z < plane.offset) result |= plane.backCameras;
					}
				else if (plane.z >= 0) {
					if (bb.minX * plane.x + bb.minY * plane.y + bb.maxZ * plane.z >= plane.offset) result = plane.frontCameras;
					if (bb.maxX * plane.x + bb.maxY * plane.y + bb.minZ * plane.z < plane.offset) result |= plane.backCameras;
				} else {
					if (bb.minX * plane.x + bb.minY * plane.y + bb.minZ * plane.z >= plane.offset) result = plane.frontCameras;
					if (bb.maxX * plane.x + bb.maxY * plane.y + bb.maxZ * plane.z < plane.offset) result |= plane.backCameras;
				}
				culling &= result | plane.unusedBits;
			}
			return culling;
		}

		private function collectDraws(context:Context3D, caster:Object3D, edgeCamera:Camera3D):void {
			// если объект является мешем, собираем для него дроуколы
			var mesh:Mesh = caster as Mesh;
			if (mesh != null && mesh.geometry != null) {
				var program:ShaderProgram;
				var programListByTransformProcedure:Vector.<ShaderProgram>;
				var skin:Skin = mesh as Skin;

				// пробегаемся по сурфейсам
				for (var i:int = 0; i < mesh._surfacesLength; i++) {
					var surface:Surface = mesh._surfaces[i];
					if (surface.material == null) continue;

					var material:Material = surface.material;
					var geometry:Geometry = mesh.geometry;
					var alphaTest:Boolean;
					var useDiffuseAlpha:Boolean;
					var alphaThreshold:Number;
					var materialAlpha:Number;
					var diffuse:TextureResource;
					var opacity:TextureResource;
					var uvBuffer:VertexBuffer3D;

					// ловим параметры прозрачности
					if (material is TextureMaterial) {
						alphaThreshold = TextureMaterial(material).alphaThreshold;
						materialAlpha = TextureMaterial(material).alpha;
						diffuse = TextureMaterial(material).diffuseMap;
						opacity = TextureMaterial(material).opacityMap;
						alphaTest = alphaThreshold > 0;
						useDiffuseAlpha = TextureMaterial(material).opacityMap == null;
						uvBuffer = geometry.getVertexBuffer(VertexAttributes.TEXCOORDS[0]);
						if (uvBuffer == null) continue;
					} else {
						alphaTest = false;
						useDiffuseAlpha = false;
					}


					var positionBuffer:VertexBuffer3D = mesh.geometry.getVertexBuffer(VertexAttributes.POSITION);
					if (positionBuffer == null) continue;

					// поднимаем и кэшируем programListByTransformProcedure
					if (skin != null) {
						caster.transformProcedure = skin.surfaceTransformProcedures[i];
					}
					programListByTransformProcedure = programs[caster.transformProcedure];
					if (programListByTransformProcedure == null) {
						programListByTransformProcedure = new Vector.<ShaderProgram>(3, true);
						programs[caster.transformProcedure] = programListByTransformProcedure;
					}

					// собираем программу и Формируем дроуюнит
					program = getProgram(caster.transformProcedure, programListByTransformProcedure, context, alphaTest, useDiffuseAlpha);
					var drawUnit:DrawUnit = renderer.createDrawUnit(caster, program.program, mesh.geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);
					drawUnit.culling = Context3DTriangleFace.BACK;

					// Установка стрима
					drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aPosition"), positionBuffer, mesh.geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);

					if (alphaTest) {
						drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aUV"), uvBuffer, geometry._attributesOffsets[VertexAttributes.TEXCOORDS[0]], VertexAttributes.FORMATS[VertexAttributes.TEXCOORDS[0]]);
						drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cThresholdAlpha"), alphaThreshold, 0, 0, materialAlpha);
						if (useDiffuseAlpha) {
							drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sTexture"), diffuse._texture);
						} else {
							drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sTexture"), opacity._texture);
						}
					}

					// Установка констант
					caster.setTransformConstants(drawUnit, surface, program.vertexShader, null);
					drawUnit.setProjectionConstants(edgeCamera, program.vertexShader.getVariableIndex("cProjMatrix"), casterToEdgedCameraTransform);
					drawUnit.setVertexConstantsFromTransform(program.vertexShader.getVariableIndex("cCasterToOmni"), caster.localToLightTransform);

					drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cConstants"), 1 / 255, 0, 255 / radius, 1);

					renderer.addDrawUnit(drawUnit, Renderer.OPAQUE);
				}
			}
		}

		/**
		 * @private
		 * Процедура для передачи UV координат во фрагментный шейдер
		 */
		static private const passUVProcedure:Procedure = new Procedure(["#v0=vUV", "#a0=aUV", "mov v0, a0"], "passUVProcedure");

		// diffuse alpha test
		private static const diffuseAlphaTestProcedure:Procedure = new Procedure([
			"#v0=vUV",
			"#s0=sTexture",
			"#c0=cThresholdAlpha",
			"tex t0, v0, s0 <2d, linear,repeat, miplinear>",
			"mul t0.w, t0.w, c0.w",
			"sub t0.w, t0.w, c0.x",
			"kil t0.w"
		], "diffuseAlphaTestProcedure");

		// opacity alpha test
		private static const opacityAlphaTestProcedure:Procedure = new Procedure([
			"#v0=vUV",
			"#s0=sTexture",
			"#c0=cThresholdAlpha",
			"tex t0, v0, s0 <2d, linear,repeat, miplinear>",
			"mul t0.w, t0.x, c0.w",
			"sub t0.w, t0.w, c0.x",
			"kil t0.w"
		], "opacityAlphaTestProcedure");


		private function getProgram(transformProcedure:Procedure, programListByTransformProcedure:Vector.<ShaderProgram>, context:Context3D, alphaTest:Boolean, useDiffuseAlpha:Boolean):ShaderProgram {
			var key:int = (alphaTest ? (useDiffuseAlpha ? 1 : 2) : 0);
			var program:ShaderProgram = programListByTransformProcedure[key];

			if (program == null) {
				var vLinker:Linker = new Linker(Context3DProgramType.VERTEX);
				var fLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);

				var positionVar:String = "aPosition";
				vLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);

				if (alphaTest) {
					vLinker.addProcedure(passUVProcedure);
				}

				if (transformProcedure != null) {
					var newPosVar:String = "tTransformedPosition";
					vLinker.declareVariable(newPosVar);
					vLinker.addProcedure(transformProcedure, positionVar);
					vLinker.setOutputParams(transformProcedure, newPosVar);
					positionVar = newPosVar;
				}

				var proc:Procedure = Procedure.compileFromArray([
					"#v0=vDistance",

					"m34 t0.xyz, i0, c2",
					"mov v0, t0.xyzx",

					"m44 o0, i0, c0"
				]);
				proc.assignVariableName(VariableType.CONSTANT, 0, "cProjMatrix", 4);
				proc.assignVariableName(VariableType.CONSTANT, 2, "cCasterToOmni", 3);

				vLinker.addProcedure(proc, positionVar);

				if (alphaTest) {
					if (useDiffuseAlpha) {
						fLinker.addProcedure(diffuseAlphaTestProcedure);
					} else {
						fLinker.addProcedure(opacityAlphaTestProcedure);
					}
				}
				fLinker.addProcedure(Procedure.compileFromArray([
					"#v0=vDistance", // xyz
					"#c0=cConstants", // 1/255, 0, 255/radius, 1
					// calculate distance
					"dp3 t0.z, v0.xyz, v0.xyz",
					"sqt t0.z, t0.z", // x: [0, radius]
					"mul t0.z, t0.z, c0.z", // x: [0, 255]
					// codeing
					"frc t0.y, t0.z",
					"sub t0.x, t0.z, t0.y",
					"mul t0.x, t0.x, c0.x",

					"mov t0.w, c0.w",
					"mov o0, t0"
				]));
				program = new ShaderProgram(vLinker, fLinker);
				fLinker.varyings = vLinker.varyings;
				programListByTransformProcedure[key] = program;
				program.upload(context);

			}
			return program;
		}


		//------------- ShadowMap Shader in material----------

		/**
		 * @private
		 */
		alternativa3d override function setup(drawUnit:DrawUnit, vertexLinker:Linker, fragmentLinker:Linker, surface:Surface):void {
			// Устанавливаем матрицу перевода в шедоумапу
			objectToLightTransform.combine(_light.cameraToLocalTransform, surface.object.localToCameraTransform);
			drawUnit.setVertexConstantsFromTransform(vertexLinker.getVariableIndex("cObjectToLightTransform"), objectToLightTransform);

			// Устанавливаем шедоумапу
			drawUnit.setTextureAt(fragmentLinker.getVariableIndex("sCubeMap"), cubeShadowMap);

			// Устанавливаем коеффициенты
			if (_pcfOffset > 0) {
				var offset:Number = Math.tan(_pcfOffset / 180 * Math.PI) / 3;
				drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cPCFOffsets"), -3 / 2, 1 / 16, 0, 0);
				drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cConstants"), -1, 1, 0, offset);
				drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cDecode"), -DIFFERENCE_MULTIPLIER, -DIFFERENCE_MULTIPLIER / 255, biasMultiplier * DIFFERENCE_MULTIPLIER / radius, 10);
			} else {
				drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cConstants"), -DIFFERENCE_MULTIPLIER, -DIFFERENCE_MULTIPLIER / 255, biasMultiplier * DIFFERENCE_MULTIPLIER / radius, 1.0);
			}
		}

		private static function getVShader():Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				"#v0=vSample",

				"m34 t0.xyz, i0, c0",

				"mov v0, t0.xyz"
			], "OmniShadowMapVertex");
			shader.assignVariableName(VariableType.CONSTANT, 0, "cObjectToLightTransform", 3);
			return shader;
		}

		private static function getFShader():Procedure {
			var shaderArr:Array = [
				"#v0=vSample",
				"#c0=cConstants",
				"#s0=sCubeMap"
			];
			var line:int = 3;
			// Расстояние
			shaderArr[line++] = "dp3 t0.z, v0.xyz, v0.xyz";
			shaderArr[line++] = "sqt t0.z, t0.z";			// w: [0, radius]
			shaderArr[line++] = "tex t0.xy, v0, s0 <cube, nearest>";
			shaderArr[line++] = "dp3 t0.x, t0.xyz, c0.xyz";		// декодируем, находим разницу между расстояниями и умножаем ее на большое число

			// рассчитываем значение тени
			shaderArr[line++] = "sat t0.x, t0.x";
			shaderArr[line++] = "sub o0, c0.w, t0.x";

//			shaderArr[line++] = "sat t0.x, t0.x";
//			shaderArr[line++] = "sub t0.x, c0.w, t0.x";
//			shaderArr[line++] = "sat t0.x, t0.x";
//			shaderArr[line++] = "mov o0, t0.x";

			return Procedure.compileFromArray(shaderArr, "OmniShadowMapFragment");
		}

		private static function getFShaderPCF():Procedure {
			var shaderArr:Array = [
				"#v0=vSample",
				"#c0=cDecode",
				"#c1=cConstants",
				"#c2=cPCFOffsets",
				"#s0=sCubeMap"
			];
			var line:int = 5;
			var i:int;
			var j:int;

			// допустимо использование временных переменных t0 t1 t2 t3
			// v0 - sample

			// calculate 2 ortogonal vectors
			// (-y, x, 0)
			shaderArr[line++] = "mov t1.xyzw, v0.yxzw";
			shaderArr[line++] = "mul t1.xyzw, t1.xyzw, c1.xyzz";

			shaderArr[line++] = "crs t0.xyz, v0.xyz, t1.xyz";

			// normalize vectors
			shaderArr[line++] = "nrm t0.xyz, t0.xyz";
			shaderArr[line++] = "nrm t1.xyz, t1.xyz";

			shaderArr[line++] = "dp3 t3.z, v0.xyz, v0.xyz";
			shaderArr[line++] = "sqt t3.z, t3.z";			//  distance

			// apply pcf offset
			shaderArr[line++] = "mul t0.w, c1.w, t3.z";		//	с1.w = offset/radius
			shaderArr[line++] = "mul t0.xyz, t0.xyz, t0.w";
			shaderArr[line++] = "mul t1.xyz, t1.xyz, t0.w";
			// --------- {13  opcode}

			// t0, t1 - ortogonals ↑→
			// t2 - current vector

			// t3.z distance to object
			// t3.xy - result from shadow map
			// t3.w - summ of sat

			// first point
			shaderArr[line++] = "add t2.xyz, t0.xyz, t1.xyz";
			shaderArr[line++] = "mul t2.xyz, t2.xyz, c2.xxx";
			shaderArr[line++] = "add t2.xyz, t2.xyz, v0.xyz";

			// получаем длинну из шадоумапы [0, 1]
//			shaderArr[line++] = "mov t3.z, t0.w";

			shaderArr[line++] = "tex t3.xy, t2.xyz, s0 <cube, nearest>";
			shaderArr[line++] = "dp3 o0." + componentByIndex[0] + ", t3.xyz, c0.xyz";				// декодируем, вычитаем, умножаем на большое число

			//-----

			for (j = 1; j < 4; j++) {
				shaderArr[line++] = "add t2.xyz, t2.xyz, t1.xyz";

				shaderArr[line++] = "tex t3.xy, t2.xyz, s0 <cube, nearest>";
				shaderArr[line++] = "dp3 o0." + componentByIndex[j] + ", t3.xyz, c0.xyz";			// декодируем, вычитаем, умножаем на большое число
			}

			shaderArr[line++] = "sat o0, o0";
			shaderArr[line++] = "dp4 t3.w, o0, c2.y";

			//-----

			for (i = 0; i < 3; i++) {
				shaderArr[line++] = "add t2.xyz, t2.xyz, t0.xyz";

				shaderArr[line++] = "tex t3.xy, t2.xyz, s0 <cube, nearest>";
				shaderArr[line++] = "dp3 o0." + componentByIndex[0] + ", t3.xyz, c0.xyz";			// декодируем, вычитаем, умножаем на большое число

				for (j = 1; j < 4; j++) {
					shaderArr[line++] = (i % 2 == 1) ? ("add t2.xyz, t2.xyz, t1.xyz") : ("sub t2.xyz, t2.xyz, t1.xyz");

					shaderArr[line++] = "tex t3.xy, t2.xyz, s0 <cube, nearest>";
					shaderArr[line++] = "dp3 o0." + componentByIndex[j] + ", t3.xyz, c0.xyz";			// декодируем, вычитаем, умножаем на большое число
				}
				shaderArr[line++] = "sat o0, o0";
				shaderArr[line++] = "dp4 o0.x, o0, c2.y";
				shaderArr[line++] = "add t3.w, t3.w, o0.x";
			}

			shaderArr[line++] = "sub o0, c1.y, t3.w";

			//--------- {73 opcodes}
			return Procedure.compileFromArray(shaderArr, "OmniShadowMapFragment");
		}

		private static const componentByIndex:Array = ["x", "y", "z", "w"];

		/**
		 * Adds  given object to list of objects, that cast shadow.
		 * @param object Added object.
		 */
		public function addCaster(object:Object3D):void {
			if (_casters.indexOf(object) < 0) {
				_casters.push(object);
			}
		}

		/**
		 * Removes given object from shadow casters list.
		 * @param object Object which should be removed from shadow casters list.
		 */
		public function removeCaster(object:Object3D):void {
			var index:int = _casters.indexOf(object);
			if (index < 0) throw new Error("Caster not found");
			if (index == _casters.length - 1) {
				_casters.pop();
			}
			else {
				_casters[index] = _casters.pop();
			}
		}

		/**
		* Clears the list of objects, that cast shadow.
		*/
		public function clearCasters():void {
			_casters.length = 0;
		}

		/**
		 * Set resolution of shadow map. This property can get value of power of 2 (up to 2048).
		 * OmniLightShadow uses 6 shadow maps.
		 */
		public function get mapSize():int {
			return _mapSize;
		}

		/**
		 * @private
		 */
		public function set mapSize(value:int):void {
			if (value != _mapSize) {
				this._mapSize = value;
				if (value < 2) {
					throw new ArgumentError("Map size cannot be less than 2.");
				} else if (value > 1024) {
					throw new ArgumentError("Map size exceeds maximum value 1024.");
				}
				if ((Math.log(value) / Math.LN2 % 1) != 0) {
					throw new ArgumentError("Map size must be power of two.");
				}
				if (cubeShadowMap != null) {
					cubeShadowMap.dispose();
				}
				cubeShadowMap = null;
			}
		}

		/**
		 * Offset of Percentage Closer Filtering. This way of filtering is used for mitigation of shadow bounds.
		 */
		public function get pcfOffset():Number {
			return _pcfOffset;
		}

		/**
		 * @private
		 */
		public function set pcfOffset(value:Number):void {
			_pcfOffset = value;
			type = _pcfOffset > 0 ? Shadow.PCF_MODE : Shadow.SIMPLE_MODE;
			fragmentShadowProcedure = _pcfOffset > 0 ? getFShaderPCF() : getFShader();
		}

	}
}

import alternativa.engine3d.alternativa3d;
import alternativa.engine3d.core.Camera3D;
import alternativa.engine3d.core.DrawUnit;
import alternativa.engine3d.core.Light3D;
import alternativa.engine3d.core.Object3D;
import alternativa.engine3d.core.Renderer;
import alternativa.engine3d.core.VertexAttributes;
import alternativa.engine3d.materials.Material;
import alternativa.engine3d.materials.ShaderProgram;
import alternativa.engine3d.materials.compiler.Linker;
import alternativa.engine3d.materials.compiler.Procedure;
import alternativa.engine3d.materials.compiler.VariableType;
import alternativa.engine3d.objects.Surface;
import alternativa.engine3d.resources.Geometry;

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.CubeTexture;
import flash.utils.Dictionary;

class ShadowDebugMaterial extends Material {

	use namespace alternativa3d;

	/**
	 * Прозрачность.
	 * Является дополнительным множителем к прозрачности текстуры.
	 * Значение по умолчанию <code>1</code>.
	 */
	alternativa3d var alpha:Number = 1;

	private var cachedContext3D:Context3D;
	private static var caches:Dictionary = new Dictionary(true);
	private var program:ShaderProgram;

	/**
	 * Текстура.
	 */
	alternativa3d var cubeMap:CubeTexture;

	/**
	 * @private
	 */
	override alternativa3d function collectDraws(camera:Camera3D, surface:Surface, geometry:Geometry, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean, objectRenderPriority:int = -1):void {
		var object:Object3D = surface.object;
		// Стримы
		var positionBuffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
		// Проверка на валидность
		if (positionBuffer == null) return;

		// Обновляем кеш программы для данного контекста
		if (camera.context3D != cachedContext3D) {
			cachedContext3D = camera.context3D;
			program = caches[cachedContext3D];
		}

		if (program == null) {
			program = setupProgram(object);
			program.upload(camera.context3D);
			caches[cachedContext3D] = program;
		}

		// Создание отрисовочного вызова
		var drawUnit:DrawUnit = camera.renderer.createDrawUnit(object, program.program, geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);
		// Установка стримов
		drawUnit.setVertexBufferAt(program.vertexShader.getVariableIndex("aPosition"), positionBuffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
		// Установка констант
		drawUnit.setProjectionConstants(camera, program.vertexShader.getVariableIndex("cProjMatrix"), object.localToCameraTransform);
		drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cDecode"), 1, 1 / 255, 0, alpha);
		drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sCubeMap"), cubeMap);

		// Отправка на отрисовку
		if (alpha < 1) {
			drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
			drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.TRANSPARENT_SORT);
		} else {
			camera.renderer.addDrawUnit(drawUnit, objectRenderPriority >= 0 ? objectRenderPriority : Renderer.OPAQUE);
		}
	}

	private function copyDrawUnit(source:DrawUnit, dest:DrawUnit):void {

	}

	private function setupProgram(object:Object3D):ShaderProgram {
		var vertexLinker:Linker = new Linker(Context3DProgramType.VERTEX);
		var positionVar:String = "aPosition";
		vertexLinker.declareVariable(positionVar, VariableType.ATTRIBUTE);

		var proc:Procedure = Procedure.compileFromArray([
			"#v0=vCubeMapCoord",
			"mov v0, i0",
			"m44 o0, i0, c0"
		]);
		proc.assignVariableName(VariableType.CONSTANT, 0, "cProjMatrix", 4);
		vertexLinker.addProcedure(proc, positionVar);

		var fragmentLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
		var colorProc:Procedure = Procedure.compileFromArray([
			"#v0=vCubeMapCoord",
			"#s0=sCubeMap",
			"#c0=cDecode",

			"tex t0.xy, v0, s0 <cube, linear>",
			"dp3 t0.xyz, t0.xy, c0.xy",
			"mov t0.w, c0.w",
			"mov o0, t0"
		]);
		fragmentLinker.addProcedure(colorProc, "vCubeMapCoord");
		fragmentLinker.varyings = vertexLinker.varyings;
		return new ShaderProgram(vertexLinker, fragmentLinker);
	}

}

class SectionPlane {

	public var x:Number = 0;
	public var y:Number = 0;
	public var z:Number = 0;
	public var offset:Number = 0;

	public var next:SectionPlane;

	public var frontCameras:int;
	public var backCameras:int;
	public var unusedBits:int = 63;

	public function SectionPlane(frontCameras:int, backCameras:int, unused:int) {
		this.frontCameras = frontCameras;
		this.backCameras = backCameras;
		this.unusedBits = unused;
	}

}
