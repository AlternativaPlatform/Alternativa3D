/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.ShaderProgram;

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;

	use namespace alternativa3d;

	/**
	 * @private
	 */
	public class DebugMaterialsRenderer extends Renderer {

		override alternativa3d function createDrawUnit(object:Object3D, program:Program3D, indexBuffer:IndexBuffer3D, firstIndex:int, numTriangles:int, debugShader:ShaderProgram = null):DrawUnit {
			var res:DebugDrawUnit;
			if (collector != null) {
				res = DebugDrawUnit(collector);
				collector = collector.next;
				res.next = null;
			} else {
				res = new DebugDrawUnit();
			}
			res.shader = debugShader;
			res.object = object;
			res.program = program;
			res.indexBuffer = indexBuffer;
			res.firstIndex = firstIndex;
			res.numTriangles = numTriangles;
			return res;
		}

		override alternativa3d function addDrawUnit(drawUnit:DrawUnit, renderPriority:int):void {
			DebugDrawUnit(drawUnit).check();
			super.addDrawUnit(drawUnit, renderPriority);
		}

	}
}
