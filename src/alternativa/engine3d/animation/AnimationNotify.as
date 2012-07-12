/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;

	import flash.events.EventDispatcher;

	use namespace alternativa3d;

	/**
	 * The notification trigger bound to certain time on an animation time line.
	 * <code>AnimationNotify</code> instance subscribes to <code>NotifyEvent.NOTIFY</code>
	 * When animation playback reaches the given time, an event is dispatched by the trigger.
	 *
	 * @example The following code listens event when 30 seconds elapsed from animation start:
     * <listing version="3.0">
     * animationClip.addNotify(30).addEventListener(NotifyEvent.NOTIFY, notifyHandler)
     * …
     * private function notifyHandler(e:NotifyEvent):void{
     *  trace("Animation time is " + e.notify.time + " seconds now")
     *}
	 * </listing>
     *
	 * 
	 * @see AnimationClip#addNotify()
	 * @see AnimationClip#addNotifyAtEnd()
	 */
	public class AnimationNotify extends EventDispatcher {
		
		/**
		 * The name of notification trigger.
		 */
		public var name:String;

		/**
		 * @private 
		 */
 		alternativa3d var _time:Number = 0;
		/**
		 * @private 
		 */
		alternativa3d var next:AnimationNotify;
		
		/**
		 * @private 
		 */
		alternativa3d var updateTime:Number;
		/**
		 * @private 
		 */
		alternativa3d var processNext:AnimationNotify;

		/**
		 * A new instance should not be created directly. Instead, use <code>AnimationClip.addNotify()</code> or <code>AnimationClip.addNotifyAtEnd()</code> methods.
		 * 
		 * @see AnimationClip#addNotify()
		 * @see AnimationClip#addNotifyAtEnd()
		 */
		public function AnimationNotify(name:String) {
			this.name = name;
		}

		/**
		 * The time in seconds on the time line to which the trigger is bound.
		 */
		public function get time():Number {
			return _time;
		}

	}
}
