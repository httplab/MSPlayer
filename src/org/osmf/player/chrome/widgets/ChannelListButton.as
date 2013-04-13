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
	import org.osmf.player.chrome.assets.AssetsManager;

	public class ChannelListButton extends ButtonWidget {
		private var _opened:Boolean;
		private var upCollapsedFace:String;
		private var downCollapsedFace:String;
		private var overCollapsedFace:String;
		private var upCollapsed:DisplayObject;
		private var downCollapsed:DisplayObject;
		private var overCollapsed:DisplayObject;
		static public const LIST_CALL:String = "listCall";
		static public const LIST_CLOSE_CALL:String = "listCloseCall";
		public function ChannelListButton() {
			upFace = AssetIDs.CHANNEL_LIST_BUTTON_NORMAL;
			downFace = AssetIDs.CHANNEL_LIST_BUTTON_DOWN;
			overFace = AssetIDs.CHANNEL_LIST_BUTTON_OVER;
			upCollapsedFace = AssetIDs.CHANNEL_LIST_BUTTON_COLLAPSED_NORMAL;
			downCollapsedFace = AssetIDs.CHANNEL_LIST_BUTTON_COLLAPSED_DOWN;
			overCollapsedFace = AssetIDs.CHANNEL_LIST_BUTTON_COLLAPSED_OVER;
			
			addEventListener(LayoutTargetEvent.REMOVE_FROM_LAYOUT_RENDERER, removedFromControlBar);
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			upCollapsed = assetManager.getDisplayObject(upCollapsedFace);
			downCollapsed = assetManager.getDisplayObject(downCollapsedFace);
			overCollapsed = assetManager.getDisplayObject(overCollapsedFace);
		}
		
		private function removedFromControlBar(e:LayoutTargetEvent):void {
			dispatchEvent(new Event(LIST_CLOSE_CALL));
		}
		
		override protected function onMouseClick(event:MouseEvent):void {
			_opened ? dispatchEvent(new Event(LIST_CLOSE_CALL)) : dispatchEvent(new Event(LIST_CALL));
		}
		
		public function processListState(opened:Boolean = false):void {
			_opened = opened;
			setFace(up);
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			if (media && media.metadata) {
				processListState(_opened);
				var vis:Boolean = !State.isAd() && (State.streamType != StreamType.RECORDED);
				mouseChildren = mouseEnabled = vis;
				setSuperVisible(vis);
			}
		}
		
		override protected function setFace(face:DisplayObject):void {
			if (face == up) {
				super.setFace(_opened ? getFace(down) : getFace(up)); 
			} else {
				super.setFace(getFace(face)); 
			}
		}
		
		private function getFace(face:DisplayObject):DisplayObject {
			if (isExpanded) { return face; }
			switch (face) {
				case up:
					return upCollapsed;
				case down:
					return downCollapsed;
				case over:
					return overCollapsed;
				default:
					return face;
			}
		}
		
		/**
		* OSMF-fight.
		*/
		
		override public function get layoutMetadata():LayoutMetadata {
			var toReturn:LayoutMetadata = super.layoutMetadata;
			toReturn.includeInLayout = true;
			toReturn.width = (State.streamType == StreamType.RECORDED) ? 0 : toReturn.width;
			return toReturn;
		}
		
		override public function get measuredWidth():Number {
			return currentFace.width;
		}
		
		override public function get measuredHeight():Number {
			return currentFace.height;
		}
		
		public function get isExpanded():Boolean {
			return State.streamType != StreamType.DVR;
		}
	}		
}