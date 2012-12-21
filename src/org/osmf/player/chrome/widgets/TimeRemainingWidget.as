package org.osmf.player.chrome.widgets {
	import flash.text.TextFormatAlign;
	import org.osmf.player.chrome.assets.AssetsManager;
	public class TimeRemainingWidget extends TimeLabelWidget {
		private var _isFixedPosition:Boolean;
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			mouseChildren = mouseEnabled = false;
			autoSize = true;
			selectable = false;
			multiline = false;
			textColor = "0xffffff";
			fontSize = 12;
			super.configure(xml, assetManager);
			
		}
		
		override internal function updateValues(currentTimePosition:Number, totalDuration:Number, isLive:Boolean):void {	
			timeLabel.text = '';
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
			if (parent) {
				parent.addChild(this);
			}
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			super.layout(availableWidth, availableHeight, deep);
			x = availableWidth - textField.width;
			y = (availableHeight - textField.height) / 2;
		}
	}
}