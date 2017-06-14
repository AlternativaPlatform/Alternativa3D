package alternativa.engine3d.primitives
{
	import alternativa.engine3d.materials.Material;
	
	/**
	 * Конус.
	 * @public
	 * @author redefy
	 */
	public class Cone extends Cylinder
	{
		
		/**
		 * Радиус нижней части конуса.
		 */
		public function get radius():Number
		{
			return _bottomRadius;
		}
		
		/**
		 * Конструктор конуса.
		 * @param radius Радиус нижней части конуса.
		 * @param height Высота конуса.
		 * @param segmentsW Определяет количество сегментов по горизонтали из которых будет состоять конус. Значение по умолчанию равно 16.
		 * @param segmentsH Определяет количество сегментов по вертикали из которых будет состоять конус. Значение по умолчанию равно 1.
		 * @param closed Определяет будет ли нижний конец конуса закрытым (true) или открытым.
		 * @param yUp Определяет как будут лежать полюса конуса, по оси Y(true) или по оси Z(false).
		 * @param material Материал, c которым будет рендерится конус.
		 */
		public function Cone(radius:Number = 50, height:Number = 100, segmentsW:uint = 16, segmentsH:uint = 1, closed:Boolean = true, yUp:Boolean = true, material:Material = null)
		{
			super(0, radius, height, segmentsW, segmentsH, false, closed, true, yUp, material);
		}
	}
}