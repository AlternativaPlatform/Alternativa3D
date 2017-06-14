/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DClearMask;

	use namespace alternativa3d;

/**
 * CameraManager
 *
 */
public class CameraManager {
	/**
	 * @private
	 */
	alternativa3d var cameraList:Array;

	/**
	 * @private
	 */
	alternativa3d var stage3D:Stage3D;
	
	/**
	 * @private
	 */
	alternativa3d var view:View;
	
	/**
	 * Creates a <code>CameraManager</code> object.
	 *
	 * @param Stage3D.
	 * @param View.
	 */
	public function CameraManager(s3d:Stage3D, vw:View) {
		stage3D = s3d;
		view = vw;
		cameraList = new Array();
	}

	/**
	 * Add Camera.
	 */
	public function addCamera(cam:*) :int {
		cameraList.push(cam);
	
		return cameraList.length - 1;
	}

	/**
	 * Remove Camera.
	 */
	public function removeCamera(no:int) :void {
		delete cameraList[no];
		
		if(cameraList.length == 0) {
			view = null;
		}
	}

	/**
	 * Clear Screen.
	 */
	public function clearScreen() : void {
		var r:Number = ((view.backgroundColor >> 16) & 0xff)/0xff;
		var g:Number = ((view.backgroundColor >> 8) & 0xff)/0xff;
		var b:Number = (view.backgroundColor & 0xff)/0xff;
		if (view._canvas != null) {
			r *= view.backgroundAlpha;
			g *= view.backgroundAlpha;
			b *= view.backgroundAlpha;
		}

		stage3D.context3D.clear(r, g, b, view.backgroundAlpha, 1, 0, Context3DClearMask.ALL);
	}

	/**
	 * Render Layers.
	 */
	public function renderLayers() : void {
		var i:int;
		var cameraListLength:int;

		var r:Number = ((view.backgroundColor >> 16) & 0xff)/0xff;
		var g:Number = ((view.backgroundColor >> 8) & 0xff)/0xff;
		var b:Number = (view.backgroundColor & 0xff)/0xff;
		if (view._canvas != null) {
			r *= view.backgroundAlpha;
			g *= view.backgroundAlpha;
			b *= view.backgroundAlpha;
		}

		cameraListLength = cameraList.length;

		for(i=0; i< cameraListLength; i++) {
			stage3D.context3D.clear(r, g, b, view.backgroundAlpha, 1, 0, cameraList[i].clearFlags);

			if(cameraList[i] != null)
				cameraList[i].render(stage3D);
		}
	}

	/**
	 * Draw Screen.
	 */	
	public function drawScreen():void{
		// Output
		if (view._canvas == null) {
			stage3D.context3D.present();
		} else {
			stage3D.context3D.drawToBitmapData(view._canvas);
			stage3D.context3D.present();
		}
	}

	/**
	 * Swap Camera Layer.
	 */	
	public function swapCamera(no1:int, no2:int):void {
		var work:*;

		work = cameraList[no1];
		cameraList[no1] = cameraList[no2];
		cameraList[no2] = work;
	}
}
}
