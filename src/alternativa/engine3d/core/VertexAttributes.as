/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;

	import flash.display3D.Context3DVertexBufferFormat;

	use namespace alternativa3d;

	/**
	 * Types of attributes which defines format of vertex streams. It can be used as values of array,
	 * passed to <code>geometry.addVertexStream(attributes)</code> as an argument.
	 *
	 * 	 @see alternativa.engine3d.resources.Geometry
	 */
	public class VertexAttributes {
	   /**
		* Coordinates in 3D space. Defines by sequence of three floats.
		*
		* @see alternativa.engine3d.resources.Geometry
		* @see #getAttributeStride()
		*/
		public static const POSITION:uint = 1;
		/**
		 * Vertex normal. Defines by sequence of three floats.
		 *
		 * @see alternativa.engine3d.resources.Geometry
		 * @see #getAttributeStride()
		 */
		public static const NORMAL:uint = 2; 
		/**
		 * This data type combines values of vertex tangent and binormal within one sequence of four floats.
		 * The first three values defines tangent direction and the fourth can be 1 or -1 which defines to what side binormal is ordered.
		 *
		 * @see alternativa.engine3d.resources.Geometry
		 */
		public static const TANGENT4:uint = 3;
		/**
		 * Data of linking  of two <code>Joint</code>s with vertex. Defines by sequence of four floats in following order:
		 * id of the first <code>Joint</code> multiplied with 3, power of influence of the first <code>Joint</code>,
		 * id  of the second <code>Joint</code> multiplied with 3, power of influence of the second <code>Joint</code>.
		 * There are a four 'slots' for this data type, so influence of 8  <code>Joint</code>s can be described.
		 * @see alternativa.engine3d.resources.Geometry
		 * @see alternativa.engine3d.objects.Skin
		 */
		public static const JOINTS:Vector.<uint> = Vector.<uint>([4,5,6,7]);

		/**
		 * Texture coordinates data type. There are a 8 independent channels. Coordinates defines by the couples (u, v).
		 *
		 * @see alternativa.engine3d.resources.Geometry
		 */
		public static const TEXCOORDS:Vector.<uint> = Vector.<uint>([8,9,10,11,12,13,14,15]);

		/**
		 * @private
		 */
		alternativa3d static const FORMATS:Array = [
			Context3DVertexBufferFormat.FLOAT_1,	//NONE
			Context3DVertexBufferFormat.FLOAT_3,	//POSITION
			Context3DVertexBufferFormat.FLOAT_3,	//NORMAL
			Context3DVertexBufferFormat.FLOAT_4,	//TANGENT4
			Context3DVertexBufferFormat.FLOAT_4,	//JOINTS[0]
			Context3DVertexBufferFormat.FLOAT_4,	//JOINTS[1]
			Context3DVertexBufferFormat.FLOAT_4,	//JOINTS[2]
			Context3DVertexBufferFormat.FLOAT_4,	//JOINTS[3]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[0]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[1]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[2]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[3]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[4]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[5]
			Context3DVertexBufferFormat.FLOAT_2,	//TEXCOORDS[6]
			Context3DVertexBufferFormat.FLOAT_2 	//TEXCOORDS[7]
		];

		/**
		 * Returns a dimensions of given attribute type (Number of floats by which defines given type)
		 *
		 * @param attribute Type of the attribute.
		 * @return
		 */
		public static function getAttributeStride(attribute:int):int {
			switch(FORMATS[attribute]) {
				case Context3DVertexBufferFormat.FLOAT_1:
					return 1;
					break;
				case Context3DVertexBufferFormat.FLOAT_2:
					return 2;
					break;
				case Context3DVertexBufferFormat.FLOAT_3:
					return 3;
					break;
				case Context3DVertexBufferFormat.FLOAT_4:
					return 4;
					break;
			}
			return 0;
		}


	}
}
