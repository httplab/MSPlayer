package org.osmf.player.chrome.widgets {
	import flash.events.Event;
	import flash.text.TextFormatAlign;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	public class TimeRemainingWidget extends TimeLabelWidget {
		private var _isFixedPosition:Boolean;
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			mouseChildren = mouseEnabled = false;
			autoSize = true;
			selectable = false;
			multiline = false;
			textColor = "0xffffff";
			fontSize = 10;
			font = AssetIDs.TAHOMA;
			bold = false;
			super.configure(xml, assetManager);
			text = '00:00';
			width = textField.textWidth;
			height = textField.textHeight;
			x = parent.width - textField.textWidth - 10;
			y = (parent.height - textField.textHeight) / 2;
		}
		
		override internal function updateValues(currentTimePosition:Number, totalDuration:Number, isLive:Boolean):void {	
			var remained:Number = totalDuration - currentTimePosition;
			var hours:String = String(int(remained / 3600));
			remained %= 3600;
			var minutes:String = String(int(remained / 60));
			remained %= 60;
			var seconds:String = String(int(remained));
			minutes.length < 2 && (minutes = "0" + minutes);
			seconds.length < 2 && (seconds = "0" + seconds);
			text = "-" + (hours != "0" ? (hours + ":") : "") + minutes + ":" + seconds;
			width = textField.textWidth;
			height = textField.textHeight;
			if (!_isFixedPosition) {
				_isFixedPosition = true;
				validateNow();
			}
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			x = availableWidth - textField.textWidth - 10;
			y = (availableHeight - textField.textHeight) / 2;
			super.layout(availableWidth, availableHeight, deep);
		}
	}
}