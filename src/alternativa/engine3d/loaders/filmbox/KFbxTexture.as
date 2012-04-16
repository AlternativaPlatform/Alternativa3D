package alternativa.engine3d.loaders.filmbox {

	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * @private SDK: This class is the base class for textures,
	 * ie classes KFbxFileTexture, KFbxLayeredTexture and KFbxProceduralTexture.
	 */
	public class KFbxTexture {

		public var RelativeFilename:String = "";
		/* these aren't actually set by 3dmax?
		 public var ModelUVTranslation:Vector.<Number> = new <Number> [0, 0];
		 public var ModelUVScaling:Vector.<Number> = new <Number> [1, 1];
		 */
		public var Translation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var Rotation:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var Scaling:Vector.<Number> = Vector.<Number>([1, 1, 1]);
		public var TextureRotationPivot:Vector.<Number> = Vector.<Number>([0, 0, 0]);
		public var TextureScalingPivot:Vector.<Number> = Vector.<Number>([0, 0, 0]);

		public var transformation:Matrix;

		public function calculateTextureTransformation():Matrix {
			// guesswork by analogy to KFbxNode formula
			var T:Matrix3D = new Matrix3D;
			T.prependTranslation(Translation [0], Translation [1], Translation [2]);
			// rotaton pivot
			var Rp:Matrix3D = new Matrix3D;
			Rp.prependTranslation(TextureRotationPivot [0], TextureRotationPivot [1], TextureRotationPivot [2]);
			T.prepend(Rp);
			// rotation
			T.prepend(makeRotationMatrix(Rotation [0], Rotation [1], Rotation [2]));
			// inv. rotation pivot
			Rp.invert();
			T.prepend(Rp);
			// scaling pivot
			var Sp:Matrix3D = new Matrix3D;
			Sp.prependTranslation(TextureScalingPivot [0], TextureScalingPivot [1], TextureScalingPivot [2]);
			T.prepend(Sp);
			// scaling
			T.prependScale(Scaling [0], Scaling [1], Scaling [2]);
			// inv. scaling pivot
			Sp.invert();
			T.prepend(Sp);

			// sample transform at W = 0
			var raw:Vector.<Number> = T.rawData;
			transformation = new Matrix(raw [0], raw [1], raw [4], raw [5], raw [3], raw [7]);

			return transformation;
		}

		private function makeRotationMatrix(rx:Number, ry:Number, rz:Number):Matrix3D {
			var R:Matrix3D = new Matrix3D;
			R.prependRotation(rx, Vector3D.X_AXIS);
			R.prependRotation(ry, Vector3D.Y_AXIS);
			R.prependRotation(rz, Vector3D.Z_AXIS);
			return R;
		}

	}

}
