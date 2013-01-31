/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */
package alternativa.engine3d.shadows {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Debug;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.core.VertexAttributes;
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
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.resources.TextureResource;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 * Class of the shadow, that is created by one  source of light(<code>DirectionalLight</code>). Shadow is rendered in fixed volume.
	 * For binding of shadow to light source you need:
	 * 1) to set instance of the <code>DirectionalLightShadow</code> as a value of property <code>shadow</code> of light source;
	 * 2) to add <code>Object3D</code> to corresponding list, using the method <code>addCaster()</code>.
	 *
	 * @see #addCaster()
	 * @see alternativa.engine3d.lights.DirectionalLight#shadow
	 * @see #farBoundPosition
	 */
	public class DirectionalLightShadow extends Shadow {

		private var renderer:Renderer = new Renderer();

		/**
		 * Degree of correcting offset of shadow map space. It need for getting rid of self-shadowing artifacts.
		 */
		public var biasMultiplier:Number = 0.97;

		private static const DIFFERENCE_MULTIPLIER:Number = 32768;

		// TODO: implement property parent

		/**
		 * Coordinate X of center of shadow rendering area. Relative to the center are specified such properties as:
		 * <code>width</code>, <code>height</code>, <code>nearBoundPosition</code>, <code>farBoundPosition</code>.
		 * @see #width
		 * @see #height
		 * @see #nearBoundPosition
		 * @see #farBoundPosition
		 */
		public var centerX:Number = 0;
		
		/**
		 * Coordinate Y of center of shadow rendering area. Relative to the center are specified such properties as:
		 * <code>width</code>, <code>height</code>, <code>nearBoundPosition</code>, <code>farBoundPosition</code>.
		 * @see #width
		 * @see #height
		 * @see #nearBoundPosition
		 * @see #farBoundPosition
		 */
		public var centerY:Number = 0;

		/**
		 * Coordinate Z of center of shadow rendering area. Relative to the center are specified such properties as:
		 * <code>width</code>, <code>height</code>, <code>nearBoundPosition</code>, <code>farBoundPosition</code>.
		 * @see #width
		 * @see #height
		 * @see #nearBoundPosition
		 * @see #farBoundPosition
		 */
		public var centerZ:Number = 0;

		/**
		 * Width of shadow area (basics of bounbox).
		 * @see #centerX
		 * @see #centerY
		 * @see #centerZ
		 */
		public var width:Number;

		/**
		 * Length of shadow area (basics of bounbox).
		 * @see #centerX
		 * @see #centerY
		 * @see #centerZ
		 */
		public var height:Number;

		/**
		 * Near clipping bound of calculation of shadow area.
		 * Shadow map essentially similar to z-buffer: distance from light source to shadow
		 * casting place is coded by pixel color. So, properties <code>nearBoundPosition</code>
		 * and <code>farBoundPosition</code> in some ways are analogues of <code>Camera3D.farClipping</code>
		 * and <code>Camera3D.nearclipping</code>. The greater the range between <code>nearBoundPosition</code>
		 * and <code> farBoundPosition </code>, the rougher the coordinates of the pixel shader
		 * will be determined. Shadow area, that is not included into this range would not be drawn.
		 * Value is measured from center of shadow, that is set by properties: <code>centerX</code>,
		 * <code>centerY</code>, <code>centerZ</code>.
		 * @see #centerX
		 * @see #centerY
		 * @see #centerZ
		 */
		public var nearBoundPosition:Number = 0;
		
		/**
		 * Far clipping bound of calculation of shadow area.
		 * Shadow map essentially similar to z-buffer: distance from light source to shadow
		 * casting place is coded by pixel color. So, properties <code>nearBoundPosition</code>
		 * and <code>farBoundPosition</code> in some ways are analogues of <code>Camera3D.farClipping</code>
		 * and <code>Camera3D.nearclipping</code>. The greater the range between <code>nearBoundPosition</code>
		 * and <code> farBoundPosition </code>, the rougher the coordinates of the pixel shader
		 * will be determined. Shadow area, that is not included into this range would not be drawn.
		 * Value is measured from center of shadow, that is set by properties <code>centerX</code>,
		 * <code>centerY</code>, <code>centerZ</code>.
		 * @see #centerX
		 * @see #centerY
		 * @see #centerZ
		 */
		public var farBoundPosition:Number = 0;

		// TODO: implement property rotation

		private var _casters:Vector.<Object3D> = new Vector.<Object3D>();
		private var actualCasters:Vector.<Object3D> = new Vector.<Object3D>();

		private var programs:Dictionary = new Dictionary();
		private var cachedContext:Context3D;
		private var shadowMap:Texture;
		private var _mapSize:int;

	    // TODO: to understand the correctness of offset setting in shadowmap units. (It is possible that it is incorrect after the clipping on zone on edges).
		private var _pcfOffset:Number;

		/**
		 * Enable/disable automatic calculation of shadow zone parameters on specified bound-box at shadowBoundBox property.
		 */
		public var calculateParametersByVolume:Boolean = false;

		public var volume:BoundBox = null;

		// TODO: implement special shader for display of shadowmap in debug (black-and-white).
		private var debugTexture:ExternalTextureResource = new ExternalTextureResource("debug");
        private var debugMaterial:TextureMaterial;
        private var emptyLightVector:Vector.<Light3D> = new Vector.<Light3D>();

        private var debugPlane:Mesh;

		// Matrix of projection from light source to context.
		private var cameraToShadowMapContextProjection:Transform3D = new Transform3D();
		// Matrix of projection from light source to shadowmap texture.
		private var cameraToShadowMapUVProjection:Transform3D = new Transform3D();
		// Auxiliary matrix for transfer of object to shadowmap.
		private var objectToShadowMapTransform:Transform3D = new Transform3D();
		// Auxiliary matrix for transfer from global space to local space of light source.
        private var globalToLightTransform:Transform3D = new Transform3D();

		private var tempBounds:BoundBox = new BoundBox();
		private var rect:Rectangle = new Rectangle();
        private var tmpPoints:Vector.<Vector3D> = Vector.<Vector3D>([
            new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D()
		]);
        private var localTmpPoints:Vector.<Vector3D> = Vector.<Vector3D>([
            new Vector3D(), new Vector3D(), new Vector3D(), new Vector3D()
		]);

		/**
		 * Create an instance of DirectionalLightShadow.
		 * @param width Width of area, that will dispay shadow.
		 * @param height Lenght of area, that will display shadow.
		 * @param nearBoundPosition Near bound of cut of shadow calculation area.
		 * @param farBoundPosition Far bound of cut of shadow calculation area.
		 * @param mapSize Size of shadow map. Must be a power of two.
		 * @param pcfOffset Mitigation of shadow bounds.
		 */
		public function DirectionalLightShadow(width:Number, height:Number, nearBoundPosition:Number, farBoundPosition:Number, mapSize:int = 512, pcfOffset:Number = 0) {
			this.width = width;
			this.height = height;
			this.nearBoundPosition = nearBoundPosition;
			this.farBoundPosition = farBoundPosition;

			if (mapSize < 2) {
				throw new ArgumentError("Map size cannot be less than 2.");
			} else if (mapSize > 2048) {
				throw new ArgumentError("Map size exceeds maximum value 2048.");
			}
			if ((Math.log(mapSize)/Math.LN2 % 1) != 0) {
				throw new ArgumentError("Map size must be power of two.");
			}
			this._mapSize = mapSize;

			this._pcfOffset = pcfOffset;
			this.type = _pcfOffset > 0 ? Shadow.PCF_MODE : Shadow.SIMPLE_MODE;

			vertexShadowProcedure = getVShader();
			fragmentShadowProcedure = _pcfOffset > 0 ? getFShaderPCF() : getFShader();

			debugMaterial = new TextureMaterial(debugTexture);
			debugMaterial.alphaThreshold = 1.1;
			debugMaterial.opaquePass = false;
			debugMaterial.alpha = 0.7;
		}

		private function createDebugPlane(material:Material, context:Context3D):Mesh {
            var mesh:Mesh = new Mesh();
            var geometry:Geometry = new Geometry(4);
            mesh.geometry = geometry;

            var attributes:Array = [];
            attributes[0] = VertexAttributes.POSITION;
            attributes[1] = VertexAttributes.POSITION;
            attributes[2] = VertexAttributes.POSITION;
            attributes[3] = VertexAttributes.TEXCOORDS[0];
            attributes[4] = VertexAttributes.TEXCOORDS[0];
            geometry.addVertexStream(attributes);

            geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([-0.5, -0.5, 0, -0.5, 0.5, 0, 0.5, 0.5, 0, 0.5, -0.5, 0]));
            geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));

            geometry.indices = Vector.<uint>([0, 1, 3, 2, 3, 1, 0, 3, 1, 2, 1, 3]);

            mesh.addSurface(material, 0, 4);
            geometry.upload(context);

            return mesh;
        }

		/**
		 * @private
		 */
		override alternativa3d function process(camera:Camera3D):void {
			var i:int;
			var object:Object3D;
			// TODO: realize culling
			// Clipping of casters, that have  shadows which are invisible.
			var numActualCasters:int = 0;
			for (i = 0; i < _casters.length; i++) {
				object = _casters[i];

				var visible:Boolean = object.visible;
				var parent:Object3D = object._parent;
				while (visible && parent != null) {
					visible = parent.visible;
					parent = parent._parent;
				}
				if (visible) {
					actualCasters[numActualCasters++] = object;
				}
			}

			if (camera.context3D != cachedContext) {
				// Processing of changing of context.
				programs = new Dictionary();
				shadowMap = null;
				debugPlane = null;
				cachedContext = camera.context3D;
			}

			var frustumMinX:Number;
			var frustumMaxX:Number;
			var frustumMinY:Number;
			var frustumMaxY:Number;
			var frustumMinZ:Number;
			var frustumMaxZ:Number;

			globalToLightTransform.combine(_light.cameraToLocalTransform, camera.globalToLocalTransform);

            // 2 - calculate boundaries of shadow frustum.
			if (calculateParametersByVolume) {
                updateParametersByVolume();
            }
			var cx:Number = centerX*globalToLightTransform.a + centerY*globalToLightTransform.b + centerZ*globalToLightTransform.c + globalToLightTransform.d;
			var cy:Number = centerX*globalToLightTransform.e + centerY*globalToLightTransform.f + centerZ*globalToLightTransform.g + globalToLightTransform.h;
			var cz:Number = centerX*globalToLightTransform.i + centerY*globalToLightTransform.j + centerZ*globalToLightTransform.k + globalToLightTransform.l;

			// Size of pixel in light source.
			var wPSize:Number = width/_mapSize;
			var hPSize:Number = height/_mapSize;
			// Round coordinates of center to integer pixels.
			cx = Math.round(cx/wPSize)*wPSize;
			cy = Math.round(cy/hPSize)*hPSize;
			// TODO: implement rounding among the z-axis too

			frustumMinX = cx - width*0.5;
			frustumMaxX = cx + width*0.5;
			frustumMinY = cy - height*0.5;
			frustumMaxY = cy + height*0.5;

			frustumMinZ = cz + nearBoundPosition;
			frustumMaxZ = cz + farBoundPosition;

			// Calculation of projection matrices to shadowmap in context.
            var correction:Number = (_mapSize - 2)/_mapSize;
			// Calculate projection matrix.
			cameraToShadowMapContextProjection.a = 2/(frustumMaxX - frustumMinX)*correction;
			cameraToShadowMapContextProjection.b = 0;
			cameraToShadowMapContextProjection.c = 0;
			cameraToShadowMapContextProjection.e = 0;
			cameraToShadowMapContextProjection.f = -2/(frustumMaxY - frustumMinY)*correction;
			cameraToShadowMapContextProjection.g = 0;
			cameraToShadowMapContextProjection.h = 0;
			cameraToShadowMapContextProjection.i = 0;
			cameraToShadowMapContextProjection.j = 0;
			cameraToShadowMapContextProjection.k = 1 / (frustumMaxZ - frustumMinZ);
			cameraToShadowMapContextProjection.d = (-0.5 * (frustumMaxX + frustumMinX) * cameraToShadowMapContextProjection.a);
			cameraToShadowMapContextProjection.h = (-0.5 * (frustumMaxY + frustumMinY) * cameraToShadowMapContextProjection.f);
			cameraToShadowMapContextProjection.l = -frustumMinZ / (frustumMaxZ - frustumMinZ);

			cameraToShadowMapUVProjection.copy(cameraToShadowMapContextProjection);
			cameraToShadowMapUVProjection.a = 1 / ((frustumMaxX - frustumMinX)) * correction;
			cameraToShadowMapUVProjection.f = 1 / ((frustumMaxY - frustumMinY)) * correction;
			cameraToShadowMapUVProjection.d = 0.5 - (0.5 * (frustumMaxX + frustumMinX) * cameraToShadowMapUVProjection.a);
			cameraToShadowMapUVProjection.h = 0.5 - (0.5 * (frustumMaxY + frustumMinY) * cameraToShadowMapUVProjection.f);

			cameraToShadowMapContextProjection.prepend(_light.cameraToLocalTransform);
			cameraToShadowMapUVProjection.prepend(_light.cameraToLocalTransform);

			// Calculation of transfer matrix to space of shadowmap texture.
			for (i = 0; i < numActualCasters; i++) {
				object = actualCasters[i];
				// 4- Collect drawcalls for caster and its child objects.
				collectDraws(camera.context3D, object);
			}

			// Rendering of drawacalls to atlas.
			if (shadowMap == null) {
				shadowMap = camera.context3D.createTexture(_mapSize, _mapSize, Context3DTextureFormat.BGRA, true);
				debugTexture._texture = shadowMap;
			}
			// TODO Don't clear if there was no casters

			camera.context3D.setRenderToTexture(shadowMap, true);
			camera.context3D.clear(1, 0, 0, 0.3);

			renderer.camera = camera;

			rect.x = 1;
			rect.y = 1;
			rect.width = _mapSize - 2;
			rect.height = _mapSize - 2;
			camera.context3D.setScissorRectangle(rect);

			renderer.render(camera.context3D);

			camera.context3D.setScissorRectangle(null);

			camera.context3D.setRenderToBackBuffer();

			if (debug) {
				if (debugPlane == null) {
					debugPlane = createDebugPlane(debugMaterial, camera.context3D);
				}
				// Form transformation matrix for debugPlane
				debugPlane.transform.compose((frustumMinX + frustumMaxX) / 2, (frustumMinY + frustumMaxY) / 2, frustumMinZ, 0, 0, 0, (frustumMaxX - frustumMinX), (frustumMaxY - frustumMinY), 1);
				debugPlane.localToCameraTransform.combine(_light.localToCameraTransform, debugPlane.transform);

				// Draw
				var debugSurface:Surface = debugPlane._surfaces[0];
				debugSurface.material.collectDraws(camera, debugSurface, debugPlane.geometry, emptyLightVector, 0, false, -1);

				// Form transformation matrix for debugPlane
				debugPlane.transform.compose((frustumMinX + frustumMaxX) / 2, (frustumMinY + frustumMaxY) / 2, frustumMaxZ, 0, 0, 0, (frustumMaxX - frustumMinX), (frustumMaxY - frustumMinY), 1);
				debugPlane.localToCameraTransform.combine(_light.localToCameraTransform, debugPlane.transform);
				debugSurface.material.collectDraws(camera, debugSurface, debugPlane.geometry, emptyLightVector, 0, false, -1);

				tempBounds.minX = frustumMinX;
				tempBounds.maxX = frustumMaxX;
				tempBounds.minY = frustumMinY;
				tempBounds.maxY = frustumMaxY;
				tempBounds.minZ = frustumMinZ;
				tempBounds.maxZ = frustumMaxZ;
				Debug.drawBoundBox(camera, tempBounds, _light.localToCameraTransform, 0xe1cd27);
			}
		}

		private function updateParametersByVolume():void {
//            globalToLightTransform.combine(_light.cameraToLocalTransform, camera.globalToLocalTransform);

			if (volume != null) {
				// converts boundbox to point.
				tmpPoints[0].x = tmpPoints[2].x = tmpPoints[3].x = volume.minX;
				tmpPoints[1].x = volume.maxX;
				tmpPoints[2].y = volume.minY;
				tmpPoints[0].y = tmpPoints[1].y = tmpPoints[3].y = volume.maxY;
				tmpPoints[0].z = tmpPoints[1].z = tmpPoints[2].z = volume.minZ;
				tmpPoints[3].z = volume.maxZ;

                var i:int;
                var tmpPoint:Vector3D;
                var x:Number;
                var y:Number;
                var z:Number;
				var localX:Number;
				var localY:Number;
				var localZ:Number;

				// converts points to local space.
				tmpPoint = tmpPoints[0];
				x = tmpPoint.x;
				y = tmpPoint.y;
				z = tmpPoint.z;
				localX = x*globalToLightTransform.a + y*globalToLightTransform.b + z*globalToLightTransform.c + globalToLightTransform.d;
				localY = x*globalToLightTransform.e + y*globalToLightTransform.f + z*globalToLightTransform.g + globalToLightTransform.h;
				localZ = x*globalToLightTransform.i + y*globalToLightTransform.j + z*globalToLightTransform.k + globalToLightTransform.l;
				tempBounds.minX = localX;
				tempBounds.maxX = localX;
	            tempBounds.minY = localY;
	            tempBounds.maxY = localY;
				tempBounds.minZ = localZ;
				tempBounds.maxZ = localZ;
                tmpPoint = localTmpPoints[0];
                tmpPoint.x = localX;
                tmpPoint.y = localY;
                tmpPoint.z = localZ;

                for (i = 1; i<4; i++){
					tmpPoint = tmpPoints[i];
					x = tmpPoint.x;
					y = tmpPoint.y;
					z = tmpPoint.z;
                    localX = x*globalToLightTransform.a + y*globalToLightTransform.b + z*globalToLightTransform.c + globalToLightTransform.d;
                    localY = x*globalToLightTransform.e + y*globalToLightTransform.f + z*globalToLightTransform.g + globalToLightTransform.h;
                    localZ = x*globalToLightTransform.i + y*globalToLightTransform.j + z*globalToLightTransform.k + globalToLightTransform.l;

	                // Find maximums and minimums and put them to local boundbox.
					if (tempBounds.minX > localX)tempBounds.minX = localX;
					if (tempBounds.maxX < localX)tempBounds.maxX = localX;
					if (tempBounds.minY > localY)tempBounds.minY = localY;
					if (tempBounds.maxY < localY)tempBounds.maxY = localY;
					if (tempBounds.minZ > localZ)tempBounds.minZ = localZ;
					if (tempBounds.maxZ < localZ)tempBounds.maxZ = localZ;
                    tmpPoint = localTmpPoints[i];
                    tmpPoint.x = localX;
                    tmpPoint.y = localY;
                    tmpPoint.z = localZ;
                }

				// Find last four points and maximums/minimums of them.
                var localTmpPoint0:Vector3D = localTmpPoints[0];
                var localTmpPoint1:Vector3D = localTmpPoints[1];
                var localTmpPoint2:Vector3D = localTmpPoints[2];
                var localTmpPoint3:Vector3D = localTmpPoints[3];
                //7
                localX = localTmpPoint2.x + localTmpPoint3.x - localTmpPoint0.x;
                localY = localTmpPoint2.y + localTmpPoint3.y - localTmpPoint0.y;
                localZ = localTmpPoint2.z + localTmpPoint3.z - localTmpPoint0.z;
				if (tempBounds.minX > localX)tempBounds.minX = localX;
				if (tempBounds.maxX < localX)tempBounds.maxX = localX;
				if (tempBounds.minY > localY)tempBounds.minY = localY;
				if (tempBounds.maxY < localY)tempBounds.maxY = localY;
				if (tempBounds.minZ > localZ)tempBounds.minZ = localZ;
				if (tempBounds.maxZ < localZ)tempBounds.maxZ = localZ;

                //5
                localX = localTmpPoint3.x + localTmpPoint1.x - localTmpPoint0.x;
                localY = localTmpPoint3.y + localTmpPoint1.y - localTmpPoint0.y;
                localZ = localTmpPoint3.z + localTmpPoint1.z - localTmpPoint0.z;
				if (tempBounds.minX > localX)tempBounds.minX = localX;
				if (tempBounds.maxX < localX)tempBounds.maxX = localX;
				if (tempBounds.minY > localY)tempBounds.minY = localY;
				if (tempBounds.maxY < localY)tempBounds.maxY = localY;
				if (tempBounds.minZ > localZ)tempBounds.minZ = localZ;
				if (tempBounds.maxZ < localZ)tempBounds.maxZ = localZ;

                //6
                localX = localTmpPoint2.x + localTmpPoint1.x - localTmpPoint0.x;
                localY = localTmpPoint2.y + localTmpPoint1.y - localTmpPoint0.y;
                localZ = localTmpPoint2.z + localTmpPoint1.z - localTmpPoint0.z;
				if (tempBounds.minX > localX)tempBounds.minX = localX;
				if (tempBounds.maxX < localX)tempBounds.maxX = localX;
				if (tempBounds.minY > localY)tempBounds.minY = localY;
				if (tempBounds.maxY < localY)tempBounds.maxY = localY;
				if (tempBounds.minZ > localZ)tempBounds.minZ = localZ;
				if (tempBounds.maxZ < localZ)tempBounds.maxZ = localZ;

                //4
                localX = localX + localTmpPoint3.x - localTmpPoint0.x;
                localY = localY + localTmpPoint3.y - localTmpPoint0.y;
                localZ = localZ + localTmpPoint3.z - localTmpPoint0.z;
				if (tempBounds.minX > localX)tempBounds.minX = localX;
				if (tempBounds.maxX < localX)tempBounds.maxX = localX;
				if (tempBounds.minY > localY)tempBounds.minY = localY;
				if (tempBounds.maxY < localY)tempBounds.maxY = localY;
				if (tempBounds.minZ > localZ)tempBounds.minZ = localZ;
				if (tempBounds.maxZ < localZ)tempBounds.maxZ = localZ;

				//Calculate parameters, depending on the boundbox.
				width = tempBounds.maxX - tempBounds.minX;
				height = tempBounds.maxY - tempBounds.minY;
                nearBoundPosition = (tempBounds.minZ - tempBounds.maxZ)/2;
                farBoundPosition = -nearBoundPosition;

				centerX = (volume.minX + volume.maxX)/2;
				centerY = (volume.minY + volume.maxY)/2;
				centerZ = (volume.minZ + volume.maxZ)/2;
            }
        }

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
                    "#c3=cScale",
                    "#v0=vDistance",
                    "m34 t0.xyz, i0, c0",
                    "mov t0.w, c3.w",
                    "mul v0, t0, c3.x",
                    "mov o0, t0"
                ]);
                proc.assignVariableName(VariableType.CONSTANT, 0, "cTransform", 3);
                vLinker.addProcedure(proc, positionVar);

                if (alphaTest) {
                    if (useDiffuseAlpha) {
                        fLinker.addProcedure(diffuseAlphaTestProcedure);
                    } else {
                        fLinker.addProcedure(opacityAlphaTestProcedure);
                    }
                }
                fLinker.addProcedure(Procedure.compileFromArray([
                    "#v0=vDistance",
                    "#c0=cConstants",
                    "frc t0.y, v0.z",
                    "sub t0.x, v0.z, t0.y",
                    "mul t0.x, t0.x, c0.x",
                    "mov t0.z, c0.z",
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

		/**
		 * @private
		 * Procedure for passing of UV coordinates to fragment shader.
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
			"kil t0.w",
		], "diffuseAlphaTestProcedure");

		// opacity alpha test
		private static const opacityAlphaTestProcedure:Procedure = new Procedure([
			"#v0=vUV",
			"#s0=sTexture",
			"#c0=cThresholdAlpha",
			"tex t0, v0, s0 <2d, linear,repeat, miplinear>",
			"mul t0.w, t0.x, c0.w",
			"sub t0.w, t0.w, c0.x",
			"kil t0.w"], "opacityAlphaTestProcedure");

        // collectDraws for rendering to shadowmap.
		private function collectDraws(context:Context3D, object:Object3D):void {
            // alphaThreshold:Number, diffuse:TextureResource, opacity:TextureResource, materialAlpha:Number
			var child:Object3D;

			var mesh:Mesh = object as Mesh;
			if (mesh != null && mesh.geometry != null) {
				var program:ShaderProgram;
                var programListByTransformProcedure:Vector.<ShaderProgram>;
				var skin:Skin = mesh as Skin;

				if (skin != null) {
					// Calculation of matrices of joints.
					for (child = skin.childrenList; child != null; child = child.next) {
						if (child.transformChanged) child.composeTransforms();
						// Write в localToGlobalTransform matrix of transfering to skin coordinates
						child.localToGlobalTransform.copy(child.transform);
						if (child is Joint) {
							Joint(child).calculateTransform();
						}
						skin.calculateJointsTransforms(child);
					}
				}

				// 1- calculation of transfer matrix from object to light source.
				objectToShadowMapTransform.combine(cameraToShadowMapContextProjection, object.localToCameraTransform);

				for (var i:int = 0; i < mesh._surfacesLength; i++) {
					// Form drawcall.
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

					if (skin != null) {
						object.transformProcedure = skin.surfaceTransformProcedures[i];
					}
					programListByTransformProcedure = programs[object.transformProcedure];
					if (programListByTransformProcedure == null) {
						programListByTransformProcedure = new Vector.<ShaderProgram>(3, true);
						programs[object.transformProcedure] = programListByTransformProcedure;
					}
					program = getProgram(object.transformProcedure, programListByTransformProcedure, context, alphaTest, useDiffuseAlpha);

					var drawUnit:DrawUnit = renderer.createDrawUnit(object, program.program, mesh.geometry._indexBuffer, surface.indexBegin, surface.numTriangles, program);

					// Setting of buffers.
					object.setTransformConstants(drawUnit, surface, program.vertexShader, null);

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

					// Setting of constants.
					drawUnit.setVertexConstantsFromTransform(program.vertexShader.getVariableIndex("cTransform"), objectToShadowMapTransform);
					drawUnit.setVertexConstantsFromNumbers(program.vertexShader.getVariableIndex("cScale"), 255, 0, 0, 1);
					drawUnit.setFragmentConstantsFromNumbers(program.fragmentShader.getVariableIndex("cConstants"), 1 / 255, 0, 0, 1);

					renderer.addDrawUnit(drawUnit, Renderer.OPAQUE);
				}
			}
			for (child = object.childrenList; child != null; child = child.next) {
				if (child.visible) collectDraws(context, child);
			}
		}

		//------------- ShadowMap Shader ----------

		/**
		 * @private
		 */
		alternativa3d override function setup(drawUnit:DrawUnit, vertexLinker:Linker, fragmentLinker:Linker, surface:Surface):void {
			// Устанавливаем матрицу перевода в шедоумапу
			objectToShadowMapTransform.combine(cameraToShadowMapUVProjection, surface.object.localToCameraTransform);

			drawUnit.setVertexConstantsFromTransform(vertexLinker.getVariableIndex("cUVProjection"), objectToShadowMapTransform);
			// Устанавливаем шедоумапу
			drawUnit.setTextureAt(fragmentLinker.getVariableIndex("sShadowMap"), shadowMap);
			// Устанавливаем коеффициенты
			drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cConstants"), -255*DIFFERENCE_MULTIPLIER, -DIFFERENCE_MULTIPLIER, biasMultiplier*255*DIFFERENCE_MULTIPLIER, 1/16);
			if (_pcfOffset > 0) {
				var offset1:Number = _pcfOffset/_mapSize;
				var offset2:Number = offset1/3;

				drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cPCFOffsets"), -offset1, -offset2, offset2, offset1);
			}
			drawUnit.setFragmentConstantsFromNumbers(fragmentLinker.getVariableIndex("cDist"), 0.9999, DIFFERENCE_MULTIPLIER, 1);
		}

		private static function getVShader():Procedure {
			var shader:Procedure = Procedure.compileFromArray([
				"#v0=vSample",
				"m34 v0.xyz, i0, c0",
				"mov v0.w, i0.w"
			], "DirectionalShadowMapVertex");
			shader.assignVariableName(VariableType.CONSTANT, 0, "cUVProjection", 3);
			return shader;
		}
		
		private static function getFShader():Procedure {
			var shaderArr:Array = [
				"#v0=vSample",
				"#c0=cConstants",
				"#c1=cDist",		// 0, -max*10000, 10000
				"#s0=sShadowMap"
			];
			var line:int = 4;
			shaderArr[line++] = "mov t0.zw, v0.zz";
			// Distance.
			shaderArr[line++] = "tex t0.xy, v0, s0 <2d,clamp,near,nomip>";
			shaderArr[line++] = "dp3 t0.x, t0.xyz, c0.xyz";

			// Clipping by distance.
			shaderArr[line++] = "sub t0.y, c1.x, t0.z";   // maxDist - z
			shaderArr[line++] = "mul t0.y, t0.y, c1.y";   // mul 10000

			shaderArr[line++] = "sat t0.xy, t0.xy";
			shaderArr[line++] = "mul t0.x, t0.x, t0.y";
			shaderArr[line++] = "sub o0, c1.z, t0.x";

			return Procedure.compileFromArray(shaderArr, "DirectionalShadowMapFragment");
		}

		private static const pcfOffsetRegisters:Array = [
			"xx", "xy", "xz", "xw",
			"yx", "yy", "yz", "yw",
			"zx", "zy", "zz", "zw",
			"wx", "wy", "wz", "ww"
		];
		private static const componentByIndex:Array = [
			"x", "y", "z", "w"
		];

		private static function getFShaderPCF():Procedure {
			var shaderArr:Array = [
				"#v0=vSample",
				"#c0=cConstants",
				"#c1=cPCFOffsets",
				"#c2=cDist",
				"#s0=sShadowMap"
			];
			var line:int = 5;
			shaderArr[line++] = "mov t0.zw, v0.zz";	// put distance to t1.z
			for (var i:int = 0; i < 16; i++) {
				var column:int = i & 3;

				// Calculation of offset
				shaderArr[line++] = "add t0.xy, v0.xy, c1." + pcfOffsetRegisters[i];
				// Distance.
				shaderArr[line++] = "tex t0.xy, t0, s0 <2d,clamp,near,nomip>";
				shaderArr[line++] = "dp3 t1." + componentByIndex[column] + ", t0.xyz, c0.xyz";  // restore distance and calculate difference
				if (column == 3) {
					// Last item in string.
					shaderArr[line++] = "sat t1, t1";
					shaderArr[line++] = "dp4 t2." + componentByIndex[int(i >> 2)] + ", t1, c0.w";
				}
			}
			shaderArr[line++] = "dp4 t0.x, t2, v0.w";

			// Clipping by distance.
			shaderArr[line++] = "sub t0.y, c2.x, t0.z";   // maxDist - z
			shaderArr[line++] = "mul t0.y, t0.y, c2.y";   // mul 10000
			shaderArr[line++] = "sat t0.y, t0.y";
			shaderArr[line++] = "mul t0.x, t0.x, t0.y";
			shaderArr[line++] = "sub o0, c2.z, t0.x";

			return Procedure.compileFromArray(shaderArr, "DirectionalShadowMapFragment");
		}

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
			_casters[index] = _casters.pop();
		}
		/**
		 * Clears the list of objects, which cast shadow.
		 */
		public function clearCasters():void {
			_casters.length = 0;
		}

		/**
		 * Set resolution of shadow map. This property can get value of power of 2 (up to 2048).
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
				} else if (value > 2048) {
					throw new ArgumentError("Map size exceeds maximum value 2048.");
				}
				if ((Math.log(value)/Math.LN2 % 1) != 0) {
					throw new ArgumentError("Map size must be power of two.");
				}
				if (shadowMap != null) {
					shadowMap.dispose();
				}
				shadowMap = null;
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
