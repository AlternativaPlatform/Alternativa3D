/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.Alternativa3D;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.ShaderProgram;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.materials.compiler.VariableType;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.resources.Geometry;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.VertexBuffer3D;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;

	use namespace alternativa3d;

	/**
	 * A viewport. Though GPU can render to one of <code>Stage3D</code> only,  View still extends <code>DisplayObject</code> and should be in <code>DisplayList</code>.
	 * Since 8 version of Alternativa3D view used as wrapper for configuring <code>Stage3D</code> properties for first. Main task of <code>view</code> is defining
	 * rectangular field of screen to which image will be rendered. Another opportunity is render image to <code>Bitmap</code>. In this case the <code>view</code>
	 * will have this <code>Bitmap</code> as a child. The size of <code>View</code> should be 50x50 at least.
	 * In case of size will be more than 2048 and anti-aliasing is turned on, usage of MouseEvents will cause of crash.
	 *
	 * @see alternativa.engine3d.core.Camera3D
	 */
	public class View extends Sprite {

		private static const renderEvent:MouseEvent = new MouseEvent("render");

		static private var drawDistanceFragment:Linker;
		static private var drawDistanceVertexProcedure:Procedure;

		static private const drawUnit:DrawUnit = new DrawUnit();
		static private const pixels:Dictionary = new Dictionary();
		static private const stack:Vector.<int> = new Vector.<int>();

		static private const point:Point = new Point();
		static private const scissor:Rectangle = new Rectangle(0, 0, 1, 1);
		static private const localCoords:Vector3D = new Vector3D();

		static private const branch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const overedBranch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const changedBranch:Vector.<Object3D> = new Vector.<Object3D>();
		static private const functions:Vector.<Function> = new Vector.<Function>();

		private static const drawColoredRectConst:Vector.<Number> = Vector.<Number>([0, 0, -1, 1]);
		private static const drawRectColor:Vector.<Number> = new Vector.<Number>(4);

		/**
		 * Background color.
		 */
		public var backgroundColor:uint;

		/**
		 * Background transparency.
		 */
		public var backgroundAlpha:Number;

		/**
		 * Level of anti-aliasing.
		 */
		public var antiAlias:int;

		/**
		 * @private
		 */
		alternativa3d var _width:int;

		/**
		 * @private
		 */
		alternativa3d var _height:int;

		/**
		 * @private
		 */
		alternativa3d var _canvas:BitmapData = null;

		/**
		 * Mouse events occurred over this <code>View</code> since last render.
		 */
		private var events:Vector.<MouseEvent> = new Vector.<MouseEvent>();
		/**
		 * Indices of rays in the <code>raysOrigins</code> array for each mouse event.
		 */
		private var indices:Vector.<int> = new Vector.<int>();
		private var eventsLength:int = 0;

		//	Surfaces of objects which can be crossed by mouse and procedures of transformation their coordinates

		private var surfaces:Vector.<Surface> = new Vector.<Surface>();
		private var geometries:Vector.<Geometry> = new Vector.<Geometry>();
		private var procedures:Vector.<Procedure> = new Vector.<Procedure>();
		private var surfacesLength:int = 0;

		/**
		 * @private
		 */
		alternativa3d var raysOrigins:Vector.<Vector3D> = new Vector.<Vector3D>();
		/**
		 * @private
		 */
		alternativa3d var raysDirections:Vector.<Vector3D> = new Vector.<Vector3D>();
		private var raysCoefficients:Vector.<Point> = new Vector.<Point>();
		private var raysSurfaces:Vector.<Vector.<Surface>> = new Vector.<Vector.<Surface>>();
		private var raysDepths:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
		private var raysIs:Vector.<int> = new Vector.<int>();
		private var raysJs:Vector.<int> = new Vector.<int>();

		/**
		 * @private
		 */
		alternativa3d var raysLength:int = 0;

		private var lastEvent:MouseEvent;

		private var target:Object3D;
		private var targetSurface:Surface;
		private var targetDepth:Number;
		private var pressedTarget:Object3D;
		private var pressedMiddleTarget:Object3D;
		private var pressedRightTarget:Object3D;
		private var clickedTarget:Object3D;
		private var overedTarget:Object3D;
		private var overedTargetSurface:Surface;

		private var altKey:Boolean;
		private var ctrlKey:Boolean;
		private var shiftKey:Boolean;

		private var container:Bitmap;
		private var area:Sprite;
		private var logo:Logo;
		private var bitmap:Bitmap;
		private var _logoAlign:String = "BR";
		private var _logoHorizontalMargin:Number = 0;
		private var _logoVerticalMargin:Number = 0;
		private var _renderToBitmap:Boolean;
		private var _rightClick3DEnabled:Boolean = false;
		
		/**
		 * Creates a <code>View</code> object.
		 * @param width Width of a view, should be 50 at least.
		 * @param height Height of a view, should be 50 at least.
		 * @param renderToBitmap If <code>true</code>, image will render to <code>Bitmap</code> object which will included into the <code>view</code> as a child. It also will available through <code>canvas</code> property.
		 * @param backgroundColor Background color.
		 * @param backgroundAlpha BAckground transparency.
		 * @param antiAlias Level of anti-aliasing.
		 *
		 * @see #canvas
		 */
		public function View(width:int, height:int, renderToBitmap:Boolean = false, backgroundColor:uint = 0, backgroundAlpha:Number = 1, antiAlias:int = 0) {
			if (width < 50) width = 50;
			if (height < 50) height = 50;
			_width = width;
			_height = height;
			_renderToBitmap = renderToBitmap;
			this.backgroundColor = backgroundColor;
			this.backgroundAlpha = backgroundAlpha;
			this.antiAlias = antiAlias;

			mouseEnabled = true;
			mouseChildren = true;
			doubleClickEnabled = true;

			buttonMode = true;
			useHandCursor = false;

			tabEnabled = false;
			tabChildren = false;

			// Context menu
			var item:ContextMenuItem = new ContextMenuItem("Powered by Alternativa3D " + Alternativa3D.version);
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent):void {
				try {
					navigateToURL(new URLRequest("http://alternativaplatform.com"), "_blank");
				} catch (e:Error) {
				}
			});
			var menu:ContextMenu = new ContextMenu();
			menu.customItems = [item];
			contextMenu = menu;

			// Canvas
			container = new Bitmap();
			if (renderToBitmap) {
				createRenderBitmap();
			}
			super.addChild(container);

			// Hit area
			area = new Sprite();
			area.graphics.beginFill(0xFF0000);
			area.graphics.drawRect(0, 0, 100, 100);
			area.mouseEnabled = false;
			area.visible = false;
			area.width = _width;
			area.height = _height;
			hitArea = area;
			super.addChild(hitArea);

			// Logo
			showLogo();

			if (drawDistanceFragment == null) {
				drawDistanceVertexProcedure = Procedure.compileFromArray([
					// Declaraion
					"#v0=distance",
					"#c0=transform0",
					"#c1=transform1",
					"#c2=transform2",
					"#c3=coefficient",
					"#c4=projection",
					// Convert to the camera coordinates
					"dp4 t0.x, i0, c0",
					"dp4 t0.y, i0, c1",
					"dp4 t0.z, i0, c2",
					// Passing the depth
					"mul v0.x, t0.z, c3.z",
					"mov v0.y, i0.x",
					"mov v0.z, i0.x",
					"mov v0.w, i0.x",
					// Projection
					"mul t1.x, t0.x, c4.x",
					"mul t1.y, t0.y, c4.y",
					"mul t0.w, t0.z, c4.z",
					"add t1.z, t0.w, c4.w",
					// Get last line
					"mov t3.z, c4.x",
					"div t3.z, t3.z, c4.x",
					"sub t3.z, t3.z, c3.w",
					// Finding W
					"mul t1.w, t0.z, t3.z",
					"add t1.w, t1.w, c3.w",
					// Offset
					"mul t0.x, c3.x, t1.w",
					"mul t0.y, c3.y, t1.w",
					"add t1.x, t1.x, t0.x",
					"add t1.y, t1.y, t0.y",
					"mov o0, t1",
				], "mouseEventsVertex");
				drawDistanceFragment = new Linker(Context3DProgramType.FRAGMENT);
				drawDistanceFragment.addProcedure(new Procedure([
					// Id
					"mov t0.z, c0.z",
					// An unit
					"mov t0.w, c0.w",
					// Remainder
					"frc t0.y, v0.x",
					// A whole part
					"sub t0.x, v0.x, t0.y",
					"mul t0.x, t0.x, c0.x",
					"mov o0, ft0",
					// Declaration
					"#v0=distance",
					"#c0=code",
				], "mouseEventsFragment"));
			}

			// Listeners
			addEventListener(MouseEvent.MOUSE_DOWN, onMouse);
			addEventListener(MouseEvent.CLICK, onMouse);
			addEventListener("middleMouseDown", onMouse);
			addEventListener("middleClick", onMouse);
			addEventListener(MouseEvent.DOUBLE_CLICK, onMouse);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouse);
			addEventListener(MouseEvent.MOUSE_OVER, onMouse);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouse);
			addEventListener(MouseEvent.MOUSE_OUT, onLeave);
			addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
		}

        /**
         * If <code>true</code>, you will able to handle following events <code>MouseEvent3D.RIGHT_CLICK</code>,
         * <code>MouseEvent3D.RIGHT_MOUSE_DOWN</code>, <code>MouseEvent3D.RIGHT_MOUSE_UP</code>.
         * The context menu will no longer open on clicking right mouse button.
         */
		public function get rightClick3DEnabled():Boolean {
			return _rightClick3DEnabled;
		}

		/**
		 * @private
		 */
		public function set rightClick3DEnabled(value:Boolean):void {
			if (value != _rightClick3DEnabled) {
				if (value) {
					addEventListener("rightMouseDown", onMouse);
					addEventListener("rightClick", onMouse);
				} else {
					removeEventListener("rightMouseDown", onMouse);
					removeEventListener("rightClick", onMouse);
				}
				_rightClick3DEnabled = value;
			}
		}

		private function onMouse(mouseEvent:MouseEvent):void {
			var prev:int = eventsLength - 1;
			// case of mouseMove repeats
			if (eventsLength > 0 && mouseEvent.type == "mouseMove" && (events[prev] as MouseEvent).type == "mouseMove") {
				events[prev] = mouseEvent;
			} else {
				events[eventsLength] = mouseEvent;
				eventsLength++;
			}
			lastEvent = mouseEvent;
		}

		private function onLeave(mouseEvent:MouseEvent):void {
			events[eventsLength] = mouseEvent;
			eventsLength++;
			lastEvent = null;
		}

		private function createRenderBitmap():void {
			_canvas = new BitmapData(_width, _height, backgroundAlpha < 1, backgroundColor);
			container.bitmapData = _canvas;
			container.smoothing = true;
		}

		private function onAddToStage(e:Event):void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}

		private function onRemoveFromStage(e:Event):void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			altKey = false;
			ctrlKey = false;
			shiftKey = false;
		}

		private function onKeyDown(keyboardEvent:KeyboardEvent):void {
			altKey = keyboardEvent.altKey;
			ctrlKey = keyboardEvent.ctrlKey;
			shiftKey = keyboardEvent.shiftKey;
			if (ctrlKey && shiftKey && keyboardEvent.keyCode == Keyboard.F1 && bitmap == null) {
				bitmap = new Bitmap(Logo.image);
				bitmap.x = Math.round((_width - bitmap.width)/2);
				bitmap.y = Math.round((_height - bitmap.height)/2);
				super.addChild(bitmap);
				setTimeout(removeBitmap, 2048);
			}
		}

		private function onKeyUp(keyboardEvent:KeyboardEvent):void {
			altKey = keyboardEvent.altKey;
			ctrlKey = keyboardEvent.ctrlKey;
			shiftKey = keyboardEvent.shiftKey;
		}

		private function removeBitmap():void {
			if (bitmap != null) {
				super.removeChild(bitmap);
				bitmap = null;
			}
		}

		/**
		 * @private
		 */
		alternativa3d function calculateRays(camera:Camera3D, processMoving:Boolean, processPressing:Boolean, processMouseWheel:Boolean, processMiddleButton:Boolean, processRightButton:Boolean):void {
			var i:int;
			var mouseEvent:MouseEvent;
			// Case of last coordinates fits in the view.
			if (processMoving && lastEvent != null) {
				// Detecting mouse movement within the frame
				var mouseMoved:Boolean = false;
				for (i = 0; i < eventsLength; i++) {
					mouseEvent = events[i];
					if (mouseEvent.type == "mouseMove" || mouseEvent.type == "mouseOut") {
						mouseMoved = true;
						break;
					}
				}
				// Add event of checking if content over mouse was changed
				if (!mouseMoved) {
					renderEvent.localX = lastEvent.localX;
					renderEvent.localY = lastEvent.localY;
					renderEvent.ctrlKey = ctrlKey;
					renderEvent.altKey = altKey;
					renderEvent.shiftKey = shiftKey;
					renderEvent.buttonDown = lastEvent.buttonDown;
					renderEvent.delta = 0;
					events[eventsLength] = renderEvent;
					eventsLength++;
				}
			}

			if (!processMoving) {
				overedTarget = null;
				overedTargetSurface = null;
			}
			if (!processPressing) {
				pressedTarget = null;
				clickedTarget = null;
			}
			if (!processMiddleButton) {
				pressedMiddleTarget = null;
			}
			// Mask with rightClick3DEnabled for case when in the list there are old events witch dispatched before rightClick3DEnabled was made false
			processRightButton &&= _rightClick3DEnabled;
			if (!processRightButton) {
				pressedRightTarget = null;
			}

			// Creation of exclusive rays
			var mouseX:Number = 1e+22;
			var mouseY:Number = 1e+22;
			var totalEvents:int = 0;
			for (i = 0; i < eventsLength; i++) {
				mouseEvent = events[i];
				// Filter events
				if (!processMoving && (mouseEvent.type == MouseEvent.MOUSE_MOVE || mouseEvent.type == MouseEvent.MOUSE_OVER || mouseEvent.type == MouseEvent.MOUSE_OUT)) {
					continue;
				}
				if (!processPressing && (mouseEvent.type == MouseEvent.MOUSE_DOWN || mouseEvent.type == MouseEvent.CLICK || mouseEvent.type == MouseEvent.DOUBLE_CLICK)) {
					continue;
				}
				if (!processMouseWheel && mouseEvent.type == MouseEvent.MOUSE_WHEEL) {
					continue;
				}
				if (!processMiddleButton && (mouseEvent.type == "middleMouseDown" || mouseEvent.type == "middleClick")) {
					continue;
				}
				if (!processRightButton && (mouseEvent.type == "rightMouseDown" || mouseEvent.type == "rightClick")) {
					continue;
				}

				if (mouseEvent.type != "mouseOut") {
					// Calculation of ray within the camera
					if (mouseEvent.localX != mouseX || mouseEvent.localY != mouseY) {
						mouseX = mouseEvent.localX;
						mouseY = mouseEvent.localY;
						// Creation
						var origin:Vector3D;
						var direction:Vector3D;
						var coefficient:Point;
						if (raysLength < raysOrigins.length) {
							origin = raysOrigins[raysLength];
							direction = raysDirections[raysLength];
							coefficient = raysCoefficients[raysLength];
						} else {
							origin = new Vector3D();
							direction = new Vector3D();
							coefficient = new Point();
							raysOrigins[raysLength] = origin;
							raysDirections[raysLength] = direction;
							raysCoefficients[raysLength] = coefficient;
							raysSurfaces[raysLength] = new Vector.<Surface>();
							raysDepths[raysLength] = new Vector.<Number>();
						}
						// Filling
						if (!camera.orthographic) {
							direction.x = mouseX - _width*0.5;
							direction.y = mouseY - _height*0.5;
							direction.z = camera.focalLength;
							origin.x = direction.x*camera.nearClipping/camera.focalLength;
							origin.y = direction.y*camera.nearClipping/camera.focalLength;
							origin.z = camera.nearClipping;
							direction.normalize();
							coefficient.x = mouseX*2/_width;
							coefficient.y = mouseY*2/_height;
						} else {
							direction.x = 0;
							direction.y = 0;
							direction.z = 1;
							origin.x = mouseX - _width*0.5;
							origin.y = mouseY - _height*0.5;
							origin.z = camera.nearClipping;
							coefficient.x = mouseX*2/_width;
							coefficient.y = mouseY*2/_height;
						}
						raysLength++;
					}
					// Considering event with the ray
					indices[totalEvents] = raysLength - 1;
				} else {
					indices[totalEvents] = -1;
				}
				events[totalEvents] = mouseEvent;
				totalEvents++;
			}
			eventsLength = totalEvents;
		}

		/**
		 * @private
		 */
		alternativa3d function addSurfaceToMouseEvents(surface:Surface, geometry:Geometry, procedure:Procedure):void {
			surfaces[surfacesLength] = surface;
			geometries[surfacesLength] = geometry;
			procedures[surfacesLength] = procedure;
			surfacesLength++;
		}

		/**
		 * @private
		 */
		alternativa3d function configureContext3D(stage3D:Stage3D, context3D:Context3D, camera:Camera3D):void {
			if (_canvas == null) {
				var vis:Boolean = this.visible;
				for (var parent:DisplayObject = this.parent; parent != null; parent = parent.parent) {
					vis &&= parent.visible;
				}
				var coords:Point;
				point.x = 0;
				point.y = 0;
				coords = localToGlobal(point);
				stage3D.x = coords.x;
				stage3D.y = coords.y;
				stage3D.visible = vis;
			} else {
				stage3D.visible = false;
				if (_width != _canvas.width || _height != _canvas.height || (backgroundAlpha < 1) != _canvas.transparent) {
					_canvas.dispose();
					createRenderBitmap();
				}
			}
			var context3DProperties:RendererContext3DProperties = camera.context3DProperties;
			if (context3DProperties.drawRectGeometry == null) {
				// Inititalize data for mouse events
				var rectGeometry:Geometry = new Geometry(4);
				rectGeometry.addVertexStream([VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0]]);
				rectGeometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1]));
				rectGeometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));
				rectGeometry.indices = Vector.<uint>([0, 1, 3, 2, 3, 1]);
				rectGeometry.upload(context3D);
				var vLinker:Linker = new Linker(Context3DProgramType.VERTEX);
				vLinker.addProcedure(Procedure.compileFromArray([
					"#a0=a0",
					"#c0=c0",
					"mul t0.x, a0.x, c0.x",
					"mul t0.y, a0.y, c0.y",
					"add o0.x, t0.x, c0.z",
					"add o0.y, t0.y, c0.w",
					"mov o0.z, a0.z",
					"mov o0.w, a0.z",
				]));
				var fLinker:Linker = new Linker(Context3DProgramType.FRAGMENT);
				fLinker.addProcedure(Procedure.compileFromArray([
					"#c0=c0",
					"mov o0, c0",
				]));
				var coloredRectProgram:ShaderProgram = new ShaderProgram(vLinker, fLinker);
				coloredRectProgram.upload(context3D);

				context3DProperties.drawRectGeometry = rectGeometry;
				context3DProperties.drawColoredRectProgram = coloredRectProgram;
			}
			if (_width != context3DProperties.backBufferWidth || _height != context3DProperties.backBufferHeight || antiAlias != context3DProperties.backBufferAntiAlias) {
				context3DProperties.backBufferWidth = _width;
				context3DProperties.backBufferHeight = _height;
				context3DProperties.backBufferAntiAlias = antiAlias;
				context3D.configureBackBuffer(_width, _height, antiAlias);
			}
		}

		/**
		 * @private
		 */
		alternativa3d function processMouseEvents(context3D:Context3D, camera:Camera3D):void {
			var i:int;
			// Mouse events
			if (eventsLength > 0) {
				if (surfacesLength > 0) {
					// Calculating the depth
					calculateSurfacesDepths(context3D, camera, _width, _height);
					// Sorting by decreasing the depth
					for (i = 0; i < raysLength; i++) {
						var raySurfaces:Vector.<Surface> = raysSurfaces[i];
						var rayDepths:Vector.<Number> = raysDepths[i];
						var raySurfacesLength:int = raySurfaces.length;
						if (raySurfacesLength > 1) {
							sort(raySurfaces, rayDepths, raySurfacesLength);
						}
					}
				}
				// Event handling
				targetDepth = camera.farClipping;
				for (i = 0; i < eventsLength; i++) {
					var mouseEvent:MouseEvent = events[i];
					var index:int = indices[i];
					// Check event type
					switch (mouseEvent.type) {
						case "mouseDown":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MOUSE_DOWN, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
							}
							pressedTarget = target;
							break;
						case "click":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MOUSE_UP, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								if (pressedTarget == target) {
									clickedTarget = target;
									propagateEvent(MouseEvent3D.CLICK, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								}
							}
							pressedTarget = null;
							break;
						case "doubleClick":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MOUSE_UP, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								if (pressedTarget == target) {
									propagateEvent(clickedTarget == target && target.doubleClickEnabled ? MouseEvent3D.DOUBLE_CLICK : MouseEvent3D.CLICK, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								}
							}
							clickedTarget = null;
							pressedTarget = null;
							break;
						case "middleMouseDown":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MIDDLE_MOUSE_DOWN, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
							}
							pressedMiddleTarget = target;
							break;
						case "middleClick":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MIDDLE_MOUSE_UP, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								if (pressedMiddleTarget == target) {
									propagateEvent(MouseEvent3D.MIDDLE_CLICK, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								}
							}
							pressedMiddleTarget = null;
							break;
						case "rightMouseDown":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.RIGHT_MOUSE_DOWN, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
							}
							pressedRightTarget = target;
							break;
						case "rightClick":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.RIGHT_MOUSE_UP, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								if (pressedRightTarget == target) {
									propagateEvent(MouseEvent3D.RIGHT_CLICK, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
								}
							}
							pressedRightTarget = null;
							break;
						case "mouseMove":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MOUSE_MOVE, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
							}
							if (overedTarget != target) {
								processOverOut(mouseEvent, camera);
							}
							break;
						case "mouseWheel":
							defineTarget(index);
							if (target != null) {
								propagateEvent(MouseEvent3D.MOUSE_WHEEL, mouseEvent, camera, target, targetSurface, branchToVector(target, branch));
							}
							break;
						case "mouseOut":
							// TODO: lastEvent not need change here. For example when MOUSE_OUT and MOUSE_MOVE exists in the one frame.
							lastEvent = null;
							target = null;
							targetSurface = null;
							if (overedTarget != target) {
								processOverOut(mouseEvent, camera);
							}
							break;
						case "render":
							defineTarget(index);
							if (overedTarget != target) {
								processOverOut(mouseEvent, camera);
							}
							break;
					}
					target = null;
					targetSurface = null;
					targetDepth = camera.farClipping;
				}
			}
			// Reset surfaces
			surfaces.length = 0;
			surfacesLength = 0;
			// Reset events
			events.length = 0;
			eventsLength = 0;
			// Reset rays
			for (i = 0; i < raysLength; i++) {
				raysSurfaces[i].length = 0;
				raysDepths[i].length = 0;
			}
			raysLength = 0;
		}

		/**
		 * Calculates depth of every ray to every surface and writes it to the <code>rayDepths</code> property
		 *
		 * @param context
		 * @param camera
		 * @param contextWidth
		 * @param contextHeight
		 */
		private function calculateSurfacesDepths(context:Context3D, camera:Camera3D, contextWidth:int, contextHeight:int):void {
			// Clear
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context.setCulling(Context3DTriangleFace.FRONT);
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
			context.setTextureAt(2, null);
			context.setTextureAt(3, null);
			context.setTextureAt(4, null);
			context.setTextureAt(5, null);
			context.setTextureAt(6, null);
			context.setTextureAt(7, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
			context.setVertexBufferAt(4, null);
			context.setVertexBufferAt(5, null);
			context.setVertexBufferAt(6, null);
			context.setVertexBufferAt(7, null);

			var drawRectGeometry:Geometry = camera.context3DProperties.drawRectGeometry;
			var drawColoredRectProgram:ShaderProgram = camera.context3DProperties.drawColoredRectProgram;

			// Rectangle
			var vLinker:Linker, fLinker:Linker;

			// Constants
			var m0:Number = camera.m0;
			var m5:Number = camera.m5;
			var m10:Number = camera.m10;
			var m11:Number = camera.m14;
			var kZ:Number = 255/camera.farClipping;
			var fragmentConst:Number = 1/255;

			// Loop the unique rays
			var i:int;
			var j:int;
			var pixelIndex:int = 0;

			for (i = 0; i < raysLength; i++) {
				var rayCoefficients:Point = raysCoefficients[i];
				// Draws the surface of the ray
				for (j = 0; j < surfacesLength; j++) {
					if (pixelIndex == 0) {
						// Set constants
						drawColoredRectConst[0] = raysLength*surfacesLength*2/contextWidth;
						drawColoredRectConst[1] = -2/contextHeight;
						// Fill background with blue color
						context.setDepthTest(false, Context3DCompareMode.ALWAYS);
						context.setProgram(drawColoredRectProgram.program);
						context.setVertexBufferAt(0, drawRectGeometry.getVertexBuffer(VertexAttributes.POSITION), drawRectGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
						context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, drawColoredRectConst);
						drawRectColor[0] = 0;
						drawRectColor[1] = 0;
						drawRectColor[2] = 1;
						drawRectColor[3] = 1;
						context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, drawRectColor);
						context.drawTriangles(drawRectGeometry._indexBuffer, 0, 2);
						context.setVertexBufferAt(0, null);
						context.setDepthTest(true, Context3DCompareMode.LESS);
					}
					scissor.x = pixelIndex;
					context.setScissorRectangle(scissor);
					drawSurface(context, camera, j, m0, m5, m10, m11, (pixelIndex*2/contextWidth - rayCoefficients.x), rayCoefficients.y, kZ, fragmentConst, camera.orthographic);
					raysIs[pixelIndex] = i;
					raysJs[pixelIndex] = j;
					pixelIndex++;
					if (pixelIndex >= contextWidth || i >= raysLength - 1 && j >= surfacesLength - 1) {
						// get
						var pixel:BitmapData = pixels[pixelIndex];
						if (pixel == null) {
							pixel = new BitmapData(pixelIndex, 1, false, 0xFF);
							pixels[pixelIndex] = pixel;
						}
						context.drawToBitmapData(pixel);
						for (var k:int = 0; k < pixelIndex; k++) {
							var color:int = pixel.getPixel(k, 0);
							var red:int = (color >> 16) & 0xFF;
							var green:int = (color >> 8) & 0xFF;
							var blue:int = color & 0xFF;
							if (blue == 0) {
								var ind:int = raysIs[k];
								var raySurfaces:Vector.<Surface> = raysSurfaces[ind];
								var rayDepths:Vector.<Number> = raysDepths[ind];
								ind = raysJs[k];
								raySurfaces.push(surfaces[ind]);
								rayDepths.push((red + green/255)/kZ);
							}
						}
						pixelIndex = 0;
					}
				}
			}
			context.setScissorRectangle(null);

			// Overlaying by background color
			context.setDepthTest(true, Context3DCompareMode.ALWAYS);
			context.setProgram(drawColoredRectProgram.program);
			context.setVertexBufferAt(0, drawRectGeometry.getVertexBuffer(VertexAttributes.POSITION), drawRectGeometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			drawColoredRectConst[0] = raysLength*surfacesLength*2/contextWidth;
			drawColoredRectConst[1] = -2/contextHeight;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, drawColoredRectConst);
			var r:Number = ((backgroundColor >> 16) & 0xff)/0xff;
			var g:Number = ((backgroundColor >> 8) & 0xff)/0xff;
			var b:Number = (backgroundColor & 0xff)/0xff;
			if (canvas != null) {
				drawRectColor[0] = backgroundAlpha*r;
				drawRectColor[1] = backgroundAlpha*g;
				drawRectColor[2] = backgroundAlpha*b;
			} else {
				drawRectColor[0] = r;
				drawRectColor[1] = g;
				drawRectColor[2] = b;
			}
			drawRectColor[3] = backgroundAlpha;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, drawRectColor);
			context.drawTriangles(drawRectGeometry._indexBuffer, 0, 2);
			context.setVertexBufferAt(0, null);
		}

		private function drawSurface(context:Context3D, camera:Camera3D, index:int, m0:Number, m5:Number, m10:Number, m14:Number, xOffset:Number, yOffset:Number, vertexConst:Number, fragmentConst:Number, orthographic:Boolean):void {
			// Surface
			var surface:Surface = surfaces[index];
			var geometry:Geometry = geometries[index];
			var procedure:Procedure = procedures[index];
			var object:Object3D = surface.object;
			// Program
			var drawDistanceProgram:ShaderProgram = camera.context3DProperties.drawDistancePrograms[procedure];
			if (drawDistanceProgram == null) {
				// Assembling the vertex shader
				var vertex:Linker = new Linker(Context3DProgramType.VERTEX);
				var position:String = "position";
				vertex.declareVariable(position, VariableType.ATTRIBUTE);
				if (procedure != null) {
					vertex.addProcedure(procedure);
					vertex.declareVariable("localPosition", VariableType.TEMPORARY);
					vertex.setInputParams(procedure, position);
					vertex.setOutputParams(procedure, "localPosition");
					position = "localPosition";
				}
				vertex.addProcedure(drawDistanceVertexProcedure);
				vertex.setInputParams(drawDistanceVertexProcedure, position);
				// Assembling the prgram
				drawDistanceProgram = new ShaderProgram(vertex, drawDistanceFragment);
				drawDistanceProgram.fragmentShader.varyings = drawDistanceProgram.vertexShader.varyings;
				drawDistanceProgram.upload(context);
				camera.context3DProperties.drawDistancePrograms[procedure] = drawDistanceProgram;
			}
			var buffer:VertexBuffer3D = geometry.getVertexBuffer(VertexAttributes.POSITION);
			if (buffer == null) return;
			// Draw call (it is required for setting constants only)
			drawUnit.vertexBuffersLength = 0;
			drawUnit.vertexConstantsRegistersCount = 0;
			drawUnit.fragmentConstantsRegistersCount = 0;
			object.setTransformConstants(drawUnit, surface, drawDistanceProgram.vertexShader, camera);
			drawUnit.setVertexConstantsFromTransform(drawDistanceProgram.vertexShader.getVariableIndex("transform0"), object.localToCameraTransform);
			drawUnit.setVertexConstantsFromNumbers(drawDistanceProgram.vertexShader.getVariableIndex("coefficient"), xOffset, yOffset, vertexConst, orthographic ? 1 : 0);
			drawUnit.setVertexConstantsFromNumbers(drawDistanceProgram.vertexShader.getVariableIndex("projection"), m0, m5, m10, m14);
			drawUnit.setFragmentConstantsFromNumbers(drawDistanceProgram.fragmentShader.getVariableIndex("code"), fragmentConst, 0, 0, 1);
			context.setProgram(drawDistanceProgram.program);
			// Buffers
			var i:int;
			context.setVertexBufferAt(0, buffer, geometry._attributesOffsets[VertexAttributes.POSITION], VertexAttributes.FORMATS[VertexAttributes.POSITION]);
			for (i = 0; i < drawUnit.vertexBuffersLength; i++) {
				context.setVertexBufferAt(drawUnit.vertexBuffersIndexes[i], drawUnit.vertexBuffers[i], drawUnit.vertexBuffersOffsets[i], drawUnit.vertexBuffersFormats[i]);
			}
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, drawUnit.vertexConstants, drawUnit.vertexConstantsRegistersCount);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, drawUnit.fragmentConstants, drawUnit.fragmentConstantsRegistersCount);
			context.drawTriangles(geometry._indexBuffer, surface.indexBegin, surface.numTriangles);
			// Clearing
			context.setVertexBufferAt(0, null);
			for (i = 0; i < drawUnit.vertexBuffersLength; i++) {
				context.setVertexBufferAt(drawUnit.vertexBuffersIndexes[i], null);
			}
		}

		private function sort(surfaces:Vector.<Surface>, depths:Vector.<Number>, length:int):void {
			stack[0] = 0;
			stack[1] = length - 1;
			var index:int = 2;
			while (index > 0) {
				index--;
				var r:int = stack[index];
				var j:int = r;
				index--;
				var l:int = stack[index];
				var i:int = l;
				var median:Number = depths[(r + l) >> 1];
				while (i <= j) {
					var left:Number = depths[i];
					while (left > median) {
						i++;
						left = depths[i];
					}
					var right:Number = depths[j];
					while (right < median) {
						j--;
						right = depths[j];
					}
					if (i <= j) {
						depths[i] = right;
						depths[j] = left;
						var surface:Surface = surfaces[i];
						surfaces[i] = surfaces[j];
						surfaces[j] = surface;
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

		private function processOverOut(mouseEvent:MouseEvent, camera:Camera3D):void {
			branchToVector(target, branch);
			branchToVector(overedTarget, overedBranch);
			var branchLength:int = branch.length;
			var overedBranchLength:int = overedBranch.length;
			var changedBranchLength:int;
			var i:int;
			var j:int;
			var object:Object3D;
			if (overedTarget != null) {
				propagateEvent(MouseEvent3D.MOUSE_OUT, mouseEvent, camera, overedTarget, overedTargetSurface, overedBranch, true, target);
				changedBranchLength = 0;
				for (i = 0; i < overedBranchLength; i++) {
					object = overedBranch[i];
					for (j = 0; j < branchLength; j++) if (object == branch[j]) break;
					if (j == branchLength) {
						changedBranch[changedBranchLength] = object;
						changedBranchLength++;
					}
				}
				if (changedBranchLength > 0) {
					changedBranch.length = changedBranchLength;
					propagateEvent(MouseEvent3D.ROLL_OUT, mouseEvent, camera, overedTarget, overedTargetSurface, changedBranch, false, target);
				}
			}
			if (target != null) {
				changedBranchLength = 0;
				for (i = 0; i < branchLength; i++) {
					object = branch[i];
					for (j = 0; j < overedBranchLength; j++) if (object == overedBranch[j]) break;
					if (j == overedBranchLength) {
						changedBranch[changedBranchLength] = object;
						changedBranchLength++;
					}
				}
				if (changedBranchLength > 0) {
					changedBranch.length = changedBranchLength;
					propagateEvent(MouseEvent3D.ROLL_OVER, mouseEvent, camera, target, targetSurface, changedBranch, false, overedTarget);
				}
				propagateEvent(MouseEvent3D.MOUSE_OVER, mouseEvent, camera, target, targetSurface, branch, true, overedTarget);
				useHandCursor = target.useHandCursor;
			} else {
				useHandCursor = false;
			}
			Mouse.cursor = Mouse.cursor;
			overedTarget = target;
			overedTargetSurface = targetSurface;
		}

		private function branchToVector(object:Object3D, vector:Vector.<Object3D>):Vector.<Object3D> {
			var len:int = 0;
			while (object != null) {
				vector[len] = object;
				len++;
				object = object._parent;
			}
			vector.length = len;
			return vector;
		}

		private function propagateEvent(type:String, mouseEvent:MouseEvent, camera:Camera3D, target:Object3D, targetSurface:Surface, objects:Vector.<Object3D>, bubbles:Boolean = true, relatedObject:Object3D = null):void {
			var oblectsLength:int = objects.length;
			var object:Object3D;
			var vector:Vector.<Function>;
			var length:int;
			var i:int;
			var j:int;
			var mouseEvent3D:MouseEvent3D;
			// Capture
			for (i = oblectsLength - 1; i > 0; i--) {
				object = objects[i];
				if (object.captureListeners != null) {
					vector = object.captureListeners[type];
					if (vector != null) {
						if (mouseEvent3D == null) {
							calculateLocalCoords(camera, target.cameraToLocalTransform, targetDepth, mouseEvent);
							mouseEvent3D = new MouseEvent3D(type, bubbles, localCoords.x, localCoords.y, localCoords.z, relatedObject, mouseEvent.ctrlKey, mouseEvent.altKey, mouseEvent.shiftKey, mouseEvent.buttonDown, mouseEvent.delta);
							mouseEvent3D._target = target;
							mouseEvent3D._surface = targetSurface;
						}
						mouseEvent3D._currentTarget = object;
						mouseEvent3D._eventPhase = 1;
						length = vector.length;
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) {
							(functions[j] as Function).call(null, mouseEvent3D);
							if (mouseEvent3D.stopImmediate) return;
						}
						if (mouseEvent3D.stop) return;
					}
				}
			}
			// Bubble
			for (i = 0; i < oblectsLength; i++) {
				object = objects[i];
				if (object.bubbleListeners != null) {
					vector = object.bubbleListeners[type];
					if (vector != null) {
						if (mouseEvent3D == null) {
							calculateLocalCoords(camera, target.cameraToLocalTransform, targetDepth, mouseEvent);
							mouseEvent3D = new MouseEvent3D(type, bubbles, localCoords.x, localCoords.y, localCoords.z, relatedObject, mouseEvent.ctrlKey, mouseEvent.altKey, mouseEvent.shiftKey, mouseEvent.buttonDown, mouseEvent.delta);
							mouseEvent3D._target = target;
							mouseEvent3D._surface = targetSurface;
						}
						mouseEvent3D._currentTarget = object;
						mouseEvent3D._eventPhase = (i == 0) ? 2 : 3;
						length = vector.length;
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) {
							(functions[j] as Function).call(null, mouseEvent3D);
							if (mouseEvent3D.stopImmediate) return;
						}
						if (mouseEvent3D.stop) return;
					}
				}
			}
		}

		private function calculateLocalCoords(camera:Camera3D, transform:Transform3D, z:Number, mouseEvent:MouseEvent):void {
			var x:Number;
			var y:Number;
			if (!camera.orthographic) {
				x = z*(mouseEvent.localX - _width*0.5)/camera.focalLength;
				y = z*(mouseEvent.localY - _height*0.5)/camera.focalLength;
			} else {
				x = mouseEvent.localX - _width*0.5;
				y = mouseEvent.localY - _height*0.5;
			}
			localCoords.x = transform.a*x + transform.b*y + transform.c*z + transform.d;
			localCoords.y = transform.e*x + transform.f*y + transform.g*z + transform.h;
			localCoords.z = transform.i*x + transform.j*y + transform.k*z + transform.l;
		}

		private function defineTarget(index:int):void {
			var source:Object3D;
			// Get surfaces
			var surfaces:Vector.<Surface> = raysSurfaces[index];
			var depths:Vector.<Number> = raysDepths[index];
			// Loop surfaces
			for (var i:int = surfaces.length - 1; i >= 0; i--) {
				var surface:Surface = surfaces[i];
				var depth:Number = depths[i];
				var object:Object3D = surface.object;
				var potentialTarget:Object3D = null;
				var obj:Object3D;
				// Get possible target
				for (obj = object; obj != null; obj = obj._parent) {
					if (!obj.mouseChildren) potentialTarget = null;
					if (potentialTarget == null && obj.mouseEnabled) potentialTarget = obj;
				}
				// If possible target found
				if (potentialTarget != null) {
					if (target != null) {
						for (obj = potentialTarget; obj != null; obj = obj._parent) {
							if (obj == target) {
								source = object;
								if (target != potentialTarget) {
									target = potentialTarget;
									targetSurface = surface;
									targetDepth = depth;
								}
								break;
							}
						}
					} else {
						source = object;
						target = potentialTarget;
						targetSurface = surface;
						targetDepth = depth;
					}
					if (source == target) break;
				}
			}
		}

		/**
         * If <code>true</code>, image will render to <code>Bitmap</code> object which will included into the view as a child. It also will available through <code>canvas</code> property.
		 *
		 * @see #canvas
         */
		public function get renderToBitmap():Boolean {
			return _canvas != null;
		}

		/**
		 * @private
		 */
		public function set renderToBitmap(value:Boolean):void {
			if (value) {
				if (_canvas == null) createRenderBitmap();
			} else {
				if (_canvas != null) {
					container.bitmapData = null;
					_canvas.dispose();
					_canvas = null;
				}
			}
		}

		/**
		 * <code>BitmapData</code> with rendered image in case of <code>renderToBitmap</code> turned on.
		 *
		 *  @see #renderToBitmap
		 */
		public function get canvas():BitmapData {
			return _canvas;
		}

		/**
		 * Places Alternativa3D logo into the <code>view</code>.
		 */
		public function showLogo():void {
			if (logo == null) {
				logo = new Logo();
				super.addChild(logo);
				resizeLogo();
			}
		}

		/**
		 * Places Alternativa3D logo from the <code>view</code>.
		 */
		public function hideLogo():void {
			if (logo != null) {
				super.removeChild(logo);
				logo = null;
			}
		}

		/**
		 * Alinging the logo.  Constants of <code>StageAlign</code> class can be used as a value to set.
		 */
		public function get logoAlign():String {
			return _logoAlign;
		}

		/**
		 * @private
		 */
		public function set logoAlign(value:String):void {
			_logoAlign = value;
			resizeLogo();
		}

		/**
		 * Horizontal margin.
		 */
		public function get logoHorizontalMargin():Number {
			return _logoHorizontalMargin;
		}

		/**
		 * @private
		 */
		public function set logoHorizontalMargin(value:Number):void {
			_logoHorizontalMargin = value;
			resizeLogo();
		}

		/**
		 * Vertical margin.
		 */
		public function get logoVerticalMargin():Number {
			return _logoVerticalMargin;
		}

		/**
		 * @private
		 */
		public function set logoVerticalMargin(value:Number):void {
			_logoVerticalMargin = value;
			resizeLogo();
		}

		private function resizeLogo():void {
			if (logo != null) {
				if (_logoAlign == StageAlign.TOP_LEFT || _logoAlign == StageAlign.LEFT || _logoAlign == StageAlign.BOTTOM_LEFT) {
					logo.x = Math.round(_logoHorizontalMargin);
				}
				if (_logoAlign == StageAlign.TOP || _logoAlign == StageAlign.BOTTOM) {
					logo.x = Math.round((_width - logo.width)/2);
				}
				if (_logoAlign == StageAlign.TOP_RIGHT || _logoAlign == StageAlign.RIGHT || _logoAlign == StageAlign.BOTTOM_RIGHT) {
					logo.x = Math.round(_width - _logoHorizontalMargin - logo.width);
				}
				if (_logoAlign == StageAlign.TOP_LEFT || _logoAlign == StageAlign.TOP || _logoAlign == StageAlign.TOP_RIGHT) {
					logo.y = Math.round(_logoVerticalMargin);
				}
				if (_logoAlign == StageAlign.LEFT || _logoAlign == StageAlign.RIGHT) {
					logo.y = Math.round((_height - logo.height)/2);
				}
				if (_logoAlign == StageAlign.BOTTOM_LEFT || _logoAlign == StageAlign.BOTTOM || _logoAlign == StageAlign.BOTTOM_RIGHT) {
					logo.y = Math.round(_height - _logoVerticalMargin - logo.height);
				}
			}
		}

		/**
		 * Width of this <code>View</code>. Should be 50 at least.
		 */
		override public function get width():Number {
			return _width;
		}

		/**
		 * @private
		 */
		override public function set width(value:Number):void {
			if (value < 50) value = 50;
			_width = value;
			area.width = value;
			resizeLogo();
		}

		/**
		 *  Height of this <code>View</code>. Should be 50 at least.
		 */
		override public function get height():Number {
			return _height;
		}

		/**
		 * @private
		 */
		override public function set height(value:Number):void {
			if (value < 50) value = 50;
			_height = value;
			area.height = value;
			resizeLogo();
		}

		/**
		 * @private
		 */
		override public function addChild(child:DisplayObject):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function removeChild(child:DisplayObject):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function removeChildAt(index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function removeChildren(beginIndex:int = 0, endIndex:int = 2147483647):void {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function getChildAt(index:int):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function getChildIndex(child:DisplayObject):int {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function setChildIndex(child:DisplayObject, index:int):void {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function swapChildrenAt(index1:int, index2:int):void {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function get numChildren():int {
			return 0;
		}

		/**
		 * @private
		 */
		override public function getChildByName(name:String):DisplayObject {
			throw new Error("Unsupported operation.");
		}

		/**
		 * @private
		 */
		override public function contains(child:DisplayObject):Boolean {
			throw new Error("Unsupported operation.");
		}

	}
}

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.net.URLRequest;
import flash.net.navigateToURL;

class Logo extends Sprite {

	static public const image:BitmapData = createBMP();

	static private function createBMP():BitmapData {

		var bmp:BitmapData = new BitmapData(165, 27, true, 0);

		bmp.setVector(bmp.rect, Vector.<uint>([
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,134217728,503316480,721420288,503316480,134217728,134217728,503316480,721420288,503316480,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100663296,419430400,721420288,788529152,536870912,234881024,50331648,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1677721600,503316480,503316480,1677721600,2348810240,1677721600,503316480,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,67108864,301989888,822083584,1677721600,2365587456,2483027968,1996488704,1241513984,536870912,117440512,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16777216,167772160,520093696,822083584,905969664,822083584,520093696,301989888,520093696,822083584,905969664,822083584,620756992,620756992,721420288,620756992,620756992,721420288,620756992,620756992,721420288,620756992,620756992,822083584,905969664,822083584,520093696,218103808,234881024,536870912,721420288,620756992,620756992,822083584,905969664,822083584,520093696,301989888,520093696,822083584,1493172224,2768240640,4292467161,2533359616,822083584,822083584,2533359616,4292467161,2768240640,1493172224,822083584,620756992,620756992,721420288,503316480,268435456,503316480,721420288,503316480,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,134217728,620756992,1392508928,2248146944,3514129719,4192520610,4277921461,3886715221,2905283846,1778384896,788529152,234881024,50331648,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,167772160,822083584,1845493760,2533359616,2734686208,2533359616,1845493760,1325400064,1845493760,2533359616,2734686208,2533359616,2164260864,2164260864,2348810240,2164260864,2164260864,2348810240,2164260864,2164260864,2348810240,2164260864,2164260864,2533359616,2734686208,2533359616,1845493760,1056964608,1107296256,1895825408,2348810240,2164260864,2164260864,2533359616,2734686208,2533359616,1845493760,1325400064,1845493760,2533359616,2952790016,3730463322,4292467161,2734686208,905969664,905969664,2734686208,4292467161,3730463322,2952790016,2533359616,2164260864,2164260864,2348810240,1677721600,989855744,1677721600,2348810240,1677721600,503316480,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,16777216,167772160,754974720,1828716544,3022988562,4022445697,4294959283,4294953296,4294953534,4294961056,4226733479,3463135252,2130706432,1224736768,486539264,83886080,0,0,0,0,0,0,0,0,0,0,0,0,0,0,520093696,1845493760,3665591420,4292467161,4292467161,4292467161,3665591420,2650800128,3665591420,4292467161,4292467161,4292467161,3816191606,3355443200,4292467161,3355443200,3355443200,4292467161,3355443200,3355443200,4292467161,3355443200,3816191606,4292467161,4292467161,4292467161,3665591420,2382364672,2415919104,3801125008,4292467161,3355443200,3816191606,4292467161,4292467161,4292467161,3495911263,2650800128,3665591420,4292467161,4292467161,4292467161,4292467161,2533359616,822083584,822083584,2533359616,4292467161,4292467161,4292467161,4292467161,3816191606,3355443200,4292467161,2533359616,1627389952,2533359616,4292467161,2533359616,822083584,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,50331648,251658240,889192448,1962934272,3463338042,4260681651,4294955128,4294949388,4294949120,4294948864,4294948864,4294953816,4294960063,3903219779,2701722370,1627389952,620756992,100663296,0,0,0,0,0,0,0,0,0,0,0,0,0,822083584,2533359616,4292467161,3730463322,3187671040,3730463322,4292467161,3456106496,4292467161,3849680245,3221225472,3849680245,4292467161,3640655872,4292467161,3640655872,3640655872,4292467161,3640655872,3640655872,4292467161,3640655872,4292467161,3966923378,3640655872,3966923378,4292467161,3355443200,3918236555,4292467161,3763951961,3539992576,4292467161,3966923378,3640655872,3966923378,4292467161,3456106496,4292467161,3849680245,3221225472,3422552064,3456106496,2348810240,721420288,721420288,2348810240,3456106496,3422552064,3221225472,3849680245,4292467161,3640655872,4292467161,2734686208,1828716544,2734686208,4292467161,2734686208,905969664,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,50331648,318767104,1006632960,2080374784,3683940948,4294958002,4294949951,4294946816,4294946048,4294944256,4294944256,4294945536,4294944512,4294944799,4294954914,4123823487,3056010753,1778384896,671088640,117440512,0,0,0,0,0,0,0,0,0,0,0,0,822083584,2533359616,4292467161,3187671040,2734686208,3187671040,4292467161,3640655872,4292467161,3221225472,2801795072,3221225472,4292467161,3640655872,4292467161,3966923378,3640655872,4292467161,3966923378,3640655872,4292467161,3640655872,4292467161,3640655872,4292467161,4292467161,4292467161,3640655872,4292467161,3613154396,2818572288,3221225472,4292467161,3640655872,4292467161,4292467161,4292467161,3640655872,4292467161,3221225472,2801795072,3221225472,4292467161,2533359616,822083584,822083584,2533359616,4292467161,3221225472,2801795072,3221225472,4292467161,3640655872,4292467161,2952790016,2264924160,2952790016,4292467161,2533359616,822083584,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,50331648,318767104,1056964608,2147483648,3819605095,4294955172,4294944795,4294943744,4294941184,4294939392,4294940672,4294940160,4294938624,4294941440,4294940672,4294936323,4294815095,4208955271,3208382211,1845493760,721420288,134217728,0,0,0,0,0,0,0,0,0,0,0,721420288,2348810240,3456106496,3405774848,3187671040,3730463322,4292467161,3456106496,4292467161,3849680245,3221225472,3849680245,4292467161,3355443200,3816191606,4292467161,3966923378,3966923378,4292467161,3966923378,4292467161,3640655872,4292467161,3966923378,3640655872,3640655872,3640655872,3640655872,4292467161,2868903936,1996488704,2684354560,4292467161,3966923378,3640655872,3640655872,3539992576,3456106496,4292467161,3849680245,3221225472,3849680245,4292467161,2533359616,822083584,822083584,2533359616,4292467161,3849680245,3221225472,3849680245,4292467161,3456106496,4292467161,3730463322,3187671040,3405774848,3456106496,2348810240,721420288,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,16777216,234881024,989855744,2147483648,3836647021,4294952084,4294939916,4294939392,4294936064,4294935808,4294939907,3970992676,3783616794,4260594952,4294933248,4294937088,4294937088,4294865664,4294676569,4243165579,3292924164,1862270976,721420288,134217728,0,0,0,0,0,0,0,0,0,0,822083584,2533359616,4292467161,4292467161,4292467161,4292467161,3665591420,2650800128,3665591420,4292467161,4292467161,4292467161,3665591420,2348810240,2348810240,3665591420,4292467161,3355443200,3816191606,4292467161,4292467161,3355443200,3816191606,4292467161,4292467161,4292467161,3696908890,3355443200,4292467161,2533359616,1325400064,1845493760,3665591420,4292467161,4292467161,4292467161,3665591420,2650800128,3665591420,4292467161,4292467161,4292467161,3665591420,1845493760,520093696,520093696,1845493760,3665591420,4292467161,4292467161,4292467161,3665591420,2650800128,3665591420,4292467161,4292467161,4292467161,4292467161,2533359616,822083584,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,150994944,855638016,2063597568,3785853032,4294949263,4294935301,4294934528,4294931200,4294865408,4294739211,3598869795,2348810240,2248146944,3157861897,4158024716,4294930432,4294934272,4294934016,4294796032,4294604868,4260400774,3309963524,1862270976,704643072,117440512,0,0,0,0,0,0,0,0,0,905969664,2734686208,4292467161,3730463322,2952790016,2533359616,1845493760,1325400064,1845493760,2533359616,2734686208,2533359616,1845493760,1006632960,1006632960,1845493760,2348810240,2164260864,2164260864,2533359616,2533359616,2164260864,2164260864,2533359616,2734686208,2533359616,2164260864,2164260864,2348810240,1677721600,671088640,822083584,1845493760,2533359616,2734686208,2533359616,1845493760,1325400064,1845493760,2533359616,2734686208,2533359616,1845493760,822083584,167772160,167772160,822083584,1845493760,2533359616,2734686208,2533359616,1845493760,1325400064,1845493760,2533359616,2952790016,3730463322,4292467161,2734686208,905969664,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,117440512,738197504,1962934272,3632951638,4294947982,4294931462,4294930176,4294794752,4294662144,4260327185,3378071325,1946157056,922746880,822083584,1677721600,2785937666,3954400527,4294929408,4294931968,4294931712,4294661120,4294469180,4260200571,3208316675,1795162112,620756992,83886080,0,0,0,0,0,0,0,0,822083584,2533359616,4292467161,2768240640,1493172224,822083584,520093696,301989888,520093696,822083584,905969664,822083584,520093696,184549376,184549376,520093696,721420288,620756992,620756992,822083584,822083584,620756992,620756992,822083584,905969664,822083584,620756992,620756992,721420288,503316480,150994944,167772160,520093696,822083584,905969664,822083584,520093696,301989888,520093696,822083584,905969664,822083584,520093696,167772160,16777216,16777216,167772160,520093696,822083584,905969664,822083584,520093696,301989888,520093696,822083584,1493172224,2768240640,4292467161,2533359616,822083584,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,67108864,620756992,1811939328,3429059385,4294882972,4294796301,4294727936,4294526208,4294325760,4226241553,3242276118,1862270976,738197504,150994944,100663296,520093696,1325400064,2264924160,3768667144,4294928385,4294929408,4294796800,4294460416,4294335293,4225986666,3055813377,1644167168,503316480,50331648,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1677721600,503316480,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1677721600,503316480,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,16777216,335544320,1459617792,3005750036,4243500445,4294661403,4294524672,4294258432,4294121728,4259985678,3259118102,1845493760,704643072,134217728,0,0,50331648,335544320,1006632960,2080374784,3751757574,4294794241,4294794240,4294592771,4294323463,4294400588,4123811671,2769158144,1275068416,251658240,0,0,0,0,0,0,0,134217728,503316480,721420288,503316480,134217728,0,0,0,0,134217728,503316480,721420288,503316480,268435456,503316480,721420288,503316480,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,134217728,503316480,721420288,503316480,134217728,0,0,0,0,134217728,503316480,721420288,503316480,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,134217728,503316480,721420288,520093696,167772160,16777216,0,0,0,0,0,0,0,0,134217728,503316480,721420288,520093696,234881024,285212672,570425344,687865856,436207616,117440512,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,150994944,922746880,2348810240,4056321414,4294197820,4294119936,4294056448,4293921536,4293991688,3394978333,1879048192,704643072,117440512,0,0,0,0,33554432,268435456,1023410176,2248146944,3869450497,4293927168,4293661957,4293331976,4293330946,4293609799,3936365867,2181038080,822083584,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1744830464,1140850688,1744830464,2348810240,1744830464,637534208,67108864,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1744830464,637534208,67108864,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1811939328,771751936,150994944,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1811939328,1040187392,1207959552,1979711488,2248146944,1509949440,436207616,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,50331648,620756992,1879048192,3649264467,4294272360,4293853184,4293920000,4293920000,4293918720,3649195041,1979711488,754974720,134217728,0,0,0,0,0,67108864,335544320,1023410176,2080374784,3036676096,4088070144,4292476928,4292608000,4292739072,4292804608,4293347915,3581022738,1879048192,654311424,83886080,0,0,0,0,0,0,0,0,50331648,201326592,335544320,201326592,50331648,0,822083584,2533359616,4294967295,3261885548,2080374784,2768240640,4294967295,3261885548,1258291200,234881024,117440512,402653184,671088640,687865856,469762048,184549376,33554432,0,83886080,318767104,419430400,352321536,469762048,620756992,620756992,520093696,335544320,150994944,50331648,0,0,50331648,201326592,335544320,201326592,50331648,0,822083584,2533359616,4294967295,3295439980,1610612736,872415232,520093696,318767104,301989888,167772160,33554432,0,33554432,167772160,301989888,167772160,33554432,50331648,201326592,335544320,201326592,50331648,0,0,0,50331648,184549376,469762048,704643072,704643072,469762048,184549376,855638016,2533359616,4294809856,3566287616,1493172224,335544320,0,0,50331648,234881024,402653184,234881024,50331648,0,822083584,2550136832,4294809856,3583064832,2147483648,2382364672,3921236224,4209802240,2181038080,687865856,184549376,469762048,704643072,704643072,469762048,184549376,50331648,50331648,234881024,520093696,671088640,704643072,822083584,889192448,771751936,721420288,805306368,771751936,520093696,234881024,50331648,0,
			0,0,0,268435456,1358954496,3023117852,4260334217,4293854213,4293919488,4293921024,4293853184,4055516443,2348810240,939524096,150994944,0,0,0,0,33554432,201326592,671088640,1442840576,2264924160,3513790764,3356295425,3473866752,4207017984,4292673536,4292804608,4292870144,4292937479,4276240705,3174499075,1610612736,419430400,0,0,0,0,0,0,0,83886080,452984832,1157627904,1577058304,1174405120,486539264,83886080,905969664,2734686208,4294967295,3479528805,2533359616,3087007744,4294967295,3429394536,1543503872,520093696,754974720,1610612736,2248146944,2298478592,1845493760,1107296256,385875968,150994944,587202560,1409286144,1644167168,1442840576,1761607680,2147483648,2147483648,1962934272,1593835520,1040187392,385875968,50331648,83886080,452984832,1157627904,1577058304,1174405120,486539264,234881024,1191182336,2868903936,4294967295,3630326370,2734686208,2432696320,1962934272,1526726656,1392508928,822083584,167772160,0,167772160,822083584,1392508928,1073741824,436207616,503316480,1157627904,1577058304,1174405120,486539264,83886080,0,83886080,452984832,1140850688,1845493760,2315255808,2315255808,1845493760,1140850688,1375731712,2818572288,4294804480,3666292992,1744830464,419430400,0,100663296,520093696,1275068416,1694498816,1291845632,536870912,234881024,1191182336,2868903936,4294804480,3783471360,2952790016,3768006912,4294606336,3681495040,2130706432,1023410176,1140850688,1845493760,2315255808,2315255808,1845493760,1140850688,469762048,335544320,1006632960,1879048192,2248146944,2298478592,2533359616,2667577344,2449473536,2332033024,2499805184,2449473536,1962934272,1191182336,419430400,50331648,
			0,0,83886080,754974720,2181038080,3971250292,4293995053,4293853184,4293855488,4293591040,4208406034,2938050314,1426063360,335544320,16777216,0,0,50331648,234881024,620756992,1207959552,2013265920,3107396370,4055000155,4293554803,4003672881,3221225472,3544186880,4292673536,4292804608,4292870144,4292870144,4293006099,4122616354,2600796160,1023410176,134217728,0,0,0,0,0,67108864,520093696,1560281088,2685209869,3768886436,2736133654,1644167168,603979776,1006632960,2734686208,4294967295,3630326370,2952790016,3630326370,4294967295,3429394536,1711276032,1191182336,1979711488,3531768450,4140814287,4140945873,3801519766,2584349194,1493172224,1006632960,1728053248,3380576127,3769610159,2734686208,3752175013,4022386880,4022386880,3886721706,3513806960,2739028546,1140850688,285212672,520093696,1560281088,2685209869,3768886436,2736133654,1644167168,1107296256,1996488704,3579994722,4294967295,3780992349,3456106496,4294967295,3596837731,3173130786,3600916897,1828716544,553648128,50331648,553648128,1828716544,3600916897,2620009002,1509949440,1694498816,2685209869,3768886436,2736133654,1644167168,603979776,150994944,503316480,1543503872,2889486848,3767873792,4175254272,4175254272,3767873792,2889486848,2399141888,3120562176,4294798592,3632408576,1694498816,402653184,83886080,587202560,1644167168,2786133248,3870512384,2870872320,1711276032,1140850688,2013265920,3682543616,4294798592,3866764800,3456106496,4294798592,4054399232,3338665984,2516582400,2097152000,2889486848,3767873792,4175254272,4175254272,3767873792,2889486848,1660944384,1275068416,2097152000,3836689152,4192360448,3422552064,4294798592,4294798592,4192360448,3970513152,4294798592,4192360448,3903601152,2788757760,1174405120,234881024,
			0,0,335544320,1493172224,3259970090,4294206305,4293591040,4293263872,4292935936,4292806915,3648730389,1862270976,620756992,117440512,117440512,285212672,553648128,922746880,1392508928,2063597568,2938704652,3834466116,4276189301,4292948534,4293067009,4293740360,3732214294,3187671040,3918004480,4293132288,4293066752,4292935680,4292870144,4293073434,3681683208,1879048192,536870912,33554432,0,0,0,16777216,402653184,1509949440,2869890831,4106733511,4277729528,4157920468,3022135842,1644167168,1392508928,2751463424,4294967295,3730726494,3271557120,4294967295,4294967295,3429394536,2030043136,2147483648,3768820643,4209699562,3832574064,3815599469,4260820726,3970410407,2936999695,2499805184,3464001656,4022189501,3578678862,3355443200,4294967295,3747569503,3426828609,3426828609,4004030632,3784347792,1996488704,922746880,1509949440,2869890831,4106733511,4277729528,4157920468,3022135842,2348810240,2768240640,4294967295,4294967295,3847969627,3640655872,4294967295,3847969627,4020084125,4260820726,2888510251,1157627904,335544320,1157627904,2888510251,4260820726,3852772516,2734686208,3004174352,4106733511,4277729528,4157920468,3022135842,1644167168,721420288,1275068416,3058897920,4106697728,4294726912,4020186368,4020186368,4294726912,4106697728,3561427200,3489660928,4294792448,3598458880,1660944384,402653184,452984832,1577058304,2937455616,4158017536,4277752576,4192228608,3090025216,2382364672,2801795072,4294792448,4294792448,3916570368,3640655872,4294792448,4294792448,4294792448,3170893824,3460961024,4106697728,4294726912,4020186368,4020186368,4294726912,4106697728,3259962368,2617245696,3649906432,4277752576,3730839552,3539992576,4294792448,3849592320,3679458560,4277752576,4037094656,3813479168,4277752576,3886493184,1996488704,536870912,
			0,67108864,788529152,2281701376,4072894821,4293201424,4292870144,4292804608,4292608000,4156898324,2634022912,1392508928,822083584,905969664,1140850688,1476395008,2013265920,2617573888,3292798484,3902098491,4241976422,4292888908,4292806923,4293001216,4293263360,4293525760,4294260515,3510376966,3305308160,4191289856,4293394432,4293066752,4292935680,4293001473,4242215445,2871133184,1191182336,201326592,0,0,0,268435456,1291845632,2701723913,4072652735,4260754933,3782702967,4175355614,4158446812,2870877726,2264924160,3019898880,4294967295,3630326370,2952790016,3305111552,4294967295,3462817382,2399141888,3243660886,4277795321,3764675684,3372220416,3405774848,3780071247,4174829270,3729542220,3456106496,4294967295,3801256594,2885681152,3271557120,4294967295,3546506083,2298478592,2348810240,3648616825,4294967295,2818572288,2097152000,2701723913,4072652735,4260754933,3782702967,4175355614,4158446812,3289979161,3137339392,3456106496,4294967295,3847969627,3640655872,4294967295,3780992349,3645064003,4226674157,3767833748,1996488704,1174405120,1996488704,3767833748,4243385580,3712107074,3473278470,4072652735,4260754933,3782702967,4175355614,4158446812,2870877726,1711276032,1811939328,3685360896,4124521216,3410759424,2920416000,2920416000,3427536640,4157944576,4105775616,3640655872,4294787072,3564509184,1627389952,637534208,1342177280,2785739264,4106956544,4260773120,3867745792,4209325824,4192286208,3323987200,3137339392,3456106496,4294787072,3899463168,3640655872,4294787072,3798931456,3204448256,3221225472,4055509504,4157944576,3427536640,2920416000,2920416000,3427536640,4157944576,4072286720,3456106496,4294787072,3886162944,2969567232,3305111552,4294787072,3698464768,2952790016,3783794432,4294787072,3640655872,3951172864,4294787072,2550136832,822083584,
			0,285212672,1426063360,3277007389,4293737023,4293066752,4292870144,4292739072,4241565196,3423471106,2717908992,2197815296,2264924160,2685010432,3005286916,3377536014,3851039012,4139536965,4292959323,4292818747,4292742414,4292804608,4292804608,4292935680,4293725440,4294590464,3954466066,2871071238,2466250752,3445623808,4294119168,4293525504,4293132288,4293001216,4293462024,3835439624,2030043136,654311424,67108864,0,50331648,788529152,2348941826,3851061898,4260886519,3529005144,3120562176,3525452322,4243451373,3902446234,3288926473,3439329280,4294967295,3513017444,2634022912,3137339392,4294967295,3496306021,2583691264,3717567893,4209041632,3489660928,4141406424,4141538010,4124168657,4192461795,3868365458,3523215360,4294967295,3462817382,2499805184,3070230528,4294967295,3429394536,1811939328,1845493760,3446040166,4294967295,3422552064,3221225472,3851061898,4260886519,3529005144,3120562176,3525452322,4243451373,3952580503,3490318858,3539992576,4294967295,3847969627,3640655872,4294967295,3630326370,2952790016,3869483939,4260689140,3123917619,2415919104,3123917619,4260689140,4020084125,3640655872,3968239238,4260886519,3529005144,3120562176,3525452322,4243451373,3902446234,2735475724,2113929216,2600468480,3019898880,2583691264,2063597568,2063597568,2667577344,3714912256,4294781952,3640655872,4294781952,3547336960,1728053248,1191182336,2382495744,3902150144,4277545472,3580038656,3120562176,3559458048,4243531776,3986889472,3490382080,3539992576,4294781952,3882225408,3640655872,4294781952,3614249216,2634022912,2919235584,4294781952,3714912256,2667577344,2063597568,2063597568,2667577344,3714912256,4294781952,3640655872,4294781952,3547336960,2583691264,3120562176,4294781952,3547336960,2566914048,3547336960,4294781952,3640655872,3882225408,4294781952,2734686208,905969664,
			50331648,687865856,2164260864,4004986156,4293526023,4293132288,4292804608,4292739072,4190049031,3866102791,3816952331,3868467732,4003800346,4156500256,4275644710,4292683559,4292682277,4292679193,4292739073,4292739072,4292608000,4292411392,4292673536,4293661184,4174923273,3446360857,2164260864,1291845632,1191182336,2332033024,4073140736,4294119168,4293525504,4293066752,4293263360,4276230916,3260750080,1392508928,318767104,16777216,184549376,1275068416,3157340465,4274439878,3678486849,3120562176,3289452817,3848232799,4120681628,4291611852,3711251765,3456106496,4291611852,3799348597,2919235584,3288334336,4291611852,3461435729,2499805184,3410446151,4206212533,3778952766,3591574291,3388997632,3305111552,3170893824,3036676096,3372220416,4291611852,3427947090,2415919104,3019898880,4291611852,3427947090,1795162112,1795162112,3427947090,4291611852,3640655872,3760793897,4274439878,3678486849,3120562176,3289452817,3848232799,4120681628,4291611852,3795137845,3640655872,4291611852,3846785353,3640655872,4291611852,3478212945,2399141888,3073322799,4172394929,4121339558,3491832097,4121339558,4172394929,3542690089,3643353385,4274439878,3678486849,3120562176,3289452817,3848232799,4120681628,4291611852,3510188345,2785017856,3582069760,4090368512,3376612608,2920218624,2920218624,3393389824,4123791872,4037807872,3456106496,4294514688,3835038720,2231369728,1862270976,3191800832,4277278208,3696690944,3137339392,3323461888,3883600384,4140044544,4294514688,3813017088,3640655872,4294514688,3865118720,3640655872,4294514688,3496610048,2130706432,2399141888,3954183936,4123791872,3393389824,2920218624,2920218624,3393389824,4123791872,4071296768,3640655872,4294514688,3496610048,2466250752,3053453312,4294514688,3496610048,2466250752,3496610048,4294514688,3640655872,3865118720,4294514688,2734686208,905969664,
			201326592,1224736768,3023639812,4277017613,4293656576,4293263360,4292870144,4292804608,4292870144,4292871176,4292939794,4292939796,4292873232,4292871689,4292739587,4292804608,4292804608,4292673536,4292542464,4292345856,4292542464,4293133568,4157219336,3665638928,2651785731,1677721600,771751936,251658240,385875968,1526726656,3327729408,4294721792,4294119168,4293591040,4293197824,4293925893,3987551235,2248146944,872415232,134217728,385875968,1677721600,3630721128,4291546059,3813757265,3849088108,4189172145,4154893990,3881063508,4154762404,3781387107,3070230528,3629931612,4257728455,3661512254,3539992576,4291611852,3427947090,2231369728,2769885465,3934158462,4205949361,3847311697,3643419178,3729081669,4037585064,2902458368,3288334336,4291611852,3427947090,2415919104,3019898880,4291611852,3427947090,1795162112,1795162112,3427947090,4291611852,3640655872,3932250465,4291546059,3813757265,3849088108,4189172145,4154893990,3881063508,4154762404,3915275870,3640655872,4291611852,3846785353,3640655872,4291611852,3427947090,1929379840,1946157056,3309980234,4206541498,4274374085,4206541498,3427289160,2835349504,3731187045,4291546059,3813757265,3849088108,4189172145,4154893990,3881063508,4154762404,3865075808,3456106496,4294511104,4088530432,4294380032,3968205824,3968205824,4294380032,4038395392,3158180096,2533359616,3531015424,4260563200,3310682880,2583691264,3665954048,4294445568,3815047936,3867608064,4191881216,4157409024,3899130624,4157277952,3933602816,3640655872,4294511104,3864789504,3640655872,4294511104,3462923264,1778384896,1577058304,2957115648,4038395392,4294380032,3968205824,3968205824,4294380032,4038395392,3493396736,3472883712,4294511104,3462923264,2449473536,3036676096,4294511104,3462923264,2449473536,3462923264,4294511104,3640655872,3864789504,4294511104,2734686208,905969664,
			436207616,1795162112,3784914178,4294453760,4293985792,4293525504,4293263360,4293066752,4293001216,4292870144,4292870144,4292870144,4292804608,4292739072,4292608000,4292411392,4292411392,4292411392,4292804608,4276096257,4055439621,3462337541,2617967874,1778384896,1006632960,436207616,100663296,0,83886080,822083584,2332033024,4107292928,4294722560,4294251776,4293656576,4293856768,4276101633,3515097344,1342177280,234881024,436207616,1711276032,3817968017,4206673084,4223647679,4019952539,3613812326,3157077293,2869101315,3461238350,4037716650,2516582400,2365587456,3614865014,4104759721,3405774848,4291611852,3260503895,1560281088,1526726656,2703500324,3630786921,4036861341,4240490688,3867575942,2973514812,2231369728,2885681152,4291611852,3260503895,2080374784,2768240640,4291611852,3260503895,1493172224,1493172224,3260503895,4291611852,3372220416,3951922573,4206673084,4223647679,4019952539,3613812326,3157077293,2869101315,3461238350,4087982505,3405774848,4291611852,3662499149,3355443200,4291611852,3260503895,1358954496,872415232,1795162112,3224646708,4257662662,3224646708,2147483648,2147483648,3817968017,4206673084,4223647679,4019952539,3613812326,3157077293,2869101315,3461238350,4104628135,3590324224,4294508544,3815702528,3698589696,4073127936,4073127936,3598123008,2720661504,1543503872,1107296256,1929379840,3616538624,4057071616,2801795072,3870294016,4209246208,4226351104,4022140928,3615162368,3157852160,2869100544,3462266880,4090298368,3405774848,4294508544,3663659008,3355443200,4294508544,3261661184,1325400064,687865856,1476395008,2720661504,3598123008,4073127936,4073127936,3598123008,2720661504,2231369728,2902458368,4294508544,3261661184,2080374784,2768240640,4294508544,3261661184,2080374784,3261661184,4294508544,3355443200,3663659008,4294508544,2533359616,822083584,
			520093696,1962934272,4022817026,4294132225,4294521600,4294253056,4293920768,4293591296,4293197824,4293132288,4292935680,4292804608,4292804608,4292804608,4292935936,4293135104,4242084099,4072214529,3597801734,3023440387,2231369728,1577058304,956301312,452984832,117440512,16777216,0,0,0,352321536,1627389952,3530502912,4294929408,4294791936,4294592513,4158276864,3444975876,2535986688,1006632960,150994944,234881024,1006632960,1929379840,2449473536,2483027968,2164260864,1694498816,1258291200,1174405120,1610612736,1929379840,1459617792,1124073472,1660944384,2130706432,2264924160,2348810240,1744830464,687865856,436207616,1023410176,1694498816,2197815296,2348810240,1962934272,1224736768,989855744,1761607680,2348810240,1744830464,1140850688,1744830464,2348810240,1744830464,721420288,721420288,1744830464,2348810240,2197815296,2164260864,2449473536,2483027968,2164260864,1694498816,1258291200,1174405120,1610612736,2063597568,2248146944,2348810240,2164260864,2164260864,2348810240,1744830464,637534208,184549376,704643072,1728053248,2281701376,1728053248,939524096,1124073472,1929379840,2449473536,2483027968,2164260864,1694498816,1258291200,1174405120,1610612736,2483027968,3305111552,4294508544,3563126784,2449473536,2214592512,2147483648,1677721600,1023410176,402653184,234881024,788529152,1660944384,1996488704,1828716544,2030043136,2449473536,2483027968,2164260864,1694498816,1258291200,1174405120,1610612736,2063597568,2248146944,2348810240,2164260864,2164260864,2348810240,1744830464,637534208,150994944,402653184,1023410176,1677721600,2147483648,2147483648,1677721600,1023410176,905969664,1744830464,2348810240,1744830464,1140850688,1744830464,2348810240,1744830464,1140850688,1744830464,2348810240,2164260864,2164260864,2348810240,1677721600,503316480,
			318767104,1375731712,3059226113,3699846145,3869130506,4022230030,4141306627,4226171904,4260378112,4260178176,4259914240,4191428864,4089652224,3936955141,3648853506,3361147392,2887846915,2248146944,1694498816,1191182336,721420288,335544320,83886080,16777216,0,0,0,0,0,117440512,989855744,2585332736,4039860480,3784984577,3226543360,2382364672,1728053248,989855744,318767104,33554432,50331648,234881024,536870912,771751936,788529152,620756992,385875968,167772160,134217728,352321536,520093696,369098752,234881024,436207616,620756992,671088640,721420288,503316480,134217728,33554432,150994944,385875968,637534208,721420288,520093696,234881024,184549376,503316480,721420288,503316480,268435456,503316480,721420288,503316480,134217728,134217728,503316480,721420288,637534208,620756992,771751936,788529152,620756992,385875968,167772160,134217728,352321536,587202560,671088640,721420288,620756992,620756992,721420288,503316480,134217728,0,134217728,469762048,687865856,469762048,167772160,234881024,536870912,771751936,788529152,620756992,385875968,167772160,134217728,352321536,1258291200,2734686208,4294508544,3278503936,1476395008,754974720,620756992,385875968,150994944,33554432,16777216,150994944,436207616,570425344,503316480,587202560,771751936,788529152,620756992,385875968,167772160,134217728,352321536,587202560,671088640,721420288,620756992,620756992,721420288,503316480,134217728,0,33554432,150994944,385875968,620756992,620756992,385875968,150994944,150994944,503316480,721420288,503316480,268435456,503316480,721420288,503316480,268435456,503316480,721420288,620756992,620756992,721420288,503316480,134217728,
			67108864,503316480,1224736768,1744830464,1979711488,2181038080,2382364672,2533359616,2634022912,2634022912,2600468480,2466250752,2298478592,2046820352,1728053248,1409286144,1073741824,704643072,385875968,167772160,50331648,0,0,0,0,0,0,0,0,16777216,419430400,1342177280,1979711488,1862270976,1342177280,822083584,419430400,150994944,33554432,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,503316480,1677721600,2348810240,1744830464,637534208,67108864,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,50331648,234881024,419430400,536870912,637534208,738197504,822083584,855638016,872415232,838860800,788529152,687865856,570425344,419430400,251658240,117440512,33554432,0,0,0,0,0,0,0,0,0,0,0,0,67108864,335544320,536870912,469762048,234881024,50331648,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,134217728,503316480,721420288,503316480,134217728,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		]));
		return bmp;
	}

	private var border:int = 5;

	public function Logo() {
		graphics.beginFill(0xFF0000, 0);
		graphics.drawRect(0, 0, image.width + border + border, image.height + border + border);
		graphics.drawRect(border, border, image.width, image.height);
		graphics.beginBitmapFill(image, new Matrix(1, 0, 0, 1, border, border), false, true);
		graphics.drawRect(border, border, image.width, image.height);

		tabEnabled = false;
		buttonMode = true;
		useHandCursor = true;

		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.CLICK, onClick);
		addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseMove);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
	}

	private function onMouseDown(e:MouseEvent):void {
		e.stopPropagation();
	}

	private function onClick(e:MouseEvent):void {
		e.stopPropagation();
		try {
			navigateToURL(new URLRequest("http://alternativaplatform.com"), "_blank");
		} catch (e:Error) {
		}
	}

	private function onDoubleClick(e:MouseEvent):void {
		e.stopPropagation();
	}

	private static const normal:ColorTransform = new ColorTransform();
	private static const highlighted:ColorTransform = new ColorTransform(1.1, 1.1, 1.1, 1);

	private function onMouseMove(e:MouseEvent):void {
		e.stopPropagation();
		transform.colorTransform = highlighted;
	}

	private function onMouseOut(e:MouseEvent):void {
		e.stopPropagation();
		transform.colorTransform = normal;
	}

	private function onMouseWheel(e:MouseEvent):void {
		e.stopPropagation();
	}

}
