/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.osgi.OSGi;
	import alternativa.osgi.service.clientlog.IClientLog;
	import alternativa.protocol.ICodec;
	import alternativa.protocol.IProtocol;
	import alternativa.protocol.OptionalMap;
	import alternativa.protocol.ProtocolBuffer;
	import alternativa.protocol.impl.OptionalMapCodecHelper;
	import alternativa.protocol.impl.PacketHelper;
	import alternativa.protocol.impl.Protocol;
	import alternativa.protocol.info.TypeCodecInfo;
	import alternativa.protocol.osgi.ProtocolActivator;

	import flash.utils.ByteArray;

	import platform.client.formats.a3d.osgi.Activator;
	import platform.clients.fp10.libraries.alternativaprotocol.Activator;

	import versions.version1.a3d.A3D;
	import versions.version2.a3d.A3D2;
	import versions.version2.a3d.A3D2Extra1;
	import versions.version2.a3d.A3D2Extra2;

	use namespace alternativa3d;

/**
 * A parser for loading models of  A3D binary format.
 *  A3D format reference you can find <a href="http://alternativaplatform.com/public/A3DFormat_en.pdf">here</a>.
 */
public class ParserA3D extends Parser {

//		static public const logChannel:String = "ParserLog";

	private var protocol:Protocol;

	private var wasInit:Boolean = false;

	/**
	 * Creates a new instance of ParserA3D.
	 *
	 */
	public function ParserA3D() {
		init();
	}

	/**
	 *  Parses model of a3d format, that is passed as byteArray to <code>input</code> parameter, then  fills the arrays <code>objects</code> and <code>hierarchy</code> by the instances of three-dimensional objects.
	 * @param input  <code>ByteArray</code> consists of A3D data.
	 */
	public function parse(input:ByteArray):void {
		try {
			input.position = 0;
			var version:int = input.readByte();
			if (version == 0) {
				// For the 1st version of format
				parseVersion1(input);
			} else {
				// For the 2nd version of format and above, the first byte contains length of file and flag bits.
				// Bit of packing. It always equal to 1, because version 2 and above is always packed.
				parseVersionOver1(input);
			}
		} catch (e:Error) {
			e.message = "Parsing failed: " + e.message;
			throw e;
		}

	}

	private function init():void {
		if (wasInit) return;
		var osgi:OSGi;
		if (OSGi.getInstance() == null) {
			osgi = new OSGi();
			OSGi.clientLog = new DummyClientLog();
			osgi.registerService(IClientLog, new DummyClientLog());
			new ProtocolActivator().start(osgi);
			new platform.clients.fp10.libraries.alternativaprotocol.Activator().start(osgi);
		} else {
			osgi = OSGi.getInstance();
		}
		new platform.client.formats.a3d.osgi.Activator().start(osgi);
		protocol = Protocol(osgi.getService(IProtocol));
		wasInit = true;
	}

	private function parseVersion1(input:ByteArray):void {
		input.position = 4;
		var nullMap:OptionalMap = OptionalMapCodecHelper.decodeNullMap(input);
		nullMap.setReadPosition(0);
		var data:ByteArray = new ByteArray();
		data.writeBytes(input, input.position);
		data.position = 0;
		var buffer:ProtocolBuffer = new ProtocolBuffer(data, data, nullMap);
		var codec:ICodec = protocol.getCodec(new TypeCodecInfo(A3D, false));
		var _a3d:A3D = A3D(codec.decode(buffer));
		complete(_a3d);
	}

	private function parseVersionOver1(input:ByteArray):void {
		input.position = 0;
		var data:ByteArray = new ByteArray();
		var buffer:ProtocolBuffer = new ProtocolBuffer(data, data, new OptionalMap());
		PacketHelper.unwrapPacket(input, buffer);
		input.position = 0;
		var versionMajor:int = buffer.reader.readUnsignedShort();
		var versionMinor:int = buffer.reader.readUnsignedShort();
		switch (versionMajor) {
			case 2:
				if (versionMinor >= 6) {
					compressedBuffers = true;
				}
				var parts:Vector.<Object> = new Vector.<Object>();
				parts.push(parseVersion2_0(buffer));
				if (versionMinor >= 4) {
					parts.push(parseVersion2_4(buffer));
				}
				if (versionMinor >= 5) {
					parts.push(parseVersion2_5(buffer));
				}
				complete(parts);
				break;
		}
	}

	private function parseVersion2_0(buffer:ProtocolBuffer):Object {
		var codec:ICodec = protocol.getCodec(new TypeCodecInfo(A3D2, false));
		var a3d:A3D2 = A3D2(codec.decode(buffer));
		return a3d;
	}

	private function parseVersion2_5(buffer:ProtocolBuffer):Object {
		var codec:ICodec = protocol.getCodec(new TypeCodecInfo(A3D2Extra2, false));
		var a3d:A3D2Extra2 = A3D2Extra2(codec.decode(buffer));
		return a3d;
	}

	private function parseVersion2_4(buffer:ProtocolBuffer):Object {
		var codec:ICodec = protocol.getCodec(new TypeCodecInfo(A3D2Extra1, false));
		var a3d:A3D2Extra1 = A3D2Extra1(codec.decode(buffer));
		return a3d;
	}

}
}

import alternativa.osgi.service.clientlog.IClientLog;
import alternativa.osgi.service.clientlog.IClientLogChannelListener;

class DummyClientLog implements IClientLog {

	public function logError(channelName:String, text:String, ...vars):void {
	}

	public function log(channelName:String, text:String, ...rest):void {
	}

	public function getChannelStrings(channelName:String):Vector.<String> {
		return null;
	}

	public function addLogListener(listener:IClientLogChannelListener):void {
	}

	public function removeLogListener(listener:IClientLogChannelListener):void {
	}

	public function addLogChannelListener(channelName:String, listener:IClientLogChannelListener):void {
	}

	public function removeLogChannelListener(channelName:String, listener:IClientLogChannelListener):void {
	}

	public function getChannelNames():Vector.<String> {
		return null;
	}
}
