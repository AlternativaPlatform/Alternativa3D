package alternativa.engine3d.loaders.filmbox.versions {

	import alternativa.engine3d.loaders.filmbox.readers.IReader;

	/** @private Прокладка для интерпретации содержимого файла. TODO better separation! */
	public interface IVersion {
		function parseCurrentRecord(reader:IReader, stack:Array, heap:Object):void;
	}
}
