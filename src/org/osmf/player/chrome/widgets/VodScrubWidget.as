package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;

	public class VodScrubWidget extends Widget {
		private var backDropLeft_played:DisplayObject;
		private var backDropMiddle_played:DisplayObject;
		private var backDropRight_played:DisplayObject;
		private var backDropLeft_loaded:DisplayObject;
		private var backDropMiddle_loaded:DisplayObject;
		private var backDropRight_loaded:DisplayObject;
		private var backDropLeft_empty:DisplayObject;
		private var backDropMiddle_empty:DisplayObject;
		private var backDropRight_empty:DisplayObject;
		private var emptyContainer:Sprite;
		private var loadedContainer:Sprite;
		private var playedContainer:Sprite;
		private var _loadedMask:Sprite;
		private var _playedMask:Sprite;
		private var seeker:Seeker;
		private var _seekTo:Number;
		
		public function VodScrubWidget() {
			super();
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			emptyContainer = new Sprite();
			loadedContainer = new Sprite();
			playedContainer = new Sprite();
			
			backDropLeft_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_LEFT); 
			backDropMiddle_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_MIDDLE); 
			backDropRight_played = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_RIGHT); 
			
			backDropLeft_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_LEFT); 
			backDropMiddle_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_MIDDLE); 
			backDropRight_loaded = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_RIGHT); 
			
			backDropLeft_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_LEFT); 
			backDropMiddle_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_MIDDLE); 
			backDropRight_empty = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_GRAY_RIGHT); 
			
			emptyContainer.addChild(backDropLeft_empty);
			emptyContainer.addChild(backDropMiddle_empty);
			emptyContainer.addChild(backDropRight_empty);
			
			loadedContainer.addChild(backDropLeft_loaded);
			loadedContainer.addChild(backDropMiddle_loaded);
			loadedContainer.addChild(backDropRight_loaded);
			_loadedMask = new Sprite();
			loadedContainer.mask = _loadedMask;
			loadedContainer.addChild(_loadedMask);
			
			playedContainer.addChild(backDropLeft_played);
			playedContainer.addChild(backDropMiddle_played);
			playedContainer.addChild(backDropRight_played);
			_playedMask = new Sprite();
			playedContainer.mask = _playedMask;
			playedContainer.addChild(_playedMask);
			
			addChild(emptyContainer);
			addChild(loadedContainer);
			addChild(playedContainer);
			
			seeker = new Seeker();
			seeker.addEventListener(Seeker.SEEK_START, onSeekerStart);
			seeker.addEventListener(Seeker.SEEK_UPDATE, onSeekerUpdate);
			seeker.addEventListener(Seeker.SEEK_END, onSeekerEnd);
			addChild(seeker);
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			if (availableWidth + availableHeight == 0) { return;}
			backDropMiddle_empty.width = availableWidth - (backDropLeft_empty.width + backDropRight_empty.width);
			backDropMiddle_loaded.width = availableWidth - (backDropLeft_loaded.width + backDropRight_loaded.width);
			backDropMiddle_played.width = availableWidth - (backDropLeft_played.width + backDropRight_played.width);
			
			backDropMiddle_empty.x = backDropLeft_empty.width;
			backDropRight_empty.x = availableWidth - backDropRight_empty.width;
			
			backDropMiddle_loaded.x = backDropLeft_loaded.width;
			backDropRight_loaded.x = availableWidth - backDropRight_loaded.width;
			
			backDropMiddle_played.x = backDropLeft_played.width;
			backDropRight_played.x = availableWidth - backDropRight_played.width;
			seeker.point = new Point(width, height);
		}
		
		private function onSeekerStart(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PAUSE_CALL));
		}
		
		private function onSeekerUpdate(event:Event):void {
			_seekTo = seeker.position;
			dispatchEvent(new Event(ScrubBar.SEEK_CALL));
		}
		
		private function onSeekerEnd(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PLAY_CALL));
		}
		
		public function set loadedPosition(value:Number):void {
			isNaN(value) && (value = 0);
			with (_loadedMask.graphics) {
				clear();
				beginFill(0, 1);
				drawRect(0, 0, value * width, height);
				endFill();
			}
		}
		
		public function set playedPosition(value:Number):void {
			isNaN(value) && (value = 0);
			with (_playedMask.graphics) {
				clear();
				beginFill(0, 1);
				drawRect(0, 0, value * width, height);
				endFill();
			}
		}
		
		public function removeHandlers():void {
			seeker.removeHandlers();
		}
		
		override public function get width():Number {
			return Math.max(emptyContainer.width, loadedContainer.width, playedContainer.width);
		}
		
		override public function get height():Number {
			return Math.max(emptyContainer.height, loadedContainer.height, playedContainer.height);
		}
		
		public function get seekTo():Number {
			return _seekTo;
		}
	}
}