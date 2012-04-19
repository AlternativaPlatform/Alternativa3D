package alternativa.engine3d.loaders.filmbox {

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * @private SDK: Represents an element in the scene graph.
	 */
	public class KFbxNode {
		public var LclTranslation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var LclRotation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var LclScaling:Vector.<Number> = Vector.<Number>([1, 1, 1]);
		public var RotationOffset:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var RotationPivot:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var PreRotation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var PostRotation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var ScalingOffset:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var ScalingPivot:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var GeometricTranslation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var GeometricRotation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var GeometricScaling:Vector.<Number> = Vector.<Number>([1, 1, 1]);

		public function transformationClone():KFbxNode {
			var tmp:KFbxNode = new KFbxNode;
			tmp.LclTranslation = LclTranslation.slice();
			tmp.LclRotation = LclRotation.slice();
			tmp.LclScaling = LclScaling.slice();
			tmp.RotationOffset = RotationOffset.slice();
			tmp.RotationPivot = RotationPivot.slice();
			tmp.PreRotation = PreRotation.slice();
			tmp.PostRotation = PostRotation.slice();
			tmp.ScalingOffset = ScalingOffset.slice();
			tmp.ScalingPivot = ScalingPivot.slice();
			tmp.GeometricTranslation = GeometricTranslation.slice();
			tmp.GeometricRotation = GeometricRotation.slice();
			tmp.GeometricScaling = GeometricScaling.slice();
			return tmp;
		}

		/**
		 * Собирает матрицу трансформации. Из доки СДК:
		 *
		 * Each pivot context stores values (as KFbxVector4) for:
		 *	  - Rotation offset (Roff)
		 *	  - Rotation pivot (Rp)
		 *	  - Pre-rotation (Rpre)
		 *	  - Post-rotation (Rpost)
		 *	  - Scaling offset (Soff)
		 *	  - Scaling pivot (Sp)
		 *	  - Geometric translation (Gt)
		 *	  - Geometric rotation (Gr)
		 *	  - Geometric scaling (Gs)
		 *
		 * These values combine in the matrix form to compute the World transform of the node
		 * using the formula:
		 *
		 * World = ParentWorld * T * Roff * Rp * Rpre * R * Rpost * Rp-1 * Soff * Sp * S * Sp-1
		 */
		public function calculateNodeTransformation():Matrix3D {
			var extraPostRotation:Number = 0;
			if (getAttribute(KFbxLight)) {
				// By default, a KFbxNode uses its positive X axis as the aiming constraint. Recall that
				// a newly created light points along the node's negative Y axis by default. To make the
				// light point along the node's positive X axis, a rotation offset of 90 degrees must be
				// applied to the light's node using KFbxNode::SetPostTargetRotation().
				extraPostRotation = 90;
			}

			var T:Matrix3D = new Matrix3D;
			T.prependTranslation(LclTranslation [0], LclTranslation [1], LclTranslation [2]);
			// rotation offset
			T.prependTranslation(RotationOffset [0], RotationOffset [1], RotationOffset [2]);
			// rotaton pivot
			var Rp:Matrix3D = new Matrix3D;
			Rp.prependTranslation(RotationPivot [0], RotationPivot [1], RotationPivot [2]);
			T.prepend(Rp);
			// prerotation
			T.prepend(makeRotationMatrix(PreRotation [0], PreRotation [1], PreRotation [2]));
			// rotation
			T.prepend(makeRotationMatrix(LclRotation [0], LclRotation [1], LclRotation [2]));
			// postrotation
			T.prepend(makeRotationMatrix(PostRotation [0] - extraPostRotation, PostRotation [1], PostRotation [2]));
			// inv. rotation pivot
			Rp.invert();
			T.prepend(Rp);
			// scaling offset
			T.prependTranslation(ScalingOffset [0], ScalingOffset [1], ScalingOffset [2]);
			// scaling pivot
			var Sp:Matrix3D = new Matrix3D;
			Sp.prependTranslation(ScalingPivot [0], ScalingPivot [1], ScalingPivot [2]);
			T.prepend(Sp);
			// scaling
			T.prependScale(LclScaling [0], LclScaling [1], LclScaling [2]);
			// inv. scaling pivot
			Sp.invert();
			T.prepend(Sp);

			return T;
		}

		/**
		 * Если возвращает ненулевое преобразование, аттрибуты должны быть по-любому добавлены
		 * как дочерние объекты к данной ноде.
		 *
		 * The geometric transformation (Gt * Gr * Gs) is applied only to the node attribute
		 * and after the node transformations. This transformation is not inherited across the
		 * node hierarchy.
		 *
		 * Gt * Gr * Gs вроде как используется только 3DMax-ом в редких случаях:
		 * @see http://download.autodesk.com/global/docs/fbxsdk2012/en_us/files/GUID-10CDD63C-79C1-4F2D-BB28-AD2BE65A02E-50.htm
		 */
		public function calculateAttributesTransformation():Matrix3D {
			var hasAttrTransform:Boolean;
			for (var i:int = 0; i < 3; i++) {
				hasAttrTransform ||= (GeometricTranslation [i] != 0);
				hasAttrTransform ||= (GeometricRotation [i] != 0);
				hasAttrTransform ||= (GeometricScaling [i] != 1);
			}

			if (hasAttrTransform) {
				// shit :(
				var G:Matrix3D = new Matrix3D;
				G.prependTranslation(GeometricTranslation [0], GeometricTranslation [1], GeometricTranslation [2]);
				G.prepend(makeRotationMatrix(GeometricRotation [0], GeometricRotation [1], GeometricRotation [2]));
				G.prependScale(GeometricScaling [0], GeometricScaling [1], GeometricScaling [2]);
				return G;
			}

			return null;
		}

		/**
		 * typedef enum
		 * { 
		 *	 eEULER_XYZ = 0,
		 *	 eEULER_XZY,
		 *	 eEULER_YZX,
		 *	 eEULER_YXZ,
		 *	 eEULER_ZXY,
		 *	 eEULER_ZYX,
		 *	 eSPHERIC_XYZ // WTF??
		 * } ERotationOrder;
		 */
		public var RotationOrder:int = 0;
		private const eEULER_XYZ:int = 0;
		private const eEULER_XZY:int = 1;
		private const eEULER_YZX:int = 2;
		private const eEULER_YXZ:int = 3;
		private const eEULER_ZXY:int = 4;
		private const eEULER_ZYX:int = 5;

		/**
		 * The R matrix takes into account the rotation order. Because of the mathematical
		 * properties of the matrices, R is the result of one of the possible combinations
		 * of Ry, Ry and Rz (each being matrices also). For example, for the default rotation
		 * order of XYZ, R = Rx * Ry * Rz
		 */
		private function makeRotationMatrix(rx:Number, ry:Number, rz:Number):Matrix3D {
			var R:Matrix3D = new Matrix3D;
			switch (RotationOrder) {
				case eEULER_XZY:
					R.appendRotation(rx, Vector3D.X_AXIS);
					R.appendRotation(rz, Vector3D.Z_AXIS);
					R.appendRotation(ry, Vector3D.Y_AXIS);
					break;

				case eEULER_YZX:
					R.appendRotation(ry, Vector3D.Y_AXIS);
					R.appendRotation(rz, Vector3D.Z_AXIS);
					R.appendRotation(rx, Vector3D.X_AXIS);
					break;

				case eEULER_YXZ:
					R.appendRotation(ry, Vector3D.Y_AXIS);
					R.appendRotation(rx, Vector3D.X_AXIS);
					R.appendRotation(rz, Vector3D.Z_AXIS);
					break;

				case eEULER_ZXY:
					R.appendRotation(rz, Vector3D.Z_AXIS);
					R.appendRotation(rx, Vector3D.X_AXIS);
					R.appendRotation(ry, Vector3D.Y_AXIS);
					break;

				case eEULER_ZYX:
					R.appendRotation(rz, Vector3D.Z_AXIS);
					R.appendRotation(ry, Vector3D.Y_AXIS);
					R.appendRotation(rx, Vector3D.X_AXIS);
					break;

				case eEULER_XYZ:
				default:
					R.appendRotation(rx, Vector3D.X_AXIS);
					R.appendRotation(ry, Vector3D.Y_AXIS);
					R.appendRotation(rz, Vector3D.Z_AXIS);
					break;
			}
			return R;
		}

		public var parent:KFbxNode;
		public var Children:Vector.<String> = new Vector.<String>();//* for V5 only */

		public var attributes:Vector.<KFbxNodeAttribute> = new Vector.<KFbxNodeAttribute>();

		public var materials:Vector.<KFbxSurfaceMaterial> = new Vector.<KFbxSurfaceMaterial>();
		public var textures:Vector.<KFbxTexture> = new Vector.<KFbxTexture>();

		public var Visibility:Number = 1;

		public function isVisible():Boolean {
			return (Visibility == 1);
		}

		/**
		 * Судя по методам в СДК, аттрибутов может быть много, но по одному одного типа.
		 */
		public function getAttribute(type:Class):KFbxNodeAttribute {
			for (var i:int = 0; i < attributes.length; i++) {
				var a:KFbxNodeAttribute = attributes [i];
				if (a is type) return a;
			}
			return null;
		}
	}
}
