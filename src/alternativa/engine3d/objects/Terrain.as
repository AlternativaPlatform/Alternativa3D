package alternativa.engine3d.objects
{
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.resources.Geometry;
	import flash.display.BitmapData;
	import flash.geom.Vector3D;
	
	/**
	 * Создает Mesh из карты высот.
	 * @public
	 * @author redefy
	 */
	public class Terrain extends Mesh
	{
		private var _heights:Vector.<Number>;
		
		private var _segmentsW:uint;
		private var _segmentsH:uint;
		private var _width:Number;
		private var _height:Number;
		private var _depth:Number;
		private var _heightMap:BitmapData;
		private var _material:Material;
		
		private var _smoothedHeightMap:BitmapData;
		private var _activeMap:BitmapData;
		private var _minElevation:uint;
		private var _maxElevation:uint;
		private var attributes:Array;
		
		/**
		 * Конструктор
		 * @param material Материал, который будет наложен на A3DTerrain
		 * @param heightMap Карта высот. По ней будет сгенерирован меш
		 * @param width ширина меша
		 * @param depth длина меша
		 * @param height высота меша
		 * @param segmentsW количество сегментов меша по его ширине
		 * @param segmentsH количество сегментов меша по его длине
		 * @param maxElevation максимальное значение цвета, которое будет учитываться при генерации меша
		 * @param minElevation минимальное значение цвета, которое будет учитываться при генерации меша
		 * @param smoothMap если true, то резкие переходы цвета на карте высот сглаживаются.
		 */
		public function Terrain(material:Material, heightMap:BitmapData, width:Number = 1000, height:Number = 100, depth:Number = 1000, segmentsW:uint = 30, segmentsH:uint = 30, maxElevation:uint = 255, minElevation:uint = 0, smoothMap:Boolean = false)
		{
			super();
			
			geometry = new Geometry();
			_heightMap = heightMap;
			_activeMap = heightMap;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_material = material;
			_width = width;
			_height = height;
			_depth = depth;
			_maxElevation = maxElevation;
			_minElevation = minElevation;
			
			buildGeometry();
			
			if (smoothMap) smoothHeightMap();
			
			var _minW:Number = -width / 2;
			var _minH:Number = -depth / 2;
			var _dw:Number = width / segmentsW;
			var _dh:Number = depth / segmentsH;
			
			_heights = new Vector.<Number>();
			for (var iy:int = 0; iy < _segmentsH; iy++)
			{
				for (var ix:int = 0; ix < _segmentsW; ix++)
				{
					_heights.push(this.getHeightAt(_minW + (_dw * ix), _minH + (_dh * iy)));
				}
			}
		}
		
		/**
		 * Количество сегментов по ширине меша.
		 * @public (getter)
		 */
		public function get sw():int  { return _segmentsW; }
		
		/**
		 * Количество сегментов по длине меша.
		 * @public (getter)
		 */
		public function get sh():int  { return _segmentsH; }
		
		/**
		 * Ширина меша
		 * @public (getter)
		 */
		public function get lw():Number  { return this._width; }
		
		/**
		 * Длина меша.
		 * @public (getter)
		 */
		public function get lh():Number  { return this._depth; }
		
		/**
		 * Максимальная высота меша.
		 * @public (getter)
		 */
		public function get maxHeight():Number  { return _maxElevation; }
		
		/**
		 * Вектор с высотой для каждого сегмента.
		 * @public (getter)
		 */
		public function get heights():Vector.<Number>  { return _heights; }
		
		/**
		 * Считывает высоту поверхности иcходя из координаты пикселя на карте высот.
		 * @public
		 * @param x Координата пикселя по оси X
		 * @param y Координата пикселя по оси Y
		 * @return Number
		 */
		public function getHeightAt(x:Number, z:Number):Number
		{
			var col:uint = _activeMap.getPixel((x / _width + .5) * _activeMap.width, (-z / _depth + .5) * _activeMap.height) & 0xff;
			return (col > _maxElevation) ? (_maxElevation / 0xff) * _height : ((col < _minElevation) ? (_minElevation / 0xff) * _height : (col / 0xff) * _height);
		}
		
		/**
		 * При вызове этой функции оригинальная карта высот подвергается обработке, если на карте есть резкие переходы цвета, то геометрия меша будет иметь также резкие, острые переходы.
		 * Эта функция сглаживает такие участки цвета на карте высот.
		 * @public
		 */
		public function smoothHeightMap():void
		{
			if (_smoothedHeightMap)
				_smoothedHeightMap.dispose();
			_smoothedHeightMap = new BitmapData(_heightMap.width, _heightMap.height, false, 0);
			
			var w:uint = _smoothedHeightMap.width;
			var h:uint = _smoothedHeightMap.height;
			var i:uint;
			var j:uint;
			var k:uint;
			var l:uint;
			
			var px1:uint;
			var px2:uint;
			var px3:uint;
			var px4:uint;
			
			var lockx:uint;
			var locky:uint;
			
			_smoothedHeightMap.lock();
			
			var incXL:Number;
			var incXR:Number;
			var incYL:Number;
			var incYR:Number;
			var pxx:Number;
			var pxy:Number;
			
			for (i = 0; i < w + 1; i += _segmentsW)
			{
				
				if (i + _segmentsW > w - 1)
				{
					lockx = w - 1;
				}
				else
				{
					lockx = i + _segmentsW;
				}
				
				for (j = 0; j < h + 1; j += _segmentsH)
				{
					
					if (j + _segmentsH > h - 1)
					{
						locky = h - 1;
					}
					else
					{
						locky = j + _segmentsH;
					}
					
					if (j == 0)
					{
						px1 = _heightMap.getPixel(i, j) & 0xFF;
						px1 = (px1 > _maxElevation) ? _maxElevation : ((px1 < _minElevation) ? _minElevation : px1);
						px2 = _heightMap.getPixel(lockx, j) & 0xFF;
						px2 = (px2 > _maxElevation) ? _maxElevation : ((px2 < _minElevation) ? _minElevation : px2);
						px3 = _heightMap.getPixel(lockx, locky) & 0xFF;
						px3 = (px3 > _maxElevation) ? _maxElevation : ((px3 < _minElevation) ? _minElevation : px3);
						px4 = _heightMap.getPixel(i, locky) & 0xFF;
						px4 = (px4 > _maxElevation) ? _maxElevation : ((px4 < _minElevation) ? _minElevation : px4);
					}
					else
					{
						px1 = px4;
						px2 = px3;
						px3 = _heightMap.getPixel(lockx, locky) & 0xFF;
						px3 = (px3 > _maxElevation) ? _maxElevation : ((px3 < _minElevation) ? _minElevation : px3);
						px4 = _heightMap.getPixel(i, locky) & 0xFF;
						px4 = (px4 > _maxElevation) ? _maxElevation : ((px4 < _minElevation) ? _minElevation : px4);
					}
					
					for (k = 0; k < _segmentsW; ++k)
					{
						incXL = 1 / _segmentsW * k;
						incXR = 1 - incXL;
						
						for (l = 0; l < _segmentsH; ++l)
						{
							incYL = 1 / _segmentsH * l;
							incYR = 1 - incYL;
							
							pxx = ((px1 * incXR) + (px2 * incXL)) * incYR;
							pxy = ((px4 * incXR) + (px3 * incXL)) * incYL;
							
							//_smoothedHeightMap.setPixel(k+i, l+j, pxy+pxx << 16 |  0xFF-(pxy+pxx) << 8 | 0xFF-(pxy+pxx) );
							_smoothedHeightMap.setPixel(k + i, l + j, pxy + pxx << 16 | pxy + pxx << 8 | pxy + pxx);
						}
					}
				}
			}
			_smoothedHeightMap.unlock();
			
			_activeMap = _smoothedHeightMap;
		}
		
		/**
		 * Возвращает сглаженную карту высот если до этого была вызвана функция smoothHeightMap().
		 * @public
		 * @return BitmapData
		 */
		public function get smoothedHeightMap():BitmapData
		{
			return _smoothedHeightMap;
		}
		
		private function buildGeometry():void
		{
			
			attributes = [];
			attributes[0] = VertexAttributes.POSITION;
			attributes[1] = VertexAttributes.POSITION;
			attributes[2] = VertexAttributes.POSITION;
			attributes[3] = VertexAttributes.TEXCOORDS[0];
			attributes[4] = VertexAttributes.TEXCOORDS[0];
			attributes[5] = VertexAttributes.NORMAL, attributes[6] = VertexAttributes.NORMAL, attributes[7] = VertexAttributes.NORMAL, geometry.addVertexStream(attributes);
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var normals:Vector.<Number> = new Vector.<Number>();
			var tangent:Vector.<Number> = new Vector.<Number>();
			var x:Number, z:Number;
			var numInds:uint;
			var base:uint;
			var tw:uint = _segmentsW + 1;
			var numVerts:uint = (_segmentsH + 1) * tw;
			var uDiv:Number = (_heightMap.width - 1) / _segmentsW;
			var vDiv:Number = (_heightMap.height - 1) / _segmentsH;
			var u:Number, v:Number;
			var y:Number;
			
			if (numVerts == geometry.numVertices)
			{
				vertices = geometry.getAttributeValues(VertexAttributes.POSITION);
				indices = geometry.indices;
			}
			else
			{
				vertices = new Vector.<Number>(numVerts * 3, true);
				indices = new Vector.<uint>(_segmentsH * _segmentsW * 6, true);
			}
			
			numVerts = 0;
			var col:uint;
			
			for (var zi:uint = 0; zi <= _segmentsH; ++zi)
			{
				for (var xi:uint = 0; xi <= _segmentsW; ++xi)
				{
					x = (xi / _segmentsW - .5) * _width;
					z = (zi / _segmentsH - .5) * _depth;
					u = xi * uDiv;
					v = (_segmentsH - zi) * vDiv;
					
					col = _heightMap.getPixel(u, v) & 0xff;
					y = (col > _maxElevation) ? (_maxElevation / 0xff) * _height : ((col < _minElevation) ? (_minElevation / 0xff) * _height : (col / 0xff) * _height);
					
					vertices[numVerts++] = x;
					vertices[numVerts++] = y;
					vertices[numVerts++] = z;
					
					if (xi != _segmentsW && zi != _segmentsH)
					{
						base = xi + zi * tw;
						indices[numInds++] = base;
						indices[numInds++] = base + tw;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base + 1;
					}
				}
			}
			
			geometry.numVertices = vertices.length / 3;
			geometry.indices = indices;
			geometry.setAttributeValues(VertexAttributes.POSITION, vertices);
			
			var uvs:Vector.<Number> = new Vector.<Number>();
			var numUvs:uint = (_segmentsH + 1) * (_segmentsW + 1) * 2;
			
			if (geometry.getAttributeValues(VertexAttributes.TEXCOORDS[0]) && numUvs == geometry.getAttributeValues(VertexAttributes.TEXCOORDS[0]).length)
				uvs = geometry.getAttributeValues(VertexAttributes.TEXCOORDS[0])
			else
				uvs = new Vector.<Number>(numUvs, true);
			
			numUvs = 0;
			for (var yuvs:uint = 0; yuvs <= _segmentsH; ++yuvs)
			{
				for (var xuvs:uint = 0; xuvs <= _segmentsW; ++xuvs)
				{
					uvs[numUvs++] = xuvs / _segmentsW;
					uvs[numUvs++] = 1 - yuvs / _segmentsH;
				}
			}
			
			var index:int;
			var normal:Vector3D;
			
			for (index = 0; index < geometry.numVertices; index++)
			{
				normal = calcNormals(new Vector3D(vertices[index], vertices[index + 1], vertices[index + 2]), new Vector3D(vertices[index + 3], vertices[index + 4], vertices[index + 5]), new Vector3D(vertices[index + 6], vertices[index + 7], vertices[index + 8]))
				normals.push(normal.x, normal.y, normal.z);
			}
			
			geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], uvs);
			geometry.setAttributeValues(VertexAttributes.NORMAL, normals);
			
			addSurface(_material, 0, geometry.numTriangles);
		}
		
		private function calcNormals(a:Vector3D, b:Vector3D, c:Vector3D):Vector3D
		{
			var v1:Vector3D = a.subtract(b);
			var v2:Vector3D = a.subtract(c);
			var v3:Vector3D = v1.crossProduct(v2);
			v3.normalize();
			return (v3);
		}
	}
}