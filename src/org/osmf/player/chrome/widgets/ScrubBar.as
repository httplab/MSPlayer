package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaElementEvent;
	import org.osmf.events.MetadataEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.media.MediaElement;
	import org.osmf.metadata.MetadataNamespaces;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.events.ScrubberEvent;
	import org.osmf.player.chrome.utils.MediaElementUtils;
	import org.osmf.player.chrome.widgets.DVRScrubWidget;
	import org.osmf.player.chrome.widgets.LiveScrubWidget;
	import org.osmf.player.chrome.widgets.Widget;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayState;
	import org.osmf.traits.PlayTrait;
	import org.osmf.traits.SeekTrait;
	import org.osmf.traits.TimeTrait;
	import org.osmf.layout.LayoutAttributesMetadata;

	public class ScrubBar extends Widget {
		private static const CURRENT_POSITION_UPDATE_INTERVAL:int = 100;
		static public const PAUSE_CALL:String = "pauseCall";
		static public const PLAY_CALL:String = "playCall";
		static public const SEEK_CALL:String = "seekCall";
		
		private var vodScrub:VodScrubWidget;
		private var liveScrub:LiveScrubWidget;
		private var dvrScrub:DVRScrubWidget;
		private var _currentSubWidget:Widget;
		private var currentPositionTimer:Timer;
		private var _pausedByCall:Boolean;
		
		override protected function setSuperVisible(value:Boolean):void {
			super.setSuperVisible(true);
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			vodScrub = new VodScrubWidget();
			vodScrub.configure(xml, assetManager);
			
			liveScrub = new LiveScrubWidget();
			liveScrub.configure(xml, assetManager);
			
			dvrScrub = new DVRScrubWidget();
			dvrScrub.configure(xml, assetManager);
			
			currentPositionTimer = new Timer(CURRENT_POSITION_UPDATE_INTERVAL);
			currentPositionTimer.addEventListener(TimerEvent.TIMER, currentTimeChangedHandler);
			currentPositionTimer.addEventListener(TimerEvent.TIMER, bytesLoadedChangedHandler);
			currentPositionTimer.start();
		}
		
		override public function get layoutMetadata():LayoutMetadata {
			var toReturn:LayoutMetadata = super.layoutMetadata;
			toReturn.includeInLayout = true;
			return toReturn;
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			if (!availableWidth || !availableHeight) { return; }
			vodScrub.layout(availableWidth, availableWidth, deep);
			liveScrub.layout(availableWidth, availableWidth, deep);
			dvrScrub.layout(availableWidth, availableWidth, deep);
			//super.layout(availableWidth, availableHeight, deep);
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			enabled = media ? media.hasTrait(MediaTraitType.SEEK) : false;
			visible = Boolean(media);
			if (!media) {
				return;
			}
			for each(var traitType:String in value.traitTypes) {
				var traitAddEvent:MediaElementEvent = new MediaElementEvent(MediaElementEvent.TRAIT_ADD, false, false, traitType);						
				onMediaElementTraitAdd(traitAddEvent);
			}
            if (media && media.metadata) {
                visible = !media.metadata.getValue("Advertisement");
            }
			onMediaElementTraitRemove(null);
			switch(streamType) {
				case StreamType.DVR: 
					currentSubWidget = dvrScrub;
					break;
				case StreamType.LIVE: 
					currentSubWidget = liveScrub;
					break;
				case StreamType.RECORDED: 
					currentSubWidget = vodScrub;
					break;
			}
		}
		
		override protected function onMediaElementTraitAdd(event:MediaElementEvent):void {
			switch (event.traitType) {
				case MediaTraitType.TIME:
					timeTrait.removeEventListener(TimeEvent.CURRENT_TIME_CHANGE, currentTimeChangedHandler);
					timeTrait.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, currentTimeChangedHandler);
					currentTimeChangedHandler(null);
					break;
				case MediaTraitType.LOAD:
					loadTrait.removeEventListener(LoadEvent.BYTES_LOADED_CHANGE, bytesLoadedChangedHandler);
					loadTrait.addEventListener(LoadEvent.BYTES_LOADED_CHANGE, bytesLoadedChangedHandler);
					bytesLoadedChangedHandler(null);
					break;
				case MediaTraitType.SEEK:
					visible = Boolean(seekTrait);
					break;
			}
		}
		
		private function currentTimeChangedHandler(e:Event):void {
			timeTrait && (vodScrub.playedPosition = timeTrait.currentTime / timeTrait.duration);
		}
		
		private function bytesLoadedChangedHandler(e:Event):void {
			loadTrait && (vodScrub.loadedPosition = loadTrait.bytesLoaded / loadTrait.bytesTotal); 
		}
		
		override protected function onMediaElementTraitRemove(event:MediaElementEvent):void {
			if (!seekTrait) {
                visible = false;
			}
		}
		
		private function set currentSubWidget(value:Widget):void {
			if (_currentSubWidget) {
				removeSubWidgetHandlers(_currentSubWidget);
				removeChildWidget(_currentSubWidget);
			}
			_currentSubWidget = value;
			if (_currentSubWidget) {
				addSubWidgetHandlers(_currentSubWidget);
				addChildWidget(_currentSubWidget);
			}
		}
		
		private function addSubWidgetHandlers(currentSubWidget:Widget):void {
			_currentSubWidget.addEventListener(PAUSE_CALL, pauseCallHandler);
			_currentSubWidget.addEventListener(PLAY_CALL, playCallHandler);
			_currentSubWidget.addEventListener(SEEK_CALL, seekCallHandler);
		}
		
		private function removeSubWidgetHandlers(currentSubWidget:Widget):void {
			try {
				_currentSubWidget['removeHandlers']();
			} catch (e:Error) { }
			_currentSubWidget.removeEventListener(PAUSE_CALL, pauseCallHandler);
			_currentSubWidget.removeEventListener(PLAY_CALL, playCallHandler);
			_currentSubWidget.removeEventListener(SEEK_CALL, seekCallHandler);
		}
		
		private function playCallHandler(e:Event):void {
			if (playTrait && _pausedByCall) {
				playTrait.play();
				_pausedByCall = false;
			}
		}
		
		private function pauseCallHandler(e:Event):void {
			if (playTrait && playTrait.canPause && playTrait.playState == PlayState.PLAYING) {
				playTrait.pause();
				_pausedByCall = true;
			}
		}
		
		private function seekCallHandler(e:Event):void {
			if (!timeTrait && !seekTrait) { return; }
			var time:Number = timeTrait.duration * (_currentSubWidget['seekTo'] || 0);
			if (seekTrait.canSeekTo(time)) {
				if (playTrait && playTrait.playState == PlayState.STOPPED) {
					if (playTrait.canPause) {
						playTrait.play();
						playTrait.pause();
					}
				}
				seekTrait.seek(time);
			}
		}
		
		public function get timeTrait():TimeTrait {
			return media ? media.getTrait(MediaTraitType.TIME) as TimeTrait : null;
		}
		
		public function get loadTrait():LoadTrait {
			return media ? media.getTrait(MediaTraitType.LOAD) as LoadTrait : null;
		}
		
		public function get seekTrait():SeekTrait {
			return media ? media.getTrait(MediaTraitType.SEEK) as SeekTrait : null;
		}
		
		public function get playTrait():PlayTrait {
			return media ? media.getTrait(MediaTraitType.PLAY) as PlayTrait : null;
		}
		
		private function get streamType():String {			
			if (!media) {
				return "";
			}
			return MediaElementUtils.getStreamType(media);
		}
		
		override public function get measuredHeight():Number {
			return vodScrub.height;
		}
		
		override public function get height():Number {
			return vodScrub.height;
		}
	}
}