package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class FreeModeButton extends ButtonWidget {
		private var _opened:Boolean;
		static public const FREE_MODE_CALL:String = "freeModeCall";
		
		public function FreeModeButton() {
			upFace = AssetIDs.FREE_MODE_NORMAL;
			downFace = AssetIDs.FREE_MODE_DOWN;
			overFace = AssetIDs.FREE_MODE_OVER;
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			dispatchEvent(new Event(FREE_MODE_CALL));
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