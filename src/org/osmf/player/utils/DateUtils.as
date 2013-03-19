package org.osmf.player.utils {
	public class DateUtils {
		static private var _gap:Number;
		public static function renewDateDelta(currentServerTime:String):void {
			currentServerTime = currentServerTime.split('-').join('/').split('T').join(' ');
			var serverTimeArray:Array = currentServerTime.split('.');
			serverTimeArray.length--;
			var serverTime:Number = Date.parse(serverTimeArray.join(''));
			var clientTime:Date = new Date();
			_gap = clientTime.time - serverTime;
		}
		
		public static function formatToClientTime(serverTime:String):Number {
			serverTime = serverTime.split('-').join('/').split('T').join(' ');
			var serverTimeArray:Array = serverTime.split('.');
			serverTimeArray.length--;
			var countedServerTime:Number = Date.parse(serverTimeArray.join(''));
			return countedServerTime + _gap;
		}
	}
}