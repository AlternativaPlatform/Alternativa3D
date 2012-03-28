package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.Geometry;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.display3D.textures.CubeTexture;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class OmniShadowRenderer extends ShadowRenderer {

//		[Embed("geosphere.A3D", mimeType="application/octet-stream")] private static const ModelClass:Class;
		private static const debugGeometry:Geometry = createDebugGeometry();
		private static function createDebugGeometry():Geometry {
//			var parser:ParserA3D = new ParserA3D();
//			parser.parse(new ModelClass());
//			var mesh:Mesh = Mesh(parser.getObjectByName("sphere"));
//			return mesh.geometry;
			var geo:GeoSphere = new GeoSphere(0.5, 4);
			return geo.geometry;
		}

		private var caster:Object3D;
		private var casterBounds:BoundBox = new BoundBox();

		private var pcfOffset:Number = 0;

		private var context:Context3D;

		public var omnies:Vector.<OmniLight>;

		private var shadowMap:CubeTexture;
		private var shadowMapSize:int;
		private var cameras:Vector.<Camera3D> = new Vector.<Camera3D>();
		private var clearBits:uint = 0xFF;
		
		private var currentOmni:OmniLight = new OmniLight(0, 0, 0);

		private static const constants:Vector.<Number> = Vector.<Number>([
			255, 0.97, 10000, 1/255
		]);
		private static const offset:Number = 0.005;
		private static const pcfOffsets:Vector.<Number> = Vector.<Number>([
			-offset, -offset, -offset, 1/8,
			-offset, -offset, offset, 1,
			-offset, offset, -offset, 1,
			-offset, offset, offset, 1,
			offset, -offset, -offset, 1,
			offset, -offset, offset, 1,
			offset, offset, -offset, 1,
			offset, offset, offset, 1,
		]);
		
		public function OmniShadowRenderer(context:Context3D, size:int, pcfSize:Number = 0) {
			this.context = context;
			this.pcfOffset = pcfSize;
			shadowMapSize = size;
			shadowMap = context.createCubeTexture(size, Context3DTextureFormat.BGRA, true);
			debugGeometry.upload(context);

			for (var i:int = 0; i < 6; i++) {
				var cam:Camera3D = new Camera3D(1, 100);
				cam.fov = 1.910633237;
				cam.view = new View(size, size);
				cameras[i] = cam;
			}
			// Left
			cameras[1].rotationY = -Math.PI/2;
			cameras[1].scaleY = -1;
			// Right
			cameras[0].rotationY = Math.PI/2;
			cameras[0].scaleY = -1;
			// Back
			cameras[3].rotationX = -Math.PI/2;
			cameras[3].rotationZ = Math.PI;
			cameras[3].scaleX = -1;
			// Front
			cameras[2].rotationX = -Math.PI/2;
			cameras[2].scaleY = -1;
			// Bottom
			cameras[5].rotationX = Math.PI;
			cameras[5].scaleX = -1;
			// Top
			cameras[4].rotationX = 0;
			cameras[4].scaleY = -1;
		}

		alternativa3d override function cullReciever(boundBox:BoundBox, object:Object3D):Boolean {
//			tempBounds.reset();
//			object.localToCameraTransform.copy(object.localToGlobalTransform);
//			StaticShadowRenderer.calculateBoundBox(tempBounds, object, false);
			var bounds:BoundBox = object.boundBox;
			object.globalToLocalTransform.copy(object.localToGlobalTransform);
			object.globalToLocalTransform.invert();
			var inverseMatrix:Transform3D = object.globalToLocalTransform;

//			trace(object.scaleX, object.scaleY, object.scaleZ);
			var ox:Number = inverseMatrix.a*currentOmni._x + inverseMatrix.b*currentOmni._y + inverseMatrix.c*currentOmni._z + inverseMatrix.d;
			var oy:Number = inverseMatrix.e*currentOmni._x + inverseMatrix.f*currentOmni._y + inverseMatrix.g*currentOmni._z + inverseMatrix.h;
			var oz:Number = inverseMatrix.i*currentOmni._x + inverseMatrix.j*currentOmni._y + inverseMatrix.k*currentOmni._z + inverseMatrix.l;
			var radius:Number = currentOmni.attenuationEnd;
			if (ox + radius > bounds.minX && ox - radius < bounds.maxX && oy + radius > bounds.minY && oy - radius < bounds.maxY && oz + radius > bounds.minZ && oz - radius < bounds.maxZ) {
				return true;
			}
			return false;
		}

		alternativa3d override function get needMultiplyBlend():Boolean {
			return true;
		}

		public var debugObject:Mesh = new Mesh();
		// TODO: repair
//		private var debugMaterial:OmniShadowRendererDebugMaterial = new OmniShadowRendererDebugMaterial();
		private var debugMaterial:Object;

		public function setCaster(object:Object3D):void {
			caster = object;
			object.localToCameraTransform.identity();
			StaticShadowRenderer.calculateBoundBox(casterBounds, object);

			debugObject.geometry = debugGeometry;
//			debugObject.addSurface(debugMaterial, 0, debugGeometry.numTriangles);
			debugObject.addSurface(new FillMaterial(0xFFFFFF), 0, debugGeometry.numTriangles);
			debugObject.scaleX = 400;
			debugObject.scaleY = 400;
			debugObject.scaleZ = 400;
		}

		private var culledOmnies:Vector.<OmniLight> = new Vector.<OmniLight>();

		private var influences:Vector.<Number> = new Vector.<Number>();
		private static const inverseMatrix:Transform3D = new Transform3D();

//		private static const omniLocalCoords:Vector.<Number> = new Vector.<Number>(3);

		override public function update():void {
			// Расчет матрицы объекта
			caster.localToGlobalTransform.compose(caster._x, caster._y, caster._z, caster._rotationX, caster._rotationY, caster._rotationZ, caster._scaleX, caster._scaleY, caster._scaleZ);
			var root:Object3D = caster;
			while (root._parent != null) {
				root = root._parent;
				root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
				caster.localToGlobalTransform.append(root.localToGlobalTransform);
			}
			// Расчет матрицы перевода в объект
			caster.globalToLocalTransform.copy(caster.localToGlobalTransform);
			caster.globalToLocalTransform.invert();

/**
//			// Вычисление множителя масштаба
//			caster.inverseCameraMatrix.transformVectors(sIn, sOut);
//			var dx:Number = sOut[0] - sOut[3];
//			var dy:Number = sOut[1] - sOut[4];
//			var dz:Number = sOut[2] - sOut[5];
//			var scale:Number = Math.sqrt(dx*dx + dy*dy + dz*dz);*/

//			var selectedOmni:OmniLight;
//			var selectedOmniInfluence:Number = -1;
			var influenceSum:Number = 0;

			var omni:OmniLight;

			culledOmnies.length = 0;
			influences.length = 0;
			// Куллинг источников света и нахождение основного
			for each (omni in omnies) {
				// Вычисление глобальной позиции омника
				inverseMatrix.identity();
				var parent:Object3D = omni._parent;
				if (parent != null) {
					parent.localToGlobalTransform.compose(parent._x, parent._y, parent._z, parent._rotationX, parent._rotationY, parent._rotationZ, parent._scaleX, parent._scaleY, parent._scaleZ);
					root = parent;
					while (root._parent != null) {
						if (root == caster || parent == caster) {
							throw new Error("Caster can not be parent of light");
						}
						root = root._parent;
						root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
						parent.localToGlobalTransform.append(root.localToGlobalTransform);
					}
					inverseMatrix.append(parent.localToGlobalTransform);
				}
				inverseMatrix.append(caster.globalToLocalTransform);

				var ox:Number = inverseMatrix.a*omni._x + inverseMatrix.b*omni._y + inverseMatrix.c*omni._z + inverseMatrix.d;
				var oy:Number = inverseMatrix.e*omni._x + inverseMatrix.f*omni._y + inverseMatrix.g*omni._z + inverseMatrix.h;
				var oz:Number = inverseMatrix.i*omni._x + inverseMatrix.j*omni._y + inverseMatrix.k*omni._z + inverseMatrix.l;

				// Использовать описывающий баунд-бокс объекта
				// Куллинг
				if (ox + omni.attenuationEnd > casterBounds.minX && ox - omni.attenuationEnd < casterBounds.maxX && oy + omni.attenuationEnd > casterBounds.minY && oy - omni.attenuationEnd < casterBounds.maxY && oz + omni.attenuationEnd > casterBounds.minZ && oz - omni.attenuationEnd < casterBounds.maxZ) {
					// В зоне действия источника
					// Считаем степень влияния
					var d:Number = Math.sqrt(ox*ox + oy*oy + oz*oz)/omni.attenuationEnd - 0.1;
					var influence:Number;
					if (d > 1) {
						influence = 0;
					} else {
						influence = omni.intensity*calcBrightness(omni.color) * (1 - d);
					}
//					if (influence > selectedOmniInfluence) {
//						selectedOmni = omni;
//						selectedOmniInfluence = influence;
//					}
					influenceSum += influence;
					influences.push(influence);
					culledOmnies.push(omni);
				}
			}
			debugMaterial.texture = null;

			var i:int;
			var surface:uint;
			var drawed:int = 0;
/**			if (selectedOmni == null || influenceSum <= 0) {*/
			if (culledOmnies.length == 0 || influenceSum <= 0) {
				// Ни один источник не влияет
				for (i = 0; i < 6; i++) {
					surface = 1 << i;
					if (clearBits & surface) {
						context.setRenderToTexture(shadowMap, true, 0, i);
//						context.clear(1);
						context.clear(1, 1, 1, 1);
//						trace("clear", i);
						clearBits &= ~surface;
					}
				}
//				trace("INVISIBLE");
			} else {
				currentOmni._x = 0;
				currentOmni._y = 0;
				currentOmni._z = 0;
				currentOmni.attenuationEnd = 0;
				for (i = 0; i < culledOmnies.length; i++) {
					var weight:Number = influences[i]/influenceSum;
					omni = culledOmnies[i];
					// Считаем матрицу перевода в глобальное пространство из омника
					omni.localToGlobalTransform.identity();
					omni.localToGlobalTransform.d = omni.x;
					omni.localToGlobalTransform.h = omni.y;
					omni.localToGlobalTransform.l = omni.z;
					root = omni;
					while (root._parent != null) {
						root = root._parent;
						if (root.transformChanged) root.composeTransforms();
						omni.localToGlobalTransform.append(root.transform);
					}
					currentOmni._x += omni.localToGlobalTransform.d*weight;
					currentOmni._y += omni.localToGlobalTransform.h*weight;
					currentOmni._z += omni.localToGlobalTransform.l*weight;
					currentOmni.attenuationEnd += omni.attenuationEnd*weight;
				}
				currentOmni.localToGlobalTransform.identity();
				currentOmni.localToGlobalTransform.d = currentOmni._x;
				currentOmni.localToGlobalTransform.h = currentOmni._y;
				currentOmni.localToGlobalTransform.l = currentOmni._z;

//				constants[3] = 0.5*1/255;
				constants[3] = 1.0/255;
/**				// Расчитываем яркость тени
//				var weight:Number = (selectedOmniInfluence > 0) ? 1 - (influenceSum - selectedOmniInfluence)/influenceSum : 0;
//				trace(weight, influenceSum, selectedOmniInfluence);
//				trace(weight);
//				var weight:Number = 1;
//				if (weight > 0) {
//					constants[3] = (1 + (1 - weight)*5)/255;
//				} else {
//					constants[3] = 1/255;
//				}
//				// Считаем матрицу перевода в глобальное пространство из омника
//				selectedOmni.cameraMatrix.identity();
//				selectedOmni.cameraMatrix.appendTranslation(selectedOmni.x, selectedOmni.y, selectedOmni.z);
////				selectedOmni.composeMatrix();
//				root = selectedOmni;
//				while (root._parent != null) {
//					root = root._parent;
//					root.composeMatrix();
//					selectedOmni.cameraMatrix.append(root.cameraMatrix);
//				}
////			// Матрица родителя уже посчитана
////			if (omni._parent != null) {
////				omni.cameraMatrix.append(omni._parent.cameraMatrix);
////			}
//				selectedOmni.globalCoords[0] = 0;
//				selectedOmni.globalCoords[1] = 0;
//				selectedOmni.globalCoords[2] = 0;
//				selectedOmni.cameraMatrix.transformVectors(selectedOmni.globalCoords, selectedOmni.globalCoords); */
				// Записываем параметры омника в константы
				
				debugObject.x = currentOmni._x;
				debugObject.y = currentOmni._y;
				debugObject.z = currentOmni._z;

				cleanContext(context);
				for (i = 0; i < 6; i++) {
					surface = 1 << i;
					context.setRenderToTexture(shadowMap, true, 0, i);
//					trace("SIDE:", i);
					if (renderToOmniShadowMap(currentOmni, cameras[i])) {
						drawed++;
						clearBits |= surface;
					} else {
						if (clearBits & surface) {
//							trace("clear", i);
							context.clear(1, 1, 1, 1);
//							context.clear(1, 1, 1, 1);
							clearBits &= ~surface;
						}
					}
				}
//				trace("NUMSIDES:", drawed);
				debugMaterial.texture = shadowMap;
			}
			context.setRenderToBackBuffer();
			cleanContext(context);
			active = drawed > 0;
		}

		private function calcBrightness(color:uint):Number {
			var r:uint = color & 0xFF;
			var g:uint = (color >> 8) & 0xFF;
			var b:uint = (color >> 16) & 0xFF;
			var result:uint = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b);
			return result/255;
		}

//		private var axises:Vector.<Number> = Vector.<Number>([
//			1, 0, 0,
//			0, 1, 0,
//		]);
//		private var globalAxises:Vector.<Number> = new Vector.<Number>(6);

		public function renderToOmniShadowMap(omni:OmniLight, camera:Camera3D):Boolean {
			camera.nearClipping = 1;
			camera.farClipping = omni.attenuationEnd;
			// Расчёт параметров проецирования
			camera.calculateProjection(camera.view._width, camera.view._height);

			if (camera.transformChanged) camera.composeTransforms();
			// Считаем омник родительским объектом камеры
			camera.localToGlobalTransform.combine(omni.localToGlobalTransform, camera.transform);
			camera.globalToLocalTransform.copy(camera.localToGlobalTransform);
			camera.globalToLocalTransform.invert();

			caster.localToCameraTransform.compose(caster._x, caster._y, caster._z, caster._rotationX, caster._rotationY, caster._rotationZ, caster._scaleX, caster._scaleY, caster._scaleZ);
			var root:Object3D = caster;
			while (root._parent != null) {
				root = root._parent;
				if (root.transformChanged) root.composeTransforms();
				caster.localToCameraTransform.append(root.transform);
			}
			caster.localToCameraTransform.append(camera.globalToLocalTransform);

/**			if (pcfOffset > 0.1) {
//				axises[0] = pcfOffset;
//				// Считаем преобразования PCF
//				camera.globalMatrix.transformVectors(axises, globalAxises);
//				pcfOffsets[0] = -pcfOffset*globalAxises[0];
//				pcfOffsets[1] = -pcfOffset*globalAxises[1];
//				pcfOffsets[2] = -pcfOffset*globalAxises[2];
//				pcfOffsets[4] = pcfOffset*globalAxises[0];
//				pcfOffsets[5] = pcfOffset*globalAxises[1];
//				pcfOffsets[6] = pcfOffset*globalAxises[2];
//				pcfOffsets[8] = -pcfOffset*globalAxises[3];
//				pcfOffsets[9] = -pcfOffset*globalAxises[4];
//				pcfOffsets[10] = -pcfOffset*globalAxises[5];
//				pcfOffsets[12] = pcfOffset*globalAxises[3];
//				pcfOffsets[13] = pcfOffset*globalAxises[4];
//				pcfOffsets[14] = pcfOffset*globalAxises[5];
			} */

			// Отрисовка в шедоумапу
			if (cullingInCamera(caster, casterBounds)) {
				context.clear(1, 1, 0, 1);
				drawObjectToShadowMap(context, caster, camera);
				return true;
			}
			return false;
		}

		private static const points:Vector.<Vector3D> = Vector.<Vector3D>([
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D()
		]);
		private static const boundVertices:Vector.<Number> = new Vector.<Number>(24);
		alternativa3d function cullingInCamera(object:Object3D, objectBounds:BoundBox):Boolean {
			var i:int;
			var infront:Boolean;
			var behind:Boolean;
			// Заполнение
			var point:Vector3D;
			var bb:BoundBox = objectBounds;
			point = points[0];
			point.x = bb.minX;
			point.y = bb.minY;
			point.z = bb.minZ;
			point = points[1];
			point.x = bb.minX;
			point.y = bb.minY;
			point.z = bb.maxZ;
			point = points[2];
			point.x = bb.minX;
			point.y = bb.maxY;
			point.z = bb.minZ;
			point = points[3];
			point.x = bb.minX;
			point.y = bb.maxY;
			point.z = bb.maxZ;
			point = points[4];
			point.x = bb.maxX;
			point.y = bb.minY;
			point.z = bb.minZ;
			point = points[5];
			point.x = bb.maxX;
			point.y = bb.minY;
			point.z = bb.maxZ;
			point = points[6];
			point.x = bb.maxX;
			point.y = bb.maxY;
			point.z = bb.minZ;
			point = points[7];
			point.x = bb.maxX;
			point.y = bb.maxY;
			point.z = bb.maxZ;
			// Коррекция под 90 градусов
			var transform:Transform3D = object.localToCameraTransform;
			for (i = 0; i < 8; i++) {
				point = points[i];
				var x:Number = transform.a*point.x + transform.b*point.y + transform.c*point.z + transform.d;
				var y:Number = transform.e*point.x + transform.f*point.y + transform.g*point.z + transform.h;
				var z:Number = transform.i*point.x + transform.j*point.y + transform.k*point.z + transform.l;
				var index:int = 3*i;
				boundVertices[int(index++)] = x;
				boundVertices[int(index++)] = y;
				boundVertices[index] = z;
			}

			// Куллинг
			for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
				if (-boundVertices[i] < boundVertices[int(i + 2)]) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
//				trace("L", infront);
				if (!infront) return false;
			}
			for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
				if (boundVertices[i] < boundVertices[int(i + 2)]) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
//				trace("R", infront);
				if (!infront) return false;
			}
			for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
				if (-boundVertices[i] < boundVertices[int(i + 1)]) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
//				trace("U", infront);
				if (!infront) return false;
			}
			for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
				if (boundVertices[i] < boundVertices[int(i + 1)]) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
//				trace("D", infront);
				if (!infront) return false;
			}
			return true;
		}
		
		alternativa3d static function drawObjectToShadowMap(context:Context3D, object:Object3D, camera:Camera3D):void {
			if (object is Mesh) {
				drawMeshToShadowMap(context, Mesh(object), camera);
			}
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				if (child.visible) {
					if (child.transformChanged) child.composeTransforms();
					child.localToCameraTransform.combine(object.localToCameraTransform, child.transform);
					drawObjectToShadowMap(context, child, camera);
				}
			}
		}

		private static function copyRawFromTransform(raw:Vector.<Number>, transform:Transform3D):void {
			raw[0] = transform.a;
			raw[1] = transform.b;
			raw[2] = transform.c;
			raw[3] = transform.d;
			raw[4] = transform.e;
			raw[5] = transform.f;
			raw[6] = transform.g;
			raw[7] = transform.h;
			raw[8] = transform.i;
			raw[9] = transform.j;
			raw[10] = transform.k;
			raw[11] = transform.l;
			raw[12] = 0;
			raw[13] = 0;
			raw[14] = 0;
			raw[15] = 1;
		}

		private static var shadowMapProgram:Program3D;
		private static var projectionVector:Vector.<Number> = new Vector.<Number>(16);
		private static function drawMeshToShadowMap(context:Context3D, mesh:Mesh, camera:Camera3D):void {
			if (mesh.geometry == null || mesh.geometry.numTriangles == 0 || !mesh.geometry.isUploaded) {
				return;
			}

			// TODO : update to new logic
			if (shadowMapProgram == null) shadowMapProgram = initMeshToShadowMapProgram(context);
			context.setProgram(shadowMapProgram);

			context.setVertexBufferAt(0, mesh.geometry.getVertexBuffer(VertexAttributes.POSITION), mesh.geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);

			// TODO: uncomment
//			camera.composeProjectionMatrix(projectionVector, 0, mesh.localToCameraTransform);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, projectionVector, 4);

			copyRawFromTransform(projectionVector, mesh.localToCameraTransform);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, projectionVector, 4);

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, Vector.<Number>([Math.sqrt(255)/camera.farClipping, 0, 0, 1]));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1/255, 0, 0, 1]));

			context.setCulling(Context3DTriangleFace.BACK);
			for (var i:int = 0; i < mesh._surfacesLength; i++) {
				var surface:Surface = mesh._surfaces[i];
				if (surface.material == null) continue;
				context.drawTriangles(mesh.geometry._indexBuffer, surface.indexBegin, surface.numTriangles);
			}
			context.setVertexBufferAt(0, null);
		}

		private static function initMeshToShadowMapProgram(context3d:Context3D):Program3D {
			var vLinker:Linker = new Linker(Context3DProgramType.VERTEX);
			var fLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
			var proc:Procedure = Procedure.compileFromArray([
				"#a0=a0",
				"#c8=c8",
				"#v0=v0",
				"m44 o0, a0, c0",
				"m44 t0, a0, c4",
				"mul t0, t0, c8.x",
				"mov v0, t0"
			]);
			proc.assignVariableName(VariableType.CONSTANT, 0, "c0", 4);
			proc.assignVariableName(VariableType.CONSTANT, 4, "c4", 4);
			vLinker.addProcedure(proc);

			fLinker.addProcedure(Procedure.compileFromArray([
				"#v0=v0",
				"#c0=c0",
				"mov t0.zw, c0.z \n",
				"dp3 t1.w, v0.xyz, v0.xyz \n",
				"frc t0.y, t1.w",
				"sub t0.x, t1.w, t0.y",
				"mul t0.x, t0.x, c0.x",
				"mov o0, to"
			]));
			var program:Program3D = context3d.createProgram();
//			trace("VERTEX");
//			trace(A3DUtils.disassemble(vLinker.getByteCode()));
//			trace("FRAGMENT");
//			trace(A3DUtils.disassemble(fLinker.getByteCode()));
			fLinker.varyings = vLinker.varyings;
			vLinker.link();
			fLinker.link();
			program.upload(vLinker.data, fLinker.data);
			return program;
		}

		private static function initVShader():Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				// Координата вершины в глобальном пространстве
				"m44 v0, a0, c0"
			]);
			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPosition");
			shader.assignVariableName(VariableType.CONSTANT, 0, "cGLOBALMATRIX", 4);
			shader.assignVariableName(VariableType.VARYING, 0, "vPOSITION");
			return shader;
		}

		private static function initFShader(mult:Boolean, usePCF:Boolean):Procedure {
			var line:int = 0;
			var shaderArr:Array = [];
			var numPass:uint = (usePCF) ? 8 : 1;
			for (var i:int = 0; i < numPass; i++) {
				// Вектор от источника света к точке
				shaderArr[line++] = "sub t0.xyz, v0.xyz, c4.xyz";
				
				// Квадрат расстояния
				shaderArr[line++] = "dp3 t0.w, t0.xyz, t0.xyz";
				shaderArr[line++] = "mul t0.w, t0.w, c4.w";	// * (255 / radius^2)
				shaderArr[line++] = "mul t0.w, t0.w, c5.y";	// bias [0.95]
				
				// Квадрат расстояния из карты теней
				shaderArr[line++] = "nrm t0.xyz, t0.xyz";
				
				if (usePCF) {
					shaderArr[line++] = "add t0.xyz, t0.xyz, c" + (i + 6).toString();
				}
				
				shaderArr[line++] = "tex t1, t0, s0 <cube,clamp,near,nomip>";
				shaderArr[line++] = "mov t3, t1";
				shaderArr[line++] = "mul t1.w, t1.x, c5.x";		// 255
				shaderArr[line++] = "add t1.w, t1.w, t1.y";
				
				// Перекрытие тенью
				shaderArr[line++] = "sub t2.z, t1.w, t0.w";
				shaderArr[line++] = "mul t2.z, t2.z, c5.z";		// smooth [10000]
				shaderArr[line++] = "sat t2.z, t2.z";
				
//				// Затухание тени по расстоянию
				shaderArr[line++] = "mul t1.x, t0.w, c5.w";		// div 255
				shaderArr[line++] = "add t2.z, t2.z, t1.x";
				if (i == 0) {
					shaderArr[line++] = "sat t2.x, t2.z";
				} else {
					shaderArr[line++] = "sat t2.z, t2.z";
					shaderArr[line++] = "add t2.x, t2.x, t2.z";
				}
			}
			if (usePCF) {
				shaderArr[line++] = "mul t2.x, t2.x, c6.w";
			}
			if (mult) {
				shaderArr.push("mul t0.xyz, i0.xyz, t2.x");
//				shaderArr.push("mul t0.xyz, t1.w, c5.w");
				shaderArr.push("mov t0.w, i0.w");
				shaderArr.push("mov o0, t0");
			} else {
				shaderArr.push("mov o0, t2.xxxx");
			}
			var shader:Procedure = Procedure.compileFromArray(shaderArr, "OmniShadowMap");
			shader.assignVariableName(VariableType.VARYING, 0, "vPOSITION");
			shader.assignVariableName(VariableType.CONSTANT, 4, "cOmni", 1);
			shader.assignVariableName(VariableType.CONSTANT, 5, "cConstants", 1);
			if (usePCF) {
				shader.assignVariableName(VariableType.CONSTANT, 6, "cPCF0", 1);
				shader.assignVariableName(VariableType.CONSTANT, 7, "cPCF1", 1);
				shader.assignVariableName(VariableType.CONSTANT, 8, "cPCF2", 1);
				shader.assignVariableName(VariableType.CONSTANT, 9, "cPCF3", 1);
				shader.assignVariableName(VariableType.CONSTANT, 10, "cPCF4", 1);
				shader.assignVariableName(VariableType.CONSTANT, 11, "cPCF5", 1);
				shader.assignVariableName(VariableType.CONSTANT, 12, "cPCF6", 1);
				shader.assignVariableName(VariableType.CONSTANT, 13, "cPCF7", 1);
			}
			shader.assignVariableName(VariableType.SAMPLER, 0, "sCUBE");
			return shader;
		}

		override public function getVShader(index:int = 0):Procedure {
			return initVShader();
		}

		override public function getFShader(index:int = 0):Procedure {
			return initFShader(false, pcfOffset > 0);
		}

		private static const globalMatrix:Transform3D = new Transform3D();
		override public function applyShader(drawUnit:DrawUnit, program:ShaderProgram, object:Object3D, camera:Camera3D, index:int = 0):void {
			var fLinker:Linker = program.fragmentShader;
			
			globalMatrix.combine(camera.localToGlobalTransform, object.localToCameraTransform);

			var mIndex:int = program.vertexShader.getVariableIndex("cGLOBALMATRIX");
			drawUnit.setVertexConstantsFromNumbers(mIndex, globalMatrix.a, globalMatrix.b, globalMatrix.c,  globalMatrix.d);
			drawUnit.setVertexConstantsFromNumbers(mIndex+1, globalMatrix.e, globalMatrix.f, globalMatrix.g,  globalMatrix.h);
			drawUnit.setVertexConstantsFromNumbers(mIndex+2, globalMatrix.i, globalMatrix.j, globalMatrix.k,  globalMatrix.l);
			drawUnit.setVertexConstantsFromNumbers(mIndex+3, 0, 0, 0, 1);

//			destination.addFragmentConstantSet(fLinker.getVariableIndex("cOmni"), omniPos, 1);
			drawUnit.setFragmentConstantsFromNumbers(fLinker.getVariableIndex("cOmni"), currentOmni._x, currentOmni._y, currentOmni._z, 255/currentOmni.attenuationEnd/currentOmni.attenuationEnd);
			drawUnit.setFragmentConstantsFromVector(fLinker.getVariableIndex("cConstants"), constants, 1);
			if (pcfOffset > 0) {
				drawUnit.setVertexConstantsFromVector(fLinker.getVariableIndex("cPCF0"), pcfOffsets, 8);
			}
			drawUnit.setTextureAt(fLinker.getVariableIndex("sCUBE"), shadowMap);
		}

//		private static var program:LinkedProgram;
//		private static var programPCF:LinkedProgram;
//		private static function initMeshProgram(context:Context3D, usePCF:Boolean):LinkedProgram {
//			var vLinker:Linker = new Linker(Context3DProgramType.VERTEX);
//			vLinker.addShader(vShader);
//
//			var fLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
//			if (usePCF) {
//				fLinker.addShader(pcfFShader);
//			} else {
//				fLinker.addShader(fShader);
//			}
//
//			vLinker.setOppositeLinker(fLinker);
//			fLinker.setOppositeLinker(vLinker);
//
//			trace("[VERTEX]");
//			trace(AgalUtils.disassemble(vLinker.getByteCode()));
//			trace("[FRAGMENT]");
//			trace(AgalUtils.disassemble(fLinker.getByteCode()));
//
//			var result:LinkedProgram;
//			if (usePCF) {
//				programPCF = new LinkedProgram();
//				result = programPCF;
//			} else {
//				program = new LinkedProgram();
//				result = program;
//			}
//			result.vLinker = vLinker;
//			result.fLinker = fLinker;
//			result.program = context.createProgram();
//			result.program.upload(vLinker.getByteCode(), fLinker.getByteCode());
//
//			return result;
//		}
//
//		override public function drawShadow(mesh:Mesh, camera:Camera3D, texture:Texture):void {
//			var context3d:Context3D = camera.view._context3d;
//
//			var linkedProgram:LinkedProgram;
//			if (pcfOffset > 0) {
//				linkedProgram = (programPCF == null) ? initMeshProgram(context3d, true) : programPCF;
//			} else {
//				linkedProgram = (program == null) ? initMeshProgram(context3d, false) : program;
//			}
//			var vLinker:Linker = linkedProgram.vLinker;
//			var fLinker:Linker = linkedProgram.fLinker;
//			context3d.setProgram(linkedProgram.program);
//
//			context3d.setVertexBufferAt(vLinker.getVariableIndex("aPOSITION"), mesh.geometry.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
//			context3d.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vLinker.getVariableIndex("cPROJ"), mesh.projectionMatrix, true);
//			applyShader(context3d, linkedProgram, mesh, camera);
//			context3d.setVertexBufferAt(1, null);
//
//			context3d.setCulling(Context3DTriangleFace.FRONT);
//			context3d.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangles);
//
//			context3d.setVertexBufferAt(vLinker.getVariableIndex("aPOSITION"), null);
//			context.setTextureAt(getTextureIndex(fLinker), texture);
//		}
		
	}
}
