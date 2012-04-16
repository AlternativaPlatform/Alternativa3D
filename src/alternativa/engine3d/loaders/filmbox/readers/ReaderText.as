package alternativa.engine3d.loaders.filmbox.readers {

	import flash.utils.ByteArray;

	//	import flash.utils.getTimer;

	/** @private */
	public class ReaderText implements IReader {

		private var lines:Vector.<String>, currentLine:int = 0, nextLineHint:int = -1;

		public function ReaderText(ba:ByteArray):void {
			var text:String = ba.toString(); // ba.readUTFBytes (ba.bytesAvailable);

			var crat:int = text.indexOf("\n");
			var eol:String = ((crat > 0) && (text.charAt(crat - 1) == "\r")) ? "\r\n" : "\n";

			lines = Vector.<String>(text.split(eol));
		}

		public function hasDataLeft():Boolean {
			if (currentLine < nextLineHint) {
				currentLine = nextLineHint;
			}

			while (currentLine < lines.length) {
				var line:String = lines [currentLine];
				if (line.indexOf(": ") > -1) return true;
				// can't have "{" here
				if (line.indexOf("}") > -1) depth--;
				currentLine++;
			}
			return (currentLine < lines.length);
		}

		private var depth:uint = 0;

		public function getDepth():uint {
			return depth;
		}

		public function getRecordName():String {
			var line:String = lines [currentLine];
			var name:String = line.substr(0, line.indexOf(":"));
			var last:int = name.lastIndexOf(" ") + 1;
			if (last > 0) {
				name = name.substr(last);
			} else {
				last = name.lastIndexOf("\t") + 1;
				if (last > 0) {
					name = name.substr(last);
				}
			}
			return name;
		}

		public function getRecordData(parseNumbers:Boolean = true):RecordData {
			//var t:int = getTimer ();
			var data:RecordData = new RecordData;

			var text:String = "";

			// 1st bit of data starts at currentLine after ": "
			var line:String = lines [currentLine];
			line = line.substr(line.indexOf(": ") + 1);

			var c:int = currentLine + 1;
			while ((line.indexOf(": ") < 0) && (line.indexOf("}") < 0) && (line.indexOf("{") < 0)) {
				// additional check for comments
				var s:int = line.indexOf(";");
				if (s >= 0) {
					for (var i:int = 0; i < s; i++) {
						if (line.charCodeAt(i) > 32) {
							s = -1;
						}
					}
				}
				if (s < 0) {
					text += line;
				}
				line = lines [c];
				c++;
			}

			// now line is either last one, or irrelevant one
			nextLineHint = c - 2;
			if ((line.indexOf(": ") < 0) && (line.indexOf("}") < 0)) {
				line = line.substr(0, line.indexOf("{"));
				text += line;
			}

			// split text
			var items:Array = text.split(",");

			//var profile:Boolean = (items.length > 10);
			//if (profile) {
			//	trace ("----->", items.length, "data items over", (c - currentLine), "lines");
			//	trace ("@", lines [currentLine].substr (0, 50));
			//}

			var isNumber:Boolean, n:int = items.length;
			for (i = 0; i < n; i++) {
				var item:String = items [i] as String;

				// trim heading whitespace
				s = 0;
				while (item.charCodeAt(s) < 33) s++;
				if (s > 0) item = item.substr(s);

				// number ?
				if (!isNumber) {
					s = item.charCodeAt(0);
					if (parseNumbers) isNumber = (s == 0x2D) || ((0x2F < s) && (s < 0x3A));
				}

				if (isNumber) {
					data.numbers.push(parseFloat(item));
				} else {
					var quotes:Boolean = (s == 0x22);

					// trim trailing whitespace
					s = item.length;
					while (item.charCodeAt(s - 1) < 33) s--;
					if (s < item.length) item = item.substr(0, s);

					if (quotes) {
						// strip quotes
						data.strings.push(item.substr(1, item.length - 2));
					} else if (item.length > 0) {
						data.strings.push(item);
					}
				}
			}

			//if (profile) trace (1e-3 * (getTimer () - t), "wasted in getRecordData()");

			if ((data.numbers.length == 0) && (data.strings.length == 1) && (data.strings [0].charCodeAt(0) == 0x2A)) {
				// v7 arrays shortcut
				c = currentLine;
				i = nextLineHint;
				s = depth;
				stepIn();
				hasDataLeft();
				data = getRecordData();
				currentLine = c;
				nextLineHint = i;
				depth = s;
			}

			return data;
		}

		public function stepIn():void {
			currentLine++;
			depth++;
		}

		public function stepOver():void {
			var par:int = 0;
			do {
				var line:String = lines [currentLine];
				if (line.indexOf("{") >= 0) par++; else if (line.indexOf("}") >= 0) par--;
				currentLine++;
			} while (par > 0);
		}
	}
}
