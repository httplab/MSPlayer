package org.osmf.player.utils {
	public class DateUtils {
		static private var _gap:Number;
		public static function renewDateDelta(currentServerTime:Number):void {
			var clientTime:Date = new Date();
			_gap = clientTime.time - currentServerTime;
		}
		
		public static function formatToClientTime(serverTime:Number):Number {
			return serverTime + _gap;
		}
	}
}