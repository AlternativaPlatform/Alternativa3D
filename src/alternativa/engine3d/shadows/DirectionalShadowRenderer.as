package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DirectionalShadowRenderer extends ShadowRenderer {

		public var offset:Vector3D = new Vector3D();

		public var caster:Object3D;

		private var context:Context3D;
		
		private var shadowMap:Texture;
		private var _worldSize:Number;

		private var light:DirectionalLight;
		alternativa3d var globalToShadowMap:Matrix3D = new Matrix3D();
		
		private var debugObject:Mesh;
		public var debugMaterial:TextureMaterial = new TextureMaterial();
		private var debugTexture:TextureResource = new ExternalTextureResource("null");
//		private var debugTexture:TextureResource = new BitmapTextureResource(new BitmapData(4, 4, false, 0xFF0000));
		
		private static const constants:Vector.<Number> = Vector.<Number>([
//			255, 255*0.98, 100, 1
			255, 255*0.96, 100, 1
		]);
		
		private var pcfOffset:Number = 0;
		private var pcfOffsets:Vector.<Number>;
		
		public function DirectionalShadowRenderer(context:Context3D, size:int, worldSize:Number, pcfSize:Number = 0) {
			this.context = context;
			this._worldSize = worldSize;
			this.pcfOffset = pcfSize/worldSize/255;
//			this.pcfOffset = pcfSize;
			if (pcfOffset > 0) {
				pcfOffsets = Vector.<Number>([
					-pcfOffset, -pcfOffset, 0, 1/4,
					-pcfOffset, pcfOffset, 0, 1,
					pcfOffset, -pcfOffset, 0, 1,
					pcfOffset, pcfOffset, 0, 1
				]);
			}
			this.shadowMap = context.createTexture(size, size, Context3DTextureFormat.BGRA, true);
			debugTexture._texture = this.shadowMap;
			debugMaterial.diffuseMap = debugTexture;
			debugMaterial.alpha = 0.9;
			// TODO: fix
			debugMaterial.transparentPass = true;
			debugMaterial.opaquePass = false;
			debugMaterial.alphaThreshold = 1.1;

//			debugTexture.upload(context);
			
			debugObject = new Box(worldSize, worldSize, 1, 1, 1, 1, false, debugMaterial);
			debugObject.geometry.upload(context);
		}

		public function get worldSize():Number {
			return _worldSize;
		}

		public function set worldSize(value:Number):void {
			_worldSize = value;
			var newDebug:Mesh = new Box(_worldSize, _worldSize, 1, 1, 1, 1, false, debugMaterial);
			newDebug.geometry.upload(context);
			if (debugObject._parent != null) {
				debugObject._parent.addChild(newDebug);
				debugObject._parent.removeChild(debugObject);
			}
			debugObject = newDebug;
	}

		private var _debug:Boolean = false;
		public function setLight(value:DirectionalLight):void {
			light = value;
			if (_debug) {
				light.addChild(debugObject);
			}
		}
		
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
				if (debugObject._parent != null) {
					debugObject._parent.removeChild(debugObject);
				}
			}
		}

		private static var matrix:Matrix3D = new Matrix3D();
		override alternativa3d function cullReciever(boundBox:BoundBox, object:Object3D):Boolean {
			copyMatrixFromTransform(matrix, object.localToGlobalTransform);
			matrix.append(this.globalToShadowMap);
			return cullObjectImplementation(boundBox, matrix);
		}
		
		private var lightProjectionMatrix:Matrix3D = new Matrix3D();
		private var uvMatrix:Matrix3D = new Matrix3D();
		private var center:Vector3D = new Vector3D();
		override public function update():void {
			active = true;
			var root:Object3D;
			// Расчитываем матрицу объекта
//			if (caster.transformChanged) {
				caster.localToCameraTransform.compose(caster._x, caster._y, caster._z, caster._rotationX, caster._rotationY, caster._rotationZ, caster._scaleX, caster._scaleY, caster._scaleZ);
//			} else {
//				caster.localToCameraTransform.copy(caster.transform);
//			}
			root = caster;
			while (root._parent != null) {
				root = root._parent;
//				if (root.transformChanged) {
					root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
//				}
				caster.localToCameraTransform.append(root.localToGlobalTransform);
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
			caster.localToCameraTransform.append(light.globalToLocalTransform);
			
			// Расчет матрицы проецирования
			var t:Transform3D = caster.localToCameraTransform;
			center.x = t.a*offset.x + t.b*offset.y + t.c*offset.z + t.d;
			center.y = t.e*offset.x + t.f*offset.y + t.g*offset.z + t.h;
			center.z = t.i*offset.x + t.j*offset.y + t.k*offset.z + t.l;
//			var center:Vector3D = new Vector3D(caster.localToCameraTransform.d, caster.localToCameraTransform.h, caster.localToCameraTransform.l);

			calculateShadowMapProjection(lightProjectionMatrix, uvMatrix, center, _worldSize, _worldSize, _worldSize);
			copyMatrixFromTransform(globalToShadowMap, light.globalToLocalTransform);
			globalToShadowMap.append(uvMatrix);
			
			debugObject.x = center.x;
			debugObject.y = center.y;
			debugObject.z = center.z - _worldSize/2;
//			trace("center", center);
			
			debugMaterial.diffuseMap = null;
			
			// Рисуем в шедоумапу
			context.setRenderToTexture(shadowMap, true, 0, 0);
//			context.clear(1);
			context.clear(1, 1, 1, 1);
			cleanContext(context);
			drawObjectToShadowMap(context, caster, light, lightProjectionMatrix);
			context.setRenderToBackBuffer();
			cleanContext(context);
			debugMaterial.diffuseMap = debugTexture;
		}

		private static var transformToMatrixRawData:Vector.<Number> = new Vector.<Number>(16);
		alternativa3d static function copyMatrixFromTransform(matrix:Matrix3D, transform:Transform3D):void {
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
//			matrix.copyRawDataFrom(transformToMatrixRawData);
			matrix.rawData = transformToMatrixRawData;
		}
		
		alternativa3d static function drawObjectToShadowMap(context:Context3D, object:Object3D, light:DirectionalLight, projection:Matrix3D):void {
			if (object is Mesh) {
				drawMeshToShadowMap(context, Mesh(object), projection);
			}
			for (var child:Object3D = object.childrenList; child != null; child = child.next) {
				if (child.visible && child.useShadow) {
					if (child.transformChanged) child.composeTransforms();
					child.localToCameraTransform.combine(object.localToCameraTransform, child.transform);
					drawObjectToShadowMap(context, child, light, projection);
				}
			}
		}

		private static var drawProjection:Matrix3D = new Matrix3D();
		private static var directionalShadowMapProgram:Program3D;
		private static function drawMeshToShadowMap(context:Context3D, mesh:Mesh, projection:Matrix3D):void {
			if (mesh.geometry == null || mesh.geometry.numTriangles == 0 || !mesh.geometry.isUploaded) {
				return;
			}

			copyMatrixFromTransform(drawProjection, mesh.localToCameraTransform);
			drawProjection.append(projection);
			if (directionalShadowMapProgram == null) directionalShadowMapProgram = initMeshToShadowMapProgram(context);
			context.setProgram(directionalShadowMapProgram);

			context.setVertexBufferAt(0, mesh.geometry.getVertexBuffer(VertexAttributes.POSITION), mesh.geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);

			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, drawProjection, true);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, Vector.<Number>([255, 0, 0, 1]));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1/255, 0, 0, 1]));

			context.setCulling(Context3DTriangleFace.BACK);

			for (var i:int = 0; i < mesh._surfacesLength; i++) {
				var surface:Surface = mesh._surfaces[i];
				if (surface.material == null || !surface.material.canDrawInShadowMap) continue;
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

		// должен быть заполнен нулями
		private var rawData:Vector.<Number> = new Vector.<Number>(16);
		private function calculateShadowMapProjection(matrix:Matrix3D, uvMatrix:Matrix3D, offset:Vector3D, width:Number, height:Number, length:Number):void {
			var halfW:Number = width/2;
			var halfH:Number = height/2;
			var halfL:Number = length/2;
			var frustumMinX:Number = offset.x - halfW;
			var frustumMaxX:Number = offset.x + halfW;
			var frustumMinY:Number = offset.y - halfH;
			var frustumMaxY:Number = offset.y + halfH;
			var frustumMinZ:Number = offset.z - halfL;
			var frustumMaxZ:Number = offset.z + halfL;
			
			// Считаем матрицу проецирования
			rawData[0] = 2/(frustumMaxX - frustumMinX);
			rawData[5] = 2/(frustumMaxY - frustumMinY);
			rawData[10]= 1/(frustumMaxZ - frustumMinZ);
			rawData[12] = (-0.5 * (frustumMaxX + frustumMinX) * rawData[0]);
			rawData[13] = (-0.5 * (frustumMaxY + frustumMinY) * rawData[5]);
			rawData[14]= -frustumMinZ/(frustumMaxZ - frustumMinZ);
			rawData[15]= 1;
			matrix.rawData = rawData;

			rawData[0] = 1/((frustumMaxX - frustumMinX));
//			if (useSingle) {
//				rawData[5] = 1/((frustumMaxY - frustumMinY));
//			} else {
				rawData[5] = -1/((frustumMaxY - frustumMinY));
//			}
			rawData[12] = 0.5 - (0.5 * (frustumMaxX + frustumMinX) * rawData[0]);
			rawData[13] = 0.5 - (0.5 * (frustumMaxY + frustumMinY) * rawData[5]);
			uvMatrix.rawData = rawData;
		}

/*
		private static const fullVShader:Procedure = initFullVShader();
		private static function initFullVShader():Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				"m44 o0, a0, c0",
				// Координата вершины в локальном пространстве
				"m44 v0, a0, c4",
			]);
			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPosition");
			shader.assignVariableName(VariableType.CONSTANT, 0, "cPROJ", 4);
			shader.assignVariableName(VariableType.CONSTANT, 4, "cTOSHADOW", 4);
			shader.assignVariableName(VariableType.VARYING, 0, "vSHADOWSAMPLE");
			return shader;
		}
*/
		private static function initVShader(index:int):Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				"m44 v0, a0, c0"
			]);
			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPosition");
			shader.assignVariableName(VariableType.CONSTANT, 0, index + "cTOSHADOW", 4);
			shader.assignVariableName(VariableType.VARYING, 0, index + "vSHADOWSAMPLE");
			return shader;
		}
		private static function initFShader(mult:Boolean, usePCF:Boolean, index:int, grayScale:Boolean = false):Procedure {
			var i:int;
			var line:int = 0;
			var shaderArr:Array = [];
			var numPass:uint = (usePCF) ? 4 : 1;
			for (i = 0; i < numPass; i++) {
				// Расстояние
				shaderArr[line++] = "mov t0.w, v0.z";
				shaderArr[line++] = "mul t0.w, t0.w, c4.y";	// bias [0.99] * 255
				
				if (usePCF) {
					 // Добавляем смещение
					shaderArr[line++] = "mul t1, c" + (i + 6).toString() + ", t0.w";
					shaderArr[line++] = "add t1, v0, t1";
					shaderArr[line++] = "tex t1, t1, s0 <2d,clamp,near,nomip>";
				} else {
					shaderArr[line++] = "tex t1, v0, s0 <2d,clamp,near,nomip>";
				}

				// Восстанавливаем расстояние
				shaderArr[line++] = "mul t1.w, t1.x, c4.x";		// * 255
				shaderArr[line++] = "add t1.w, t1.w, t1.y";

				// Перекрытие тенью
				shaderArr[line++] = "sub t2.z, t1.w, t0.w";
				shaderArr[line++] = "mul t2.z, t2.z, c4.z";		// smooth [10000]
				shaderArr[line++] = "sat t2.z, t2.z";
				
				// Добавляем маску и прозрачность, затем sat
				if (grayScale) {
					shaderArr[line++] = "add t2, t2.zzzz, t1.zzzz";	// маска тени
				} else {
					shaderArr[line++] = "add t2.z, t2.z, t1.z";		// маска тени
					shaderArr[line++] = "add t2, t2.zzzz, c5";		// цвет тени
				}
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
				shaderArr[line++] = "mul t2, t3, c6.w";
			}
			if (grayScale) {
				shaderArr[line++] = "mov o0.w, t2.x";
			} else {
				if (mult) {
					shaderArr[line++] = "mul t0.xyz, i0.xyz, t2.xyz";
					shaderArr[line++] = "mov t0.w, i0.w";
					shaderArr[line++] = "mov o0, t0";
				} else {
					shaderArr[line++] = "mov o0, t2";
				}
			}
			var shader:Procedure = Procedure.compileFromArray(shaderArr, "DirectionalShadowMap");
			shader.assignVariableName(VariableType.VARYING, 0, index + "vSHADOWSAMPLE");
			shader.assignVariableName(VariableType.CONSTANT, 4, index + "cConstants", 1);
			if (!grayScale) shader.assignVariableName(VariableType.CONSTANT, 5, index + "cShadowColor", 1);
			if (usePCF) {
				for (i = 0; i < numPass; i++) {
					shader.assignVariableName(VariableType.CONSTANT, i + 6, "cDPCF" + i.toString(), 1);
				}
			}
			shader.assignVariableName(VariableType.SAMPLER, 0, index + "sSHADOWMAP");
			return shader;
		}

		override public function getVShader(index:int = 0):Procedure {
			return initVShader(index);
		}
		override public function getFShader(index:int = 0):Procedure {
			return initFShader(false, (pcfOffset > 0), index);
		}
//		override public function getMultFShader():Procedure {
//			return initFShader(true, (pcfOffset > 0), 0);
//		}
//		override public function getMultVShader():Procedure {
//			return initVShader(0);
//		}

		override public function getFIntensityShader():Procedure {
			return initFShader(false, (pcfOffset > 0), 0, true);
		}

		private static const objectToShadowMap:Matrix3D = new Matrix3D();
		private static const localToGlobal:Transform3D = new Transform3D();
		private static const vector:Vector.<Number> = new Vector.<Number>(16, false);
		override public function applyShader(drawUnit:DrawUnit, program:ShaderProgram, object:Object3D, camera:Camera3D, index:int = 0):void {
			// Считаем матрицу перевода в лайт из объекта
			localToGlobal.combine(camera.localToGlobalTransform, object.localToCameraTransform);
			copyMatrixFromTransform(objectToShadowMap, localToGlobal);
			objectToShadowMap.append(globalToShadowMap);
			objectToShadowMap.copyRawDataTo(vector, 0, true);
//			objectToShadowMap.transpose();

//			drawUnit.setVertexConstantsFromVector(program.vertexShader.getVariableIndex(index + "cTOSHADOW"), objectToShadowMap.rawData, 4)
			drawUnit.setVertexConstantsFromVector(program.vertexShader.getVariableIndex(index + "cTOSHADOW"), vector, 4)
			drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex(index + "cConstants"), constants, 1);
			if (program.fragmentShader.containsVariable(index + "cShadowColor")) {
//			drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex(index + "cShadowColor"), camera.ambient, 1);
				// В дальнейшем яркость тени увеличтся в два раза
				drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex(index + "cShadowColor"), camera.ambient[0]/2, camera.ambient[1]/2, camera.ambient[2]/2, 1);
			}

			if (pcfOffset > 0) {
//				destination.addFragmentConstantSet(program.fragmentShader.getVariableIndex(index + "cPCF0"), pcfOffsets, pcfOffsets.length/4);
				drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex("cDPCF0"), pcfOffsets, pcfOffsets.length/4);
			}
			drawUnit.setTextureAt(program.fragmentShader.getVariableIndex(index + "sSHADOWMAP"), shadowMap);
		}
		
//		override public function getTextureIndex(fLinker:Linker):int {
//			return fLinker.getVariableIndex("sSHADOWMAP");
//		}
		
//		private static var program:ShaderProgram;
//		private static var programPCF:ShaderProgram;
//		private static function initMeshProgram(context:Context3D, usePCF:Boolean):ShaderProgram {
//			var vLinker:Linker = new Linker(Context3DProgramType.VERTEX);
//			vLinker.addProcedure(fullVShader);
//			
//			var fLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
//			if (usePCF) {
//				fLinker.addProcedure(pcfFShader);
//			} else {
//				fLinker.addProcedure(fShader);
//			}
//
//			vLinker.setOppositeLinker(fLinker);
//			fLinker.setOppositeLinker(vLinker);
//
////			trace("[VERTEX]");
////			trace(AgalUtils.disassemble(vLinker.getByteCode()));
////			trace("[FRAGMENT]");
////			trace(AgalUtils.disassemble(fLinker.getByteCode()));
//
//			var result:ShaderProgram;
//			if (usePCF) {
//				programPCF = new ShaderProgram(vLinker, fLinker);
//				result = programPCF;
//			} else {
//				program = new ShaderProgram(vLinker, fLinker);
//				result = program;
//			}
//			return result;
//		}

//		override public function drawShadow(mesh:Mesh, camera:Camera3D, texture:Texture):void {
//			var context3d:Context3D = camera.view._context3d;
//			
//			var linkedProgram:ShaderProgram;
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
