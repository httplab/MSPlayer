package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.events.ContainerChangeEvent;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.LayoutTargetEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamingURLResource;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class ChannelListButton extends ButtonWidget {
		private var _opened:Boolean;
		static public const LIST_CALL:String = "listCall";
		static public const LIST_CLOSE_CALL:String = "listCloseCall";
		public function ChannelListButton() {
			upFace = AssetIDs.CHANNEL_LIST_BUTTON_NORMAL;
			downFace = AssetIDs.CHANNEL_LIST_BUTTON_DOWN;
			overFace = AssetIDs.CHANNEL_LIST_BUTTON_OVER;
			addEventListener(LayoutTargetEvent.REMOVE_FROM_LAYOUT_RENDERER, removedFromControlBar);
		}
		
		private function removedFromControlBar(e:LayoutTargetEvent):void {
			dispatchEvent(new Event(LIST_CLOSE_CALL));
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			_opened	? dispatchEvent(new Event(LIST_CLOSE_CALL)) : dispatchEvent(new Event(LIST_CALL));
		}
		
		public function processListState(opened:Boolean = false):void {
			_opened = opened;
			setFace(up);
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			if (media && media.metadata) {
				var vis:Boolean = !media.metadata.getValue("Advertisement") && (streamType != StreamType.RECORDED);
				mouseChildren = mouseEnabled = vis;
				setSuperVisible(vis);
			}
		}
		
		override protected function setFace(face:DisplayObject):void {
			if (face == up) {
				super.setFace(_opened ? down : up); 
			} else {
				super.setFace(face); 
			}
		}
		
		private function get streamType():String {
			if (super.media && super.media.resource && (super.media.resource as StreamingURLResource)) {
				return (super.media.resource as StreamingURLResource).streamType;
			} 
			return '';
		}
		
		/**
		* OSMF-fight.
		*/
		
		override public function get layoutMetadata():LayoutMetadata {
			var toReturn:LayoutMetadata = super.layoutMetadata;
			toReturn.includeInLayout = true;
			toReturn.width = (streamType == StreamType.RECORDED) ? 0 : toReturn.width;
			return toReturn;
		}
		
		override public function get measuredWidth():Number {
			return currentFace.width;
		}
		
		override public function get measuredHeight():Number {
			return currentFace.height;
		}
	}		
}