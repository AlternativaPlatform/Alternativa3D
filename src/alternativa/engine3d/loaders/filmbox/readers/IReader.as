package alternativa.engine3d.loaders.filmbox.readers {

	/** @private Прокладка для чтения файла. */
	public interface IReader {
		function hasDataLeft():Boolean;

		function getDepth():uint;

		function getRecordName():String;

		function getRecordData(parseNumbers:Boolean = true):RecordData;

		function stepIn():void;

		function stepOver():void;
	}
}
