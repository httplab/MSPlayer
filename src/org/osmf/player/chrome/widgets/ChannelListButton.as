package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class ChannelListButton extends ButtonWidget {
		private var _opened:Boolean;
		static public const LIST_CALL:String = "listCall";
		public function ChannelListButton() {
			upFace = AssetIDs.CHANNEL_LIST_BUTTON_NORMAL;
			downFace = AssetIDs.CHANNEL_LIST_BUTTON_DOWN;
			overFace = AssetIDs.CHANNEL_LIST_BUTTON_OVER;
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			dispatchEvent(new Event(LIST_CALL));
		}
		
		public function processListState(opened:Boolean = false):void {
			_opened = opened;
			setFace(up);
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			if (media && media.metadata) {
				mouseChildren = mouseEnabled = !media.metadata.getValue("Advertisement");
				setSuperVisible(!media.metadata.getValue("Advertisement"));
			}
		}
		
		override protected function setFace(face:DisplayObject):void {
			if (face == up) {
				super.setFace(_opened ? down : up); 
			} else {
				super.setFace(face); 
			}
			
		}
	}		
}