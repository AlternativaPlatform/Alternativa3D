/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.controllers {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Transform3D;

	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	use namespace alternativa3d;

	/**
	 * Controller for <code>Object3D</code>. Allow to handle the object with a keyboard and mouse.
	 *
	 * @see alternativa.engine3d.core.Object3D
	 */
	public class SimpleObjectController {
	
		/**
		 * Name of action for binding "forward" action.
		 */
		public static const ACTION_FORWARD:String = "ACTION_FORWARD";
		
		/**
		 * Name of action for binding "back" action.
		 */
		public static const ACTION_BACK:String = "ACTION_BACK";
		
		/**
		 * Name of action for binding "left" action.
		 */
		public static const ACTION_LEFT:String = "ACTION_LEFT";
		
		/**
		 * Name of action for binding "right" action.
		 */
		public static const ACTION_RIGHT:String = "ACTION_RIGHT";
		
		/**
		 * Name of action for binding "up" action.
		 */
		public static const ACTION_UP:String = "ACTION_UP";
		
		/**
		 * Name of action for binding "down" action.
		 */
		public static const ACTION_DOWN:String = "ACTION_DOWN";
		
		/**
		 * Name of action for binding "pitch up" action.
		 */
		public static const ACTION_PITCH_UP:String = "ACTION_PITCH_UP";
		
		/**
		 * Name of action for binding "pitch down" action.
		 */
		public static const ACTION_PITCH_DOWN:String = "ACTION_PITCH_DOWN";
		
		/**
		 * Name of action for binding "yaw left" action.
		 */
		public static const ACTION_YAW_LEFT:String = "ACTION_YAW_LEFT";
		
		/**
		 * Name of action for binding "yaw right" action.
		 */
		public static const ACTION_YAW_RIGHT:String = "ACTION_YAW_RIGHT";
		
		/**
		 * Name of action for binding "accelerate" action.
		 */
		public static const ACTION_ACCELERATE:String = "ACTION_ACCELERATE";
		
		/**
		 * ИName of action for binding "mouse look" action.
		 */
		public static const ACTION_MOUSE_LOOK:String = "ACTION_MOUSE_LOOK";
	
		/**
		 * Speed.
		 */
		public var speed:Number;
		
		/**
		 * Speed multiplier for acceleration mode.
		 */
		public var speedMultiplier:Number;
		
		/**
		 * Mouse sensitivity.
		 */
		public var mouseSensitivity:Number;
		
		/**
		 * The maximal slope in the vertical plane in radians.
		 */
		public var maxPitch:Number = 1e+22;
		
		/**
		 * The minimal slope in the vertical plane in radians.
		 */
		public var minPitch:Number = -1e+22;
	
		private var eventSource:InteractiveObject;
		private var _object:Object3D;
	
		private var _up:Boolean;
		private var _down:Boolean;
		private var _forward:Boolean;
		private var _back:Boolean;
		private var _left:Boolean;
		private var _right:Boolean;
		private var _accelerate:Boolean;
	
		private var displacement:Vector3D = new Vector3D();
		private var mousePoint:Point = new Point();
		private var mouseLook:Boolean;
		private var objectPosition:Vector3D = new Vector3D();
		private var objectRotation:Vector3D = new Vector3D();
	
		private var time:int;
	
		/**
		 * The hash for binding  names of action and functions. The functions should be at a form are follows:
		 * <code>
		 *     function(value:Boolean):void
		 * </code>
		 *
		 * <code>value</code> argument defines if bound key pressed down or up.
		 */
		private var actionBindings:Object = {};
		
		/**
		 * The hash for binding key codes and action names.
		 */
		protected var keyBindings:Object = {};
	
		/**
		 * Creates a SimpleObjectController object.
		 * @param eventSource Source for event listening.
		 * @param speed Speed of movement.
		 * @param mouseSensitivity Mouse sensitivity, i.e. number of degrees per each pixel of mouse movement.
		 */
		public function SimpleObjectController(eventSource:InteractiveObject, object:Object3D, speed:Number, speedMultiplier:Number = 3, mouseSensitivity:Number = 1) {
			this.eventSource = eventSource;
			this.object = object;
			this.speed = speed;
			this.speedMultiplier = speedMultiplier;
			this.mouseSensitivity = mouseSensitivity;
	
			actionBindings[ACTION_FORWARD] = moveForward;
			actionBindings[ACTION_BACK] = moveBack;
			actionBindings[ACTION_LEFT] = moveLeft;
			actionBindings[ACTION_RIGHT] = moveRight;
			actionBindings[ACTION_UP] = moveUp;
			actionBindings[ACTION_DOWN] = moveDown;
			actionBindings[ACTION_ACCELERATE] = accelerate;
	
			setDefaultBindings();
	
			enable();
		}
	
		/**
		 * Enables the controler.
		 */
		public function enable():void {
			eventSource.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			eventSource.addEventListener(KeyboardEvent.KEY_UP, onKey);
			eventSource.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			eventSource.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
	
		/**
		 * Disables the controller.
		 */
		public function disable():void {
			eventSource.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			eventSource.removeEventListener(KeyboardEvent.KEY_UP, onKey);
			eventSource.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			eventSource.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stopMouseLook();
		}
	
		private function onMouseDown(e:MouseEvent):void {
			startMouseLook();
		}
	
		private function onMouseUp(e:MouseEvent):void {
			stopMouseLook();
		}
	
		/**
		 * Enables mouse look mode.
		 */
		public function startMouseLook():void {
			mousePoint.x = eventSource.mouseX;
			mousePoint.y = eventSource.mouseY;
			mouseLook = true;
		}
	
		/**
		 * Disables mouse look mode.
		 */
		public function stopMouseLook():void {
			mouseLook = false;
		}
	
		private function onKey(e:KeyboardEvent):void {
			var method:Function = keyBindings[e.keyCode];
			if (method != null) method.call(this, e.type == KeyboardEvent.KEY_DOWN);
		}
	
		/**
		 * Target of handling.
		 */
		public function get object():Object3D {
			return _object;
		}
	
		/**
		 * @private
		 */
		public function set object(value:Object3D):void {
			_object = value;
			updateObjectTransform();
		}
	
		/**
		 * Refreshes controller state from state of handled object. Should be called if object was moved without the controller (i.e. <code>object.x = 100;</code>).
		 */
		public function updateObjectTransform():void {
			if (_object == null) return;
			if (_object.transformChanged) _object.composeTransforms();
			objectPosition.x = _object.x;
			objectPosition.y = _object.y;
			objectPosition.z = _object.z;
			objectRotation.x = _object.rotationX;
			objectRotation.y = _object.rotationY;
			objectRotation.z = _object.rotationZ;
		}
	
		/**
		 * Calculates and sets new object position.
		 */
		public function update():void {
			if (_object == null) return;
	
			var frameTime:Number = time;
			time = getTimer();
			frameTime = 0.001*(time - frameTime);
			if (frameTime > 0.1) frameTime = 0.1;
	
			var moved:Boolean = false;
	
			if (mouseLook) {
				var dx:Number = eventSource.mouseX - mousePoint.x;
				var dy:Number = eventSource.mouseY - mousePoint.y;
				mousePoint.x = eventSource.mouseX;
				mousePoint.y = eventSource.mouseY;
				objectRotation.x -= dy*Math.PI/180*mouseSensitivity;
				if (objectRotation.x > maxPitch) objectRotation.x = maxPitch;
				if (objectRotation.x < minPitch) objectRotation.x = minPitch;
				objectRotation.z -= dx*Math.PI/180*mouseSensitivity;
				moved = true;
			}
	
			displacement.x = _right ? 1 : (_left ? -1 : 0);
			displacement.y = _forward ? 1 : (_back ? -1 : 0);
			displacement.z = _up ? 1 : (_down ? -1 : 0);
			if (displacement.lengthSquared > 0) {
				if (_object is Camera3D) {
					var tmp:Number = displacement.z;
					displacement.z = displacement.y;
					displacement.y = -tmp;
				}
				deltaTransformVector(displacement);
				var displacementLength:Number = displacement.length;
				if (_accelerate) {
					displacement.x *= speedMultiplier * speed * frameTime / displacementLength;
					displacement.y *= speedMultiplier * speed * frameTime / displacementLength;
					displacement.z *= speedMultiplier * speed * frameTime / displacementLength;
				} else {
					displacement.x *= speed * frameTime / displacementLength;
					displacement.y *= speed * frameTime / displacementLength;
					displacement.z *= speed * frameTime / displacementLength;
				}

				objectPosition.x += displacement.x;
				objectPosition.y += displacement.y;
				objectPosition.z += displacement.z;
				moved = true;
			}
	
			if (moved) {
				_object.x = objectPosition.x;
				_object.y = objectPosition.y;
				_object.z = objectPosition.z;
				_object.rotationX = objectRotation.x;
				_object.rotationY = objectRotation.y;
				_object.rotationZ = objectRotation.z;
			}
		}
	
		/**
		 * Sets object at given position.
		 * @param pos The position.
		 */
		public function setObjectPos(pos:Vector3D):void {
			if (_object != null) {
				objectPosition.x = pos.x;
				objectPosition.y = pos.y;
				objectPosition.z = pos.z;
			}
		}
	
		/**
		 * Sets object at given position.
		 * @param x  X.
		 * @param y  Y.
		 * @param z  Z.
		 */
		public function setObjectPosXYZ(x:Number, y:Number, z:Number):void {
			if (_object != null) {
				objectPosition.x = x;
				objectPosition.y = y;
				objectPosition.z = z;
			}
		}
	
		/**
		 * Sets direction of Z-axis of handled object to pointed at given place. If object is a camera, it will look to this direction.
		 * @param point Point to look at.
		 */
		public function lookAt(point:Vector3D):void {
			lookAtXYZ(point.x, point.y, point.z);
		}
	
		/**
		 * Sets direction of Z-axis of handled object to pointed at given place. If object is a camera, it will look to this direction.
		 * @param x  X.
		 * @param y  Y.
		 * @param z  Z.
		 */
		public function lookAtXYZ(x:Number, y:Number, z:Number):void {
			if (_object == null) return;
			var dx:Number = x - objectPosition.x;
			var dy:Number = y - objectPosition.y;
			var dz:Number = z - objectPosition.z;
			objectRotation.x = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy));
			if (_object is Camera3D) objectRotation.x -= 0.5*Math.PI;
			objectRotation.y = 0;
			objectRotation.z = -Math.atan2(dx, dy);

			_object.x = objectPosition.x;
			_object.y = objectPosition.y;
			_object.z = objectPosition.z;
			_object.rotationX = objectRotation.x;
			_object.rotationY = objectRotation.y;
			_object.rotationZ = objectRotation.z;
		}
	
		private function deltaTransformVector(v:Vector3D):void {
			var inx:Number = v.x;
			var iny:Number = v.y;
			var inz:Number = v.z;
			if (_object.transformChanged) _object.composeTransforms();
			var trm:Transform3D = _object.transform;
			v.x = inx * trm.a + iny * trm.b + inz * trm.c + trm.d - objectPosition.x;
			v.y = inx * trm.e + iny * trm.f + inz * trm.g + trm.h - objectPosition.y;
			v.z = inx * trm.i + iny * trm.j + inz * trm.k + trm.l - objectPosition.z;
		}
	
		/**
		 * Starts and stops move forward according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveForward(value:Boolean):void {
			_forward = value;
		}

		/**
		 * Starts and stops move backward according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveBack(value:Boolean):void {
			_back = value;
		}

		/**
		 * Starts and stops move to left according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveLeft(value:Boolean):void {
			_left = value;
		}

		/**
		 * Starts and stops move to right according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveRight(value:Boolean):void {
			_right = value;
		}

		/**
		 * Starts and stops move up according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveUp(value:Boolean):void {
			_up = value;
		}

		/**
		 * Starts and stops move down according to  <code>true</code> or <code>false</code> was passed.
		 * @param value Action switcher.
		 */
		public function moveDown(value:Boolean):void {
			_down = value;
		}
	
		/**
		 * Switches acceleration mode.
		 * @param value <code>true</code> turns acceleration on, <code>false</code> turns off.
		 */
		public function accelerate(value:Boolean):void {
			_accelerate = value;
		}

		/**
		 * Binds key and action. Only one action can be assigned to one key.
		 * @param keyCode Key code.
		 * @param action Action name.
		 * @see #unbindKey()
		 * @see #unbindAll()
		 */
		public function bindKey(keyCode:uint, action:String):void {
			var method:Function = actionBindings[action];
			if (method != null) keyBindings[keyCode] = method;
		}

		/**
		 * Binds keys and actions. Only one action can be assigned to one key.
		 * @param bindings Array which consists of sequence of couples of key code and action. An example are follows: <code> [ keyCode1, action1, keyCode2, action2 ] </code>.
		 */
		public function bindKeys(bindings:Array):void {
			for (var i:int = 0; i < bindings.length; i += 2) bindKey(bindings[i], bindings[i + 1]);
		}

		/**
		 * Clear binding for given keyCode.
		 * @param keyCode Key code.
		 * @see #bindKey()
		 * @see #unbindAll()
		 */
		public function unbindKey(keyCode:uint):void {
			delete keyBindings[keyCode];
		}
	
		/**
		 * Clear binding of all keys.
		 * @see #bindKey()
		 * @see #unbindKey()
		 */
		public function unbindAll():void {
			for (var key:String in keyBindings) delete keyBindings[key];
		}
	
		/**
		 * Sets default binding.
		 * @see #bindKey()
		 * @see #unbindKey()
		 * @see #unbindAll()
		 */
		public function setDefaultBindings():void {
			bindKey(87, ACTION_FORWARD);
			bindKey(83, ACTION_BACK);
			bindKey(65, ACTION_LEFT);
			bindKey(68, ACTION_RIGHT);
			bindKey(69, ACTION_UP);
			bindKey(67, ACTION_DOWN);
			bindKey(Keyboard.SHIFT, ACTION_ACCELERATE);
	
			bindKey(Keyboard.UP, ACTION_FORWARD);
			bindKey(Keyboard.DOWN, ACTION_BACK);
			bindKey(Keyboard.LEFT, ACTION_LEFT);
			bindKey(Keyboard.RIGHT, ACTION_RIGHT);
		}
	
	}
}
