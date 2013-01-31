/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */
package alternativa.engine3d.materials.compiler {


	/**
	 * @private 
	 */
	public class CommandType {
		public static const MOV : uint = 0x00;

		public static const ADD : uint = 0x01;

		public static const SUB : uint = 0x02;

		public static const MUL : uint = 0x03;

		public static const DIV : uint = 0x04;

		public static const RCP : uint = 0x05;

		public static const MIN : uint = 0x06;

		public static const MAX : uint = 0x07;

		public static const FRC : uint = 0x08;

		public static const SQT : uint = 0x09;

		public static const RSQ : uint = 0x0a;

		public static const POW : uint = 0x0b;

		public static const LOG : uint = 0x0c;

		public static const EXP : uint = 0x0d;

		public static const NRM : uint = 0x0e;

		public static const SIN : uint = 0x0f;

		public static const COS : uint = 0x10;

		public static const CRS : uint = 0x11;

		public static const DP3 : uint = 0x12;

		public static const DP4 : uint = 0x13;

		public static const ABS : uint = 0x14;

		public static const NEG : uint = 0x15;

		public static const SAT : uint = 0x16;

		public static const M33 : uint = 0x17;

		public static const M44 : uint = 0x18;

		public static const M34 : uint = 0x19;

		public static const DDX : uint = 0x1a;

		public static const DDY : uint = 0x1b;

		public static const IFE : uint = 0x1c;

		public static const INE : uint = 0x1d;

		public static const IFG : uint = 0x1e;

		public static const IFL : uint = 0x1f;

		public static const ELS : uint = 0x20;

		public static const EIF : uint = 0x21;

		public static const TED : uint = 0x26;

		public static const KIL : uint = 0x27;

		public static const TEX : uint = 0x28;

		// set if greater equal
		public static const SGE : uint = 0x29;

		// set if less than
		public static const SLT : uint = 0x2a;

		// set if greater than
		public static const SGN : uint = 0x2b;

		// set if equal
		public static const SEQ : uint = 0x2c;

		// set if not equal
		public static const SNE : uint = 0x2d;

		public static const COMMAND_NAMES : Array = [];
		COMMAND_NAMES[MOV] = "mov";
		COMMAND_NAMES[ADD] = "add";
		COMMAND_NAMES[SUB] = "sub";
		COMMAND_NAMES[MUL] = "mul";
		COMMAND_NAMES[DIV] = "div";
		COMMAND_NAMES[RCP] = "rcp";
		COMMAND_NAMES[MIN] = "min";
		COMMAND_NAMES[MAX] = "max";
		COMMAND_NAMES[FRC] = "frc";
		COMMAND_NAMES[SQT] = "sqt";
		COMMAND_NAMES[RSQ] = "rsq";
		COMMAND_NAMES[POW] = "pow";
		COMMAND_NAMES[LOG] = "log";
		COMMAND_NAMES[EXP] = "exp";
		COMMAND_NAMES[NRM] = "nrm";
		COMMAND_NAMES[SIN] = "sin";
		COMMAND_NAMES[COS] = "cos";
		COMMAND_NAMES[CRS] = "crs";
		COMMAND_NAMES[DP3] = "dp3";
		COMMAND_NAMES[DP4] = "dp4";
		COMMAND_NAMES[ABS] = "abs";
		COMMAND_NAMES[NEG] = "neg";
		COMMAND_NAMES[SAT] = "sat";
		COMMAND_NAMES[M33] = "m33";
		COMMAND_NAMES[M44] = "m44";
		COMMAND_NAMES[M34] = "m34";
		COMMAND_NAMES[DDX] = "ddx";
		COMMAND_NAMES[DDY] = "ddy";
		COMMAND_NAMES[IFE] = "ife";
		COMMAND_NAMES[INE] = "ine";
		COMMAND_NAMES[IFG] = "ifg";
		COMMAND_NAMES[IFL] = "ifl";
		COMMAND_NAMES[ELS] = "els";
		COMMAND_NAMES[EIF] = "eif";
		COMMAND_NAMES[TED] = "ted";
		COMMAND_NAMES[KIL] = "kil";
		COMMAND_NAMES[TEX] = "tex";
		COMMAND_NAMES[SGE] = "sge";
		COMMAND_NAMES[SLT] = "slt";
		COMMAND_NAMES[SGN] = "sgn";
		COMMAND_NAMES[SEQ] = "seq";
		COMMAND_NAMES[SNE] = "sne";
	}
}
