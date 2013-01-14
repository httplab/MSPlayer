package org.osmf.player.chrome.widgets {
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;
	import org.osmf.elements.VideoElement;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaElementEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.media.MediaElement;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.assets.FontAsset;
	import org.osmf.player.chrome.utils.FormatUtils;
	import org.osmf.player.chrome.utils.MediaElementUtils;
	import org.osmf.player.chrome.widgets.DVRScrubWidget;
	import org.osmf.player.chrome.widgets.LiveScrubWidget;
	import org.osmf.player.chrome.widgets.TimeHintWidget;
	import org.osmf.player.chrome.widgets.Widget;
	import org.osmf.player.media.StrobeMediaPlayer;
	import org.osmf.player.metadata.MediaMetadata;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayState;
	import org.osmf.traits.PlayTrait;
	import org.osmf.traits.SeekTrait;
	import org.osmf.traits.TimeTrait;

	public class ScrubBar extends Widget {
		private static const CURRENT_POSITION_UPDATE_INTERVAL:int = 100;
		static public const PAUSE_CALL:String = "pauseCall";
		static public const PLAY_CALL:String = "playCall";
		static public const SEEK_CALL:String = "seekCall";
		static public const SHOW_HINT_CALL:String = "showHintCall";
		static public const HIDE_HINT_CALL:String = "hideHintCall";
		
		private var vodScrub:VodScrubWidget;
		private var liveScrub:LiveScrubWidget;
		private var dvrScrub:DVRScrubWidget;
		private var _currentSubWidget:Widget;
		private var currentPositionTimer:Timer;
		private var _pausedByCall:Boolean;
		private var timeHint:TimeHintWidget;
		private var textFormat:TextFormat;
		
		/**
		* OSMF overrides. Initial settings
		*/
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			vodScrub = new VodScrubWidget();
			vodScrub.configure(xml, assetManager);
			
			liveScrub = new LiveScrubWidget();
			liveScrub.configure(xml, assetManager);
			
			dvrScrub = new DVRScrubWidget();
			dvrScrub.configure(xml, assetManager);
			
			var fontAsset:FontAsset = assetManager.getAsset(AssetIDs.TAHOMA) as FontAsset;
			textFormat = fontAsset ? fontAsset.format : new TextFormat();
			textFormat.size = 10;
			textFormat.bold = false;
			textFormat.align = TextFormatAlign.CENTER;
			
			timeHint = new TimeHintWidget();
			timeHint.autoSize = true;
			timeHint.tintColor = tintColor;
			timeHint.textFormat = textFormat;
			timeHint.configure(xml, assetManager);
			addChildWidget(timeHint);
			timeHint.visible = false;
			
			currentPositionTimer = new Timer(CURRENT_POSITION_UPDATE_INTERVAL);
			currentPositionTimer.addEventListener(TimerEvent.TIMER, currentTimeChangedHandler);
			currentPositionTimer.addEventListener(TimerEvent.TIMER, bytesLoadedChangedHandler);
			currentPositionTimer.start();
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			if (!availableWidth || !availableHeight) { return; }
			vodScrub.layout(availableWidth, availableHeight, deep);
			liveScrub.layout(availableWidth, availableHeight, deep);
			dvrScrub.layout(availableWidth, availableHeight, deep);
			//super.layout(availableWidth, availableHeight, deep);
		}
		
		private function updateCurrentWidget():void {
			switch(streamType) {
				case StreamType.DVR: 
					currentSubWidget = dvrScrub;
					var mediaMetadata:MediaMetadata = media.metadata.getValue(MediaMetadata.ID) as MediaMetadata;
					mediaMetadata.mediaPlayer.snapToLive();
					break;
				case StreamType.LIVE: 
					currentSubWidget = liveScrub;
					break;
				case StreamType.RECORDED: 
					currentSubWidget = vodScrub;
					break;
				default: 
					break;
			}
			if (_currentSubWidget && _currentSubWidget != vodScrub) {
				addShedules();
			}
		}
		
		private function addShedules():void {
			if ((media is VideoElement) && ((media as VideoElement).resource is MultiQualityStreamingResource)) {
				_currentSubWidget['programPositions'] = ((media as VideoElement).resource as MultiQualityStreamingResource).shedulesArray;
			}
		}
		
		/**
		* Event handlers
		*/
		
		private function currentTimeChangedHandler(e:Event):void {
			timeTrait && (vodScrub.playedPosition = timeTrait.currentTime / timeTrait.duration);
		}
		
		private function bytesLoadedChangedHandler(e:Event):void {
			loadTrait && (vodScrub.loadedPosition = loadTrait.bytesLoaded / loadTrait.bytesTotal); 
		}
		
		private function addSubWidgetHandlers(currentSubWidget:Widget):void {
			removeSubWidgetHandlers(currentSubWidget);
			_currentSubWidget.addEventListener(PAUSE_CALL, pauseCallHandler);
			_currentSubWidget.addEventListener(PLAY_CALL, playCallHandler);
			_currentSubWidget.addEventListener(SEEK_CALL, seekCallHandler);
			_currentSubWidget.addEventListener(SHOW_HINT_CALL, showHintCallHandler);
			_currentSubWidget.addEventListener(HIDE_HINT_CALL, hideHintHandler);
		}
		
		private function removeSubWidgetHandlers(currentSubWidget:Widget):void {
			try {
				_currentSubWidget['removeHandlers']();
			} catch (e:Error) { }
			_currentSubWidget.removeEventListener(PAUSE_CALL, pauseCallHandler);
			_currentSubWidget.removeEventListener(PLAY_CALL, playCallHandler);
			_currentSubWidget.removeEventListener(SEEK_CALL, seekCallHandler);
			_currentSubWidget.removeEventListener(SHOW_HINT_CALL, showHintCallHandler);
			_currentSubWidget.removeEventListener(HIDE_HINT_CALL, hideHintHandler);
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
		
		private function showHintCallHandler(e:Event):void {
			if (_currentSubWidget != vodScrub) {
				timeHint.text = _currentSubWidget['programText'];
			} else {
				if (!timeTrait) { return;}
				timeHint.text = FormatUtils.formatTimeStatus(_currentSubWidget['hintPosition'] * timeTrait.duration, timeTrait.duration)[0];	
			}
			timeHint.textFormat = textFormat;
			timeHint.visible = true;
			timeHint.x = width * _currentSubWidget['hintPosition'];
			timeHint.x -= timeHint.width / 2;
			timeHint.y = -timeHint.height;
		}
		
		private function hideHintHandler(e:Event):void {
			timeHint.visible = false;
		}
		
		/*
		* TODO: Check, if this override really needed?
		*/
		
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
		
		/**
		* Stuff
		*/
		
		/**
		* Getters/setters
		*/
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			//enabled = media ? media.hasTrait(MediaTraitType.SEEK) : false;
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
			updateCurrentWidget();
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
		
		override public function get layoutMetadata():LayoutMetadata {
			var toReturn:LayoutMetadata = super.layoutMetadata;
			toReturn.includeInLayout = true;
			return toReturn;
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
		
		override public function get width():Number {
			return vodScrub.width;
		}
		
		override public function get height():Number {
			return vodScrub.height;
		}
	}
}