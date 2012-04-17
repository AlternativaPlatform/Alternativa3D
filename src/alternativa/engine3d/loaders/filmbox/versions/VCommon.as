package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.*;
	import alternativa.engine3d.loaders.filmbox.readers.*;

	/** @private */
	public class VCommon {
		private function setObjectPropertyFromData(object:Object, property:String, sLength:int,
				data:RecordData):Boolean {
			if (object.hasOwnProperty(property)) {
				var defaultValue:Object = object [property];
				if (data.numbers.length > 0) {
					// this is numeric property
					//					if ((defaultValue == null) ? (data.numbers.length > 1) : defaultValue.hasOwnProperty ("length")) {
					if ((defaultValue == null) ? (data.numbers.length > 1) : defaultValue is Vector.<Number>) {
						// array
						object [property] = data.numbers;
					} else {
						// scalar
						object [property] = data.numbers [0];
					}
				} else if (data.strings.length > sLength) {
					// this is string property
					if ((defaultValue == null) ? (data.strings.length > 1 + sLength) : defaultValue is Vector.<String>) {
						// array TODO are there actually any string arrays, ever?
						data.strings.splice(0, sLength);
						object [property] = data.strings;
					} else {
						// scalar
						object [property] = data.strings [sLength];
					}
				}
				return true;
			}
			return false;
		}

		protected function setPredefinedProperty(reader:IReader, stack:Array, recordName:String):Boolean {
			if (stack.length > 0) {
				var object:Object = stack [stack.length - 1];
				if (object != null) {
					return setObjectPropertyFromData(object, recordName, 0, reader.getRecordData());
				}
			}
			return false;
		}

		protected function setProperty(reader:IReader, stack:Array, sLength:int):Boolean {
			if (stack.length > 1) {
				var object:Object = stack [stack.length - 2];
				if (object != null) {
					var data:RecordData = reader.getRecordData();
					var property:String = data.strings [0];
					if (property.indexOf("|") > 0) return false; // ignore "Compound" properties for now
					if (property.indexOf(" ") > 0) property = property.replace(" ", "");
					var success:Boolean = setObjectPropertyFromData(object, property, sLength, data);
					if (!success && (object is KFbxNode)) {
						// also attempt this on every attribute
						var node:KFbxNode = object as KFbxNode;
						for each (var attr:KFbxNodeAttribute in node.attributes) {
							if (setObjectPropertyFromData(attr, property, sLength, data)) {
								return true;
							}
						}
					}
					return success;
				}
			}
			return false;
		}

		protected function getCurrentMesh(stack:Array):KFbxMesh {
			var mesh:KFbxMesh = stack [stack.length - 1] as KFbxMesh;
			if (mesh) {
				return mesh;
			}
			// for v6-, there is node on the stack
			var node:KFbxNode = stack [stack.length - 1] as KFbxNode;
			if (node) {
				mesh = node.getAttribute(KFbxMesh) as KFbxMesh;
				// for v5, there might be no mesh attribute yet
				if (mesh == null) {
					mesh = new KFbxMesh;
					node.attributes.push(mesh);
				}
				return mesh;
			}
			return null;
		}

		protected function setMeshNumericProperty(reader:IReader, stack:Array, property:String):void {
			var mesh:KFbxMesh = getCurrentMesh(stack);
			if (mesh) mesh [property] = reader.getRecordData().numbers;
		}

		protected function addMeshLayerElement(reader:IReader, stack:Array, element:KFbxLayerElement,
				layerIndex:int = -1, saveOnStack:Boolean = true):void {
			var mesh:KFbxMesh = getCurrentMesh(stack);
			if (mesh) {

				// v5 does not specify layer in data, so we actually pass it as argument
				if (layerIndex < 0) {
					var numbers:Vector.<Number> = reader.getRecordData().numbers;
					if (numbers.length > 0) layerIndex = numbers [0];
				}

				var layer:KFbxLayer;
				if (layerIndex < mesh.layers.length) {
					layer = mesh.layers [layerIndex];
				} else {
					mesh.layers.push(layer = new KFbxLayer);
				}

				layer.elements.push(element);
			}

			if (saveOnStack) {
				stack.push(element);
			}
		}

		protected function parseAmbientLight(data:RecordData, heap:Object):void {
			var node:KFbxNode = new KFbxNode;
			var attr:KFbxLight = new KFbxLight;
			attr.Color = data.numbers;
			attr.Intensity = 100*((attr.Color.length > 3) ? attr.Color.pop() : 1);
			node.attributes.push(attr);
			heap["AmbientLight"] = node;
		}
	}
}
