package alternativa.engine3d.loaders.filmbox {

	/**
	 * @private SDK: A mesh is a geometry made of polygons.
	 * The class can define a geometry with as many n-sided polygons as needed. Users can freely mix triangles, quadrilaterals, and other polygons. Since the mesh-related terminology of the FBX SDK differs a little from the known standards, here are our definitions:
	 * A control point is an XYZ coordinate, it is synonym of vertex.
	 * A polygon vertex is an index to a control point (the same control point can be referenced by multiple polygon vertices).
	 * A polygon is a group of polygon vertices. The minimum valid number of polygon vertices to define a polygon is 3.
	 */
	public class KFbxMesh extends KFbxGeometry {
		/*
		 00955 public:
		 00956     //Please use GetPolygonVertexIndex and GetPolygonVertices to access these arrays.
		 00957     //DO NOT MODIFY them directly, otherwise unexpected behavior will occur.
		 00958     //These members are public only for application data copy performance reasons.
		 00959     struct KFbxPolygon{ int mIndex; int mSize; int mGroup; };
		 00960     KArrayTemplate<KFbxPolygon> mPolygons;
		 00961     KArrayTemplate<int> mPolygonVertices;
		 */

		/**
		 * mPolygonVertices.
		 * В файле: "PolygonVertexIndex"
		 * Пример:  0,3,2,-2,3,7,6,-3,0,4,7...
		 * отрицательные числа = последняя вершина полика XOR -1 (X XOR -1 = -X -1)
		 */
		public var PolygonVertexIndex:Vector.<Number> = new Vector.<Number>();
	}
}
