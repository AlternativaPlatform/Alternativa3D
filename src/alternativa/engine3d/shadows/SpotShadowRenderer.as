package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.lights.SpotLight;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class SpotShadowRenderer extends ShadowRenderer {

		public var caster:Object3D;

		private var context:Context3D;
		
		private var shadowMap:Texture;

		private var light:SpotLight;
		
		private var debugObject:Mesh;
		public var debugMaterial:TextureMaterial = new TextureMaterial();
		private var debugTexture:TextureResource = new TextureResource();

		private var globalToShadowMap:Matrix3D = new Matrix3D();

		private static const constants:Vector.<Number> = Vector.<Number>([
			255, 255*0.96, 100, 1
		]);
		
		private var pcfSize:Number = 0;
		private var pcfOffset:Number = 0;
		private var pcfOffsets:Vector.<Number>;
		
		public function SpotShadowRenderer(context:Context3D, size:int, pcfSize:Number = 0) {
			this.context = context;
			this.shadowMap = context.createTexture(size, size, Context3DTextureFormat.BGRA, true);
			this.pcfSize = pcfSize;
			debugTexture._texture = this.shadowMap;
//			debugMaterial.diffuseMap = debugTexture;
			debugMaterial.alpha = 0.9;
			debugMaterial.opaquePass = false;
			debugMaterial.transparentPass = true;
			debugMaterial.alphaThreshold = 1.1;
		}

		public function setLight(value:SpotLight):void {
			light = value;
			var width:Number = 2*Math.sin(light.falloff*0.5)*light.attenuationEnd;
			this.pcfOffset = pcfSize/width/255;
			if (pcfOffset > 0) {
				pcfOffsets = Vector.<Number>([
					-pcfOffset, -pcfOffset, 0, 1/4,
					-pcfOffset, pcfOffset, 0, 1,
					pcfOffset, -pcfOffset, 0, 1,
					pcfOffset, pcfOffset, 0, 1
				]);
			}
			debugObject = new Box(width, width, 1, 1, 1, 1, false, debugMaterial);
			debugObject.rotationX = Math.PI;
			debugObject.geometry.upload(context);
			if (_debug) {
				light.addChild(debugObject);
			}
		}

		private var _debug:Boolean = false;
		override public function get debug():Boolean {
			return _debug;
		}
		
		override public function set debug(value:Boolean):void {
			_debug = value;
			if (_debug) {
				if (light != null) {
					light.addChild(debugObject);
				}
			} else {
				if (debugObject != null && debugObject._parent != null) {
					debugObject._parent.removeChild(debugObject);
				}
			}
		}
		
		private static var matrix:Matrix3D = new Matrix3D();
		override alternativa3d function cullReciever(boundBox:BoundBox, object:Object3D):Boolean {
			copyMatrixFromTransform(matrix, object.localToGlobalTransform);
			matrix.append(this.globalToShadowMap);
			return cullObjectImpl(boundBox, matrix);
		}
		private function cullCaster(boundBox:BoundBox, objectToGlobal:Transform3D):Boolean {
			copyMatrixFromTransform(matrix, objectToGlobal);
			matrix.append(this.globalToShadowMap);
			return cullObjectImpl(boundBox, matrix, light.attenuationEnd);
		}

		private var projection:ProjectionTransform3D = new ProjectionTransform3D();
		private var uvProjection:Matrix3D = new Matrix3D();
		override public function update():void {
			// Считаем матрицу перевода в лайт
			var root:Object3D;
			// Расчитываем матрицу объекта для перевода в глобал
			//			if (caster.transformChanged) {
			caster.localToGlobalTransform.compose(caster._x, caster._y, caster._z, caster._rotationX, caster._rotationY, caster._rotationZ, caster._scaleX, caster._scaleY, caster._scaleZ);
			//			} else {
			//				caster.localToCameraTransform.copy(caster.transform);
			//			}
			root = caster;
			while (root._parent != null) {
				root = root._parent;
				//				if (root.transformChanged) {
				root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
				//				}
				caster.localToGlobalTransform.append(root.localToGlobalTransform);
			}
			
			// Расчитываем матрицу лайта
			light.localToGlobalTransform.compose(light._x, light._y, light._z, light._rotationX, light._rotationY, light._rotationZ, light._scaleX, light._scaleY, light._scaleZ);
			root = light;
			while (root._parent != null) {
				root = root._parent;
				//				if (root.transformChanged) {
				root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
				//				}
				light.localToGlobalTransform.append(root.localToGlobalTransform);
			}
			light.globalToLocalTransform.copy(light.localToGlobalTransform);
			light.globalToLocalTransform.invert();
			
			// Получаем матрицу перевода из объекта в лайт
			caster.localToCameraTransform.combine(light.globalToLocalTransform, caster.localToGlobalTransform);
//			caster.localToCameraTransform.append(light.globalToLocalTransform);

			// Считаем матрицу проецирования
			calculateProjection(projection, uvProjection, light.falloff, 1, light.attenuationEnd);
//			globalToShadowMap.copy(light.globalToLocalTransform);
			copyMatrixFromTransform(globalToShadowMap, light.globalToLocalTransform);
			globalToShadowMap.append(uvProjection);

			debugMaterial.diffuseMap = null;
			
//			trace("TEST:", testCasterCulling(caster));
			if (!testCasterCulling(caster)) {
				active = false;
				return;
			}
			active = true;

			// Рисуем в шедоумапу
			context.setRenderToTexture(shadowMap, true, 0, 0);
			//			context.clear(1);
			context.clear(1, 1, 1, 1);
			cleanContext(context);
			drawObjectToShadowMap(context, caster, projection);
			context.setRenderToBackBuffer();
			cleanContext(context);
			debugMaterial.diffuseMap = debugTexture;
		}

		private function testCasterCulling(object:Object3D):Boolean {
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				if (child.visible) {
					if (child.transformChanged) child.composeTransforms();
					child.localToGlobalTransform.combine(object.localToGlobalTransform, child.transform);
					if (child.boundBox == null || cullCaster(child.boundBox, child.localToGlobalTransform)) {
						return true;
					}
					if (testCasterCulling(child)) {
						return true;
					}
				}
			}
			return false;
		}

		static private const boundVertices:Vector.<Number> = new Vector.<Number>(24);
		alternativa3d function cullObjectImpl(bounds:BoundBox, matrix:Matrix3D, far:Number = 0):Boolean {
			var i:int;
			var infront:Boolean;
			var behind:Boolean;
			// Заполнение
			boundVertices[0] = bounds.minX;
			boundVertices[1] = bounds.minY;
			boundVertices[2] = bounds.minZ;
			boundVertices[3] = bounds.maxX;
			boundVertices[4] = bounds.minY;
			boundVertices[5] = bounds.minZ;
			boundVertices[6] = bounds.minX;
			boundVertices[7] = bounds.maxY;
			boundVertices[8] = bounds.minZ;
			boundVertices[9] = bounds.maxX;
			boundVertices[10] = bounds.maxY;
			boundVertices[11] = bounds.minZ;
			boundVertices[12] = bounds.minX;
			boundVertices[13] = bounds.minY;
			boundVertices[14] = bounds.maxZ;
			boundVertices[15] = bounds.maxX;
			boundVertices[16] = bounds.minY;
			boundVertices[17] = bounds.maxZ;
			boundVertices[18] = bounds.minX;
			boundVertices[19] = bounds.maxY;
			boundVertices[20] = bounds.maxZ;
			boundVertices[21] = bounds.maxX;
			boundVertices[22] = bounds.maxY;
			boundVertices[23] = bounds.maxZ;
			
			// Трансформация в камеру
			matrix.transformVectors(boundVertices, boundVertices);
			// Куллинг
			// left
			for (i = 0, infront = false, behind = false; i <= 21; i += 3) {
//				trace("POS", boundVertices[i], boundVertices[int(i + 2)]);
				if (boundVertices[i] > 0) {
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
			// right
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
			// up
			for (i = 1, infront = false, behind = false; i <= 22; i += 3) {
//				if (-boundVertices[i] < boundVertices[int(i + 1)]) {
				if (boundVertices[i] > 0) {
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
			// down
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
			if (far > 0) {
				for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
					if (boundVertices[i] < far) {
						infront = true;
						if (behind) break;
					} else {
						behind = true;
						if (infront) break;
					}
				}
				if (behind) {
					//				trace("N", infront);
					if (!infront) return false;
				}
			}
			for (i = 2, infront = false, behind = false; i <= 23; i += 3) {
				if (boundVertices[i] > 0) {
					infront = true;
					if (behind) break;
				} else {
					behind = true;
					if (infront) break;
				}
			}
			if (behind) {
				//				trace("N", infront);
				if (!infront) return false;
			}
			return true; 
		}

		// должен быть заполнен нулями
		private var rawData:Vector.<Number> = new Vector.<Number>(16);
		private var m:Matrix3D = new Matrix3D();
		private function calculateProjection(projection:ProjectionTransform3D, uvProjection:Matrix3D, fov:Number, nearClipping:Number, farClipping:Number):void {
			var viewSize:Number = 1;
			var focalLength:Number = viewSize/Math.tan(fov*0.5);
			projection.m0 = focalLength/viewSize;
			projection.m5 = -focalLength/viewSize;
			projection.m10 = farClipping/(farClipping - nearClipping);
			projection.m14 = -nearClipping*projection.m10;

			for (var i:int = 0; i < 16; i++) {
				rawData[i] = 0;
			}
			
			// TODO: предумножить матрицы
			
			rawData[0] = projection.m0;
			rawData[5] = -projection.m5;
			rawData[10]= projection.m10;
			rawData[11]= 1;
			rawData[14]= projection.m14;
			uvProjection.rawData = rawData;

//			0.5f, 0.0f, 0.0f, 0.0f,
//			0.0f, 0.5f, 0.0f, 0.0f,
//			0.0f, 0.0f, 0.5f, 0.0f,
//			0.5f, 0.5f, 0.5f, 1.0f
			
			rawData[0] = 0.5;
			rawData[12] = 0.5;
			rawData[5] = 0.5;
			rawData[13] = 0.5;
			rawData[10] = 0.5;
			rawData[14] = 0.5;
			rawData[11] = 0;
			rawData[15] = 1;
			m.rawData = rawData;
			uvProjection.append(m);
		}

		private var transformToMatrixRawData:Vector.<Number> = new Vector.<Number>(16);
		private function copyMatrixFromTransform(matrix:Matrix3D, transform:Transform3D):void {
			transformToMatrixRawData[0] = transform.a;
			transformToMatrixRawData[1] = transform.e;
			transformToMatrixRawData[2] = transform.i;
			transformToMatrixRawData[3] = 0;
			transformToMatrixRawData[4] = transform.b;
			transformToMatrixRawData[5] = transform.f;
			transformToMatrixRawData[6] = transform.j;
			transformToMatrixRawData[7] = 0;
			transformToMatrixRawData[8] = transform.c;
			transformToMatrixRawData[9] = transform.g;
			transformToMatrixRawData[10] = transform.k;
			transformToMatrixRawData[11] = 0;
			transformToMatrixRawData[12] = transform.d;
			transformToMatrixRawData[13] = transform.h;
			transformToMatrixRawData[14] = transform.l;
			transformToMatrixRawData[15] = 1;
			matrix.rawData = transformToMatrixRawData;
		}

		alternativa3d static function drawObjectToShadowMap(context:Context3D, object:Object3D, projection:ProjectionTransform3D):void {
			if (object is Mesh) {
				drawMeshToShadowMap(context, Mesh(object), projection);
			}
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				if (child.visible) {
					if (child.transformChanged) child.composeTransforms();
					child.localToCameraTransform.combine(object.localToCameraTransform, child.transform);
					drawObjectToShadowMap(context, child, projection);
				}
			}
		}

		private static var shadowMapProgram:Program3D;
		private static var projectionVector:Vector.<Number> = new Vector.<Number>(16);
		private static function drawMeshToShadowMap(context:Context3D, mesh:Mesh, projection:ProjectionTransform3D):void {
			if (mesh.geometry == null || mesh.geometry.numTriangles == 0 || !mesh.geometry.isUploaded) {
				return;
			}
			
			if (shadowMapProgram == null) shadowMapProgram = initMeshToShadowMapProgram(context);
			context.setProgram(shadowMapProgram);
			
			context.setVertexBufferAt(0, mesh.geometry.getVertexBuffer(VertexAttributes.POSITION), mesh.geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);

			var transform:Transform3D = mesh.localToCameraTransform;
			projectionVector[0] = transform.a*projection.m0;
			projectionVector[1] = transform.b*projection.m0;
			projectionVector[2] = transform.c*projection.m0;
			projectionVector[3] = transform.d*projection.m0;
			projectionVector[4] = transform.e*projection.m5;
			projectionVector[5] = transform.f*projection.m5;
			projectionVector[6] = transform.g*projection.m5;
			projectionVector[7] = transform.h*projection.m5;
			projectionVector[8] = transform.i*projection.m10;
			projectionVector[9] = transform.j*projection.m10;
			projectionVector[10] = transform.k*projection.m10;
			projectionVector[11] = transform.l*projection.m10 + projection.m14;
			projectionVector[12] = transform.i;
			projectionVector[13] = transform.j;
			projectionVector[14] = transform.k;
			projectionVector[15] = transform.l;
			
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, projectionVector, 4);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, Vector.<Number>([255, 0, 0, 1]));
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
				"#c4=c4",
				"#v0=v0",
				"m44 t0, a0, c0",
				"mul v0, t0, c4.x",
				"mov o0, t0"
			]);
			proc.assignVariableName(VariableType.CONSTANT, 0, "c0", 4);
			vLinker.addProcedure(proc);
			
			fLinker.addProcedure(Procedure.compileFromArray([
				"#v0=v0",
				"#c0=c0",
				"mov t0.xy, v0.zz",
				"frc t0.y, v0.z",
				"sub t0.x, v0.z, t0.y",
				"mul t0.x, t0.x, c0.x",
				"mov t0.z, c0.z",
				"mov t0.w, c0.w",
				"mov o0, t0"
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
		
		// Rendering with shadow
		private static function initVShader(index:int):Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				"m44 v0, a0, c0",
				"mov v1, a0"
			]);
			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPosition");
			shader.assignVariableName(VariableType.CONSTANT, 0, index + "cTOSHADOW", 4);
			shader.assignVariableName(VariableType.VARYING, 0, index + "vSHADOWSAMPLE");
			shader.assignVariableName(VariableType.VARYING, 1, "vPosition");
			return shader;
		}

		private static function initFShader(mult:Boolean, usePCF:Boolean, index:int):Procedure {
			var i:int;
			var line:int = 0;
			var shaderArr:Array = [];
			var numPass:uint = (usePCF) ? 4 : 1;
			for (i = 0; i < numPass; i++) {
				// Расстояние
				shaderArr[line++] = "mov t0.w, v0.z";
				shaderArr[line++] = "div t2, v0, v0.w";
				shaderArr[line++] = "mul t0.w, t0.w, c4.y";	// bias [0.99] * 255

				if (usePCF) {
					// Добавляем смещение
					shaderArr[line++] = "mul t1, c" + (i + 9).toString() + ", t0.w";
//					shaderArr[line++] = "add t1, v0, t1";
					shaderArr[line++] = "add t1, t2, t1";
					shaderArr[line++] = "tex t1, t1, s0 <2d,clamp,near,nomip>";
				} else {
//					shaderArr[line++] = "tex t1, v0, s0 <2d,clamp,near,nomip>";
					shaderArr[line++] = "tex t1, t2, s0 <2d,clamp,near,nomip>";
				}

				// Восстанавливаем расстояние
				shaderArr[line++] = "mul t1.w, t1.x, c4.x";		// * 255
				shaderArr[line++] = "add t1.w, t1.w, t1.y";

				// Перекрытие тенью
				shaderArr[line++] = "sub t2.z, t1.w, t0.w";
				shaderArr[line++] = "mul t2.z, t2.z, c4.z";		// smooth [10000]
				shaderArr[line++] = "sat t2.z, t2.z";

				// Добавляем маску и прозрачность, затем sat
				shaderArr[line++] = "add t2.z, t2.z, t1.z";		// маска тени
				shaderArr[line++] = "add t2, t2.zzzz, c5";		// цвет тени

				// Плавный уход в прозрачность -------------
				shaderArr[line++] = "#c6=c" + index + "Spot";
				shaderArr[line++] = "#c7=c" + index + "Direction";
				shaderArr[line++] = "#c8=c" + index + "Geometry";
				shaderArr[line++] = "#v1=vPosition";
				// Считаем вектор из точки к свету

				// Вектор из точки к свету
				shaderArr[line++] = "sub t0, c6, v1";
//				shaderArr[line++] = "sub t0, v1, c6";
				// Квадрат расстояния до точки
				shaderArr[line++] = "dp3 t0.w, t0, t0";
				// Расстояние до точки
				shaderArr[line++] = "sqt t0.w, t0.w";

				// Нормализованное направление к источнику
				shaderArr[line++] = "nrm t0.xyz, t0.xyz";
				// cos(Угол) между направлением к точке и направлением спота
				shaderArr[line++] = "dp3 t0.y, t0.xyz, c7.xyz";
//				// cos(угол) - cos(falloff*0.5)
				shaderArr[line++] = "sub t0.y, t0.y, c8.w";
//				// Делим на (cos(hotspot*0.5) - cos(falloff*0.5))
				shaderArr[line++] = "div t0.y, t0.y, c8.z";

				// Минус atenuationBegin
				shaderArr[line++] = "sub t0.w, t0.w, c8.y";			// len = len - atenuationBegin
				// Делим на (atenuationEnd - atenuationBegin)
				shaderArr[line++] = "div t0.w, t0.w, c8.x";			// att = len/radius
				// 1 - соотношение между расстоянием до точки и максимальным расстоянием
				shaderArr[line++] = "sub t0.w, c6.w, t0.w";			// att = 1 - len/radius

				shaderArr[line++] = "mul t0.w, t0.y, t0.w";
//				shaderArr[line++] = "mov t0.w, t0.y";
				shaderArr[line++] = "sub t0.w, c7.w, t0.w";
//				shaderArr[line++] = "mov t2, t0.wwww";
				shaderArr[line++] = "sat t0.w, t0.w";
				shaderArr[line++] = "add t2, t2, t0.wwww";
				// -----------------------------------------------------

				shaderArr[line++] = "sat t2, t2";

				if (usePCF) {
					if (i == 0) {
						shaderArr[line++] = "mov t3, t2";
					} else {
						shaderArr[line++] = "add t3, t3, t2";
					}
				}
			}
			if (usePCF) {
				shaderArr[line++] = "mul t2, t3, c9.w";
			}
			if (mult) {
				shaderArr[line++] = "mul t0.xyz, i0.xyz, t2.xyz";
				shaderArr[line++] = "mov t0.w, i0.w";
				shaderArr[line++] = "mov o0, t0";
			} else {
				shaderArr[line++] = "mov o0, t2";
//				shaderArr[line++] = "mov o0, t1";
			}
			var shader:Procedure = Procedure.compileFromArray(shaderArr);
			shader.assignVariableName(VariableType.VARYING, 0, index + "vSHADOWSAMPLE");
			shader.assignVariableName(VariableType.CONSTANT, 4, index + "cConstants", 1);
			shader.assignVariableName(VariableType.CONSTANT, 5, index + "cShadowColor", 1);
			if (usePCF) {
				for (i = 0; i < numPass; i++) {
					shader.assignVariableName(VariableType.CONSTANT, i + 9, "cSPCF" + i.toString(), 1);
				}
			}
			shader.assignVariableName(VariableType.SAMPLER, 0, index + "sSHADOWMAP");
			return shader;
		}

		override public function getFShader(index:int = 0):Procedure {
			return initFShader(false, (pcfOffset > 0), index);
		}
		override public function getVShader(index:int = 0):Procedure {
			return initVShader(index);
		}

		private static const objectToShadowMap:Matrix3D = new Matrix3D();
		private static const localToGlobal:Transform3D = new Transform3D();
		override public function applyShader(drawUnit:DrawUnit, program:ShaderProgram, object:Object3D, camera:Camera3D, index:int = 0):void {
			// Считаем матрицу перевода в лайт из объекта
			localToGlobal.combine(camera.localToGlobalTransform, object.localToCameraTransform);
			copyMatrixFromTransform(objectToShadowMap, localToGlobal);
			objectToShadowMap.append(globalToShadowMap);
			
//			var casterPos:Vector3D = new Vector3D(caster.localToGlobalTransform.d, caster.localToGlobalTransform.h, caster.localToGlobalTransform.l);
//			var p:Vector3D = objectToShadowMap.transformVector(casterPos);
//			p.scaleBy(1/p.w);
//			trace("caster pos:", p);

			objectToShadowMap.transpose();

			drawUnit.setVertexConstantsFromVector(program.vertexShader.getVariableIndex(index + "cTOSHADOW"), objectToShadowMap.rawData, 4);
			drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex(index + "cConstants"), constants, constants.length/4);
			drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex(index + "cShadowColor"), camera.ambient, 1);
			if (pcfOffset > 0) {
				drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex("cSPCF0"), pcfOffsets, pcfOffsets.length/4);
			}
			drawUnit.setTextureAt(program.fragmentShader.getVariableIndex(index + "sSHADOWMAP"), shadowMap);

//			localToGlobal.combine(light.cameraToLocalTransform, object.localToCameraTransform);
			localToGlobal.combine(object.cameraToLocalTransform, light.localToCameraTransform);
//			localToGlobal.invert();

			// Настройки затухания
			var transform:Transform3D = localToGlobal;
			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + index + "Spot"), transform.d, transform.h, transform.l, 1);
			var rScale:Number = Math.sqrt(transform.a * transform.a + transform.e * transform.e + transform.i * transform.i);
			rScale += Math.sqrt(transform.b * transform.b + transform.f * transform.f + transform.j * transform.j);
			var dLen:Number = Math.sqrt(transform.c * transform.c + transform.g * transform.g + transform.k * transform.k);
			rScale += dLen;
			rScale /= 3;
			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + index + "Direction"), -transform.c / dLen, -transform.g / dLen, -transform.k / dLen, 0.5);

			var falloff:Number = Math.cos(light.falloff * 0.5);
			var hotspot:Number = Math.cos(light.hotspot * 0.5);

			drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("c" + index + "Geometry"), light.attenuationEnd * rScale - light.attenuationBegin * rScale, light.attenuationBegin * rScale, hotspot == falloff ? 0.000001 : hotspot - falloff, falloff);
		}

	}
}

class ProjectionTransform3D {
	public var m0:Number;
	public var m5:Number;
	public var m10:Number;
	public var m14:Number;
}
