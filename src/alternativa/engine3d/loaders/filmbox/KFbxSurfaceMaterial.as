package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: This class contains material settings.
	 */
	public dynamic class KFbxSurfaceMaterial {
		/*
		 // v6 properties
		 public var ShadingModel:String = "Phong";
		 public var EmissiveColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var EmissiveFactor:Number = 1;
		 public var AmbientColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var AmbientFactor:Number = 1;
		 public var DiffuseColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var DiffuseFactor:Number = 1;
		 public var Bump:Vector.<Number> = new <Number> [0, 0, 0];
		 public var TransparentColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var TransparencyFactor:Number = 1;
		 public var SpecularColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var SpecularFactor:Number = 1;
		 public var ShininessExponent:Number = 1;
		 public var ReflectionColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var ReflectionFactor:Number = 1;
		 public var Emissive:Vector.<Number> = new <Number> [0, 0, 0];
		 public var Ambient:Vector.<Number> = new <Number> [0, 0, 0];
		 public var Diffuse:Vector.<Number> = new <Number> [0, 0, 0];
		 public var Specular:Vector.<Number> = new <Number> [0, 0, 0];
		 public var Shininess:Number = 1;
		 public var Opacity:Number = 1;
		 public var Reflectivity:Number = 1;
		 // v7 properties
		 public var NormalMap:Vector.<Number> = new <Number> [0, 0, 0];
		 public var BumpFactor:Number = 1;
		 public var DisplacementColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var DisplacementFactor:Number = 1;
		 public var VectorDisplacementColor:Vector.<Number> = new <Number> [0, 0, 0];
		 public var VectorDisplacementFactor:Number = 1;
		 */
		public function KFbxSurfaceMaterial() {
			// vars dynamic vars so that for (var property:String in this) could work
			// copy through byte array: ba.readObject() wastes memory
			// manual prop-after-prop copying: spagetti code, could miss new props if any
			// describeType: could be an option..

			// v6 properties
			this.ShadingModel = "Phong";
			this.EmissiveColor = Vector.<Number>([0, 0, 0]);
			this.EmissiveFactor = 1;
			this.AmbientColor = Vector.<Number>([0, 0, 0]);
			this.AmbientFactor = 1;
			this.DiffuseColor = Vector.<Number>([0, 0, 0]);
			this.DiffuseFactor = 1;
			this.Bump = Vector.<Number>([0, 0, 0]);
			this.TransparentColor = Vector.<Number>([0, 0, 0]);
			this.TransparencyFactor = 1;
			this.SpecularColor = Vector.<Number>([0, 0, 0]);
			this.SpecularFactor = 1;
			this.ShininessExponent = 1;
			this.ReflectionColor = Vector.<Number>([0, 0, 0]);
			this.ReflectionFactor = 1;
			this.Emissive = Vector.<Number>([0, 0, 0]);
			this.Ambient = Vector.<Number>([0, 0, 0]);
			this.Diffuse = Vector.<Number>([0, 0, 0]);
			this.Specular = Vector.<Number>([0, 0, 0]);
			this.Shininess = 1;
			this.Opacity = 1;
			this.Reflectivity = 1;
			// v7 properties
			this.NormalMap = Vector.<Number>([0, 0, 0]);
			this.BumpFactor = 1;
			this.DisplacementColor = Vector.<Number>([0, 0, 0]);
			this.DisplacementFactor = 1;
			this.VectorDisplacementColor = Vector.<Number>([0, 0, 0]);
			this.VectorDisplacementFactor = 1;
		}

		// node pointer for v7 to propagate textures up to node
		public var node:KFbxNode;

		// textures
		public var textures:Object = {};

		public function copyTo(dest:KFbxSurfaceMaterial):void {
			// shallow copy dynamic properties
			for (var property:String in dest) dest [property] = this [property];
			// and textures
			for (var channel:String in textures) dest.textures [channel] = this.textures [channel];
		}
	}
}
