package alternativa.engine3d.primitives
{
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;
	
	/**
	 * Капсула.
	 * @public
	 * @author redefy
	 */
	public class Capsule extends Mesh
	{
		/**
		 * Материал капсулы
		 */
		private var _material:Material;
		
		/**
		 * Радиус капсулы
		 */
		private var _radius:Number;
		
		/**
		 * Высота капсулы
		 */
		private var _height:Number;
		
		/**
		 * Количество сегментов по горизонтали из которых будет состоять капсула.
		 */
		private var _segmentsW:uint;
		
		/**
		 * Количество сегментов по вертикали из которых будет состоять капсула.
		 */
		private var _segmentsH:uint;
		
		/**
		 * Определяет как будут лежать полюса капсулы, по оси Y(true) или по оси Z(false).
		 */
		private var _yUp:Boolean;
		
		/**
		 * Stream.
		 */
		private var _attributes:Array;
		
		/**
		 * Конструктор капсулы.
		 * @param radius Радиус капсулы.
		 * @param height Высота капсулы.
		 * @param segmentsW Определяет количество сегментов по горизонтали из которых будет состоять капсула. Значение по умолчанию равно 16.
		 * @param segmentsH Определяет количество сегментов по вертикали из которых будет состоять капсула. Значение по умолчанию равно 12.
		 * @param yUp Определяет как будут лежать полюса капсулы, по оси Y(true) или по оси Z(false).
		 * @param material Материал, c которым будет рендерится капсула.
		 */
		public function Capsule(radius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 12, yUp:Boolean = true, material:Material = null)
		{
			super(); //вызываем конструктор класса Mesh
			
			_material = material; //записываем материал в приватную переменную _material
			_radius = radius; //записываем радиус капсулы переданный в конструктор класса в приватную переменную _radius
			_height = height; //записываем высоту капсулы переданную в конструктор класса в приватную переменную _height
			_segmentsW = segmentsW; //записываем количество сегментов по горизонтали переданных в конструктор класса в приватную переменную _segmentsW
			_segmentsH = segmentsH; //записываем количество сегментов по вертикали переданных в конструктор класса в приватную переменную _segmentsH
			_yUp = yUp; //записываем расположение полюсов капсулы переданных в конструктор класса в приватную переменную _yUp
			
			createStream();
			buildGeometry();
			buildUV();
		}
		
		/**
		 * Создает Stream.
		 */
		private function createStream():void
		{
			_attributes = [VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.POSITION, VertexAttributes.TEXCOORDS[0], VertexAttributes.TEXCOORDS[0], VertexAttributes.NORMAL, VertexAttributes.NORMAL, VertexAttributes.NORMAL, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4, VertexAttributes.TANGENT4];
		}
		
		/**
		 * Cоздает геометрию капсулы
		 */
		private function buildGeometry():void
		{
			var vertices:Vector.<Number>;
			var vertexNormals:Vector.<Number>;
			var vertexTangents:Vector.<Number>;
			var indices:Vector.<uint>;
			var i:uint, j:uint, triIndex:uint;
			var numVerts:uint = (_segmentsH + 1) * (_segmentsW + 1);
			var numTangents:uint;
			
			vertices = new Vector.<Number>(numVerts * 3, true);
			vertexNormals = new Vector.<Number>(numVerts * 3, true);
			vertexTangents = new Vector.<Number>(numVerts * 4, true);
			indices = new Vector.<uint>((_segmentsH - 1) * _segmentsW * 6, true);
			
			numVerts = 0;
			numTangents = 0;
			for (j = 0; j <= _segmentsH; ++j)
			{
				var horangle:Number = Math.PI * j / _segmentsH;
				var z:Number = -_radius * Math.cos(horangle);
				var ringradius:Number = _radius * Math.sin(horangle);
				
				for (i = 0; i <= _segmentsW; ++i)
				{
					var verangle:Number = 2 * Math.PI * i / _segmentsW;
					var x:Number = ringradius * Math.cos(verangle);
					var offset:Number = j > _segmentsH / 2 ? _height / 2 : -_height / 2;
					var y:Number = ringradius * Math.sin(verangle);
					var normLen:Number = 1 / Math.sqrt(x * x + y * y + z * z);
					var tanLen:Number = Math.sqrt(y * y + x * x);
					
					if (_yUp)
					{
						vertexNormals[numVerts] = x * normLen;
						vertexTangents[numTangents++] = tanLen > .007 ? -y / tanLen : 1;
						vertices[numVerts++] = x;
						vertexNormals[numVerts] = -z * normLen;
						vertexTangents[numTangents++] = 0;
						vertices[numVerts++] = -z - offset;
						vertexNormals[numVerts] = y * normLen;
						vertexTangents[numTangents++] = tanLen > .007 ? x / tanLen : 0;
						vertexTangents[numTangents++] = 1;
						vertices[numVerts++] = y;
					}
					else
					{
						vertexNormals[numVerts] = x * normLen;
						vertexTangents[numTangents++] = tanLen > .007 ? -y / tanLen : 1;
						vertices[numVerts++] = x;
						vertexNormals[numVerts] = y * normLen;
						vertexTangents[numTangents++] = tanLen > .007 ? x / tanLen : 0;
						vertices[numVerts++] = y;
						vertexNormals[numVerts] = z * normLen;
						vertexTangents[numTangents++] = 0;
						vertexTangents[numTangents++] = 1;
						vertices[numVerts++] = z + offset;
					}
					
					if (i > 0 && j > 0)
					{
						var a:int = (_segmentsW + 1) * j + i;
						var b:int = (_segmentsW + 1) * j + i - 1;
						var c:int = (_segmentsW + 1) * (j - 1) + i - 1;
						var d:int = (_segmentsW + 1) * (j - 1) + i;
						
						if (j == _segmentsH)
						{
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
						else if (j == 1)
						{
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
						}
						else
						{
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
					}
				}
			}
			
			geometry = new Geometry();
			geometry.numVertices = numVerts / 3;
			geometry.indices = indices;
			geometry.addVertexStream(_attributes);
			geometry.setAttributeValues(VertexAttributes.POSITION, vertices);
			geometry.setAttributeValues(VertexAttributes.NORMAL, vertexNormals);
			geometry.setAttributeValues(VertexAttributes.TANGENT4, vertexTangents);
		}
		
		/**
		 * Cоздает UV
		 */
		private function buildUV():void
		{
			var i:int, j:int;
			var numUvs:uint = (_segmentsH + 1) * (_segmentsW + 1) * 2;
			var uvData:Vector.<Number>;
			
			uvData = new Vector.<Number>(numUvs, true);
			
			numUvs = 0;
			for (j = 0; j <= _segmentsH; ++j)
			{
				for (i = 0; i <= _segmentsW; ++i)
				{
					uvData[numUvs++] = i / _segmentsW;
					uvData[numUvs++] = j / _segmentsH;
				}
			}
			
			geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], uvData);
			addSurface(_material, 0, geometry.indices.length / 3);
			calculateBoundBox();
			setMaterialToAllSurfaces(_material);
		}
		
		/**
		 * Радиус капсулы.
		 */
		public function get radius():Number
		{
			return _radius;
		}
		
		/**
		 * Высота капсулы.
		 */
		public function get height():Number
		{
			return _height;
		}
		
		/**
		 * Количество сегментов по горизонтали из которых состоит капсула. Значение по умолчанию равно 16.
		 */
		public function get segmentsW():uint
		{
			return _segmentsW;
		}
		
		/**
		 * Количество сегментов по вертикали из которых состоит капсула. Значение по умолчанию равно 12.
		 */
		public function get segmentsH():uint
		{
			return _segmentsH;
		}
		
		/**
		 *  Как лежат полюса капсулы, по оси Y(true) или по оси Z(false).
		 */
		public function get yUp():Boolean
		{
			return _yUp;
		}
	}
}