/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core.events {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.objects.Surface;

	import flash.events.Event;

	use namespace alternativa3d;

	/**
	 *
	 * Event <code>MouseEvent3D</code> dispatches by <code>Object3D</code>, in cases when <code>MouseEvent</code> dispatches by <code>DisplayObject</code>.
	 */
	public class MouseEvent3D extends Event3D {
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>click3D</code> event object.
		 * @eventType click3D
		 */
		public static const CLICK:String = "click3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>doubleClick3D</code> event object.
		 * @eventType doubleClick3D
		 */
		public static const DOUBLE_CLICK:String = "doubleClick3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseDown3D</code> event object.
		 * @eventType mouseDown3D
		 */
		public static const MOUSE_DOWN:String = "mouseDown3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseUp3D</code> event object.
		 * @eventType mouseUp3D
		 */
		public static const MOUSE_UP:String = "mouseUp3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>rightClick3D</code> event object.
		 * @eventType rightClick3D
		 */
		public static const RIGHT_CLICK:String = "rightClick3D";

		/**
		 * Defines the value of the <code>type</code> property of a <code>rightMouseDown3D</code> event object.
		 * @eventType rightMouseDown3D
		 */
		public static const RIGHT_MOUSE_DOWN:String = "rightMouseDown3D";

		/**
		 * Defines the value of the <code>type</code> property of a <code>rightMouseUp3D</code> event object.
		 * @eventType rightMouseUp3D
		 */
		public static const RIGHT_MOUSE_UP:String = "rightMouseUp3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>middleClick3D</code> event object.
		 * @eventType middleClick3D
		 */
		public static const MIDDLE_CLICK:String = "middleClick3D";		
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>middleMouseDown3D</code> event object.
		 * @eventType middleMouseDown3D
		 */
		public static const MIDDLE_MOUSE_DOWN:String = "middleMouseDown3D";		
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>middleMouseUp3D</code> event object.
		 * @eventType middleMouseUp3D
		 */
		public static const MIDDLE_MOUSE_UP:String = "middleMouseUp3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseOver3D</code> event object.
		 * @eventType mouseOver3D
		 */
		public static const MOUSE_OVER:String = "mouseOver3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseOut3D</code> event object.
		 * @eventType mouseOut3D
		 */
		public static const MOUSE_OUT:String = "mouseOut3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>rollOver3D</code> event object.
		 * @eventType rollOver3D
		 */
		public static const ROLL_OVER:String = "rollOver3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>rollOut3D</code> event object.
		 * @eventType rollOut3D
		 */
		public static const ROLL_OUT:String = "rollOut3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseMove3D</code> event object.
		 * @eventType mouseMove3D
		 */
		public static const MOUSE_MOVE:String = "mouseMove3D";
		
		/**
		 * Defines the value of the <code>type</code> property of a <code>mouseWheel3D</code> event object.
		 * @eventType mouseWheel3D
		 */
		public static const MOUSE_WHEEL:String = "mouseWheel3D";
	
		/**
		 * On Windows or Linux, indicates whether the Ctrl key is active (<code>true</code>) or inactive (<code>false</code>). On Macintosh, indicates whether either the Control key or the Command key is activated.
		 */
		public var ctrlKey:Boolean;
		/**
		 * Indicates whether the Alt key is active (<code>true</code>) or inactive (<code>false</code>).
		 */
		public var altKey:Boolean;
		/**
		 * Indicates whether the Shift key is active (<code>true</code>) or inactive (<code>false</code>).
		 */
		public var shiftKey:Boolean;
		/**
		 * Indicates whether the main mouse button is active (<code>true</code>) or inactive (<code>false</code>).
		 */
		public var buttonDown:Boolean;
		/**
		 * Indicates how many lines should be scrolled for each unit the user rotates the mouse wheel.
		 */
		public var delta:int;
	
		/**
		 * A reference to an object that is related to the event. This property applies to the <code>mouseOut</code>, <code>mouseOver</code>, <code>rollOut</code> и <code>rollOver</code>.
		 * For example, when <code>mouseOut</code> occurs, <code>relatedObject</code> point to the object over which mouse cursor placed now.
		 */
		public var relatedObject:Object3D;
		
		/**
		 * X coordinate of the event at local target object's space.
		 */
		public var localX:Number;

		/**
		 *  Y coordinate of the event at local target object's space.
		 */
		public var localY:Number;
		
		/**
		 *  Z coordinate of the event at local target object's space.
		 */
		public var localZ:Number;

		/**
		 * @private 
		 */
		alternativa3d var _surface:Surface;

		/**
		 * Creates a MouseEvent3D object.
		 * @param type Type.
		 * @param bubbles Indicates whether an event is a bubbling event.
		 * @param localY Y coordinate of the event at local target object's space.
		 * @param localX X coordinate of the event at local target object's space.
		 * @param localZ Z coordinate of the event at local target object's space.
		 * @param relatedObject  <code>Object3D</code>, eelated to the <code>MouseEvent3D</code>.
		 * @param altKey Indicates whether the Alt key is active.
		 * @param ctrlKey Indicates whether the Control key is active.
		 * @param shiftKey Indicates whether the Shift key is active.
		 * @param buttonDown Indicates whether the main mouse button is active .
		 * @param delta Indicates how many lines should be scrolled for each unit the user rotates the mouse wheel.
		 */
		public function MouseEvent3D(type:String, bubbles:Boolean = true, localX:Number = NaN, localY:Number = NaN, localZ:Number = NaN, relatedObject:Object3D = null, ctrlKey:Boolean = false, altKey:Boolean = false, shiftKey:Boolean = false, buttonDown:Boolean = false, delta:int = 0) {
			super(type, bubbles);
			this.localX = localX;
			this.localY = localY;
			this.localZ = localZ;
			this.relatedObject = relatedObject;
			this.ctrlKey = ctrlKey;
			this.altKey = altKey;
			this.shiftKey = shiftKey;
			this.buttonDown = buttonDown;
			this.delta = delta;
		}
		
		/**
		 * <code>Surface</code> on which event has been received. The object that owns the surface, can differs from the target event.
		 *
		 */
		public function get surface():Surface {
			return _surface;
		}

		/**
		 * Duplicates an instance of an Event subclass.
		 * Returns a new <code>MouseEvent3D</code> object that is a copy of the original instance of the Event object.
		 * @return A new <code>MouseEvent3D</code> object that is identical to the original.
		 */
		override public function clone():Event {
			return new MouseEvent3D(type, _bubbles, localX, localY, localZ, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
		}

		/**
		 * Returns a string containing all the properties of the <code>MouseEvent3D</code> object.
		 * @return A string containing all the properties of the <code>MouseEvent3D</code> object
		 */
		override public function toString():String {
			return formatToString("MouseEvent3D", "type", "bubbles", "eventPhase", "localX", "localY", "localZ", "relatedObject", "altKey", "ctrlKey", "shiftKey", "buttonDown", "delta");
		}
		
	}
}
