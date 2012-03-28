package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class StaticShadowRenderer extends ShadowRenderer {
		
		public var context:Context3D;
		
		private const alpha:Number = 0.7;
		
		private var bounds:BoundBox = new BoundBox();
		private var partSize:Number;
		private var partsShadowMaps:Vector.<Vector.<Texture>> = new Vector.<Vector.<Texture>>();
		private var partsUVMatrices:Vector.<Vector.<Matrix3D>> = new Vector.<Vector.<Matrix3D>>();
		
		private var light:DirectionalLight;
		private var globalToLight:Transform3D = new Transform3D();

		private var _debug:Boolean = false;
		private var debugContainer:Object3D;

		private var _recievers:Dictionary = new Dictionary();
		public function addReciever(object:Object3D):void {
			_recievers[object] = true;
		}
		public function removeReciever(object:Object3D):void {
			delete _recievers[object];
		}
		
		private static const constants:Vector.<Number> = Vector.<Number>([
			//			255, 255*0.99, 100, 1/255
//			255, 255*0.96, 100, 1
			255, 255, 1000, 1
		]);
		
		private var pcfOffset:Number = 0;
		private static var pcfOffsets:Vector.<Number>;

		public function dispose():void {
			for each (var textures:Vector.<Texture> in partsShadowMaps) {
				for each (var texture:Texture in textures) {
					texture.dispose();
				}
			}
			partsShadowMaps.length = 0;
			partsUVMatrices.length = 0;
		}

		public function StaticShadowRenderer(context:Context3D, partSize:int, pcfSize:Number = 0) {
			this.context = context;
			this.partSize = partSize;
			this.pcfOffset = pcfSize;
			constants[3] = 1 - alpha;
		}

		override alternativa3d function cullReciever(boundBox:BoundBox, object:Object3D):Boolean {
			return _recievers[object];
		}

		private var lightProjectionMatrix:Matrix3D = new Matrix3D();
		public function calculateShadows(object:Object3D, light:DirectionalLight, widthPartsCount:int = 1, heightPartsCount:int = 1, overlap:Number = 0):void {
			this.light = light;

			var root:Object3D;
			// Расчитываем матрицу объекта
//			if (object.transformChanged) {
				object.localToCameraTransform.compose(object._x, object._y, object._z, object._rotationX, object._rotationY, object._rotationZ, object._scaleX, object._scaleY, object._scaleZ);
//			} else {
//				object.localToCameraTransform.copy(caster.transform);
//			}
			root = object;
			while (root._parent != null) {
				root = root._parent;
//				if (root.transformChanged) {
					root.localToGlobalTransform.compose(root._x, root._y, root._z, root._rotationX, root._rotationY, root._rotationZ, root._scaleX, root._scaleY, root._scaleZ);
//				}
				object.localToCameraTransform.append(root.localToGlobalTransform);
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

			globalToLight.copy(light.globalToLocalTransform);

			// Получаем матрицу перевода из объекта в лайт
			object.localToCameraTransform.append(light.globalToLocalTransform);

			bounds.reset();
			calculateBoundBox(bounds, object);

			var frustumMinX:Number = bounds.minX;
			var frustumMaxX:Number = bounds.maxX;
			var frustumMinY:Number = bounds.minY;
			var frustumMaxY:Number = bounds.maxY;
			var frustumMinZ:Number = bounds.minZ;
			var frustumMaxZ:Number = bounds.maxZ;

			// Считаем шаг
			var halfOverlap:Number = overlap*0.5;
			var partWorldWidth:Number = (frustumMaxX - frustumMinX)/widthPartsCount;
			var partWorldHeight:Number = (frustumMaxY - frustumMinY)/heightPartsCount;
			
			debugContainer = new Object3D();
			if (_debug) {
				light.addChild(debugContainer);
			}

			// Создаем шэдоумапы и рендерим
			for (var xIndex:int = 0; xIndex < widthPartsCount; xIndex++) {
				var maps:Vector.<Texture> = new Vector.<Texture>();
				var matrices:Vector.<Matrix3D> = new Vector.<Matrix3D>();
				for (var yIndex:int = 0; yIndex < heightPartsCount; yIndex++) {
					var leftX:Number = frustumMinX + xIndex*partWorldWidth;
					var leftY:Number = frustumMinY + yIndex*partWorldHeight;

					var width:Number;
					var height:Number;
					if (xIndex == 0) {
						width = partWorldWidth + halfOverlap;
					} else if (xIndex == (widthPartsCount - 1)) {
						leftX -= halfOverlap;
						width = partWorldWidth + halfOverlap;
					} else {
						leftX -= halfOverlap;
						width = partWorldWidth + overlap;
					}
					if (yIndex == 0) {
						height = partWorldHeight + halfOverlap;
					} else if (yIndex == (heightPartsCount - 1)) {
						leftY -= halfOverlap;
						height = partWorldHeight + halfOverlap;
					} else {
						leftY -= halfOverlap;
						height = partWorldHeight + overlap;
					}

					var uvMatrix:Matrix3D = new Matrix3D();
					calculateShadowMapProjection(lightProjectionMatrix, uvMatrix, leftX, leftY, frustumMinZ, leftX + width, leftY + height, frustumMaxZ);

					var shadowMap:Texture = context.createTexture(partSize, partSize, Context3DTextureFormat.BGRA, true);
					// Рисуем в шедоумапу
					context.setRenderToTexture(shadowMap, true, 0, 0);
					context.clear(1, 1, 1, 0.5);
					cleanContext(context);
					DirectionalShadowRenderer.drawObjectToShadowMap(context, object, light, lightProjectionMatrix);
					cleanContext(context);

					maps.push(shadowMap);
					matrices.push(uvMatrix);

					var texture:TextureResource = new ExternalTextureResource(null);
					texture._texture = shadowMap;
					var material:TextureMaterial = new TextureMaterial(texture);
					material.opaquePass = false;
					material.transparentPass = true;
					material.alphaThreshold = 1.1;
					var debugObject:Mesh = new Box(width, height, 1, 1, 1, 1, false, material);
//					var debugObject:Mesh = new Box(width, height, 1, 1, 1, 1, false, new FillMaterial());
					debugObject.geometry.upload(context);
					debugObject.x = leftX + width/2;
					debugObject.y = leftY + height/2;
					debugObject.z = frustumMinZ;
					debugContainer.addChild(debugObject);
				}
				partsShadowMaps.push(maps);
				partsUVMatrices.push(matrices);
			}
			context.setRenderToBackBuffer();
			if (pcfOffset > 0) {
				var offset:Number = pcfOffset/partWorldWidth;
//				pcfOffsets = Vector.<Number>([
//					-offset, -offset, 0, 1/4,
//					-offset, offset, 0, 1,
//					offset, -offset, 0, 1,
//					offset, offset, 0, 1,
//				]);
				pcfOffsets = Vector.<Number>([
					-offset, -offset, 0, 1/4,
					-offset, offset, 0, 1,
					offset, -offset, 0, 1,
					offset, offset, 0, 1
				]);
			}
		}

		private static const points:Vector.<Vector3D> = Vector.<Vector3D>([
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D(),
			new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D()
		]);
		alternativa3d static function calculateBoundBox(boundBox:BoundBox, object:Object3D, hierarchy:Boolean = true):void {
			// Считаем баунды объекта в лайте
			var point:Vector3D;
			if (object.boundBox != null) {
				var bb:BoundBox = object.boundBox;
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
				var transform:Transform3D = object.localToCameraTransform;
				for (var i:int = 0; i < 8; i++) {
					point = points[i];
					var x:Number = transform.a*point.x + transform.b*point.y + transform.c*point.z + transform.d;
					var y:Number = transform.e*point.x + transform.f*point.y + transform.g*point.z + transform.h;
					var z:Number = transform.i*point.x + transform.j*point.y + transform.k*point.z + transform.l;
					if (x < boundBox.minX) {
						boundBox.minX = x;
					}
					if (x > boundBox.maxX) {
						boundBox.maxX = x;
					}
					if (y < boundBox.minY) {
						boundBox.minY = y;
					}
					if (y > boundBox.maxY) {
						boundBox.maxY = y;
					}
					if (z < boundBox.minZ) {
						boundBox.minZ = z;
					}
					if (z > boundBox.maxZ) {
						boundBox.maxZ = z;
					}
				}
			}
			if (hierarchy) {
			 // Пробегаемся по дочерним объектам
				for (var child:Object3D = object.childrenList; child != null; child = child.next) {
					if (child.visible) {
						if (child.transformChanged) {
							child.composeTransforms();
						}
						child.localToCameraTransform.combine(object.localToCameraTransform, child.transform);
						calculateBoundBox(boundBox, child);
					}
				}
			}
		}

		private var rawData:Vector.<Number> = new Vector.<Number>(16);
		private function calculateShadowMapProjection(matrix:Matrix3D, uvMatrix:Matrix3D, frustumMinX:Number, frustumMinY:Number, frustumMinZ:Number, frustumMaxX:Number, frustumMaxY:Number, frustumMaxZ:Number):void {
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

		override public function get debug():Boolean {
			return _debug;
		}

		override public function set debug(value:Boolean):void {
			_debug = value;
			if (debugContainer != null) {
				if (value) {
					if (light != null) {
						light.addChild(debugContainer);
					}
				} else {
					if (debugContainer._parent != null) {
						debugContainer.removeFromParent();
					}
				}
			}
		}
		
//		private static const vShader:Procedure = initVShader(index);
		private static function initVShader(index:int):Procedure {
			var shader:Procedure = Procedure.compileFromArray([
//				"m44 o0, a0, c0",
//				Координата вершины в локальном пространстве
				"m44 v0, a0, c4"
			]);
			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPosition");
			shader.assignVariableName(VariableType.CONSTANT, 0, "cPROJ", 4);
			shader.assignVariableName(VariableType.CONSTANT, 4, "cTOSHADOW", 4);
			shader.assignVariableName(VariableType.VARYING, 0, "vSHADOWSAMPLE");
			return shader;
		}
//		private static const multVShader:Procedure = initMultVShader();
//		private static function initMultVShader():Procedure {
//			var shader:Procedure = Procedure.compileFromArray([
//				"m44 v0, a0, c0",
//			]);
//			shader.assignVariableName(VariableType.ATTRIBUTE, 0, "aPOSITION");
//			shader.assignVariableName(VariableType.CONSTANT, 0, "cTOSHADOW", 4);
//			shader.assignVariableName(VariableType.VARYING, 0, "vSHADOWSAMPLE");
//			return shader;
//		}
//		private static const fShader:Procedure = initFShader(false, false, index);
//		private static const pcfFShader:Procedure = initFShader(false, true, index);
		// i0 - input color
		// o0 - shadowed result
//		private static const multFShader:Procedure = initFShader(true, false, index);
//		private static const pcfMultFShader:Procedure = initFShader(true, true, index);
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
//					shaderArr[line++] = "mul t1, c" + (i + 5).toString() + ", t0.w";
					shaderArr[line++] = "add t1, v0, c" + (i + 5).toString() + "";
					//					shaderArr[line++] = "add t1, v0, c" + (i + 5).toString();
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
//				shaderArr[line++] = "add t2.z, t2.z, t1.z";		// маска тени
//				shaderArr[line++] = "add t2.z, t2.z, c4.w";		// вес тени
				shaderArr[line++] = "sat t2.z, t2.z";
				
				if (usePCF) {
					if (i == 0) {
						shaderArr[line++] = "mov t2.x, t2.z";
					} else {
						shaderArr[line++] = "add t2.x, t2.x, t2.z";
					}
				}
			}
			if (usePCF) {
				shaderArr[line++] = "mul t2.z, t2.x, c5.w";
			}
			if (grayScale) {
				shaderArr.push("mov o0.w, t2.z");
			} else {
				if (mult) {
					shaderArr.push("mul t0.xyz, i0.xyz, t2.z");
					shaderArr.push("mov t0.w, i0.w");
					shaderArr.push("mov o0, t0");
				} else {
					shaderArr.push("mov t0, t2.z");
					shaderArr.push("mov o0, t0");
				}
			}
			var shader:Procedure = Procedure.compileFromArray(shaderArr, "StaticShadowMap");
			shader.assignVariableName(VariableType.VARYING, 0, "vSHADOWSAMPLE");
			shader.assignVariableName(VariableType.CONSTANT, 4, "cConstants", 1);
			if (usePCF) {
				for (i = 0; i < numPass; i++) {
					shader.assignVariableName(VariableType.CONSTANT, i + 5, "cPCF" + i.toString(), 1);
				}
			}
			shader.assignVariableName(VariableType.SAMPLER, 0, "sSHADOWMAP");
			return shader;
		}

		override public function getVShader(index:int = 0):Procedure {
			return initVShader(index);
		}
		override public function getFShader(index:int = 0):Procedure {
			return initFShader(false, (pcfOffset > 0), index);
		}

//		override public function getMultFShader():Procedure {
//			return (pcfOffset > 0) ? pcfMultFShader : multFShader;
//		}
//		override public function getMultVShader():Procedure {
//			return multVShader;
//		}

		override public function getFIntensityShader():Procedure {
			return initFShader(false, (pcfOffset > 0), 0, true);
		}

		private static const objectToShadowMap:Transform3D = new Transform3D();
		private static const objectToUVMap:Matrix3D = new Matrix3D();
		override public function applyShader(drawUnit:DrawUnit, program:ShaderProgram, object:Object3D, camera:Camera3D, index:int = 0):void {
			// Считаем матрицу перевода в лайт из объекта

			objectToShadowMap.combine(camera.localToGlobalTransform, object.localToCameraTransform);
			objectToShadowMap.append(globalToLight);

//			objectToShadowMap.identity();
//			objectToShadowMap.append(object.cameraMatrix);
//			objectToShadowMap.append(camera.globalMatrix);
//			objectToShadowMap.append(globalToLight);
			
			// Получаем индекс шедоумапы
//			var coords:Vector3D = objectToShadowMap.position;
			var coords:Vector3D = new Vector3D(objectToShadowMap.d,  objectToShadowMap.h, objectToShadowMap.l);
			var xIndex:int = (coords.x - bounds.minX)/(bounds.maxX - bounds.minX)*partsShadowMaps.length;

			xIndex = (xIndex < 0) ? 0 : ((xIndex >= partsShadowMaps.length) ? partsShadowMaps.length - 1 : xIndex);
			var maps:Vector.<Texture> = partsShadowMaps[xIndex];
			var matrices:Vector.<Matrix3D> = partsUVMatrices[xIndex];

			var yIndex:int = (coords.y - bounds.minY)/(bounds.maxY - bounds.minY)*maps.length;
			yIndex = (yIndex < 0) ? 0 : ((yIndex >= maps.length) ? maps.length - 1 : yIndex);
			
//			trace(xIndex, yIndex);
			
			var shadowMap:Texture = maps[yIndex];
			var uvMatrix:Matrix3D = matrices[yIndex];

			DirectionalShadowRenderer.copyMatrixFromTransform(objectToUVMap, objectToShadowMap);
			objectToUVMap.append(uvMatrix);
			objectToUVMap.transpose();
//			objectToShadowMap.append(uvMatrix);

			drawUnit.setVertexConstantsFromVector(program.vertexShader.getVariableIndex("cTOSHADOW"), objectToUVMap.rawData, 4);
			drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex("cConstants"), constants, 1);
			if (pcfOffset > 0) {
				drawUnit.setFragmentConstantsFromVector(program.fragmentShader.getVariableIndex("cPCF0"), pcfOffsets, pcfOffsets.length >> 2)
			}
			drawUnit.setTextureAt(program.fragmentShader.getVariableIndex("sSHADOWMAP"), shadowMap);
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
////			trace("[VERTEX]");
////			trace(AgalUtils.disassemble(vLinker.getByteCode()));
////			trace("[FRAGMENT]");
////			trace(AgalUtils.disassemble(fLinker.getByteCode()));
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
