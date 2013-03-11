package org.osmf.player.elements {
	import flash.display.InteractiveObject;
	import org.osmf.player.elements.Channel;
	public class Channel extends ASSET_Channel {
		private var _height:Number;
		public var srcId:int;
		public var access:Boolean;
		public var authAccess:Boolean;
		public var previousChannel:Channel;
		public var nextChannel:Channel;
		
		public function Channel(name:String, bgIdx:Boolean) {
			!bgIdx && bg.gotoAndStop(2);
			_height = bg.height;
			channelNameTxt.multiline = true;
			channelNameTxt.wordWrap = true;
			broadcastTxt.multiline = true;
			broadcastTxt.wordWrap = true;
			channelNameTxt.text = name;
			setHeight(channelNameTxt.textHeight + 4);
			for (var i:int = 0; i < numChildren; i++) {
				(getChildAt(i) as InteractiveObject) && ((getChildAt(i) as InteractiveObject).mouseEnabled = false);
			}
		}
		
		private function setHeight(value:Number):void {
			_height = Math.max(value, _height);
			channelNameTxt.height = _height;
			broadcastTxt.height = _height;
			timeTxt.height = _height;
			bg.height = _height;
		}
		
		public function setBroadcast(time:Number, broadcastName:String):void {
			broadcastTxt.text = broadcastName;
			var nl:Number = broadcastTxt.numLines;
			setHeight(broadcastTxt.textHeight + 4);
			var date:Date = new Date();
			date.setTime(time);
			var hours:String = String(date.getHours());
			var minutes:String = String(date.getMinutes());
			timeTxt.text = ((hours.length < 2) ? "0" : "") + hours + ":" + ((minutes.length < 2) ? "0" : "") + minutes;
		}
		
		override public function get height():Number {
			return _height;
		}
	}
}