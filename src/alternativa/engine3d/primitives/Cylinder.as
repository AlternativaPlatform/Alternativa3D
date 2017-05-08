package alternativa.engine3d.primitives
{
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;
	
	/**
	 * Цилиндр.
	 * @public
	 * @author redefy
	 */
	public class Cylinder extends Mesh
	{
		/**
		 * Материал цилиндра.
		 */
		private var _material:Material;
		
		/**
		 * Радиус верхней части цилиндра.
		 */
		protected var _topRadius:Number;
		
		/**
		 * Радиус нижней части цилиндра.
		 */
		protected var _bottomRadius:Number;
		
		/**
		 * Высота цилиндра.
		 */
		protected var _height:Number;
		
		/**
		 * Определяет количество сегментов по горизонтали из которых будет состоять цилиндр. Значение по умолчанию равно 16.
		 */
		protected var _segmentsW:uint;
		
		/**
		 * Определяет количество сегментов по вертикали из которых будет состоять цилиндр. Значение по умолчанию равно 1.
		 */
		protected var _segmentsH:uint;
		
		/**
		 * Определяет будет ли верхний конец цилиндра закрытым (true) или открытым.
		 */
		protected var _topClosed:Boolean;
		
		/**
		 * Определяет будет ли нижний конец цилиндра закрытым (true) или открытым.
		 */
		protected var _bottomClosed:Boolean;
		
		/**
		 * Определяет будут ли поверхности цилиндра закрытыми (true) или открытыми.
		 */
		protected var _surfaceClosed:Boolean;
		
		/**
		 * Определяет как будут лежать полюса цилиндра, по оси Y(true) или по оси Z(false).
		 */
		protected var _yUp:Boolean;
		
		/**
		 * Stream.
		 */
		private var _attributes:Array;
		
		/**
		 * Вектор с координатами вершин цилиндра
		 */
		private var _rawVertexPositions:Vector.<Number>;
		
		/**
		 * Вектор с нормалями вершин цилиндра
		 */
		private var _rawVertexNormals:Vector.<Number>;
		
		/**
		 * Вектор с тангенсами вершин цилиндра
		 */
		private var _rawVertexTangents:Vector.<Number>;
		
		/**
		 * Вектор с UV-координатами вершин цилиндра
		 */
		private var _rawUvs:Vector.<Number>;
		
		/**
		 * Вектор с индексами вершин цилиндра
		 */
		private var _rawIndices:Vector.<uint>;
		
		/**
		 * Следующий индекс вершины.
		 */
		private var _nextVertexIndex:uint;
		
		/**
		 * Текущий индекс вершины.
		 */
		private var _currentIndex:uint;
		
		/**
		 * Текущий индекс треугольника.
		 */
		private var _currentTriangleIndex:uint;
		
		/**
		 * Смещение текущего индекса вершины.
		 */
		private var _vertexIndexOffset:uint;
		
		/**
		 * Конечное количество вершин
		 */
		private var _numVertices:uint;
		
		/**
		 * Конечное количество треугольников
		 */
		private var _numTriangles:uint;
		
		/**
		 * Конструктор цилиндра.
		 * @param topRadius Радиус верхней части цилиндра.
		 * @param bottomRadius Радиус нижней части цилиндра.
		 * @param height Высота цилиндра.
		 * @param segmentsW Определяет количество сегментов по горизонтали из которых будет состоять цилиндр. Значение по умолчанию равно 16.
		 * @param segmentsH Определяет количество сегментов по вертикали из которых будет состоять цилиндр. Значение по умолчанию равно 1.
		 * @param topClosed Определяет будет ли верхний конец цилиндра закрытым (true) или открытым.
		 * @param bottomClosed Определяет будет ли нижний конец цилиндра закрытым (true) или открытым.
		 * @param surfaceClosed Определяет будут ли поверхности цилиндра закрытыми (true) или открытыми.
		 * @param yUp Определяет как будут лежать полюса цилиндра, по оси Y(true) или по оси Z(false).
		 * @param material Материал, c которым будет рендерится цилиндр.
		 */
		public function Cylinder(topRadius:Number = 50, bottomRadius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, topClosed:Boolean = true, bottomClosed:Boolean = true, surfaceClosed:Boolean = true, yUp:Boolean = true, material:Material = null)
		{
			super(); //вызываем конструктор класса Mesh
			
			_material = material;
			_topRadius = topRadius;
			_bottomRadius = bottomRadius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_topClosed = topClosed;
			_bottomClosed = bottomClosed;
			_surfaceClosed = surfaceClosed;
			_yUp = yUp;
			
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
		 * Добавляет в вектора данных позицию вершины, ее нормаль и тангенс-вектор
		 */
		private function addVertex(px:Number, py:Number, pz:Number, nx:Number, ny:Number, nz:Number, tx:Number, ty:Number, tz:Number, bi:Number):void
		{
			var compVertInd:uint = _nextVertexIndex * 3; // текущий индекс вершины
			_rawVertexPositions[compVertInd] = px;
			_rawVertexPositions[compVertInd + 1] = py;
			_rawVertexPositions[compVertInd + 2] = pz;
			_rawVertexNormals[compVertInd] = nx;
			_rawVertexNormals[compVertInd + 1] = ny;
			_rawVertexNormals[compVertInd + 2] = nz;
			_rawVertexTangents[compVertInd] = tx;
			_rawVertexTangents[compVertInd + 1] = ty;
			_rawVertexTangents[compVertInd + 2] = tz;
			_rawVertexTangents[compVertInd + 3] = bi;
			_nextVertexIndex++;
		}
		
		/**
		 * Добавляет индексы вершин треугольника.
		 */
		private function addTriangleClockWise(cwVertexIndex0:uint, cwVertexIndex1:uint, cwVertexIndex2:uint):void
		{
			_rawIndices[_currentIndex++] = cwVertexIndex0;
			_rawIndices[_currentIndex++] = cwVertexIndex1;
			_rawIndices[_currentIndex++] = cwVertexIndex2;
			_currentTriangleIndex++;
		}
		
		/**
		 * Cоздает геометрию цилиндра.
		 */
		private function buildGeometry():void
		{
			var i:uint, j:uint;
			var x:Number, y:Number, z:Number, radius:Number, revolutionAngle:Number;
			
			// сбрасываем значения вспомогательных переменных
			_numVertices = 0;
			_numTriangles = 0;
			_nextVertexIndex = 0;
			_currentIndex = 0;
			_currentTriangleIndex = 0;
			
			// считаем конечное число вершин, треугольников и индексов
			if (_surfaceClosed)
			{
				_numVertices += (_segmentsH + 1) * (_segmentsW + 1); // segmentsH + 1 из-за закрытых поверхностей, segmentsW + 1 из-за UV развертки
				_numTriangles += _segmentsH * _segmentsW * 2; // каждый уровень имеет segmentW квадратов, каждый из которыйх состоит из 2 треугольников
			}
			if (_topClosed)
			{
				_numVertices += 2 * (_segmentsW + 1); // segmentsW + 1 из-за развертки
				_numTriangles += _segmentsW; // один треугольник на каждый сегмент
			}
			if (_bottomClosed)
			{
				_numVertices += 2 * (_segmentsW + 1);
				_numTriangles += _segmentsW;
			}
			
			var numVertComponents:uint = _numVertices * 3;
			_rawVertexPositions = new Vector.<Number>(numVertComponents, true);
			_rawVertexNormals = new Vector.<Number>(numVertComponents, true);
			_rawVertexTangents = new Vector.<Number>(_numVertices * 4, true);
			_rawIndices = new Vector.<uint>(_numTriangles * 3, true);
			
			// считаем шаг поворота
			var revolutionAngleDelta:Number = 2 * Math.PI / _segmentsW;
			
			// низ
			if (_bottomClosed)
			{
				
				z = -0.5 * _height;
				
				for (i = 0; i <= _segmentsW; ++i)
				{
					// центральная вершина
					if (_yUp)
						addVertex(0, -z, 0, 0, 1, 0, 1, 0, 0, 1);
					else
						addVertex(0, 0, z, 0, 0, -1, 1, 0, 0, 1);
					
					// поворот вершины
					revolutionAngle = i * revolutionAngleDelta;
					x = _bottomRadius * Math.cos(revolutionAngle);
					y = _bottomRadius * Math.sin(revolutionAngle);
					if (_yUp)
						addVertex(x, -z, y, 0, 1, 0, 1, 0, 0, 1);
					else
						addVertex(x, y, z, 0, 0, -1, 1, 0, 0, 1);
					
					if (i > 0) // добавляем треугольник
						addTriangleClockWise(_nextVertexIndex - 1, _nextVertexIndex - 3, _nextVertexIndex - 2);
				}
				
				_vertexIndexOffset = _nextVertexIndex;
			}
			
			// верх
			if (_topClosed)
			{
				
				z = 0.5 * _height;
				
				for (i = 0; i <= _segmentsW; ++i)
				{
					// центральная вершина
					if (_yUp)
						addVertex(0, -z, 0, 0, -1, 0, 1, 0, 0, 1);
					else
						addVertex(0, 0, z, 0, 0, 1, 1, 0, 0, 1);
					
					// поворот вершины
					revolutionAngle = i * revolutionAngleDelta;
					x = _topRadius * Math.cos(revolutionAngle);
					y = _topRadius * Math.sin(revolutionAngle);
					if (_yUp)
						addVertex(x, -z, y, 0, -1, 0, 1, 0, 0, 1);
					else
						addVertex(x, y, z, 0, 0, 1, 1, 0, 0, 1);
					
					if (i > 0) // добавляем треугольник
						addTriangleClockWise(_nextVertexIndex - 2, _nextVertexIndex - 3, _nextVertexIndex - 1);
				}
				
				_vertexIndexOffset = _nextVertexIndex;
			}
			
			// боковая поверхность
			if (_surfaceClosed)
			{
				var a:uint, b:uint, c:uint, d:uint;
				
				for (j = 0; j <= _segmentsH; ++j)
				{
					radius = _bottomRadius - ((j / _segmentsH) * (_bottomRadius - _topRadius));
					z = -(_height / 2) + (j / _segmentsH * _height);
					
					for (i = 0; i <= _segmentsW; ++i)
					{
						// поворот вершины
						revolutionAngle = i * revolutionAngleDelta;
						x = radius * Math.cos(revolutionAngle);
						y = radius * Math.sin(revolutionAngle);
						var tanLen:Number = Math.sqrt(y * y + x * x);
						if (_yUp)
							addVertex(x, -z, y, x / tanLen, 0, y / tanLen, tanLen > .007 ? -y / tanLen : 1, 0, tanLen > .007 ? x / tanLen : 0, 1);
						else
							addVertex(x, y, z, x / tanLen, y / tanLen, 0, tanLen > .007 ? -y / tanLen : 1, tanLen > .007 ? x / tanLen : 0, 0, 1);
						
						// закрываем треугольник
						if (i > 0 && j > 0)
						{
							a = _nextVertexIndex - 1; // текущий
							b = _nextVertexIndex - 2; // предыдущий
							c = b - _segmentsW - 1; // предыдущий последнего уровня
							d = a - _segmentsW - 1; // текущий последнего уровня
							addTriangleClockWise(a, b, c);
							addTriangleClockWise(a, c, d);
						}
					}
				}
			}
			
			// создаем реальные данные из сырых данных
			geometry = new Geometry();
			geometry.numVertices = _numVertices;
			geometry.indices = _rawIndices;
			geometry.addVertexStream(_attributes);
			geometry.setAttributeValues(VertexAttributes.POSITION, _rawVertexPositions);
			geometry.setAttributeValues(VertexAttributes.NORMAL, _rawVertexNormals);
			geometry.setAttributeValues(VertexAttributes.TANGENT4, _rawVertexTangents);
		}
		
		/**
		 * Cоздает UV
		 */
		private function buildUV():void
		{
			var i:int, j:int;
			var x:Number, y:Number, revolutionAngle:Number;
			
			// считаем количество UV
			var numUvs:uint = _numVertices * 2;
			
			_rawUvs = new Vector.<Number>(numUvs, true);
			
			// считаем шаг поворота
			var revolutionAngleDelta:Number = 2 * Math.PI / _segmentsW;
			
			// текущий индекс UV
			var currentUvCompIndex:uint = 0;
			
			// верх
			if (_topClosed)
			{
				for (i = 0; i <= _segmentsW; ++i)
				{
					
					revolutionAngle = i * revolutionAngleDelta;
					x = 0.5 + 0.5 * Math.cos(revolutionAngle);
					y = 0.5 + 0.5 * Math.sin(revolutionAngle);
					
					_rawUvs[currentUvCompIndex++] = 0.5; // центральная вершина
					_rawUvs[currentUvCompIndex++] = 0.5;
					_rawUvs[currentUvCompIndex++] = x; // поворот вершины
					_rawUvs[currentUvCompIndex++] = y;
				}
			}
			
			// низ
			if (_bottomClosed)
			{
				for (i = 0; i <= _segmentsW; ++i)
				{
					
					revolutionAngle = i * revolutionAngleDelta;
					x = 0.5 + 0.5 * Math.cos(revolutionAngle);
					y = 0.5 + 0.5 * Math.sin(revolutionAngle);
					
					_rawUvs[currentUvCompIndex++] = 0.5; // центральная вершина
					_rawUvs[currentUvCompIndex++] = 0.5;
					_rawUvs[currentUvCompIndex++] = x; // поворот вершины
					_rawUvs[currentUvCompIndex++] = y;
				}
			}
			
			// боковая поверхность
			if (_surfaceClosed)
			{
				for (j = 0; j <= _segmentsH; ++j)
				{
					for (i = 0; i <= _segmentsW; ++i)
					{
						// поворот вершины
						_rawUvs[currentUvCompIndex++] = i / _segmentsW;
						_rawUvs[currentUvCompIndex++] = j / _segmentsH;
					}
				}
			}
			
			// создаем реальные данные из сырых данных
			geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], _rawUvs);
			addSurface(_material, 0, geometry.indices.length / 3);
			calculateBoundBox();
			setMaterialToAllSurfaces(_material);
		}
		
		/**
		 * Радиус верхней части цилиндра.
		 */
		public function get topRadius():Number
		{
			return _topRadius;
		}
		
		/**
		 * Радиус нижней части цилиндра.
		 */
		public function get bottomRadius():Number
		{
			return _bottomRadius;
		}
		
		/**
		 * Высота цилиндра.
		 */
		public function get height():Number
		{
			return _height;
		}
		
		/**
		 * Количество сегментов по горизонтали из которых состоит цилиндр. Значение по умолчанию равно 16.
		 */
		public function get segmentsW():uint
		{
			return _segmentsW;
		}
		
		/**
		 * Количество сегментов по вертикали из которых состоит цилиндр. Значение по умолчанию равно 1.
		 */
		public function get segmentsH():uint
		{
			return _segmentsH;
		}
		
		/**
		 * Верхний конец цилиндра закрытый (true) или открытый ?
		 */
		public function get topClosed():Boolean
		{
			return _topClosed;
		}
		
		/**
		 * Нижний конец цилиндра закрытый (true) или открытый ?
		 */
		public function get bottomClosed():Boolean
		{
			return _bottomClosed;
		}
		
		/**
		 * Поверхности цилиндра закрытые (true) или открытые ?
		 */
		public function get surfaceClosed():Boolean
		{
			return _surfaceClosed;
		}
		
		/**
		 * Как лежат полюса цилиндра, по оси Y(true) или по оси Z(false) ?
		 */
		public function get yUp():Boolean
		{
			return _yUp;
		}
	}
}