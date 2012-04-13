/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.objects.WireFrame;

	import flash.utils.Dictionary;

	use namespace alternativa3d;
	
	/**
	 * Class stores values, that are passed to camera methods <code>addToDebug()</code> and <code>removeFromDebug()</code>.
	 *
	 * @see alternativa.engine3d.core.Camera3D#addToDebug()
	 * @see alternativa.engine3d.core.Camera3D#removeFromDebug()
	 */
	public class Debug {
	
		//static public const NAMES:int = 1;
		
		//static public const AXES:int = 2;
		
		//static public const CENTERS:int = 4;
		
		/**
		 * Display of objects bound boxes.
		 */
		static public const BOUNDS:int = 8;
	
		/**
		 * Display of content, that is depended on object type: wireframe for <code>Mesh</code>, schematic display for light sources.
		 * Now has been implemented the support of not all classes
		 */
		static public const CONTENT:int = 16;
		
		//static public const VERTICES:int = 32;
		
		//static public const NORMALS:int = 64;
	
//		/**
//       * Display of object NODES, that contains tree structure.
//		 */
//		static public const NODES:int = 128;
		
//		/**
//       * Display of light sources.
//		 */
//		static public const LIGHTS:int = 256;
		
//		/**
//       * Display of objects joints, that contains skeletal hierarchy.
//		 */
//		static public const BONES:int = 512;

		static private var boundWires:Dictionary = new Dictionary();
		
		static private function createBoundWire():WireFrame {
			var res:WireFrame = new WireFrame();
			res.geometry.addLine(-0.5,-0.5,-0.5, 0.5,-0.5,-0.5);
			res.geometry.addLine(0.5,-0.5,-0.5, 0.5,0.5,-0.5);
			res.geometry.addLine(0.5,0.5,-0.5, -0.5,0.5,-0.5);
			res.geometry.addLine(-0.5,0.5,-0.5, -0.5,-0.5,-0.5);
			
			res.geometry.addLine(-0.5,-0.5,0.5, 0.5,-0.5,0.5);
			res.geometry.addLine(0.5,-0.5,0.5, 0.5,0.5,0.5);
			res.geometry.addLine(0.5,0.5,0.5, -0.5,0.5,0.5);
			res.geometry.addLine(-0.5,0.5,0.5, -0.5,-0.5,0.5);
			
			res.geometry.addLine(-0.5,-0.5,-0.5, -0.5,-0.5,0.5);
			res.geometry.addLine(0.5,-0.5,-0.5, 0.5,-0.5,0.5);
			res.geometry.addLine(0.5,0.5,-0.5, 0.5,0.5,0.5);
			res.geometry.addLine(-0.5,0.5,-0.5, -0.5,0.5,0.5);
			return res;
		}
		
		/**
		 * @private 
		 */
		static alternativa3d function drawBoundBox(camera:Camera3D, boundBox:BoundBox, transform:Transform3D, color:int = -1):void {
			var boundWire:WireFrame = boundWires[camera.context3D];
			if (boundWire == null) {
				boundWire = createBoundWire();
				boundWires[camera.context3D] = boundWire;
				boundWire.geometry.upload(camera.context3D);
			}
			boundWire.color = color >= 0 ? color : 0x99FF00;
			boundWire.thickness = 1;
			
			boundWire.transform.compose((boundBox.minX + boundBox.maxX)*0.5, (boundBox.minY + boundBox.maxY)*0.5, (boundBox.minZ + boundBox.maxZ)*0.5, 0, 0, 0, boundBox.maxX - boundBox.minX, boundBox.maxY - boundBox.minY, boundBox.maxZ - boundBox.minZ);
			boundWire.localToCameraTransform.combine(transform, boundWire.transform);
			boundWire.collectDraws(camera, null, 0, false);
		}
		
		
		/**
		 * @private 
		 */
		/*static alternativa3d function drawEdges(camera:Camera3D, canvas:Canvas, list:Face, color:int):void {
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			var t:Number;
			canvas.gfx.lineStyle(0, color);
			for (var face:Face = list; face != null; face = face.processNext) {
				var wrapper:Wrapper = face.wrapper;
				var vertex:Vertex = wrapper.vertex;
				t = 1/vertex.cameraZ;
				var x:Number = vertex.cameraX*viewSizeX*t;
				var y:Number = vertex.cameraY*viewSizeY*t;
				canvas.gfx.moveTo(x, y);
				for (wrapper = wrapper.next; wrapper != null; wrapper = wrapper.next) {
					vertex = wrapper.vertex;
					t = 1/vertex.cameraZ;
					canvas.gfx.lineTo(vertex.cameraX*viewSizeX*t, vertex.cameraY*viewSizeY*t);
				}
				canvas.gfx.lineTo(x, y);
			}
		}*/
	
		//static private const boundVertexList:Vertex = Vertex.createList(8);
	
		/**
		 * @private 
		 */
		/*static alternativa3d function drawBounds(camera:Camera3D, canvas:Canvas, transformation:Object3D, boundMinX:Number, boundMinY:Number, boundMinZ:Number, boundMaxX:Number, boundMaxY:Number, boundMaxZ:Number, color:int = -1, alpha:Number = 1):void {
			var vertex:Vertex;
			// Fill
			var a:Vertex = boundVertexList;
			a.x = boundMinX;
			a.y = boundMinY;
			a.z = boundMinZ;
			var b:Vertex = a.next;
			b.x = boundMaxX;
			b.y = boundMinY;
			b.z = boundMinZ;
			var c:Vertex = b.next;
			c.x = boundMinX;
			c.y = boundMaxY;
			c.z = boundMinZ;
			var d:Vertex = c.next;
			d.x = boundMaxX;
			d.y = boundMaxY;
			d.z = boundMinZ;
			var e:Vertex = d.next;
			e.x = boundMinX;
			e.y = boundMinY;
			e.z = boundMaxZ;
			var f:Vertex = e.next;
			f.x = boundMaxX;
			f.y = boundMinY;
			f.z = boundMaxZ;
			var g:Vertex = f.next;
			g.x = boundMinX;
			g.y = boundMaxY;
			g.z = boundMaxZ;
			var h:Vertex = g.next;
			h.x = boundMaxX;
			h.y = boundMaxY;
			h.z = boundMaxZ;
			// Transformation to camera
			for (vertex = a; vertex != null; vertex = vertex.next) {
				vertex.cameraX = transformation.ma*vertex.x + transformation.mb*vertex.y + transformation.mc*vertex.z + transformation.md;
				vertex.cameraY = transformation.me*vertex.x + transformation.mf*vertex.y + transformation.mg*vertex.z + transformation.mh;
				vertex.cameraZ = transformation.mi*vertex.x + transformation.mj*vertex.y + transformation.mk*vertex.z + transformation.ml;
				if (vertex.cameraZ <= 0) return;
			}
			// Projection
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			for (vertex = a; vertex != null; vertex = vertex.next) {
				var t:Number = 1/vertex.cameraZ;
				vertex.cameraX = vertex.cameraX*viewSizeX*t;
				vertex.cameraY = vertex.cameraY*viewSizeY*t;
			}
			// Rendering
			canvas.gfx.lineStyle(0, (color < 0) ? ((transformation.culling > 0) ? 0xFFFF00 : 0x00FF00) : color, alpha);
			canvas.gfx.moveTo(a.cameraX, a.cameraY);
			canvas.gfx.lineTo(b.cameraX, b.cameraY);
			canvas.gfx.lineTo(d.cameraX, d.cameraY);
			canvas.gfx.lineTo(c.cameraX, c.cameraY);
			canvas.gfx.lineTo(a.cameraX, a.cameraY);
			canvas.gfx.moveTo(e.cameraX, e.cameraY);
			canvas.gfx.lineTo(f.cameraX, f.cameraY);
			canvas.gfx.lineTo(h.cameraX, h.cameraY);
			canvas.gfx.lineTo(g.cameraX, g.cameraY);
			canvas.gfx.lineTo(e.cameraX, e.cameraY);
			canvas.gfx.moveTo(a.cameraX, a.cameraY);
			canvas.gfx.lineTo(e.cameraX, e.cameraY);
			canvas.gfx.moveTo(b.cameraX, b.cameraY);
			canvas.gfx.lineTo(f.cameraX, f.cameraY);
			canvas.gfx.moveTo(d.cameraX, d.cameraY);
			canvas.gfx.lineTo(h.cameraX, h.cameraY);
			canvas.gfx.moveTo(c.cameraX, c.cameraY);
			canvas.gfx.lineTo(g.cameraX, g.cameraY);
		}*/
	
		//static private const nodeVertexList:Vertex = Vertex.createList(4);
	
		/**
		 * @private 
		 */
		/*static alternativa3d function drawKDNode(camera:Camera3D, canvas:Canvas, transformation:Object3D, axis:int, coord:Number, boundMinX:Number, boundMinY:Number, boundMinZ:Number, boundMaxX:Number, boundMaxY:Number, boundMaxZ:Number, alpha:Number):void {
			var vertex:Vertex;
			// Fill
			var a:Vertex = nodeVertexList;
			var b:Vertex = a.next;
			var c:Vertex = b.next;
			var d:Vertex = c.next;
			if (axis == 0) {
				a.x = coord;
				a.y = boundMinY;
				a.z = boundMaxZ;
				b.x = coord;
				b.y = boundMaxY;
				b.z = boundMaxZ;
				c.x = coord;
				c.y = boundMaxY;
				c.z = boundMinZ;
				d.x = coord;
				d.y = boundMinY;
				d.z = boundMinZ;
			} else if (axis == 1) {
				a.x = boundMaxX;
				a.y = coord;
				a.z = boundMaxZ;
				b.x = boundMinX;
				b.y = coord;
				b.z = boundMaxZ;
				c.x = boundMinX;
				c.y = coord;
				c.z = boundMinZ;
				d.x = boundMaxX;
				d.y = coord;
				d.z = boundMinZ;
			} else {
				a.x = boundMinX;
				a.y = boundMinY;
				a.z = coord;
				b.x = boundMaxX;
				b.y = boundMinY;
				b.z = coord;
				c.x = boundMaxX;
				c.y = boundMaxY;
				c.z = coord;
				d.x = boundMinX;
				d.y = boundMaxY;
				d.z = coord;
			}
			// Transformation to camera
			for (vertex = a; vertex != null; vertex = vertex.next) {
				vertex.cameraX = transformation.ma*vertex.x + transformation.mb*vertex.y + transformation.mc*vertex.z + transformation.md;
				vertex.cameraY = transformation.me*vertex.x + transformation.mf*vertex.y + transformation.mg*vertex.z + transformation.mh;
				vertex.cameraZ = transformation.mi*vertex.x + transformation.mj*vertex.y + transformation.mk*vertex.z + transformation.ml;
				if (vertex.cameraZ <= 0) return;
			}
			// Projection
			var viewSizeX:Number = camera.viewSizeX;
			var viewSizeY:Number = camera.viewSizeY;
			for (vertex = a; vertex != null; vertex = vertex.next) {
				var t:Number = 1/vertex.cameraZ;
				vertex.cameraX = vertex.cameraX*viewSizeX*t;
				vertex.cameraY = vertex.cameraY*viewSizeY*t;
			}
			// Rendering
			canvas.gfx.lineStyle(0, (axis == 0) ? 0xFF0000 : ((axis == 1) ? 0x00FF00 : 0x0000FF), alpha);
			canvas.gfx.moveTo(a.cameraX, a.cameraY);
			canvas.gfx.lineTo(b.cameraX, b.cameraY);
			canvas.gfx.lineTo(c.cameraX, c.cameraY);
			canvas.gfx.lineTo(d.cameraX, d.cameraY);
			canvas.gfx.lineTo(a.cameraX, a.cameraY);
		}*/
		
		/**
		 * @private 
		 */
		/*static alternativa3d function drawBone(canvas:Canvas, x1:Number, y1:Number, x2:Number, y2:Number, size:Number, color:int):void {
			var nx:Number = x2 - x1;
			var ny:Number = y2 - y1;
			var nl:Number = Math.sqrt(nx*nx + ny*ny);
			if (nl > 0.001) {
				nx /= nl;
				ny /= nl;
				var lx:Number = ny*size;
				var ly:Number = -nx*size;
				var rx:Number = -ny*size;
				var ry:Number = nx*size;
				if (nl > size*2) {
					nl = size;
				} else {
					nl = nl/2;
				}
				canvas.gfx.lineStyle(1, color);
				canvas.gfx.beginFill(color, 0.6);
				canvas.gfx.moveTo(x1, y1);
				canvas.gfx.lineTo(x1 + nx*nl + lx, y1 + ny*nl + ly);
				canvas.gfx.lineTo(x2, y2);
				canvas.gfx.lineTo(x1 + nx*nl + rx, y1 + ny*nl + ry);
				canvas.gfx.lineTo(x1, y1);
			}
		}*/
		
	}
}
