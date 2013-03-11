package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class FullWidthButton extends ButtonWidget {
		private var _opened:Boolean;
		static public const FULL_WIDTH_CALL:String = "fullWidthCall";
		public function FullWidthButton() {
			upFace = AssetIDs.FULL_WIDTH_NORMAL;
			downFace = AssetIDs.FULL_WIDTH_DOWN;
			overFace = AssetIDs.FULL_WIDTH_OVER;
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			dispatchEvent(new Event(FULL_WIDTH_CALL));
		}
		
		public function processState(opened:Boolean = false):void {
			_opened = opened;
			setFace(up);
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