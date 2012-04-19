package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.readers.IReader;

	public class VUnknown implements IVersion {
		public var majorVersion:uint = 0;

		public function parseCurrentRecord(reader:IReader, stack:Array, heap:Object):void {
			switch (reader.getRecordName()) {
				case "FBXHeaderExtension":
					stack.push(null);
					reader.stepIn();
					break;
				case "FBXVersion":
					majorVersion = reader.getRecordData().numbers [0]/1000;
				default:
					reader.stepOver();
					break;
			}
		}
	}
}
