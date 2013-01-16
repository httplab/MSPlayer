package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.widgets.Seeker;
	import org.osmf.player.media.StrobeMediaPlayer;
	import org.osmf.player.metadata.MediaMetadata;

	public class DVRScrubWidget extends LiveScrubWidget {
		private var backDropRecorded:DisplayObject;
		private var backDropRecordedFace:String;
		private var seeker:Seeker;
		private var _seekTo:Number;
		
		public function DVRScrubWidget() {
			super();
			backDropLeftFace = AssetIDs.SCRUB_BAR_BLUE_LEFT;
			backDropMiddleFace = AssetIDs.SCRUB_BAR_BLUE_MIDDLE;
			backDropLeftProgramFace = AssetIDs.SCRUB_BAR_WHITE_LEFT;
			backDropMiddleProgramFace = AssetIDs.SCRUB_BAR_WHITE_MIDDLE;
			backDropRightProgramFace = AssetIDs.SCRUB_BAR_WHITE_RIGHT;
			backDropRecordedFace = AssetIDs.SCRUB_BAR_RECORDED_RIGHT;
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			seeker = new Seeker();
			seeker.addEventListener(Seeker.SEEK_START, onSeekerStart);
			seeker.addEventListener(Seeker.SEEK_UPDATE, onSeekerUpdate);
			seeker.addEventListener(Seeker.SEEK_END, onSeekerEnd);
			addChild(seeker);
			
			backDropRecorded = assetManager.getDisplayObject(backDropRecordedFace); 
			backDropRecorded.addEventListener(MouseEvent.MOUSE_DOWN, goToLive);
			backDropRecorded.visible = false;
			container.addChild(backDropRecorded);
		}
		
		private function goToLive(event:MouseEvent):void {
			if (!media) { return; }
			var mediaMetadata:MediaMetadata = media.metadata.getValue(MediaMetadata.ID) as MediaMetadata;
			var mediaPlayer:StrobeMediaPlayer = mediaMetadata.mediaPlayer;
			if (mediaPlayer.snapToLive()) {
				backDropRecorded.visible = false;
			}
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			super.layout(availableWidth, availableHeight, deep);
			backDropRecorded.x = backDropLiveRight.x;
			seeker.point = new Point(width, height);
		}
		
		private function onSeekerStart(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PAUSE_CALL));
		}
		
		private function onSeekerUpdate(event:Event):void {
			_seekTo = seeker.position;
			dispatchEvent(new Event(ScrubBar.SEEK_CALL));
			if (_seekTo <= 1) {
				backDropRecorded.visible = true;
			}
		}
		
		private function onSeekerEnd(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PLAY_CALL));
		}
		
		public function get seekTo():Number {
			return _seekTo;
		}
		
		public function removeHandlers():void {
			seeker.removeHandlers();
		}
	}
}