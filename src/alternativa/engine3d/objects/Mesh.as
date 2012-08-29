/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.resources.Geometry;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 *  A polygonal object defined by set of vertices and surfaces built on this vertices. <code>Surface</code> is a set of triangles which have same material.
	 *  To get access to vertices data you should use <code>geometry</code> property.
	 */
	public class Mesh extends Object3D {

		/**
		 * Through <code>geometry </code> property you can get access to vertices.
		 * @see alternativa.engine3d.resources.Geometry
		 */
		public var geometry:Geometry;

		/**
		 * @private
		 */
		alternativa3d var _surfaces:Vector.<Surface> = new Vector.<Surface>();
		/**
		 * @private
		 */
		alternativa3d var _surfacesLength:int = 0;

		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D):RayIntersectionData {
			var childrenData:RayIntersectionData = super.intersectRay(origin, direction);
			var contentData:RayIntersectionData;
			if (geometry != null && (boundBox == null || boundBox.intersectRay(origin, direction))) {
				var minTime:Number = 1e22;
				for each (var surface:Surface in _surfaces) {
					var data:RayIntersectionData = geometry.intersectRay(origin, direction, surface.indexBegin, surface.numTriangles);
					if (data != null && data.time < minTime) {
						contentData = data;
						contentData.object = this;
						contentData.surface = surface;
						minTime = data.time;
					}
				}
			}
			if (childrenData != null) {
				if (contentData != null) {
					return childrenData.time < contentData.time ? childrenData : contentData;
				} else {
					return childrenData;
				}
			} else {
				return contentData;
			}
		}

		// TODO: Add removeSurface() method

		/**
		 * Adds <code>Surface</code> to <code>Mesh</code> object.
		 * @param material Material of the surface.
		 * @param indexBegin Position of the firs index of  surface in the geometry.
		 * @param numTriangles Number of triangles.
		 */
		public function addSurface(material:Material, indexBegin:uint, numTriangles:uint):Surface {
			var res:Surface = new Surface();
			res.object = this;
			res.material = material;
			res.indexBegin = indexBegin;
			res.numTriangles = numTriangles;
			_surfaces[_surfacesLength++] = res;
			return res;
		}

		/**
		 * Returns surface by index.
		 *
		 * @param index  Index.
		 * @return  Surface with given index.
		 */
		public function getSurface(index:int):Surface {
			return _surfaces[index];
		}

		/**
		 * Number of surfaces.
		 */
		public function get numSurfaces():int {
			return _surfacesLength;
		}

		/**
		 * Assign given material to all surfaces.
		 *
		 * @param material Material.
		 * @see alternativa.engine3d.objects.Surface
		 * @see alternativa.engine3d.materials
		 */
		public function setMaterialToAllSurfaces(material:Material):void {
			for (var i:int = 0; i < _surfaces.length; i++) {
				_surfaces[i].material = material;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function get useLights():Boolean {
			return true;
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (geometry != null) geometry.updateBoundBox(boundBox, transform);
		}
		
		/**
		 * @private
		 */
		alternativa3d override function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (geometry != null && (resourceType == null || geometry is resourceType)) resources[geometry] = true;
			for (var i:int = 0; i < _surfacesLength; i++) {
				var s:Surface = _surfaces[i];
				if (s.material != null) s.material.fillResources(resources, resourceType);
			}
			super.fillResources(resources, hierarchy, resourceType);
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, -1);
				// Mouse events
				if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
			}
		}

		override alternativa3d function collectDepthDraws(camera:Camera3D, depthRenderer:Renderer, depthMaterial:Material):void {
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				if (surface.material != null) depthMaterial.collectDraws(camera, surface, geometry, null, 0, false);
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function collectGeometry(collider:EllipsoidCollider, excludedObjects:Dictionary):void {
			collider.geometries.push(geometry);
			collider.transforms.push(localToGlobalTransform);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Mesh = new Mesh();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var mesh:Mesh = source as Mesh;
			geometry = mesh.geometry;
			_surfacesLength = 0;
			_surfaces.length = 0;
			for each (var s:Surface in mesh._surfaces) {
				addSurface(s.material, s.indexBegin, s.numTriangles);
			}
		}

	}
}
