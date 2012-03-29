/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.materials {
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.compiler.Linker;

	import flash.display3D.Context3D;
	import flash.display3D.Program3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class ShaderProgram {
		
		public var program:Program3D;
		
		public var vertexShader:Linker;
		public var fragmentShader:Linker;
        
		public function ShaderProgram(vertexShader:Linker, fragmentShader:Linker) {
			this.vertexShader = vertexShader;
			this.fragmentShader = fragmentShader;
		}
		
		public function upload(context3D:Context3D):void {
			if (program != null) program.dispose();
			if (vertexShader != null && fragmentShader != null) {
				vertexShader.link();
				fragmentShader.link();
	            program = context3D.createProgram();
				try {
					program.upload(vertexShader.data, fragmentShader.data);
				} catch (e:Error) {
					throw (e);
				}
			} else {
				program = null;
			}
		}
		
		public function dispose():void {
			if (program != null) {
				program.dispose();
				program = null;
			}
		}
		
	}
}
