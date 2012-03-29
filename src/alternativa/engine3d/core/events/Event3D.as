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

	import flash.events.Event;

	use namespace alternativa3d;
	public class Event3D extends Event {

		/**
		 * Defines the value of the <code>type</code> property of a <code>added</code> event object.
		 * @eventType added
		 */
		public static const ADDED:String = "added3D";

		/**
		 * Defines the value of the <code>type</code> property of a <code>removed</code> event object.

		 * @eventType removed
		 */
		public static const REMOVED:String = "removed3D";


		/**
		 * This class should be used as base class for all events, which can have <code>Object3D</code> as an event target.
		 * @param type
		 * @param bubbles
		 */
		public function Event3D(type:String, bubbles:Boolean = true) {
			super(type, bubbles);
			_bubbles = bubbles;
		}

		/**
		 * @private
		 */
		alternativa3d var _target:Object3D;

		/**
		 * @private
		 */
		alternativa3d var _currentTarget:Object3D;

		/**
		 * @private
		 */
		alternativa3d var _bubbles:Boolean;

		/**
		 * @private
		 */
		alternativa3d var _eventPhase:uint = 3;

		/**
		 * @private
		 */
		alternativa3d var stop:Boolean = false;

		/**
		 * @private
		 */
		alternativa3d var stopImmediate:Boolean = false;

		/**
		 * Indicates whether an event is a bubbling event. If the event can bubble, this value is <code>true</code>; otherwise it is <code>false</code>.
		 */
		override public function get bubbles():Boolean {
			return _bubbles;
		}

		/**
		 * The current phase in the event flow.
		 */
		override public function get eventPhase():uint {
			return _eventPhase;
		}

		/**
		 * The event target. This property contains the target node.
		 */
		override public function get target():Object {
			return _target;
		}

		/**
		 * The object that is actively processing the Event object with an event listener.
		 */
		override public function get currentTarget():Object {
			return _currentTarget;
		}

		/**
		 * Prevents processing of any event listeners in nodes subsequent to the current node in the event flow.
  		 * Does not affect on receiving events in listeners of (<code>currentTarget</code>).
		 */
		override public function stopPropagation():void {
			stop = true;
		}

		/**
		 * Prevents processing of any event listeners in the current node and any subsequent nodes in the event flow.
		 */
		override public function stopImmediatePropagation():void {
			stopImmediate = true;
		}

		/**
		 * Duplicates an instance of an Event subclass.
		 * Returns a new <code>Event3D</code> object that is a copy of the original instance of the <code>Event</code> object.
		 * @return A new <code>Event3D</code> object that is identical to the original.
		 */
		override public function clone():Event {
			var result:Event3D = new Event3D(type, _bubbles);
			result._target = _target;
			result._currentTarget = _currentTarget;
			result._eventPhase = _eventPhase;
			return result;
		}

		/**
		 * Returns a string containing all the properties of the <code>Event3D</code> object.
		 * @return A string containing all the properties of the <code>Event3D</code> object
		 */
		override public function toString():String {
			return formatToString("Event3D", "type", "bubbles", "eventPhase");
		}

	}
}
