/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.Material;

	use namespace alternativa3d;

	/**
	 * Surface is a set of triangles within <code>Mesh</code> object or  instance of kindred class like <code>Skin</code>.
	 * Surface is a entity associated with one material, so different surfaces within one mesh can have different materials.
	 */
	public class Surface {

		/**
		 * Material.
		 */
		public var material:Material;

		/**
		 * Index of the vertex with which surface starts within index buffer of object's geometry.
		 * @see alternativa.engine3d.resources.Geometry#indices
		 */
		public var indexBegin:int = 0;

		/**
		 * Number of triangles which form this surface.
		 */
		public var numTriangles:int = 0;

		/**
		 * @private 
		 */
		alternativa3d var object:Object3D;

		/**
		 * Returns a copy of this surface.
		 * @return A copy of this surface.
		 */
		public function clone():Surface {
			var res:Surface = new Surface();
			res.object = object;
			res.material = material;
			res.indexBegin = indexBegin;
			res.numTriangles = numTriangles;
			return res;
		}

	}
}
