/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.EncodeDepthMaterial;
	import alternativa.engine3d.materials.OutputEffect;
	import alternativa.engine3d.materials.SSAOAngular;
	import alternativa.engine3d.materials.SSAOBlur;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getTimer;

	use namespace alternativa3d;

/**
 *
 * Camera - it's three-dimensional object without its own visual representation and intended for visualising  hierarchy of objects.
 * For resource optimization camera draws only visible objects(objects in frustum). The view frustum is the volume that contains
 * everything that is potentially visible on the screen. This volume takes the shape of a truncated pyramid, which defines
 * by 6 planes. The apex of the pyramid is the camera position and the base of the pyramid is the <code>farClipping</code>.
 * The pyramid is truncated at the <code>nearClipping</code>. Current version of Alternativa3D uses Z-Buffer for sorting objects,
 * accuracy of sorting depends on distance between <code>farClipping</code> and <code>nearClipping</code>. That's why necessary to set a minimum
 * distance between them for current scene. nearClipping mustn't be equal zero.
 *
 */
public class Camera3D extends Object3D {

	/**
	 * @private
	 * Key - context, value - properties.
	 */
	alternativa3d static var context3DPropertiesPool:Dictionary = new Dictionary(true);

	/**
	 * The viewport defines part of screen to which renders image seen by the camera.
	 * If viewport is not defined, the camera would not draws anything.
	 */
	public var view:View;

	/**
	 * Field if view. Defines in radians.  Default value is <code>Math.PI/2</code> which considered with 90 degrees.
	 */
	public var fov:Number = Math.PI / 2;

	/**
	 * Near clipping distance. Default value <code>0</code>. It should be as big as possible.
	 */
	public var nearClipping:Number;

	/**
	 * Far distance of clipping. Default value <code>Number.MAX_VALUE</code>.
	 */
	public var farClipping:Number;

	/**
	 * Determines whether orthographic (true) or perspective (false) projection is used. The default value is false.
	 */
	public var orthographic:Boolean = false;

	/**
	 * @private
	 */
	alternativa3d var focalLength:Number;
	/**
	 * @private
	 */
	alternativa3d var m0:Number;
	/**
	 * @private
	 */
	alternativa3d var m5:Number;
	/**
	 * @private
	 */
	alternativa3d var m10:Number;
	/**
	 * @private
	 */
	alternativa3d var m14:Number;
	/**
	 * @private
	 */
	alternativa3d var correctionX:Number;
	/**
	 * @private
	 */
	alternativa3d var correctionY:Number;

	/**
	 * @private
	 */
	alternativa3d var lights:Vector.<Light3D> = new Vector.<Light3D>();
	/**
	 * @private
	 */
	alternativa3d var lightsLength:int = 0;
	/**
	 * @private
	 */
	alternativa3d var ambient:Vector.<Number> = new Vector.<Number>(4);
	/**
	 * @private
	 */
	alternativa3d var childLights:Vector.<Light3D> = new Vector.<Light3D>();

	/**
	 * @private
	 */
	alternativa3d var frustum:CullingPlane;

	/**
	 * @private
	 */
	alternativa3d var origins:Vector.<Vector3D> = new Vector.<Vector3D>();
	/**
	 * @private
	 */
	alternativa3d var directions:Vector.<Vector3D> = new Vector.<Vector3D>();
	/**
	 * @private
	 */
	alternativa3d var raysLength:int = 0;

	/**
	 * @private
	 */
	alternativa3d var globalMouseHandlingType:uint;

	/**
	 * @private
	 */
	alternativa3d var occluders:Vector.<Occluder> = new Vector.<Occluder>();
	/**
	 * @private
	 */
	alternativa3d var occludersLength:int = 0;

	/**
	 * @private
	 * <code>Context3D</code> which is used for rendering.
	 */
	alternativa3d var context3D:Context3D;

	/**
	 * @private
	 */
	alternativa3d var context3DProperties:RendererContext3DProperties;

	/**
	 * @private
	 * Camera's renderer. If is not defined, the camera will no draw anything.
	 */
	public var renderer:Renderer = new Renderer();

	/**
	 * @private
	 */
	alternativa3d var depthRenderer:Renderer = new Renderer();

	private var encDepthMaterial:EncodeDepthMaterial = new EncodeDepthMaterial();
	private var decDepthEffect:OutputEffect = new OutputEffect();
	/**
	 * @private
	 */
	public  var ssaoAngular:SSAOAngular = new SSAOAngular();
	private var ssaoBlur:SSAOBlur = new SSAOBlur();

	private var depthTexture:Texture;
	private var ssaoTexture:Texture;
	private var bluredSSAOTexture:Texture;
	private var effectTextureLog2Width:int = -1;
	private var effectTextureLog2Height:int = -1;

	/**
	 * In this mode camera will render usual color image without SSAO.
	 */
    public static const MODE_COLOR:int = 0;
	/**
	 *  This mode represents z-buffer as it is stored with engine. For distance encoding red and green channels are used.
	 */
    public static const MODE_RAW_DEPTH:int = 1;
	/**
	 * This mode displays depth map which is z-buffer converted to grayscale.
	 */
    public static const MODE_DEPTH:int = 2;
	/**
	 * This mode displays normal map calculated in screen space.
	 */
    public static const MODE_NORMALS:int = 3;
	/**
	 * This mode displays pure SSAO effect.
	 */
    public static const MODE_SSAO_ONLY:int = 8;
	/**
	 * This mode displays  postprocessed image which is SSAO effect combined with usual color image.
	 */
    public static const MODE_SSAO_COLOR:int = 9;
	/**
	 *  Defines what will render the camera.   You should set one of following values: <code>Camera3D.MODE_COLOR</code>, <code>Camera3D.MODE_DEPTH</code>,
	 *  <code>Camera3D.MODE_NORMALS</code>, <code>Camera3D.MODE_RAW_DEPTH</code>, <code>Camera3D.MODE_SSAO_COLOR</code>, <code>Camera3D.MODE_SSAO_ONLY</code>
	 *  @see Camera3D#MODE_COLOR
	 *  @see Camera3D#MODE_DEPTH
	 *  @see Camera3D#MODE_NORMALS
	 *  @see Camera3D#MODE_RAW_DEPTH
	 *  @see Camera3D#MODE_SSAO_COLOR
	 *  @see Camera3D#MODE_SSAO_ONLY
	 */
	public var effectMode:int = 0;
	public var blurEnabled:Boolean = true;
	public var effectRate:int = 1;
	/**
	 * Defines SSAO resolution. In case of <code>0</code> SSAO resolution is equal to screen resolution, in case of <code>1</code> – half screen resolution and so on.
	 */
	public var ssaoScale:int = 0;
	private var _depthScale:int = 0;
	public function get depthScale():int {
		return _depthScale;
	}
	public function set depthScale(value:int):void {
		if (depthTexture != null) {
			depthTexture.dispose();
			depthTexture = null;
		}
		_depthScale = (value > 0) ? value : 0;
	}

	/**
	 * @private
	 */
	alternativa3d var numDraws:int;

	/**
	 * @private
	 */
	alternativa3d var numTriangles:int;

	/**
	 * Creates a <code>Camera3D</code> object.
	 *
	 * @param nearClipping  Near clipping distance.
	 * @param farClipping  Far clipping distance.
	 */
	public function Camera3D(nearClipping:Number, farClipping:Number) {
		this.nearClipping = nearClipping;
		this.farClipping = farClipping;
		frustum = new CullingPlane();
		frustum.next = new CullingPlane();
		frustum.next.next = new CullingPlane();
		frustum.next.next.next = new CullingPlane();
		frustum.next.next.next.next = new CullingPlane();
		frustum.next.next.next.next.next = new CullingPlane();
	}

	/**
	 * Rendering of objects hierarchy to the given <code>Stage3D</code>.
	 *
	 * @param stage3D  <code>Stage3D</code> to which image will be rendered.
	 */
	public function render(stage3D:Stage3D):void {
		if (ssaoScale < 0) ssaoScale = 0;

		var i:int;
		var j:int;
		var light:Light3D;
		var occluder:Occluder;
		// Error checking
		if (stage3D == null) throw new TypeError("Parameter stage3D must be non-null.");
		// Reset the counters
		numDraws = 0;
		numTriangles = 0;
		// Reset the occluders
		occludersLength = 0;
		// Reset the lights
		lightsLength = 0;
		ambient[0] = 0;
		ambient[1] = 0;
		ambient[2] = 0;
		ambient[3] = 1;
		// Receiving the context
		var currentContext3D:Context3D = stage3D.context3D;
		if (currentContext3D != context3D) {
			if (currentContext3D != null) {
				context3DProperties = context3DPropertiesPool[currentContext3D];
				if (context3DProperties == null) {
					context3DProperties = new RendererContext3DProperties();
					context3DProperties.isConstrained = currentContext3D.driverInfo.lastIndexOf("(Baseline Constrained)") >= 0;
					context3DPropertiesPool[currentContext3D] = context3DProperties;
				}
				context3D = currentContext3D;
			} else {
				context3D = null;
				context3DProperties = null;
			}
		}
		if (context3D != null && view != null && renderer != null && (view.stage != null || view._canvas != null)) {
			renderer.camera = this;
			depthRenderer.camera = this;
			// Projection argument calculating
			calculateProjection(view._width, view._height);
			// Preparing to rendering
			view.configureContext3D(stage3D, context3D, this);
			if (effectMode > 0) {
				// update depth texture
				var log2Width:int = Math.ceil(Math.log(view._width/effectRate)/Math.LN2) - ssaoScale;
				var log2Height:int = Math.ceil(Math.log(view._height/effectRate)/Math.LN2) - ssaoScale;
				log2Width = log2Width > 11 ? 11 : log2Width;
				log2Height = log2Height > 11 ? 11 : log2Height;
				if (effectTextureLog2Width != log2Width || effectTextureLog2Height != log2Height || depthTexture == null) {
					if (depthTexture != null) depthTexture.dispose();
					depthTexture = context3D.createTexture(1 << (log2Width - _depthScale), 1 << (log2Height - _depthScale), Context3DTextureFormat.BGRA, true);
					if (ssaoTexture != null) ssaoTexture.dispose();
					ssaoTexture = context3D.createTexture(1 << log2Width, 1 << log2Height, Context3DTextureFormat.BGRA, true);
					if (bluredSSAOTexture != null) bluredSSAOTexture.dispose();
					bluredSSAOTexture = context3D.createTexture(1 << log2Width, 1 << log2Height, Context3DTextureFormat.BGRA, true);
					effectTextureLog2Width = log2Width;
					effectTextureLog2Height = log2Height;
				}
				encDepthMaterial.outputScaleX = view._width/(1 << (effectTextureLog2Width + ssaoScale));
				encDepthMaterial.outputScaleY = view._height/(1 << (effectTextureLog2Height + ssaoScale));
				encDepthMaterial.outputOffsetX = encDepthMaterial.outputScaleX - 1;
				encDepthMaterial.outputOffsetY = 1 - encDepthMaterial.outputScaleY;
			}

			// Transformations calculating
			if (transformChanged) composeTransforms();
			localToGlobalTransform.copy(transform);
			globalToLocalTransform.copy(inverseTransform);
			// Searching for upper hierarchy point
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				localToGlobalTransform.append(root.transform);
				globalToLocalTransform.prepend(root.inverseTransform);
			}

			// Check if object of hierarchy is visible
			if (root.visible) {
				// Calculating the matrix to transform from the camera space to local space
				root.cameraToLocalTransform.combine(root.inverseTransform, localToGlobalTransform);
				// Calculating the matrix to transform from local space to the camera space
				root.localToCameraTransform.combine(globalToLocalTransform, root.transform);

				globalMouseHandlingType = root.mouseHandlingType;
				// Checking the culling
				if (root.boundBox != null) {
					calculateFrustum(root.cameraToLocalTransform);
					root.culling = root.boundBox.checkFrustumCulling(frustum, 63);
				} else {
					root.culling = 63;
				}
				// Calculations of content visibility
				if (root.culling >= 0) root.calculateVisibility(this);
				// Calculations  visibility of children
				root.calculateChildrenVisibility(this);
				// Calculations of transformations from occluder space to the camera space
				for (i = 0; i < occludersLength; i++) {
					occluder = occluders[i];
					occluder.localToCameraTransform.calculateInversion(occluder.cameraToLocalTransform);
					occluder.transformVertices(correctionX, correctionY);
					occluder.distance = orthographic ? occluder.localToCameraTransform.l : (occluder.localToCameraTransform.d * occluder.localToCameraTransform.d + occluder.localToCameraTransform.h * occluder.localToCameraTransform.h + occluder.localToCameraTransform.l * occluder.localToCameraTransform.l);
					occluder.enabled = true;
				}
				// Sorting the occluders by disance
				if (occludersLength > 1) sortOccluders();
				// Constructing the volumes of occluders, their intersections, starts from closest
				for (i = 0; i < occludersLength; i++) {
					occluder = occluders[i];
					if (occluder.enabled) {
						occluder.calculatePlanes(this);
						if (occluder.planeList != null) {
							for (j = i + 1; j < occludersLength; j++) { // It is possible, that start value should be 0
								var compared:Occluder = occluders[j];
								if (compared.enabled && compared != occluder && compared.checkOcclusion(occluder, correctionX, correctionY)) compared.enabled = false;
							}
						} else {
							occluder.enabled = false;
						}
					}
					// Reset of culling
					occluder.culling = -1;
				}
				//  Gather the occluders which will affects now
				for (i = 0, j = 0; i < occludersLength; i++) {
					occluder = occluders[i];
					if (occluder.enabled) {
						// Debug
						occluder.collectDraws(this, null, 0, false);
						if (debug && occluder.boundBox != null && (checkInDebug(occluder) & Debug.BOUNDS)) Debug.drawBoundBox(this, occluder.boundBox, occluder.localToCameraTransform);
						occluders[j] = occluder;
						j++;
					}
				}
				occludersLength = j;
				occluders.length = j;
				// Check light influence
				for (i = 0, j = 0; i < lightsLength; i++) {
					light = lights[i];
					light.localToCameraTransform.calculateInversion(light.cameraToLocalTransform);
					if (light.boundBox == null || occludersLength == 0 || !light.boundBox.checkOcclusion(occluders, occludersLength, light.localToCameraTransform)) {
						light.red = ((light.color >> 16) & 0xFF) * light.intensity / 255;
						light.green = ((light.color >> 8) & 0xFF) * light.intensity / 255;
						light.blue = (light.color & 0xFF) * light.intensity / 255;
						// Debug
						light.collectDraws(this, null, 0, false);
						if (debug && light.boundBox != null && (checkInDebug(light) & Debug.BOUNDS)) Debug.drawBoundBox(this, light.boundBox, light.localToCameraTransform);

						// Shadows preparing
						if (light.shadow != null) {
							light.shadow.process(this);
						}
						lights[j] = light;
						j++;
					}
					light.culling = -1;
				}
				lightsLength = j;
				lights.length = j;

				// Sort lights by types
				if (lightsLength > 0) sortLights(0, lightsLength - 1);

				// Calculating the rays of mouse events
				view.calculateRays(this, (globalMouseHandlingType & Object3D.MOUSE_HANDLING_MOVING) != 0,
										 (globalMouseHandlingType & Object3D.MOUSE_HANDLING_PRESSING) != 0,
										 (globalMouseHandlingType & Object3D.MOUSE_HANDLING_WHEEL) != 0,
										 (globalMouseHandlingType & Object3D.MOUSE_HANDLING_MIDDLE_BUTTON) != 0,
										 (globalMouseHandlingType & Object3D.MOUSE_HANDLING_RIGHT_BUTTON) != 0);
				for (i = origins.length; i < view.raysLength; i++) {
					origins[i] = new Vector3D();
					directions[i] = new Vector3D();
				}
				raysLength = view.raysLength;

				var r:Number = ((view.backgroundColor >> 16) & 0xff)/0xff;
				var g:Number = ((view.backgroundColor >> 8) & 0xff)/0xff;
				var b:Number = (view.backgroundColor & 0xff)/0xff;
				if (view._canvas != null) {
					r *= view.backgroundAlpha;
					g *= view.backgroundAlpha;
					b *= view.backgroundAlpha;
				}
				context3D.clear(r, g, b, view.backgroundAlpha);

				// Check getting in frustum and occluding
				if (root.culling >= 0 && (root.boundBox == null || occludersLength == 0 || !root.boundBox.checkOcclusion(occluders, occludersLength, root.localToCameraTransform))) {
					// Check if the ray crossing the bounding box
					if (globalMouseHandlingType > 0 && root.boundBox != null) {
						calculateRays(root.cameraToLocalTransform);
						root.listening = root.boundBox.checkRays(origins, directions, raysLength);
					} else {
						root.listening = globalMouseHandlingType > 0;
					}
					// Check if object needs in lightning
					var excludedLightLength:int = root._excludedLights.length;
					if (lightsLength > 0 && root.useLights) {
						// Pass the lights to children and calculate appropriate transformations
						var childLightsLength:int = 0;
						if (root.boundBox != null) {
							for (i = 0; i < lightsLength; i++) {
								light = lights[i];
								// Checking light source for existing in excludedLights
								j = 0;
								while (j<excludedLightLength && root._excludedLights[j]!=light)	j++;
								if (j<excludedLightLength) continue;

								light.lightToObjectTransform.combine(root.cameraToLocalTransform, light.localToCameraTransform);
								// Detect influence
								if (light.boundBox == null || light.checkBound(root)) {
									childLights[childLightsLength] = light;
									childLightsLength++;
								}
							}
						} else {
							// Calculate transformation from light space to object space
							for (i = 0; i < lightsLength; i++) {
								light = lights[i];
								// Checking light source for existing in excludedLights
								j = 0;
								while (j<excludedLightLength && root._excludedLights[j]!=light)	j++;
								if (j<excludedLightLength) continue;

								light.lightToObjectTransform.combine(root.cameraToLocalTransform, light.localToCameraTransform);

								childLights[childLightsLength] = light;
								childLightsLength++;
							}
						}
						root.collectDraws(this, childLights, childLightsLength, root.useShadow);
					} else {
						root.collectDraws(this, null, 0, root.useShadow);
					}
					if (effectMode > 0) {
						root.collectDepthDraws(this, depthRenderer, encDepthMaterial);
					}
					// Debug the boundbox
					if (debug && root.boundBox != null && (checkInDebug(root) & Debug.BOUNDS)) Debug.drawBoundBox(this, root.boundBox, root.localToCameraTransform);
				}
				// Gather the draws for children
				root.collectChildrenDraws(this, lights, lightsLength, root.useShadow);
				if (effectMode > 0) {
					root.collectChildrenDepthDraws(this, depthRenderer, encDepthMaterial);
				}

				// Mouse events processing
				view.processMouseEvents(context3D, this);
				// Render
				renderer.render(context3D);

				// TODO: separate render to texture and in backbuffer in two stages
				if (effectMode > 0) {
					encDepthMaterial.useNormals = effectMode == 3 || effectMode == 8 || effectMode == 9;

					// TODO: subpixel accuracy check
					rect.width = Math.ceil(view._width >> (_depthScale + ssaoScale));
					rect.height = Math.ceil(view._height >> (_depthScale + ssaoScale));
					context3D.setScissorRectangle(rect);
					context3D.setRenderToTexture(depthTexture, true, 0, 0);
					if (encDepthMaterial.useNormals) {
//						context3D.clear(1, 0, 0.5, 0.5);
						context3D.clear(1, 0, -1, 0.5);
					} else {
						context3D.clear(1, 0);
					}
					depthRenderer.render(context3D);

					context3D.setScissorRectangle(null);

					var visibleTexture:Texture = depthTexture;
					var multiplyEnabled:Boolean = false;

					if (effectMode == MODE_SSAO_COLOR || effectMode == MODE_SSAO_ONLY) {
						// Draw ssao
						context3D.setRenderToTexture(ssaoTexture, true, 0, 0);
						context3D.clear(0, 0);
						ssaoAngular.depthScaleX = 1;
						ssaoAngular.depthScaleY = 1;
						ssaoAngular.width = 1 << effectTextureLog2Width;
						ssaoAngular.height = 1 << effectTextureLog2Height;
						ssaoAngular.uToViewX = (1 << (effectTextureLog2Width + ssaoScale));
						ssaoAngular.vToViewY = (1 << (effectTextureLog2Height + ssaoScale));
						ssaoAngular.clipSizeX = view._width/ssaoAngular.uToViewX;
						ssaoAngular.clipSizeY = view._height/ssaoAngular.vToViewY;
						ssaoAngular.depthNormalsTexture = depthTexture;
						ssaoAngular.collectQuadDraw(this);
						renderer.render(context3D);

						if (blurEnabled) {
							// Apply blur
							// TODO: draw blur directly to Context3D
							context3D.setRenderToTexture(bluredSSAOTexture, true, 0, 0);
							context3D.clear(0, 0);
							ssaoBlur.width = 1 << effectTextureLog2Width;
							ssaoBlur.height = 1 << effectTextureLog2Height;
							ssaoBlur.clipSizeX = ssaoAngular.clipSizeX;
							ssaoBlur.clipSizeY = ssaoAngular.clipSizeY;
							ssaoBlur.ssaoTexture = ssaoTexture;
							ssaoBlur.collectQuadDraw(this);
							renderer.render(context3D);
						}
						visibleTexture = blurEnabled ? bluredSSAOTexture : ssaoTexture;
						multiplyEnabled = effectMode == 9;
					}
					// render quad to screen
					context3D.setRenderToBackBuffer();
					decDepthEffect.multiplyBlend = multiplyEnabled;
					decDepthEffect.scaleX = encDepthMaterial.outputScaleX;
					decDepthEffect.scaleY = encDepthMaterial.outputScaleY;
					decDepthEffect.depthTexture = visibleTexture;
					if (ssaoScale != 0) {
						decDepthEffect.mode = effectMode > 3 ? 4 : effectMode;
					} else {
						decDepthEffect.mode = effectMode > 3 ? 0 : effectMode;
					}
					decDepthEffect.collectQuadDraw(this);
					renderer.render(context3D);
				}
			}
			// Output
			if (view._canvas == null) {
				context3D.present();
			} else {
				context3D.drawToBitmapData(view._canvas);
				context3D.present();
			}
		}
		// Clearing
		lights.length = 0;
		childLights.length = 0;
		occluders.length = 0;
	}
	
	/**
	 * Setup Camera3D position using x, y, z coordinates
	 */	
	public function setPosition(x:Number, y:Number, z:Number):void{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/**
	 *  Camera3D lookAt method
	 */
	public function lookAt(x:Number, y:Number, z:Number):void{
		var deltaX:Number = x - this.x;
		var deltaY:Number = y - this.y;
		var deltaZ:Number = z - this.z;
		var rotX:Number = Math.atan2(deltaZ, Math.sqrt(deltaX * deltaX + deltaY * deltaY));
		rotationX = rotX - 0.5 * Math.PI;
		rotationY = 0;
		rotationZ =  -  Math.atan2(deltaX,deltaY);
	}

	/**
	 * @private
	 */
	private function sortLights(l:int, r:int):void {
		var i:int = l;
		var j:int = r;
		var left:Light3D;
		var index:int = (r + l) >> 1;
		var m:Light3D = lights[index];
		var mid:int = m.type;
		var right:Light3D;
		do {
			while ((left = lights[i]).type < mid) {
				i++;
			}
			while (mid < (right = lights[j]).type) {
				j--;
			}
			if (i <= j) {
				lights[i++] = right;
				lights[j--] = left;
			}
		} while (i <= j);
		if (l < j) {
			sortLights(l, j);
		}
		if (i < r) {
			sortLights(i, r);
		}
	}

	/**
	 * Transforms point from global space to screen space. The <code>view</code> property should be defined.
	 * @param point Point in global space.
	 * @return A Vector3D object containing screen coordinates.
	 */
	public function projectGlobal(point:Vector3D):Vector3D {
		if (view == null) throw new Error("It is necessary to have view set.");
		var viewSizeX:Number = view._width * 0.5;
		var viewSizeY:Number = view._height * 0.5;
		var focalLength:Number = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		var res:Vector3D = globalToLocal(point);
		res.x = res.x * focalLength / res.z + viewSizeX;
		res.y = res.y * focalLength / res.z + viewSizeY;
		return res;
	}

	/**
	 * Calculates a ray in global space. The ray defines by its <code>origin</code> and <code>direction</code>.
	 * The ray goes like from the global camera position
	 * trough the point corresponding to the viewport point with coordinates <code>viewX</code> и <code>viewY</code>.
	 * The ray origin placed within <code>nearClipping</code> plane.
	 * This ray can be used in the <code>Object3D.intersectRay()</code> method.  The result writes to passed arguments.
	 *
	 * @param origin Ray origin will wrote here.
	 * @param direction Ray direction will wrote here.
	 * @param viewX Horizontal coordinate in view plane, through which the ray should go.
	 * @param viewY Vertical coordinate in view plane, through which the ray should go.
	 */
	public function calculateRay(origin:Vector3D, direction:Vector3D, viewX:Number, viewY:Number):void {
		if (view == null) throw new Error("It is necessary to have view set.");
		var viewSizeX:Number = view._width * 0.5;
		var viewSizeY:Number = view._height * 0.5;
		var focalLength:Number = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		var dx:Number = viewX - viewSizeX;
		var dy:Number = viewY - viewSizeY;
		var ox:Number = dx * nearClipping / focalLength;
		var oy:Number = dy * nearClipping / focalLength;
		var oz:Number = nearClipping;
		if (transformChanged) composeTransforms();
		trm.copy(transform);
		var root:Object3D = this;
		while (root.parent != null) {
			root = root.parent;
			if (root.transformChanged) root.composeTransforms();
			trm.append(root.transform);
		}
		origin.x = trm.a * ox + trm.b * oy + trm.c * oz + trm.d;
		origin.y = trm.e * ox + trm.f * oy + trm.g * oz + trm.h;
		origin.z = trm.i * ox + trm.j * oy + trm.k * oz + trm.l;
		direction.x = trm.a * dx + trm.b * dy + trm.c * focalLength;
		direction.y = trm.e * dx + trm.f * dy + trm.g * focalLength;
		direction.z = trm.i * dx + trm.j * dy + trm.k * focalLength;
		var directionL:Number = 1 / Math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
		direction.x *= directionL;
		direction.y *= directionL;
		direction.z *= directionL;
	}

	/**
	 * @inheritDoc
	 */
	override public function clone():Object3D {
		var res:Camera3D = new Camera3D(nearClipping, farClipping);
		res.clonePropertiesFrom(this);
		return res;
	}

	/**
	 * @inheritDoc
	 */
	override protected function clonePropertiesFrom(source:Object3D):void {
		super.clonePropertiesFrom(source);
		var src:Camera3D = source as Camera3D;
		fov = src.fov;
		view = src.view;
		nearClipping = src.nearClipping;
		farClipping = src.farClipping;
		orthographic = src.orthographic;
	}

	/**
	 * @private
	 */
	alternativa3d function calculateProjection(width:Number, height:Number):void {
		var viewSizeX:Number = width * 0.5;
		var viewSizeY:Number = height * 0.5;
		focalLength = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		if (!orthographic) {
			m0 = focalLength / viewSizeX;
			m5 = -focalLength / viewSizeY;
			m10 = farClipping / (farClipping - nearClipping);
			m14 = -nearClipping * m10;
		} else {
			m0 = 1 / viewSizeX;
			m5 = -1 / viewSizeY;
			m10 = 1 / (farClipping - nearClipping);
			m14 = -nearClipping * m10;
		}
		correctionX = viewSizeX / focalLength;
		correctionY = viewSizeY / focalLength;
	}

	/**
	 * @private
	 */
	alternativa3d function calculateFrustum(transform:Transform3D):void {
		var nearPlane:CullingPlane = frustum;
		var farPlane:CullingPlane = nearPlane.next;
		var leftPlane:CullingPlane = farPlane.next;
		var rightPlane:CullingPlane = leftPlane.next;
		var topPlane:CullingPlane = rightPlane.next;
		var bottomPlane:CullingPlane = topPlane.next;
		if (!orthographic) {
			var fa:Number = transform.a * correctionX;
			var fe:Number = transform.e * correctionX;
			var fi:Number = transform.i * correctionX;
			var fb:Number = transform.b * correctionY;
			var ff:Number = transform.f * correctionY;
			var fj:Number = transform.j * correctionY;
			nearPlane.x = fj * fe - ff * fi;
			nearPlane.y = fb * fi - fj * fa;
			nearPlane.z = ff * fa - fb * fe;
			nearPlane.offset = (transform.d + transform.c * nearClipping) * nearPlane.x + (transform.h + transform.g * nearClipping) * nearPlane.y + (transform.l + transform.k * nearClipping) * nearPlane.z;

			farPlane.x = -nearPlane.x;
			farPlane.y = -nearPlane.y;
			farPlane.z = -nearPlane.z;
			farPlane.offset = (transform.d + transform.c * farClipping) * farPlane.x + (transform.h + transform.g * farClipping) * farPlane.y + (transform.l + transform.k * farClipping) * farPlane.z;

			var ax:Number = -fa - fb + transform.c;
			var ay:Number = -fe - ff + transform.g;
			var az:Number = -fi - fj + transform.k;
			var bx:Number = fa - fb + transform.c;
			var by:Number = fe - ff + transform.g;
			var bz:Number = fi - fj + transform.k;
			topPlane.x = bz * ay - by * az;
			topPlane.y = bx * az - bz * ax;
			topPlane.z = by * ax - bx * ay;
			topPlane.offset = transform.d * topPlane.x + transform.h * topPlane.y + transform.l * topPlane.z;
				// Right plane.
			ax = bx;
			ay = by;
			az = bz;
			bx = fa + fb + transform.c;
			by = fe + ff + transform.g;
			bz = fi + fj + transform.k;
			rightPlane.x = bz * ay - by * az;
			rightPlane.y = bx * az - bz * ax;
			rightPlane.z = by * ax - bx * ay;
			rightPlane.offset = transform.d * rightPlane.x + transform.h * rightPlane.y + transform.l * rightPlane.z;
				// Bottom plane.
				ax = bx;
				ay = by;
				az = bz;
				bx = -fa + fb + transform.c;
				by = -fe + ff + transform.g;
				bz = -fi + fj + transform.k;
				bottomPlane.x = bz*ay - by*az;
				bottomPlane.y = bx*az - bz*ax;
				bottomPlane.z = by*ax - bx*ay;
				bottomPlane.offset = transform.d*bottomPlane.x + transform.h*bottomPlane.y + transform.l*bottomPlane.z;
				// Left plane.
				ax = bx;
				ay = by;
				az = bz;
				bx = -fa - fb + transform.c;
				by = -fe - ff + transform.g;
				bz = -fi - fj + transform.k;
				leftPlane.x = bz*ay - by*az;
				leftPlane.y = bx*az - bz*ax;
				leftPlane.z = by*ax - bx*ay;
				leftPlane.offset = transform.d*leftPlane.x + transform.h*leftPlane.y + transform.l*leftPlane.z;
			} else {
				var viewSizeX:Number = view._width*0.5;
				var viewSizeY:Number = view._height*0.5;
				// Near plane.
				nearPlane.x = transform.j*transform.e - transform.f*transform.i;
				nearPlane.y = transform.b*transform.i - transform.j*transform.a;
				nearPlane.z = transform.f*transform.a - transform.b*transform.e;
				nearPlane.offset = (transform.d + transform.c*nearClipping)*nearPlane.x + (transform.h + transform.g*nearClipping)*nearPlane.y + (transform.l + transform.k*nearClipping)*nearPlane.z;
				// Far plane.
				farPlane.x = -nearPlane.x;
				farPlane.y = -nearPlane.y;
				farPlane.z = -nearPlane.z;
				farPlane.offset = (transform.d + transform.c*farClipping)*farPlane.x + (transform.h + transform.g*farClipping)*farPlane.y + (transform.l + transform.k*farClipping)*farPlane.z;
				// Top plane.
				topPlane.x = transform.i*transform.g - transform.e*transform.k;
				topPlane.y = transform.a*transform.k - transform.i*transform.c;
				topPlane.z = transform.e*transform.c - transform.a*transform.g;
				topPlane.offset = (transform.d - transform.b*viewSizeY)*topPlane.x + (transform.h - transform.f*viewSizeY)*topPlane.y + (transform.l - transform.j*viewSizeY)*topPlane.z;
				// Bottom plane.
				bottomPlane.x = -topPlane.x;
				bottomPlane.y = -topPlane.y;
				bottomPlane.z = -topPlane.z;
				bottomPlane.offset = (transform.d + transform.b*viewSizeY)*bottomPlane.x + (transform.h + transform.f*viewSizeY)*bottomPlane.y + (transform.l + transform.j*viewSizeY)*bottomPlane.z;
				// Left plane.
				leftPlane.x = transform.k*transform.f - transform.g*transform.j;
				leftPlane.y = transform.c*transform.j - transform.k*transform.b;
				leftPlane.z = transform.g*transform.b - transform.c*transform.f;
				leftPlane.offset = (transform.d - transform.a*viewSizeX)*leftPlane.x + (transform.h - transform.e*viewSizeX)*leftPlane.y + (transform.l - transform.i*viewSizeX)*leftPlane.z;
				// Right plane.
				rightPlane.x = -leftPlane.x;
				rightPlane.y = -leftPlane.y;
				rightPlane.z = -leftPlane.z;
				rightPlane.offset = (transform.d + transform.a*viewSizeX)*rightPlane.x + (transform.h + transform.e*viewSizeX)*rightPlane.y + (transform.l + transform.i*viewSizeX)*rightPlane.z;
		}
	}

	/**
	 * @private
	 * Transform rays in object space.
	 */
	alternativa3d function calculateRays(transform:Transform3D):void {
		for (var i:int = 0; i < raysLength; i++) {
			var o:Vector3D = view.raysOrigins[i];
			var d:Vector3D = view.raysDirections[i];
			var origin:Vector3D = origins[i];
			var direction:Vector3D = directions[i];
			origin.x = transform.a * o.x + transform.b * o.y + transform.c * o.z + transform.d;
			origin.y = transform.e * o.x + transform.f * o.y + transform.g * o.z + transform.h;
			origin.z = transform.i * o.x + transform.j * o.y + transform.k * o.z + transform.l;
			direction.x = transform.a * d.x + transform.b * d.y + transform.c * d.z;
			direction.y = transform.e * d.x + transform.f * d.y + transform.g * d.z;
			direction.z = transform.i * d.x + transform.j * d.y + transform.k * d.z;
		}
	}

	static private const stack:Vector.<int> = new Vector.<int>();

	private function sortOccluders():void {
		stack[0] = 0;
		stack[1] = occludersLength - 1;
		var index:int = 2;
		while (index > 0) {
			index--;
			var r:int = stack[index];
			var j:int = r;
			index--;
			var l:int = stack[index];
			var i:int = l;
			var occluder:Occluder = occluders[(r + l) >> 1];
			var median:Number = occluder.distance;
			while (i <= j) {
				var left:Occluder = occluders[i];
				while (left.distance < median) {
					i++;
					left = occluders[i];
				}
				var right:Occluder = occluders[j];
				while (right.distance > median) {
					j--;
					right = occluders[j];
				}
				if (i <= j) {
					occluders[i] = right;
					occluders[j] = left;
					i++;
					j--;
				}
			}
			if (l < j) {
				stack[index] = l;
				index++;
				stack[index] = j;
				index++;
			}
			if (i < r) {
				stack[index] = i;
				index++;
				stack[index] = r;
				index++;
			}
		}
	}

	// DEBUG

	/**
	 * Turns debug mode on if <code>true</code> and off otherwise.
	 * The default value is <code>false</code>.
	 *
	 * @see #addToDebug()
	 * @see #removeFromDebug()
	 */
	public var debug:Boolean = false;

	private var debugSet:Object = new Object();

	/**
	 * Adds an object or a class to list of debug drawing.
	 * In case of class, all object of this type will drawn in debug mode.
	 *
	 * @param debug The component of object which will draws in debug mode. Should be <code>Debug.BOUND</code> for now. Check <code>Debug</code> for updates.
	 * @param objectOrClass  <code>Object3D</code> or class extended <code>Object3D</code>.
	 * @see alternativa.engine3d.core.Debug
	 * @see #debug
	 * @see #removeFromDebug()
	 */
	public function addToDebug(debug:int, objectOrClass:*):void {
		if (!debugSet[debug]) debugSet[debug] = new Dictionary();
		debugSet[debug][objectOrClass] = true;
	}

	/**
	 * Removed an object or a class from list of debug drawing.
	 *
	 * @param debug The component of object which will draws in debug mode. Should be <code>Debug.BOUND</code> for now. Check <code>Debug</code> for updates.
	 * @param objectOrClass  <code>Object3D</code> or class extended <code>Object3D</code>.
	 *
	 * @see alternativa.engine3d.core.Debug
	 * @see #debug
	 * @see #addToDebug()
	 */
	public function removeFromDebug(debug:int, objectOrClass:*):void {
		if (debugSet[debug]) {
			delete debugSet[debug][objectOrClass];
			var key:*;
			for (key in debugSet[debug]) break;
			if (!key) delete debugSet[debug];
		}
	}

	/**
	 * @private
	 *
	 * Check if the object or its class is in list of debug drawing.
	 */
	alternativa3d function checkInDebug(object:Object3D):int {
		var res:int = 0;
		for (var debug:int = 1; debug <= 512; debug <<= 1) {
			if (debugSet[debug]) {
				if (debugSet[debug][Object3D] || debugSet[debug][object]) {
					res |= debug;
				} else {
					var objectClass:Class = getDefinitionByName(getQualifiedClassName(object)) as Class;
					while (objectClass != Object3D) {
						if (debugSet[debug][objectClass]) {
							res |= debug;
							break;
						}
						objectClass = Class(getDefinitionByName(getQualifiedSuperclassName(objectClass)));
					}
				}
			}
		}
		return res;
	}


	private var _diagram:Sprite = createDiagram();

	/**
	 * The amount of frames which determines the period of FPS value update in <code>diagram</code>.
	 * @see #diagram
	 */
	public var fpsUpdatePeriod:int = 10;

	/**
	 * The amount of frames which determines the period of MS value update in <code>diagram</code>.
	 * @see #diagram
	 */
	public var timerUpdatePeriod:int = 10;

	private var fpsTextField:TextField;
	private var frameTextField:TextField;
	private var memoryTextField:TextField;
	private var drawsTextField:TextField;
	private var trianglesTextField:TextField;
	private var timerTextField:TextField;
	private var graph:Bitmap;
	private var rect:Rectangle = new Rectangle();

	private var _diagramAlign:String = "TR";
	private var _diagramHorizontalMargin:Number = 2;
	private var _diagramVerticalMargin:Number = 2;

	private var fpsUpdateCounter:int;
	private var previousFrameTime:int;
	private var previousPeriodTime:int;

	private var maxMemory:int;

	private var timerUpdateCounter:int;
	private var methodTimeSum:int;
	private var methodTimeCount:int;
	private var methodTimer:int;

	/**
	 * Starts time count. <code>startTimer()</code>and <code>stopTimer()</code> are necessary to measure time for code part executing.
	 * The result is displayed in the field MS of the diagram.
	 *
	 * @see #diagram
	 * @see #stopTimer()
	 */
	public function startTimer():void {
		methodTimer = getTimer();
	}

	/**
	 * Stops time count. <code>startTimer()</code> and <code>stopTimer()</code> are necessary to measure time for code part executing.
	 * The result is displayed in the field MS of the diagram.
	 * @see #diagram
	 * @see #startTimer()
	 */
	public function stopTimer():void {
		methodTimeSum += getTimer() - methodTimer;
		methodTimeCount++;
	}

	/**
	 * Diagram where debug information is displayed. To display <code>diagram</code>, you need to add it on the screen.
	 * FPS is an average amount of frames per second.
	 * MS is an average time of executing the code part in milliseconds. This code part is measured with <code>startTimer</code> - <code>stopTimer</code>.
	 * MEM is an amount of memory reserved by player (in megabytes).
	 * DRW is an amount of draw calls in the current frame.
	 * PLG is an amount of visible polygons in the current frame.
	 * TRI is an amount of drawn triangles in the current frame.
	 *
	 * @see #fpsUpdatePeriod
	 * @see #timerUpdatePeriod
	 * @see #startTimer()
	 * @see #stopTimer()
	 */
	public function get diagram():DisplayObject {
		return _diagram;
	}

	/**
	 * Diagram alignment relatively to working space. You can use constants of <code>StageAlign</code> class.
	 *
	 */
	public function get diagramAlign():String {
		return _diagramAlign;
	}

	/**
	 * @private
	 */
	public function set diagramAlign(value:String):void {
		_diagramAlign = value;
		resizeDiagram();
	}

	/**
	 * Diagram margin from the edge of working space in horizontal axis.
	 */
	public function get diagramHorizontalMargin():Number {
		return _diagramHorizontalMargin;
	}

	/**
	 * @private
	 */
	public function set diagramHorizontalMargin(value:Number):void {
		_diagramHorizontalMargin = value;
		resizeDiagram();
	}

	/**
	 * Diagram margin from the edge of working space in vertical axis.
	 */
	public function get diagramVerticalMargin():Number {
		return _diagramVerticalMargin;
	}

	/**
	 * @private
	 */
	public function set diagramVerticalMargin(value:Number):void {
		_diagramVerticalMargin = value;
		resizeDiagram();
	}

	private function createDiagram():Sprite {
		var diagram:Sprite = new Sprite();
		diagram.mouseEnabled = false;
		diagram.mouseChildren = false;
		// FPS
		fpsTextField = new TextField();
		fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
		fpsTextField.autoSize = TextFieldAutoSize.LEFT;
		fpsTextField.text = "FPS:";
		fpsTextField.selectable = false;
		fpsTextField.x = -3;
		fpsTextField.y = -5;
		diagram.addChild(fpsTextField);
		// time of frame
		frameTextField = new TextField();
		frameTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
		frameTextField.autoSize = TextFieldAutoSize.LEFT;
		frameTextField.text = "TME:";
		frameTextField.selectable = false;
		frameTextField.x = -3;
		frameTextField.y = 4;
		diagram.addChild(frameTextField);
		// time of method execution
		timerTextField = new TextField();
		timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
		timerTextField.autoSize = TextFieldAutoSize.LEFT;
		timerTextField.text = "MS:";
		timerTextField.selectable = false;
		timerTextField.x = -3;
		timerTextField.y = 13;
		diagram.addChild(timerTextField);
		// memory
		memoryTextField = new TextField();
		memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
		memoryTextField.autoSize = TextFieldAutoSize.LEFT;
		memoryTextField.text = "MEM:";
		memoryTextField.selectable = false;
		memoryTextField.x = -3;
		memoryTextField.y = 22;
		diagram.addChild(memoryTextField);
		// debug draws
		drawsTextField = new TextField();
		drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
		drawsTextField.autoSize = TextFieldAutoSize.LEFT;
		drawsTextField.text = "DRW:";
		drawsTextField.selectable = false;
		drawsTextField.x = -3;
		drawsTextField.y = 31;
		diagram.addChild(drawsTextField);
		// triangles
		trianglesTextField = new TextField();
		trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300); // 0xFF6600, 0xFF0033
		trianglesTextField.autoSize = TextFieldAutoSize.LEFT;
		trianglesTextField.text = "TRI:";
		trianglesTextField.selectable = false;
		trianglesTextField.x = -3;
		trianglesTextField.y = 40;
		diagram.addChild(trianglesTextField);
		// diagram initialization
		diagram.addEventListener(Event.ADDED_TO_STAGE, function ():void {
			diagram.removeEventListener(Event.ADDED_TO_STAGE, arguments.callee);
			// FPS
			fpsTextField = new TextField();
			fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
			fpsTextField.autoSize = TextFieldAutoSize.RIGHT;
			fpsTextField.text = Number(diagram.stage.frameRate).toFixed(2);
			fpsTextField.selectable = false;
			fpsTextField.x = -3;
			fpsTextField.y = -5;
			fpsTextField.width = 85;
			diagram.addChild(fpsTextField);
			// Frame time
			frameTextField = new TextField();
			frameTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
			frameTextField.autoSize = TextFieldAutoSize.RIGHT;
			frameTextField.text = Number(1000 / diagram.stage.frameRate).toFixed(2);
			frameTextField.selectable = false;
			frameTextField.x = -3;
			frameTextField.y = 4;
			frameTextField.width = 85;
			diagram.addChild(frameTextField);
			// Time of method performing
			timerTextField = new TextField();
			timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
			timerTextField.autoSize = TextFieldAutoSize.RIGHT;
			timerTextField.text = "";
			timerTextField.selectable = false;
			timerTextField.x = -3;
			timerTextField.y = 13;
			timerTextField.width = 85;
			diagram.addChild(timerTextField);
			// Memory
			memoryTextField = new TextField();
			memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
			memoryTextField.autoSize = TextFieldAutoSize.RIGHT;
			memoryTextField.text = bytesToString(System.totalMemory);
			memoryTextField.selectable = false;
			memoryTextField.x = -3;
			memoryTextField.y = 22;
			memoryTextField.width = 85;
			diagram.addChild(memoryTextField);
			// Draw calls
			drawsTextField = new TextField();
			drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
			drawsTextField.autoSize = TextFieldAutoSize.RIGHT;
			drawsTextField.text = "0";
			drawsTextField.selectable = false;
			drawsTextField.x = -3;
			drawsTextField.y = 31;
			drawsTextField.width = 72;
			diagram.addChild(drawsTextField);
			// Number of triangles
			trianglesTextField = new TextField();
			trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300);
			trianglesTextField.autoSize = TextFieldAutoSize.RIGHT;
			trianglesTextField.text = "0";
			trianglesTextField.selectable = false;
			trianglesTextField.x = -3;
			trianglesTextField.y = 40;
			trianglesTextField.width = 72;
			diagram.addChild(trianglesTextField);
			// Graph
			graph = new Bitmap(new BitmapData(80, 40, true, 0x20FFFFFF));
			rect = new Rectangle(0, 0, 1, 40);
			graph.x = 0;
			graph.y = 54;
			diagram.addChild(graph);
			// Reset of parameters
			previousPeriodTime = getTimer();
			previousFrameTime = previousPeriodTime;
			fpsUpdateCounter = 0;
			maxMemory = 0;
			timerUpdateCounter = 0;
			methodTimeSum = 0;
			methodTimeCount = 0;
			// Subscription
			diagram.stage.addEventListener(Event.ENTER_FRAME, updateDiagram, false, -1000);
			diagram.stage.addEventListener(Event.RESIZE, resizeDiagram, false, -1000);
			resizeDiagram();
		});
		// Deinitialization of diagram
		diagram.addEventListener(Event.REMOVED_FROM_STAGE, function ():void {
			diagram.removeEventListener(Event.REMOVED_FROM_STAGE, arguments.callee);
			// Reset
			diagram.removeChild(fpsTextField);
			diagram.removeChild(frameTextField);
			diagram.removeChild(memoryTextField);
			diagram.removeChild(drawsTextField);
			diagram.removeChild(trianglesTextField);
			diagram.removeChild(timerTextField);
			diagram.removeChild(graph);
			fpsTextField = null;
			frameTextField = null;
			memoryTextField = null;
			drawsTextField = null;
			trianglesTextField = null;
			timerTextField = null;
			graph.bitmapData.dispose();
			graph = null;
			// Unsubscribe
			diagram.stage.removeEventListener(Event.ENTER_FRAME, updateDiagram);
			diagram.stage.removeEventListener(Event.RESIZE, resizeDiagram);
		});
		return diagram;
	}

	private function resizeDiagram(e:Event = null):void {
		if (_diagram.stage != null) {
			var coord:Point = _diagram.parent.globalToLocal(new Point());
			if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.BOTTOM_LEFT) {
				_diagram.x = Math.round(coord.x + _diagramHorizontalMargin);
			}
			if (_diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.BOTTOM) {
				_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth / 2 - graph.width / 2);
			}
			if (_diagramAlign == StageAlign.TOP_RIGHT || _diagramAlign == StageAlign.RIGHT || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
				_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth - _diagramHorizontalMargin - graph.width);
			}
			if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.TOP_RIGHT) {
				_diagram.y = Math.round(coord.y + _diagramVerticalMargin);
			}
			if (_diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.RIGHT) {
				_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight / 2 - (graph.y + graph.height) / 2);
			}
			if (_diagramAlign == StageAlign.BOTTOM_LEFT || _diagramAlign == StageAlign.BOTTOM || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
				_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight - _diagramVerticalMargin - graph.y - graph.height);
			}
		}
	}

	private function updateDiagram(e:Event):void {
		var value:Number;
		var mod:int;
		var time:int = getTimer();
		var stageFrameRate:int = _diagram.stage.frameRate;

		// FPS text
		if (++fpsUpdateCounter == fpsUpdatePeriod) {
			value = 1000 * fpsUpdatePeriod / (time - previousPeriodTime);
			if (value > stageFrameRate) value = stageFrameRate;
			mod = value * 100 % 100;
			fpsTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			value = 1000 / value;
			mod = value * 100 % 100;
			frameTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			previousPeriodTime = time;
			fpsUpdateCounter = 0;
		}
		// FPS plot
		value = 1000 / (time - previousFrameTime);
		if (value > stageFrameRate) value = stageFrameRate;
		graph.bitmapData.scroll(1, 0);
		// TODO: rollback this
		rect.width = 1;
		rect.height = 40;
		graph.bitmapData.fillRect(rect, 0x20FFFFFF);
		graph.bitmapData.setPixel32(0, 40 * (1 - value / stageFrameRate), 0xFFCCCCCC);
		previousFrameTime = time;

		// time text
		if (++timerUpdateCounter == timerUpdatePeriod) {
			if (methodTimeCount > 0) {
				value = methodTimeSum / methodTimeCount;
				mod = value * 100 % 100;
				timerTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			} else {
				timerTextField.text = "";
			}
			timerUpdateCounter = 0;
			methodTimeSum = 0;
			methodTimeCount = 0;
		}

		// memory text
		var memory:int = System.totalMemory;
		value = memory / 1048576;
		mod = value * 100 % 100;
		memoryTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));

		// memory plot
		if (memory > maxMemory) maxMemory = memory;
		graph.bitmapData.setPixel32(0, 40 * (1 - memory / maxMemory), 0xFFCCCC00);

		// debug text
		drawsTextField.text = formatInt(numDraws);

			// Triangles (text)
		trianglesTextField.text = formatInt(numTriangles);
	}

	private function formatInt(num:int):String {
		var n:int;
		var s:String;
		if (num < 1000) {
			return "" + num;
		} else if (num < 1000000) {
			n = num % 1000;
			if (n < 10) {
				s = "00" + n;
			} else if (n < 100) {
				s = "0" + n;
			} else {
				s = "" + n;
			}
			return int(num / 1000) + " " + s;
		} else {
			n = (num % 1000000) / 1000;
			if (n < 10) {
				s = "00" + n;
			} else if (n < 100) {
				s = "0" + n;
			} else {
				s = "" + n;
			}
			n = num % 1000;
			if (n < 10) {
				s += " 00" + n;
			} else if (n < 100) {
				s += " 0" + n;
			} else {
				s += " " + n;
			}
			return int(num / 1000000) + " " + s;
		}
	}

	private function bytesToString(bytes:int):String {
		if (bytes < 1024) return bytes + "b";
		else if (bytes < 10240) return (bytes / 1024).toFixed(2) + "kb";
		else if (bytes < 102400) return (bytes / 1024).toFixed(1) + "kb";
		else if (bytes < 1048576) return (bytes >> 10) + "kb";
		else if (bytes < 10485760) return (bytes / 1048576).toFixed(2);// + "mb";
		else if (bytes < 104857600) return (bytes / 1048576).toFixed(1);// + "mb";
		else return String(bytes >> 20);// + "mb";
	}
}
}
