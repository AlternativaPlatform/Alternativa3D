/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders.collada {
	import flash.geom.Vector3D;

	/**
	 * @private 
	 */
	public class DaeVertex {

		public var vertexInIndex:int;
		public var vertexOutIndex:int;
		
		public var indices:Vector.<int> = new Vector.<int>();
		
		public var x:Number;
		public var y:Number;
		public var z:Number;
		
		public var uvs:Vector.<Number> = new Vector.<Number>();

		public var normal:Vector3D;
		public var tangent:Vector3D;

		public function addPosition(data:Vector.<Number>, dataIndex:int, stride:int, unitScaleFactor:Number):void {
			indices.push(dataIndex);
			var offset:int = stride*dataIndex;
			x = data[int(offset)]*unitScaleFactor;
			y = data[int(offset + 1)]*unitScaleFactor;
			z = data[int(offset + 2)]*unitScaleFactor;
		}

		public function addNormal(data:Vector.<Number>, dataIndex:int, stride:int):void {
			indices.push(dataIndex);
			var offset:int = stride*dataIndex;
			normal = new Vector3D();
			normal.x = data[int(offset++)];
			normal.y = data[int(offset++)];
			normal.z = data[offset];
		}

		public function addTangentBiDirection(tangentData:Vector.<Number>, tangentDataIndex:int, tangentStride:int, biNormalData:Vector.<Number>, biNormalDataIndex:int, biNormalStride:int):void {
			indices.push(tangentDataIndex);
			indices.push(biNormalDataIndex);
			var tangentOffset:int = tangentStride*tangentDataIndex;
			var biNormalOffset:int = biNormalStride*biNormalDataIndex;

			var biNormalX:Number = biNormalData[int(biNormalOffset++)];			
			var biNormalY:Number = biNormalData[int(biNormalOffset++)];			
			var biNormalZ:Number = biNormalData[biNormalOffset];
			
			tangent = new Vector3D(tangentData[int(tangentOffset++)], tangentData[int(tangentOffset++)], tangentData[tangentOffset]);
			
			var crossX:Number = normal.y*tangent.z - normal.z*tangent.y;
			var crossY:Number = normal.z*tangent.x - normal.x*tangent.z;
			var crossZ:Number = normal.x*tangent.y - normal.y*tangent.x;
			var dot:Number = crossX*biNormalX + crossY*biNormalY + crossZ*biNormalZ;
			tangent.w = dot < 0 ? -1 : 1;
		}

		public function appendUV(data:Vector.<Number>, dataIndex:int, stride:int):void {
			indices.push(dataIndex);
			uvs.push(data[int(dataIndex*stride)]);
			uvs.push(1 - data[int(dataIndex*stride + 1)]);
		}

	}
}
