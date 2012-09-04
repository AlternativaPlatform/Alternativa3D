/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.core.events.Event3D;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.objects.Surface;

	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	use namespace alternativa3d;

	/**
	 * Dispatches when an <code>Object3D</code> is added  as a child to another <code>Object3D</code>.
	 * Following methods generate this event:  <code>Object3D.addChild()</code>, <code>Object3D.addChildAt()</code>.
	 *
	 * @see #addChild()
	 * @see #addChildAt()
	 *
	 * @eventType alternativa.engine3d.core.events.Event3D.ADDED
	 */
	[Event(name="added",type="alternativa.engine3d.core.events.Event3D")]

	/**
	 * Dispatched when a  <code>Object3D</code> is about to be removed from the children list.
	 * Following methods generate this event: <code>Object3D.removeChild()</code> and <code>Object3D.removeChildAt()</code>.
	 *
	 * @see #removeChild()
	 * @see #removeChildAt()
	 * @eventType alternativa.engine3d.core.events.Event3D.REMOVED
	 */
	[Event(name="removed",type="alternativa.engine3d.core.events.Event3D")]

	/**
	 * Dispatched when a user presses and releases the main button
	 * of the user's pointing device over the same <code>Object3D</code>.
	 * Any other evens can occur between pressing and releasing the button.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.CLICK
	 */
	[Event (name="click", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses and releases the main button of
	 * a pointing device twice in rapid succession over the same <code>Object3D</code>.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.DOUBLE_CLICK
	 */
	[Event (name="doubleClick", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses and releases the middle button
	 * of the user's pointing device over the same <code>Object3D</code>.
	 * Any other evens can occur between pressing and releasing the button.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MIDDLE_CLICK
	 */
	[Event (name="middleClick", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses the middle pointing device button over an <code>Object3D</code> instance.
	 * Any other evens can occur between pressing and releasing the button.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MIDDLE_MOUSE_DOWN
	 */
	[Event (name="middleMouseDown", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user releases the pointing device button over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MIDDLE_MOUSE_UP
	 */
	[Event (name="middleMouseUp", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses the pointing device button over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_DOWN
	 */
	[Event (name="mouseDown", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user moves the pointing device while it is over an <code>Object3D</code>.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_MOVE
	 */
	[Event (name="mouseMove", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user releases the pointing device button over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_UP
	 */
	[Event (name="mouseUp", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * 	Dispatched when the user moves a pointing device away from an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_OUT
	 */
	[Event (name="mouseOut", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when the user moves a pointing device over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_OVER
	 */
	[Event (name="mouseOver", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * 	Dispatched when a mouse wheel is spun over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_WHEEL
	 */
	[Event (name="mouseWheel", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses and releases the right button
	 * of the user's pointing device over the same <code>Object3D</code>.
	 * Any other evens can occur between pressing and releasing the button.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.CLICK
	 */
	[Event (name="rightClick", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user presses the right pointing device button over an <code>Object3D</code> instance.
	 * Any other evens can occur between pressing and releasing the button.
	 *
	 * @eventType alternativa.engine3d.events.MouseEvent3D.CLICK
	 */
	[Event (name="rightMouseDown", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * Dispatched when a user releases the pointing device button over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.MOUSE_UP
	 */
	[Event (name="rightMouseUp", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * 	Dispatched when the user moves a pointing device over an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.ROLL_OVER
	 */
	[Event (name="rollOver", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * 	Dispatched when the user moves a pointing device away from an <code>Object3D</code> instance.
	 * @eventType alternativa.engine3d.events.MouseEvent3D.ROLL_OUT
	 */
	[Event (name="rollOut", type="alternativa.engine3d.core.events.MouseEvent3D")]

	/**
	 * <code>Object3D</code> class ia a base class for all 3D objects. Any <code>Object3D</code> has a property
	 * of transformation that defines its position in space, the property <code>boundBox</code>,
	 * which describes the rectangular parallelepiped into which fits this 3D object.
	 * The last feature of this class is the one place in the 3d hierarchy like
	 * <code>DisplayObject</code> has its own place in Display List.
	 * Unlike the previous version Alternativa3D, an instance of this class can contain many children,
	 * so it can act as a container. This also applies to all the inheritors <code>Object3D</code> .
	 *
	 * @see alternativa.engine3d.objects.Mesh
	 * @see alternativa.engine3d.core.BoundBox
	 */
	public class Object3D implements IEventDispatcher {

		// Mouse moving
		private static const MOUSE_MOVE_BIT:uint = 1;
		private static const MOUSE_OVER_BIT:uint = 2;
		private static const MOUSE_OUT_BIT:uint = 4;
		private static const ROLL_OVER_BIT:uint = 0x8;
		private static const ROLL_OUT_BIT:uint = 0x10;
		private static const USE_HAND_CURSOR_BIT:uint = 0x20;

		// Mouse pressing
		private static const MOUSE_DOWN_BIT:uint = 0x40;
		private static const MOUSE_UP_BIT:uint = 0x80;
		private static const CLICK_BIT:uint = 0x100;
		private static const DOUBLE_CLICK_BIT:uint = 0x200;

		// Mouse wheel
		private static const MOUSE_WHEEL_BIT:uint = 0x400;

		// Mouse middle button
		private static const MIDDLE_CLICK_BIT:uint = 0x800;
		private static const MIDDLE_MOUSE_DOWN_BIT:uint = 0x1000;
		private static const MIDDLE_MOUSE_UP_BIT:uint = 0x2000;

		// Mouse right button
		private static const RIGHT_CLICK_BIT:uint = 0x4000;
		private static const RIGHT_MOUSE_DOWN_BIT:uint = 0x8000;
		private static const RIGHT_MOUSE_UP_BIT:uint = 0x10000;

		/**
		 * @private
		 */
		alternativa3d static const MOUSE_HANDLING_MOVING:uint = MOUSE_MOVE_BIT | MOUSE_OVER_BIT | MOUSE_OUT_BIT | ROLL_OVER_BIT | ROLL_OUT_BIT | USE_HAND_CURSOR_BIT;
		/**
		 * @private
		 */
		alternativa3d static const MOUSE_HANDLING_PRESSING:uint = MOUSE_DOWN_BIT | MOUSE_UP_BIT | CLICK_BIT | DOUBLE_CLICK_BIT;
		/**
		 * @private
		 */
		alternativa3d static const MOUSE_HANDLING_WHEEL:uint = MOUSE_WHEEL_BIT;
		/**
		 * @private
		 */
		alternativa3d static const MOUSE_HANDLING_MIDDLE_BUTTON:uint = MIDDLE_CLICK_BIT | MIDDLE_MOUSE_DOWN_BIT | MIDDLE_MOUSE_UP_BIT;
		/**
		 * @private
		 */
		alternativa3d static const MOUSE_HANDLING_RIGHT_BUTTON:uint = RIGHT_CLICK_BIT | RIGHT_MOUSE_DOWN_BIT | RIGHT_MOUSE_UP_BIT;

		/**
		 * Custom data available to store within <code>Object3D</code> by user.
		 */
		public var userData:Object;

		/**
		 * @private
		 */
		public var useShadow:Boolean = true;

		/**
		 * @private
		 */
		alternativa3d var _excludedLights:Vector.<Light3D> = new Vector.<Light3D>();

		/**
		 * @private
		 */
		alternativa3d static const trm:Transform3D = new Transform3D();

		/**
		 * Name of the object.
		 */
		public var name:String;

		/**
		 * Whether or not the display object is visible.
		 */
		public var visible:Boolean = true;

		/**
		 * Specifies whether this object receives mouse, or other user input, messages.
		 * The default value is  <code>true</code>.
		 *
		 * The behaviour is consistent with behaviour of <code>flash.display.InteractiveObject</code>.
		 *
		 */
		public var mouseEnabled:Boolean = true;

		/**
		 * Determines whether or not the children of the object are mouse, or user input device, enabled.
		 * In case of  <code>false</code>, the value of <code>target</code>  property of the event
		 * will be the self <code>Object3D</code>  wether mouse pointed on it  or on its child.
		 * The default value is   <code>true</code>.
		 */
		public var mouseChildren:Boolean = true;

		/**
		 * Specifies whether the object receives <code>doubleClick</code> events.
		 * The default value is false, which means that by default an Object3D
		 * instance does not receive <code>doubleClick</code> events.
		 *
		 * The <code>doubleClickEnabled</code> property of current <code>stage</code> also should be <code>true</code>.
		 */
		public var doubleClickEnabled:Boolean = false;

		/**
		 * Bounds of the object described as rectangular parallelepiped.
		 */
		public var boundBox:BoundBox;

		/**
		 * @private
		 */
		alternativa3d var _x:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _y:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _z:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _rotationX:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _rotationY:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _rotationZ:Number = 0;

		/**
		 * @private
		 */
		alternativa3d var _scaleX:Number = 1;

		/**
		 * @private
		 */
		alternativa3d var _scaleY:Number = 1;

		/**
		 * @private
		 */
		alternativa3d var _scaleZ:Number = 1;

		/**
		 * @private
		 */
		alternativa3d var _parent:Object3D;

		/**
		 * @private
		 */
		alternativa3d var childrenList:Object3D;

		/**
		 * @private
		 */
		alternativa3d var next:Object3D;

		/**
		 * @private
		 */
		alternativa3d var transform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var inverseTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var transformChanged:Boolean = true;

		/**
		 * @private
		 */
		alternativa3d var cameraToLocalTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var localToCameraTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var localToGlobalTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var globalToLocalTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var localToLightTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var lightToLocalTransform:Transform3D = new Transform3D();

		/**
		 * @private
		 */
		alternativa3d var culling:int;

		/**
		 * @private
		 */
		alternativa3d var listening:Boolean;

		/**
		 * @private
		 */
		alternativa3d var mouseHandlingType:uint = 0;

		/**
		 * @private
		 */
		alternativa3d var distance:Number;

		/**
		 * @private
		 */
		alternativa3d var bubbleListeners:Object;

		/**
		 * @private
		 */
		alternativa3d var captureListeners:Object;

		/**
		 * @private
		 */
		alternativa3d var transformProcedure:Procedure;

		/**
		 * @private
		 */
		alternativa3d var deltaTransformProcedure:Procedure;

		/**
		 * X coordinate.
		 */
		public function get x():Number {
			return _x;
		}

		/**
		 * @private
		 */
		public function set x(value:Number):void {
			if (_x != value) {
				_x = value;
				transformChanged = true;
			}
		}

		/**
		 * Y coordinate.
		 */
		public function get y():Number {
			return _y;
		}

		/**
		 * @private
		 */
		public function set y(value:Number):void {
			if (_y != value) {
				_y = value;
				transformChanged = true;
			}
		}

		/**
		 *  Z coordinate.
		 */
		public function get z():Number {
			return _z;
		}

		/**
		 * @private
		 */
		public function set z(value:Number):void {
			if (_z != value) {
				_z = value;
				transformChanged = true;
			}
		}

		/**
		 *  The  angle of rotation of <code>Object3D</code> around the X-axis expressed in radians.
		 */
		public function get rotationX():Number {
			return _rotationX;
		}

		/**
		 * @private
		 */
		public function set rotationX(value:Number):void {
			if (_rotationX != value) {
				_rotationX = value;
				transformChanged = true;
			}
		}

		/**
		 * The  angle of rotation of <code>Object3D</code> around the Y-axis expressed in radians.
		 */
		public function get rotationY():Number {
			return _rotationY;
		}

		/**
		 * @private
		 */
		public function set rotationY(value:Number):void {
			if (_rotationY != value) {
				_rotationY = value;
				transformChanged = true;
			}
		}

		/**
		 * The  angle of rotation of <code>Object3D</code> around the Z-axis expressed in radians.
		 */
		public function get rotationZ():Number {
			return _rotationZ;
		}

		/**
		 * @private
		 */
		public function set rotationZ(value:Number):void {
			if (_rotationZ != value) {
				_rotationZ = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the X-axis.
		 */
		public function get scaleX():Number {
			return _scaleX;
		}

		/**
		 * @private
		 */
		public function set scaleX(value:Number):void {
			if (_scaleX != value) {
				_scaleX = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the Y-axis.
		 */
		public function get scaleY():Number {
			return _scaleY;
		}

		/**
		 * @private
		 */
		public function set scaleY(value:Number):void {
			if (_scaleY != value) {
				_scaleY = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the Z-axis.
		 */
		public function get scaleZ():Number {
			return _scaleZ;
		}

		/**
		 * @private
		 */
		public function set scaleZ(value:Number):void {
			if (_scaleZ != value) {
				_scaleZ = value;
				transformChanged = true;
			}
		}

		/**
		 * The <code>matrix</code> property represents a transformation matrix that determines the position
		 * and orientation of an <code>Object3D</code>.
		 */
		public function get matrix():Matrix3D {
			if (transformChanged) composeTransforms();
			return new Matrix3D(Vector.<Number>([transform.a, transform.e, transform.i, 0, transform.b, transform.f, transform.j, 0, transform.c, transform.g, transform.k, 0, transform.d, transform.h, transform.l, 1]));
		}

		/**
		 * @private
		 */
		public function set matrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			_x = t.x;
			_y = t.y;
			_z = t.z;
			_rotationX = r.x;
			_rotationY = r.y;
			_rotationZ = r.z;
			_scaleX = s.x;
			_scaleY = s.y;
			_scaleZ = s.z;
			transformChanged = true;
		}

		/**
		 * A Boolean value that indicates whether the pointing hand (hand cursor)
		 * appears when the pointer rolls over a <code>Object3D</code>.
		 */
		public function get useHandCursor():Boolean {
			return (mouseHandlingType & USE_HAND_CURSOR_BIT) != 0;
		}

		/**
		 * @private
		 */
		public function set useHandCursor(value:Boolean):void {
			if (value) {
				mouseHandlingType |= USE_HAND_CURSOR_BIT;
			} else {
				mouseHandlingType &= ~USE_HAND_CURSOR_BIT;
			}
		}

		/**
		 * Searches for the intersection of an <code>Object3D</code> and given ray, defined by <code>origin</code> and <code>direction</code>.
		 *
		 * @param origin Origin of the ray.
		 * @param direction Direction of the ray.
		 * @return The result of searching given as <code>RayIntersectionData</code>. <code>null</code> will returned in case of intersection was not found.
		 * @see RayIntersectionData
		 * @see alternativa.engine3d.objects.Sprite3D
		 * @see alternativa.engine3d.core.Camera3D#calculateRay()
		 */
		public function intersectRay(origin:Vector3D, direction:Vector3D):RayIntersectionData {
			return intersectRayChildren(origin, direction);
		}

		/**
		 * @private
		 */
		alternativa3d function intersectRayChildren(origin:Vector3D, direction:Vector3D):RayIntersectionData {
			var minTime:Number = 1e22;
			var minData:RayIntersectionData = null;
			var childOrigin:Vector3D;
			var childDirection:Vector3D;
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.transformChanged) child.composeTransforms();
				if (childOrigin == null) {
					childOrigin = new Vector3D();
					childDirection = new Vector3D();
				}
				childOrigin.x = child.inverseTransform.a*origin.x + child.inverseTransform.b*origin.y + child.inverseTransform.c*origin.z + child.inverseTransform.d;
				childOrigin.y = child.inverseTransform.e*origin.x + child.inverseTransform.f*origin.y + child.inverseTransform.g*origin.z + child.inverseTransform.h;
				childOrigin.z = child.inverseTransform.i*origin.x + child.inverseTransform.j*origin.y + child.inverseTransform.k*origin.z + child.inverseTransform.l;
				childDirection.x = child.inverseTransform.a*direction.x + child.inverseTransform.b*direction.y + child.inverseTransform.c*direction.z;
				childDirection.y = child.inverseTransform.e*direction.x + child.inverseTransform.f*direction.y + child.inverseTransform.g*direction.z;
				childDirection.z = child.inverseTransform.i*direction.x + child.inverseTransform.j*direction.y + child.inverseTransform.k*direction.z;
				var data:RayIntersectionData = child.intersectRay(childOrigin, childDirection);
				if (data != null && data.time < minTime) {
					minData = data;
					minTime = data.time;
				}
			}
			return minData;
		}

		/**
		 * A <code>Matrix3D</code> object representing the combined transformation matrices of the <code>Object3D</code>
		 * and all of its parent objects, back to the root level.
		 */
		public function get concatenatedMatrix():Matrix3D {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			return new Matrix3D(Vector.<Number>([trm.a, trm.e, trm.i, 0, trm.b, trm.f, trm.j, 0, trm.c, trm.g, trm.k, 0, trm.d, trm.h, trm.l, 1]));
		}

		/**
		 * Converts the <code>Vector3D</code> object from the <code>Object3D</code>'s own (local) coordinates to the root <code>Object3D</code> (global) coordinates.
		 * @param point Point in local coordinates of <code>Object3D</code>.
		 * @return Point in coordinates of root <code>Object3D</code>.
		 */
		public function localToGlobal(point:Vector3D):Vector3D {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			var res:Vector3D = new Vector3D();
			res.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			res.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			res.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
			return res;
		}

		/**
		 * Converts the <code>Vector3D</code> object from the root <code>Object3D</code> (global) coordinates to the local <code>Object3D</code>'s own coordinates.
		 * @param point Point in coordinates of root <code>Object3D</code>.
		 * @return Point in local coordinates of <code>Object3D</code>.
		 */
		public function globalToLocal(point:Vector3D):Vector3D {
			if (transformChanged) composeTransforms();
			trm.copy(inverseTransform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.prepend(root.inverseTransform);
			}
			var res:Vector3D = new Vector3D();
			res.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			res.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			res.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
			return res;
		}

		/**
		 * @private
		 */
		alternativa3d function get useLights():Boolean {
			return false;
		}

		/**
		 * Calculates object's bounds in its own coordinates
		 */
		public function calculateBoundBox():void {
			if (boundBox != null) {
				boundBox.reset();
			} else {
				boundBox = new BoundBox();
			}
			// Fill values of th boundBox
			updateBoundBox(boundBox, null);
		}

		/**
		 * @private
		 */
		alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
		}

		/**
		 * Registers an event listener object with an EventDispatcher object
		 * so that the listener receives notification of an event.
		 * @param type The type of event.
		 * @param listener The listener function that processes the event.
		 * @param useCapture  Determines whether the listener works in the capture phase or the target and bubbling phases.
		 * @param priority The priority level of the event listener.
		 * @param useWeakReference Does not used.
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			if (listener == null) throw new TypeError("Parameter listener must be non-null.");
			var listeners:Object;
			if (useCapture) {
				if (captureListeners == null) captureListeners = new Object();
				listeners = captureListeners;
			} else {
				if (bubbleListeners == null) bubbleListeners = new Object();
				listeners = bubbleListeners;
			}
			var vector:Vector.<Function> = listeners[type];
			if (vector == null) {
				// There are not listeners of this type
				vector = new Vector.<Function>();
				listeners[type] = vector;

				// update mouseHandlingType bits
				switch (type) {
					case MouseEvent3D.MOUSE_MOVE:
						mouseHandlingType |= MOUSE_MOVE_BIT;
						break;
					case MouseEvent3D.MOUSE_OVER:
						mouseHandlingType |= MOUSE_OVER_BIT;
						break;
					case MouseEvent3D.MOUSE_OUT:
						mouseHandlingType |= MOUSE_OUT_BIT;
						break;
					case MouseEvent3D.ROLL_OVER:
						mouseHandlingType |= ROLL_OVER_BIT;
						break;
					case MouseEvent3D.ROLL_OUT:
						mouseHandlingType |= ROLL_OUT_BIT;
						break;
					case MouseEvent3D.MOUSE_DOWN:
						mouseHandlingType |= MOUSE_DOWN_BIT;
						break;
					case MouseEvent3D.MOUSE_UP:
						mouseHandlingType |= MOUSE_UP_BIT;
						break;
					case MouseEvent3D.CLICK:
						mouseHandlingType |= CLICK_BIT;
						break;
					case MouseEvent3D.DOUBLE_CLICK:
						mouseHandlingType |= DOUBLE_CLICK_BIT;
						break;
					case MouseEvent3D.MOUSE_WHEEL:
						mouseHandlingType |= MOUSE_WHEEL_BIT;
						break;
					case MouseEvent3D.MIDDLE_CLICK:
						mouseHandlingType |= MIDDLE_CLICK_BIT;
						break;
					case MouseEvent3D.MIDDLE_MOUSE_DOWN:
						mouseHandlingType |= MIDDLE_MOUSE_DOWN_BIT;
						break;
					case MouseEvent3D.MIDDLE_MOUSE_UP:
						mouseHandlingType |= MIDDLE_MOUSE_UP_BIT;
						break;
					case MouseEvent3D.RIGHT_CLICK:
						mouseHandlingType |= RIGHT_CLICK_BIT;
						break;
					case MouseEvent3D.RIGHT_MOUSE_DOWN:
						mouseHandlingType |= RIGHT_MOUSE_DOWN_BIT;
						break;
					case MouseEvent3D.RIGHT_MOUSE_UP:
						mouseHandlingType |= RIGHT_MOUSE_UP_BIT;
						break;
				}
			}
			if (vector.indexOf(listener) < 0) {
				vector.push(listener);
			}
		}

		/**
		 * Removes a listener from the EventDispatcher object.
		 * @param type The type of event.
		 * @param listener The listener object to remove.
		 * @param useCapture Specifies whether the listener was registered for the capture phase or the target and bubbling phases.
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			if (listener == null) throw new TypeError("Parameter listener must be non-null.");
			var listeners:Object = useCapture ? captureListeners : bubbleListeners;
			if (listeners != null) {
				var vector:Vector.<Function> = listeners[type];
				if (vector != null) {
					var i:int = vector.indexOf(listener);
					if (i >= 0) {
						var length:int = vector.length;
						for (var j:int = i + 1; j < length; j++,i++) {
							vector[i] = vector[j];
						}
						if (length > 1) {
							vector.length = length - 1;
						} else {
							// update mouseHandlingType bits
							var noListeners:Boolean;
							if (listeners == captureListeners) {
								noListeners = (bubbleListeners == null || bubbleListeners[type] == null);
							} else {
								noListeners = (captureListeners == null || captureListeners[type] == null);
							}
							if (noListeners) {
								switch (type) {
									case MouseEvent3D.MOUSE_MOVE:
										mouseHandlingType &= ~MOUSE_MOVE_BIT;
										break;
									case MouseEvent3D.MOUSE_OVER:
										mouseHandlingType &= ~MOUSE_OVER_BIT;
										break;
									case MouseEvent3D.MOUSE_OUT:
										mouseHandlingType &= ~MOUSE_OUT_BIT;
										break;
									case MouseEvent3D.ROLL_OVER:
										mouseHandlingType &= ~ROLL_OVER_BIT;
										break;
									case MouseEvent3D.ROLL_OUT:
										mouseHandlingType &= ~ROLL_OUT_BIT;
										break;
									case MouseEvent3D.MOUSE_DOWN:
										mouseHandlingType &= ~MOUSE_DOWN_BIT;
										break;
									case MouseEvent3D.MOUSE_UP:
										mouseHandlingType &= ~MOUSE_UP_BIT;
										break;
									case MouseEvent3D.CLICK:
										mouseHandlingType &= ~CLICK_BIT;
										break;
									case MouseEvent3D.DOUBLE_CLICK:
										mouseHandlingType &= ~DOUBLE_CLICK_BIT;
										break;
									case MouseEvent3D.MOUSE_WHEEL:
										mouseHandlingType &= ~MOUSE_WHEEL_BIT;
										break;
									case MouseEvent3D.MIDDLE_CLICK:
										mouseHandlingType &= ~MIDDLE_CLICK_BIT;
										break;
									case MouseEvent3D.MIDDLE_MOUSE_DOWN:
										mouseHandlingType &= ~MIDDLE_MOUSE_DOWN_BIT;
										break;
									case MouseEvent3D.MIDDLE_MOUSE_UP:
										mouseHandlingType &= ~MIDDLE_MOUSE_UP_BIT;
										break;
									case MouseEvent3D.RIGHT_CLICK:
										mouseHandlingType &= ~RIGHT_CLICK_BIT;
										break;
									case MouseEvent3D.RIGHT_MOUSE_DOWN:
										mouseHandlingType &= ~RIGHT_MOUSE_DOWN_BIT;
										break;
									case MouseEvent3D.RIGHT_MOUSE_UP:
										mouseHandlingType &= ~RIGHT_MOUSE_UP_BIT;
										break;
								}
							}

							delete listeners[type];

							var key:*;
							for (key in listeners) break;
							if (!key) {
								if (listeners == captureListeners) {
									captureListeners = null;
								} else {
									bubbleListeners = null;
								}
							}
						}
					}
				}
			}
		}

		/**
		 * Checks whether the EventDispatcher object has any listeners registered for a specific type of event.
		 * @param type The type of event.
		 * @return A value of true if a listener of the specified type is registered; false otherwise.
		 */
		public function hasEventListener(type:String):Boolean {
			return captureListeners != null && captureListeners[type] || bubbleListeners != null && bubbleListeners[type];
		}

		/**
		 * Checks whether an event listener is registered with this EventDispatcher object or any of its ancestors for the specified event type.
		 * @param type  The type of event.
		 * @return A value of true if a listener of the specified type will be triggered; false otherwise.
		 */
		public function willTrigger(type:String):Boolean {
			for (var object:Object3D = this; object != null; object = object._parent) {
				if (object.captureListeners != null && object.captureListeners[type] || object.bubbleListeners != null && object.bubbleListeners[type]) return true;
			}
			return false;
		}

		/**
		 * Dispatches an <code>event</code> into the event flow. In case of  dispatched event extends <code>Event</code> class, properties <code>target</code> and  <code>currentTarget</code>
		 * will not be set. They will be set if  dispatched event extends <code>Event3D</code> oe subclasses.
		 * @param event The <code>Event</code> object that is dispatched into the event flow.
		 * @return A value of <code>true</code> if the event was successfully dispatched. Otherwise returns <code>false</code>.
		 */
		public function dispatchEvent(event:Event):Boolean {
			if (event == null) throw new TypeError("Parameter event must be non-null.");
			var event3D:Event3D = event as Event3D;
			if (event3D != null) {
				event3D._target = this;
			}
			var branch:Vector.<Object3D> = new Vector.<Object3D>();
			var branchLength:int = 0;
			var object:Object3D;
			var i:int;
			var j:int;
			var length:int;
			var vector:Vector.<Function>;
			var functions:Vector.<Function>;
			for (object = this; object != null; object = object._parent) {
				branch[branchLength] = object;
				branchLength++;
			}
			// capture phase
			for (i = branchLength - 1; i > 0; i--) {
				object = branch[i];
				if (event3D != null) {
					event3D._currentTarget = object;
					event3D._eventPhase = EventPhase.CAPTURING_PHASE;
				}

				if (object.captureListeners != null) {
					vector = object.captureListeners[event.type];
					if (vector != null) {
						length = vector.length;
						functions = new Vector.<Function>();
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) (functions[j] as Function).call(null, event);
					}
				}
			}
			if (event3D != null) {
				event3D._eventPhase = EventPhase.AT_TARGET;
			}
			// target + bubbles phases
			for (i = 0; i < branchLength; i++) {
				object = branch[i];
				if (event3D != null) {
					event3D._currentTarget = object;
					if (i > 0) {
						event3D._eventPhase = EventPhase.BUBBLING_PHASE;
					}
				}
				if (object.bubbleListeners != null) {
					vector = object.bubbleListeners[event.type];
					if (vector != null) {
						length = vector.length;
						functions = new Vector.<Function>();
						for (j = 0; j < length; j++) functions[j] = vector[j];
						for (j = 0; j < length; j++) (functions[j] as Function).call(null, event);
					}
				}
				if (!event.bubbles) break;
			}
			return true;
		}

		/**
		 * <code>Object3D</code>, to which this object was added as a child.
		 */
		public function get parent():Object3D {
			return _parent;
		}

		/**
		 * @private
		 */
		alternativa3d function removeFromParent():void {
			if (_parent != null) {
				_parent.removeFromList(this);
				_parent = null;
			}
		}

		/**
		 *  Adds given <code>Object3D</code> instance as a child to the end of this <code>Object3D</code>'s children list.
		 *  If the given object was added to another <code>Object3D</code> already, it removes from it's old place.
		 * @param child The <code>Object3D</code> instance to add.
		 * @return The <code>Object3D</code> instance that you pass in the <code>child</code> parameter.
		 */
		public function addChild(child:Object3D):Object3D {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3D = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Adding
			if (child._parent != this) {
				// Removing from old place
				if (child._parent != null) child._parent.removeChild(child);
				// Adding
				addToList(child);
				child._parent = this;
				// Dispatching the event
				if (child.willTrigger(Event3D.ADDED)) child.dispatchEvent(new Event3D(Event3D.ADDED, true));
			} else {
				child = removeFromList(child);
				if (child == null) throw new ArgumentError("Cannot add child.");
				// Adding
				addToList(child);
			}
			return child;
		}

		/**
		 * Removes the specified child <code>Object3D</code> instance from the child list of the
		 * this <code>Object3D</code> instance. The <code>parent</code> property of the removed child is set to <code>null</code>.
		 *
		 * @param child The <code>Object3D</code> instance to remove.
		 * @return The <code>Object3D</code> instance that you pass in the <code>child</code> parameter.
		 */
		public function removeChild(child:Object3D):Object3D {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			child = removeFromList(child);
			if (child == null) throw new ArgumentError("Cannot remove child.");
			// Dispatching the event
			if (child.willTrigger(Event3D.REMOVED)) child.dispatchEvent(new Event3D(Event3D.REMOVED, true));
			child._parent = null;
			return child;
		}

		/**
		 * Adds a child <code>Object3D</code> instance to this <code>Object3D</code> instance. The child is added at the index position specified.
		 * @param child The <code>Object3D</code> instance to add as a child of this <code>Object3D</code> instance.
		 * @param index The index position to which the child is added.
		 * @return The <code>Object3D</code> instance that you pass in the child parameter.
		 */
		public function addChildAt(child:Object3D, index:int):Object3D {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			for (var container:Object3D = _parent; container != null; container = container._parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Search for element by index
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			// Adding
			if (child._parent != this) {
				// Removing from old parent
				if (child._parent != null) child._parent.removeChild(child);
				// Adding
				addToList(child, current);
				child._parent = this;
				// Dispatching the event
				if (child.willTrigger(Event3D.ADDED)) child.dispatchEvent(new Event3D(Event3D.ADDED, true));
			} else {
				child = removeFromList(child);
				if (child == null) throw new ArgumentError("Cannot add child.");
				// Adding
				addToList(child, current);
			}
			return child;
		}

		/**
		 * Removes a child <code>Object3D</code> from the specified index position in the child list of
		 * the <code>Object3D</code>. The parent property of the removed child is set to <code>null</code>.
		 *
		 * @param index The child index of the <code>Object3D</code> to remove.
		 * @return The <code>Object3D</code> instance that was removed.
		 */
		public function removeChildAt(index:int):Object3D {
			//  Error checking
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Search for element by index
			var child:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (child == null) throw new RangeError("The supplied index is out of bounds.");
				child = child.next;
			}
			if (child == null) throw new RangeError("The supplied index is out of bounds.");
			// Removing
			removeFromList(child);
			// Dispatching the event
			if (child.willTrigger(Event3D.REMOVED)) child.dispatchEvent(new Event3D(Event3D.REMOVED, true));
			child._parent = null;
			return child;
		}
		
		/**
		 * Removes child objects in given range of indexes.
		 * @param beginIndex Index, starts from which objects should be removed.
		 * @param endIndex Index, till which objects should be removed.
		 */
		public function removeChildren(beginIndex:int = 0, endIndex:int = 2147483647):void {
			// Error checking
			if (beginIndex < 0) throw new RangeError("The supplied index is out of bounds.");
			if (endIndex < beginIndex) throw new RangeError("The supplied index is out of bounds.");
			var i:int = 0;
			var prev:Object3D = null;
			var begin:Object3D = childrenList;
			while (i < beginIndex) {
				if (begin == null) {
					if (endIndex < 2147483647) {
						throw new RangeError("The supplied index is out of bounds.");
					} else {
						return;
					}
				}
				prev = begin;
				begin = begin.next;
				i++;
			}
			if (begin == null) {
				if (endIndex < 2147483647) {
					throw new RangeError("The supplied index is out of bounds.");
				} else {
					return;
				}
			}
			var end:Object3D = null;
			if (endIndex < 2147483647) {
				end = begin;
				while (i <= endIndex) {
					if (end == null) throw new RangeError("The supplied index is out of bounds.");
					end = end.next;
					i++;
				}
			}
			if (prev != null) {
				prev.next = end;
			} else {
				childrenList = end;
			}
			// Removing
			while (begin != end) {
				var next:Object3D = begin.next;
				begin.next = null;
				if (begin.willTrigger(Event3D.REMOVED)) begin.dispatchEvent(new Event3D(Event3D.REMOVED, true));
				begin._parent = null;
				begin = next;
			}
		}
		
		/**
		 * Returns the child <code>Object3D</code> instance that exists at the specified index.
		 * @param index Position of wished child.
		 * @return Child object at given position.
		 */
		public function getChildAt(index:int):Object3D {
			// Error checking
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Search for element by index
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			if (current == null) throw new RangeError("The supplied index is out of bounds.");
			return current;
		}

		/**
		 * Returns index of given child  <code>Object3D</code> instance.
		 * @param child Child  <code>Object3D</code> instance.
		 * @return Index of given child  <code>Object3D</code> instance.
		 */
		public function getChildIndex(child:Object3D):int {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Search for index
			var index:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) {
				if (current == child) return index;
				index++;
			}
			throw new ArgumentError("Cannot get child index.");
		}

		/**
		 * Sets index for child  <code>Object3D</code> instance.
		 * @param child Child  <code>Object3D</code> instance.
		 * @param index Index should be set.
		 */
		public function setChildIndex(child:Object3D, index:int):void {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Search for element by index
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			// Removing
			child = removeFromList(child);
			if (child == null) throw new ArgumentError("Cannot set child index.");
			// Adding
			addToList(child, current);
		}

		/**
		 * Swaps index positions of two specified child objects.
		 * @param child1 The first object to swap.
		 * @param child2 The second object to swap.
		 */
		public function swapChildren(child1:Object3D, child2:Object3D):void {
			// Error checking
			if (child1 == null || child2 == null) throw new TypeError("Parameter child must be non-null.");
			if (child1._parent != this || child2._parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Swapping
			if (child1 != child2) {
				if (child1.next == child2) {
					child2 = removeFromList(child2);
					if (child2 == null) throw new ArgumentError("Cannot swap children.");
					addToList(child2, child1);
				} else if (child2.next == child1) {
					child1 = removeFromList(child1);
					if (child1 == null) throw new ArgumentError("Cannot swap children.");
					addToList(child1, child2);
				} else {
					var count:int = 0;
					for (var child:Object3D = childrenList; child != null; child = child.next) {
						if (child == child1) count++;
						if (child == child2) count++;
						if (count == 2) break;
					}
					if (count < 2) throw new ArgumentError("Cannot swap children.");
					var nxt:Object3D = child1.next;
					removeFromList(child1);
					addToList(child1, child2);
					removeFromList(child2);
					addToList(child2, nxt);
				}
			}
		}

		/**
		 * Swaps index positions of two child objects by its index.
		 * @param index1 Index of the first object to swap.
		 * @param index2 Index of the second object to swap.
		 */
		public function swapChildrenAt(index1:int, index2:int):void {
			// Error checking
			if (index1 < 0 || index2 < 0) throw new RangeError("The supplied index is out of bounds.");
			// Swapping
			if (index1 != index2) {
				// Search for element by index
				var i:int;
				var child1:Object3D = childrenList;
				for (i = 0; i < index1; i++) {
					if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
					child1 = child1.next;
				}
				if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
				var child2:Object3D = childrenList;
				for (i = 0; i < index2; i++) {
					if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
					child2 = child2.next;
				}
				if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
				if (child1 != child2) {
					if (child1.next == child2) {
						removeFromList(child2);
						addToList(child2, child1);
					} else if (child2.next == child1) {
						removeFromList(child1);
						addToList(child1, child2);
					} else {
						var nxt:Object3D = child1.next;
						removeFromList(child1);
						addToList(child1, child2);
						removeFromList(child2);
						addToList(child2, nxt);
					}
				}
			}
		}

		/**
		 * Returns child <code>Object3D</code> instance with given <code>name</code>.
		 * In case of there are several objects with same name, the first of them will returned.
		 * If there are no objects with given name, <code>null</code> will returned.
		 *
		 * @param name The name of child object.
		 * @return Child Object3D with given name.
		 */
		public function getChildByName(name:String):Object3D {
			// Error checking
			if (name == null) throw new TypeError("Parameter name must be non-null.");
			// Search for object
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.name == name) return child;
			}
			return null;
		}

		/**
		 * Check if given object is child of this <code>Object3D</code>.
		 * @param child Child <code>Object3D</code> instance.
		 * @return <code>true</code> if given instance is this  <code>Object3D</code> or one of its children or <code>false</code> otherwise.
		 */
		public function contains(child:Object3D):Boolean {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			// Search for object
			if (child == this) return true;
			for (var object:Object3D = childrenList; object != null; object = object.next) {
				if (object.contains(child)) return true;
			}
			return false;
		}

		/**
		 * Returns the number of children of this object.
		 */
		public function get numChildren():int {
			var num:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) num++;
			return num;
		}

		private function addToList(child:Object3D, item:Object3D = null):void {
			child.next = item;
			if (item == childrenList) {
				childrenList = child;
			} else {
				for (var current:Object3D = childrenList; current != null; current = current.next) {
					if (current.next == item) {
						current.next = child;
						break;
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		alternativa3d function removeFromList(child:Object3D):Object3D {
			var prev:Object3D;
			for (var current:Object3D = childrenList; current != null; current = current.next) {
				if (current == child) {
					if (prev != null) {
						prev.next = current.next;
					} else {
						childrenList = current.next;
					}
					current.next = null;
					return child;
				}
				prev = current;
			}
			return null;
		}
		
		/**
		 * Gather the resources of this <code>Object3D</code>. This resources should be uploaded in the <code>Context3D</code> in order to <code>Object3D</code> can be rendered.
		 *
		 * @param hierarchy If <code>true</code>, the resources of all children will be gathered too.
		 * @param resourceType If defined, only resources of this type will be gathered.
		 * @return Vector consists of gathered resources
		 * @see flash.display.Stage3D
		 */
		public function getResources(hierarchy:Boolean = false, resourceType:Class = null):Vector.<Resource> {
			var res:Vector.<Resource> = new Vector.<Resource>();
			var dict:Dictionary = new Dictionary();
			var count:int = 0;
			fillResources(dict, hierarchy, resourceType);
			for (var key:* in dict) {
				res[count++] = key as Resource;
			}
			return res;
		}

		/**
		 * @private
		 */
		alternativa3d function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (hierarchy) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.fillResources(resources, hierarchy, resourceType);
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function composeTransforms():void {
			// Matrix
			var cosX:Number = Math.cos(_rotationX);
			var sinX:Number = Math.sin(_rotationX);
			var cosY:Number = Math.cos(_rotationY);
			var sinY:Number = Math.sin(_rotationY);
			var cosZ:Number = Math.cos(_rotationZ);
			var sinZ:Number = Math.sin(_rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*_scaleX;
			var sinXscaleY:Number = sinX*_scaleY;
			var cosXscaleY:Number = cosX*_scaleY;
			var cosXscaleZ:Number = cosX*_scaleZ;
			var sinXscaleZ:Number = sinX*_scaleZ;
			transform.a = cosZ*cosYscaleX;
			transform.b = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			transform.c = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			transform.d = _x;
			transform.e = sinZ*cosYscaleX;
			transform.f = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			transform.g = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			transform.h = _y;
			transform.i = -sinY*_scaleX;
			transform.j = cosY*sinXscaleY;
			transform.k = cosY*cosXscaleZ;
			transform.l = _z;
			// Inverse matrix
			var sinXsinY:Number = sinX*sinY;
			cosYscaleX = cosY/_scaleX;
			cosXscaleY = cosX/_scaleY;
			sinXscaleZ = -sinX/_scaleZ;
			cosXscaleZ = cosX/_scaleZ;
			inverseTransform.a = cosZ*cosYscaleX;
			inverseTransform.b = sinZ*cosYscaleX;
			inverseTransform.c = -sinY/_scaleX;
			inverseTransform.d = -inverseTransform.a*_x - inverseTransform.b*_y - inverseTransform.c*_z;
			inverseTransform.e = sinXsinY*cosZ/_scaleY - sinZ*cosXscaleY;
			inverseTransform.f = cosZ*cosXscaleY + sinXsinY*sinZ/_scaleY;
			inverseTransform.g = sinX*cosY/_scaleY;
			inverseTransform.h = -inverseTransform.e*_x - inverseTransform.f*_y - inverseTransform.g*_z;
			inverseTransform.i = cosZ*sinY*cosXscaleZ - sinZ*sinXscaleZ;
			inverseTransform.j = cosZ*sinXscaleZ + sinY*sinZ*cosXscaleZ;
			inverseTransform.k = cosY*cosXscaleZ;
			inverseTransform.l = -inverseTransform.i*_x - inverseTransform.j*_y - inverseTransform.k*_z;
			transformChanged = false;
		}

		/**
		 * @private
		 */
		alternativa3d function calculateVisibility(camera:Camera3D):void {
		}

		/**
		 * @private
		 */
		alternativa3d function calculateChildrenVisibility(camera:Camera3D):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				// Checking visibility flag
				if (child.visible) {
					// Compose matrix and inverse matrix
					if (child.transformChanged) child.composeTransforms();
					// Calculating matrix for converting from camera coordinates to local coordinates
					child.cameraToLocalTransform.combine(child.inverseTransform, cameraToLocalTransform);
					// Calculating matrix for converting from local coordinates to  camera coordinates
					child.localToCameraTransform.combine(localToCameraTransform, child.transform);

					camera.globalMouseHandlingType |= child.mouseHandlingType;
					// Culling checking
					if (child.boundBox != null) {
						camera.calculateFrustum(child.cameraToLocalTransform);
						child.culling = child.boundBox.checkFrustumCulling(camera.frustum, 63);
					} else {
						child.culling = 63;
					}
					// Calculating visibility of the self content
					if (child.culling >= 0) child.calculateVisibility(camera);
					// Calculating visibility of children
					if (child.childrenList != null) child.calculateChildrenVisibility(camera);
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
		}

		/**
		 * @private
		 */
		alternativa3d function collectChildrenDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			var i:int;
			var light:Light3D;

			for (var child:Object3D = childrenList; child != null; child = child.next) {
				// Checking visibility flag
				if (child.visible) {
					// Check getting in frustum and occluding
					if (child.culling >= 0 && (child.boundBox == null || camera.occludersLength == 0 || !child.boundBox.checkOcclusion(camera.occluders, camera.occludersLength, child.localToCameraTransform))) {
						// Check if the ray crossing the bounding box
						if (child.boundBox != null) {
							camera.calculateRays(child.cameraToLocalTransform);
							child.listening = child.boundBox.checkRays(camera.origins, camera.directions, camera.raysLength);
						} else {
							child.listening = true;
						}
						// Check if object needs in lightning
						var excludedLightLength:int = child._excludedLights.length;
						if (lightsLength > 0 && child.useLights) {
							// Pass the lights to children and calculate appropriate transformations
							var childLightsLength:int = 0;
							var j:int;
							if (child.boundBox != null) {
								for (i = 0; i < lightsLength; i++) {
									light = lights[i];
									// Checking object for existing in excludedLights
									j = 0;
									while (j<excludedLightLength && child._excludedLights[j]!=light)	j++;
									if (j<excludedLightLength) continue;

									light.lightToObjectTransform.combine(child.cameraToLocalTransform, light.localToCameraTransform);
									// Detect influence
									if (light.boundBox == null || light.checkBound(child)) {
										camera.childLights[childLightsLength] = light;
										childLightsLength++;
									}
								}
							} else {
								// Calculate transformation from light space to object space
								for (i = 0; i < lightsLength; i++) {
									light = lights[i];
									// Проверка источника света на отсутствие в excludedLights
									j = 0;
									while (j<excludedLightLength && child._excludedLights[j]!=light)	j++;
									if (j<excludedLightLength) continue;
									light.lightToObjectTransform.combine(child.cameraToLocalTransform, light.localToCameraTransform);
									camera.childLights[childLightsLength] = light;
									childLightsLength++;
								}
							}
							child.collectDraws(camera, camera.childLights, childLightsLength, useShadow&&child.useShadow);
						} else {
							child.collectDraws(camera, null, 0, useShadow&&child.useShadow);
						}
						// Debug the boundbox
						if (camera.debug && child.boundBox != null && (camera.checkInDebug(child) & Debug.BOUNDS)) Debug.drawBoundBox(camera, child.boundBox, child.localToCameraTransform);
					} else {
						// TODO: Optimize this
						child.culling = -1;
					}
					// Gather the draws for children
					if (child.childrenList != null) child.collectChildrenDraws(camera, lights, lightsLength, useShadow && child.useShadow);
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function collectDepthDraws(camera:Camera3D, depthRenderer:Renderer, depthMaterial:Material):void {
			// TODO: refactor this
		}

		/**
		 * @private
		 */
		alternativa3d function collectChildrenDepthDraws(camera:Camera3D, depthRenderer:Renderer, depthMaterial:Material):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				// Checking visibility flag
				if (child.visible) {
					// Check getting in frustum and occluding
					if (child.culling >= 0) child.collectDepthDraws(camera, depthRenderer, depthMaterial);
					// Gather the draws for children
					if (child.childrenList != null) child.collectChildrenDepthDraws(camera, depthRenderer, depthMaterial);
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function collectGeometry(collider:EllipsoidCollider, excludedObjects:Dictionary):void {
		}

		/**
		 * @private
		 */
		alternativa3d function collectChildrenGeometry(collider:EllipsoidCollider, excludedObjects:Dictionary):void {
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (excludedObjects == null || !excludedObjects[child]) {
					// Compose matrix and inverse matrix if it needed
					if (child.transformChanged) child.composeTransforms();
					// Calculating matrix for converting from collider coordinates to local coordinates
					child.globalToLocalTransform.combine(child.inverseTransform, globalToLocalTransform);
					// Check boundbox intersecting
					var intersects:Boolean = true;
					if (child.boundBox != null) {
						collider.calculateSphere(child.globalToLocalTransform);
						intersects = child.boundBox.checkSphere(collider.sphere);
					}
					// Adding the geometry of self content
					if (intersects) {
						// Calculating matrix for converting from local coordinates to callider coordinates
						child.localToGlobalTransform.combine(localToGlobalTransform, child.transform);
						child.collectGeometry(collider, excludedObjects);
					}
					// Check for children
					if (child.childrenList != null) child.collectChildrenGeometry(collider, excludedObjects);
				}
			}
		}

		/**
		 * @private
		 */
		alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
		}


		/**
		 * Disables lighting of the object by given <code>light</code>.
         *
         * @param light Light which should not affect to the object
         * @param updateChildren If <code>true</code> all children of this object will be also shielded from the given light.
         * @see  #excludedLights()
         * @see  #clearExcludedLights()
		 */
		public function excludeLight(light:Light3D, updateChildren:Boolean = false):void{
			if (_excludedLights.indexOf(light) < 0) {
				_excludedLights.push(light);
			}
			if (updateChildren) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.excludeLight(light, true);
				}
			}
		}

		/**
		 * Returns excluded lights list of current object.
		 */
		public function get excludedLights():Vector.<Light3D> {
			return _excludedLights.slice();
		}

		/**
		 * Resets list of lights excluded from lighting this object.
		 */
		public function clearExcludedLights(updateChildren:Boolean = false):void {
			_excludedLights.length = 0;
			if (updateChildren) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.clearExcludedLights(true);
				}
			}
		}

		/**
		 * Returns a copy of object.
		 * @return A copy of this <code>Object3D</code>.
		 */
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * Copies basic properties of <code>Object3D</code>. This method calls from  <code>clone()</code> method.
		 * @param source <code>Object3D</code>, properties of  which will be copied.
		 */
		protected function clonePropertiesFrom(source:Object3D):void {
			userData = source.userData;
			
			name = source.name;
			visible = source.visible;
			mouseEnabled = source.mouseEnabled;
			mouseChildren = source.mouseChildren;
			doubleClickEnabled = source.doubleClickEnabled;
			useHandCursor = source.useHandCursor;
			boundBox = source.boundBox ? source.boundBox.clone() : null;
			_x = source._x;
			_y = source._y;
			_z = source._z;
			_rotationX = source._rotationX;
			_rotationY = source._rotationY;
			_rotationZ = source._rotationZ;
			_scaleX = source._scaleX;
			_scaleY = source._scaleY;
			_scaleZ = source._scaleZ;
			for (var child:Object3D = source.childrenList, lastChild:Object3D; child != null; child = child.next) {
				var newChild:Object3D = child.clone();
				if (childrenList != null) {
					lastChild.next = newChild;
				} else {
					childrenList = newChild;
				}
				lastChild = newChild;
				newChild._parent = this;
			}
		}

		/**
		 * Returns the string representation of the specified object.
		 * @return The string representation of the specified object.
		 */
		public function toString():String {
			var className:String = getQualifiedClassName(this);
			var start:int = className.indexOf("::");
			return "[" + (start < 0 ? className : className.substr(start + 2)) + " " + name + "]";
		}

	}
}
