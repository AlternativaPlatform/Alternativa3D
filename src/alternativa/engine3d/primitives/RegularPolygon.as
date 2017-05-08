package alternativa.engine3d.primitives
{
	import alternativa.engine3d.materials.Material;
	
	/**
	 * Правильный многоугольник.
	 * @public
	 * @author redefy
	 */
	public class RegularPolygon extends Cylinder
	{
		
		/**
		 * Радиус правильного многоугольника.
		 */
		public function get radius():Number
		{
			return _bottomRadius;
		}
		
		/**
		 * Число сторон правильного многоугольника.
		 */
		public function get sides():uint
		{
			return _segmentsW;
		}
		
		/**
		 * Количество делений правильного многоугольника от края к центру.
		 */
		public function get subdivisions():uint
		{
			return _segmentsH;
		}
		
		/**
		 * Конструктор правильного многоугольника.
		 * @param radius Радиус правильного многоугольника.
		 * @param sides Определяет число сторон правильного многоугольника. Значение по умолчанию равно 16.
		 * @param yUp Определяет как будут лежать полюса правильного многоугольника, по оси Y(true) или по оси Z(false).
		 * @param material Материал, c которым будет рендерится правильный многоугольник.
		 */
		public function RegularPolygon(radius:Number = 100, sides:uint = 16, yUp:Boolean = true, material:Material = null)
		{
			super(radius, 0, 0, sides, 1, true, false, false, yUp, material);
		}
	}
}