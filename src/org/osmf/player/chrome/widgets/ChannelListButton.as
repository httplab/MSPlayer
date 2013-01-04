package org.osmf.player.chrome.widgets {
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class ChannelListButton extends ButtonWidget {
		static public const LIST_CALL:String = "listCall";
		public function ChannelListButton() {
			upFace = AssetIDs.CHANNEL_LIST_BUTTON_NORMAL;
			downFace = AssetIDs.CHANNEL_LIST_BUTTON_DOWN;
			overFace = AssetIDs.CHANNEL_LIST_BUTTON_OVER;
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			dispatchEvent(new Event(LIST_CALL));
		}
	}		
}