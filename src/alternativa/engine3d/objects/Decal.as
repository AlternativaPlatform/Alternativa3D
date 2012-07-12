/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Renderer;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;

	use namespace alternativa3d;

	/**
	 *  A  <code>Mesh</code> which has z-fighting engine. Most popular case of use is for dynamic addition of different tracks over existing surfaces.
	 *  The <code>Plane</code> instance  can be used as the geometry source.
	 *
	 * @example The following code creates decal from plane:
     * <listing version="3.0">
     *       var plane = new Plane(200, 200);
     *       var decal = new Decal();
     *       decal.geometry = plane.geometry;
     *       for (var i:int = 0; i &lt; plane.numSurfaces; i++){
     *       decal.addSurface(null, plane.getSurface(i).indexBegin, plane.getSurface(i).numTriangles);}
     *       decal.geometry.upload(stage3D.context3D);
     * </listing>
	 */
	public class Decal extends Mesh {

		/**
		 * Z-buffer precision in bytes.
		 */
		static public var zBufferPrecision:int = 16;

		static private var transformProcedureStatic:Procedure  = new Procedure([
			// Z in a camera
			"dp4 t0.z, i0, c0",
			// z = m14/(m14/z + 1/N)
			"div t0.x, c2.z, t0.z",		// t0.x = m14/t0.z
			"sub t0.x, t0.x, c2.w",		// t0.x = t0.x + 1/N
			"div t0.y, c2.z, t0.x",		// t0.y = m14/t0.x
			// Correction coefficient
			"div t0.w, t0.y, t0.z",		// t0.w = t0.y / t0.z
			// Vector from a camera to vertex
			"sub t0.xyz, i0.xyz, c1.xyz",	// t0.xyz = i0.xyz - c1.xyz
			// Correction of the vector
			"mul t0.xyz, t0.xyz, t0.w",		// t0.xyz = t0.xyz*t0.w
			// Get new position
			"add o0.xyz, c1.xyz, t0.xyz",	//o0.xyz = c1.xyz + t0.xyz
			"mov o0.w, i0.w",				// o0.w = i0.w
			// Declaring
			"#c0=cTrm", // Third line of the transforming to camera matrix
			"#c1=cCam", // Camera position in object space, w = 1 - offset/(far - near)
			"#c2=cProj"	// Camera projection matrix settings
		], "DecalTransformProcedure");

		/**
		 * Creates a new Decal instance.
		 */
		public function Decal() {
			transformProcedure = transformProcedureStatic;
		}
		
		/**
		 * @private 
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			for (var i:int = 0; i < _surfacesLength; i++) {
				var surface:Surface = _surfaces[i];
				if (surface.material != null) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, Renderer.DECALS);
				// Mouse events
				if (listening) camera.view.addSurfaceToMouseEvents(surface, geometry, transformProcedure);
			}
		}
		
		/**
		 * @private
		 */
		override alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
			drawUnit.setVertexConstantsFromNumbers(vertexShader.getVariableIndex("cProj"), 0, 0, camera.m14, 1/(1 << zBufferPrecision));
			drawUnit.setVertexConstantsFromNumbers(vertexShader.getVariableIndex("cCam"), cameraToLocalTransform.d, cameraToLocalTransform.h, cameraToLocalTransform.l);
			drawUnit.setVertexConstantsFromNumbers(vertexShader.getVariableIndex("cTrm"), localToCameraTransform.i, localToCameraTransform.j, localToCameraTransform.k, localToCameraTransform.l);
		}
		
		/**
		 * @inheritDoc 
		 */
		override public function clone():Object3D {
			var res:Decal = new Decal();
			res.clonePropertiesFrom(this);
			return res;
		}
		
		/**
		 * @inheritDoc 
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
		}
		
	}
}
