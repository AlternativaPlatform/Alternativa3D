package alternativa.engine3d.loaders.filmbox.readers {


	/** @private */
	public class ReaderBinary implements IReader {

		public function hasDataLeft():Boolean {
			trace("binary reader not implemented");
			return false;
		}

		public function getDepth():uint {
			return 0;
		}

		public function getRecordName():String {
			return "";
		}

		public function getRecordData(parseNumbers:Boolean = true):RecordData {
			return new RecordData;
		}

		public function stepIn():void {
			;
		}

		public function stepOver():void {
			;
		}
	}
}
