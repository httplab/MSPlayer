package {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import org.osmf.elements.ImageElement;
	import org.osmf.elements.ImageLoader;
	import org.osmf.events.LoaderEvent;
	import org.osmf.events.LoadEvent;
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaPlayerState;
	import org.osmf.media.URLResource;
	import org.osmf.net.StreamType;
	import org.osmf.player.chrome.events.WidgetEvent;
	import org.osmf.player.elements.ControlBarElement;
	import org.osmf.player.media.StrobeMediaFactory;
	import org.osmf.player.media.StrobeMediaPlayer;
	import org.osmf.player.metadata.MediaMetadata;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.vast.loader.VASTLoader;
	import org.osmf.vast.loader.VASTLoadTrait;
	import org.osmf.vast.media.VASTMediaGenerator;
	
	public class AdController extends EventDispatcher {
		private static const MAX_NUMBER_REDIRECTS:int = 5;
		private static const POSTER_INDEX:int = 2;
		
		static public const PREROLL_ENDED:String = "prerollEnded";
		static public const PAUSE_MAIN_VIDEO_REQUEST:String = "pauseMainVideoRequest";
		static public const RESTORE_MAIN_VIDEO_REQUEST:String = "restoreMainVideoRequest";
		static public const RESUME_MAIN_VIDEO_REQUEST:String = "resumeMainVideoRequest";
		
		// Weak references for the currently playing ads
        private var adPlayers:Dictionary = new Dictionary(true);
		
		private var _player:StrobeMediaPlayer;
		private var _viewHelper:ViewHelper;
		private var _vastLoader:VASTLoader;
		private var _vastLoadTrait:VASTLoadTrait;
		private var _factory:StrobeMediaFactory;
		private var _loaderParams:Object;
		private var posterImage:ImageElement;
		private var _linearAdsQueue:Array = [];
		private var _linearSlotBusy:Boolean = false;
		
		public function AdController(
			player:StrobeMediaPlayer, 
			viewHelper:ViewHelper, 
			factory:StrobeMediaFactory
		) {
			_player = player;
			_viewHelper = viewHelper;
			_factory = factory;
		}
		
		public function checkForAd(loaderParams:Object, streamType:String, liveResumingHack:Boolean = false):void {
			_loaderParams = loaderParams;
			if (!liveResumingHack && _loaderParams.preRoll) {
				var interruptInterval:int = int(_loaderParams.preRollInterrupt) || int(_loaderParams.interrupt) || 0;
				prepareLinearAd(_loaderParams.preRoll, true, interruptInterval);
            }
            if (streamType != StreamType.LIVE && _loaderParams.midRoll && _loaderParams.midRollTime) {
                _player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, checkForMidrollNeed);
            }
            if (streamType != StreamType.LIVE && _loaderParams.pauseRoll) {
				_viewHelper.controlBar.addEventListener(ControlBarElement.PLAY_BUTTON_CLICK, planPauseRoll, false, int.MAX_VALUE);
			}
            if (streamType == StreamType.RECORDED && _loaderParams.postRoll) {
                _player.addEventListener(TimeEvent.COMPLETE, planPostRoll);
            }
		}
		
		public function prepareLinearAd(adFile:String, resumePlaybackAfterAd:Boolean = true, interruptInterval:int = 0):void {
			var vastResource:URLResource = new URLResource(adFile);
			_vastLoader = new VASTLoader(MAX_NUMBER_REDIRECTS);
			_vastLoadTrait = new VASTLoadTrait(_vastLoader, vastResource);
			_vastLoader.addEventListener(LoaderEvent.LOAD_STATE_CHANGE, onRollLoaderStateChange);
			_vastLoader.load(_vastLoadTrait);
			var loadStarted:Number = new Date().time;
			function onRollLoaderStateChange(event:LoaderEvent):void {
				if (event.newState == LoadState.READY) {
					event.currentTarget.removeEventListener(LoadEvent.LOAD_STATE_CHANGE, arguments.callee);
					ExternalInterface.available && ExternalInterface.call('console.log', "VAST responce time: " + (new Date().time - loadStarted) + " ms");
					var generator:VASTMediaGenerator = new VASTMediaGenerator();
					var mediaElements:Vector.<MediaElement> = generator.createMediaElements(
						_vastLoadTrait.vastDocument
					);
					mediaElements.length && _linearAdsQueue.push([mediaElements[0], true, resumePlaybackAfterAd, interruptInterval]);
					continueAdvertising();
				}
			}
		}
		
		/**
		* 
		*/
		
		//public function displayNonLinearAd(url:String, layoutInfo:Object):void
		public function displayNonLinearAd():void {
			var overlayMetadata:LayoutMetadata = new LayoutMetadata();
			overlayMetadata.right = 10;
			overlayMetadata.bottom = 10;
			overlayMetadata.width = 200;
			overlayMetadata.height = 140;
			overlayMetadata.scaleMode = ScaleMode.STRETCH;
			var overlayUrl:String = "http://gcdn.2mdn.net/MotifFiles/html/1379578/PID_938961_1237818260000_women.flv";
			var adMediaElement:MediaElement = _factory.createMediaElement(new URLResource(overlayUrl));
			adMediaElement.metadata.addValue(LayoutMetadata.LAYOUT_NAMESPACE, overlayMetadata);
			displayAd(adMediaElement, false, false);
		}
		
		public function displayAd(
			adMediaElement:MediaElement, 
			pauseMainMediaWhilePlayingAd:Boolean = true, 
			resumePlaybackAfterAd:Boolean = true,
			interruptInterval:int = 0
		):void {
			var adMediaPlayer:StrobeMediaPlayer = new StrobeMediaPlayer();
			_viewHelper.mediaContainer.addMediaElement(adMediaElement);
			adPlayers[adMediaPlayer] = {
				pauseMainMediaWhilePlayingAd: pauseMainMediaWhilePlayingAd,
				resumePlaybackAfterAd: resumePlaybackAfterAd,
				mediaPlayer:adMediaPlayer
			}
			adMediaPlayer.media = adMediaElement;
			SOWrapper.processPlayer(adMediaPlayer, false);
			adMediaPlayer.media.metadata.addValue("Advertisement", "1");
			if (pauseMainMediaWhilePlayingAd) {
				dispatchEvent(new Event(PAUSE_MAIN_VIDEO_REQUEST));
				//displayNonLinearAd();
			}
			var mediaMetadata:MediaMetadata = new MediaMetadata();
			mediaMetadata.mediaPlayer = adMediaPlayer;
			adMediaElement.metadata.addValue(MediaMetadata.ID, mediaMetadata);
			_viewHelper.controlBar && (_viewHelper.controlBar.target = adMediaElement);
			_viewHelper.playerTitle && (_viewHelper.playerTitle.target = adMediaElement);
			adMediaPlayer.removeEventListener(TimeEvent.COMPLETE, adCompleteHandler);
			adMediaPlayer.addEventListener(TimeEvent.COMPLETE, adCompleteHandler);
			adMediaPlayer.play();
			interruptInterval = interruptInterval || adMediaElement.metadata.getValue('canBeSkipped') || 0;
			_viewHelper.adBlockHeader.startCountdown(interruptInterval * 1000);
			_viewHelper.adBlockHeader.addEventListener(AdBlockHeader.PASS_AD_REQUEST, interruptAllRolls);
		}
		
		public function processPoster(posterUrl:String, scaleMode:String):void {
			//Show a poster if there's one set, and the content is not yet playing back:
			try {
				if (posterImage) {
					removePoster();
				}
				posterImage = new ImageElement(new URLResource(posterUrl), new ImageLoader(false));
				//Setup the poster image:
				//posterImage.smoothing = true;
				var layoutMetadata:LayoutMetadata = new LayoutMetadata();
				layoutMetadata.scaleMode = scaleMode;
				layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				layoutMetadata.percentWidth = 100;
				layoutMetadata.percentHeight = 100;
				layoutMetadata.index = POSTER_INDEX;
				posterImage.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
				LoadTrait(posterImage.getTrait(MediaTraitType.LOAD)).load();
				_viewHelper.mediaContainer.addMediaElement(posterImage);
				// Listen for the main content player to reach a playing, or playback error
				// state. At that time, we remove the poster:
				_player.addEventListener(
					MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE,
					removePosterOnMediaPlayerStateChange
				);
			} catch (error:Error) {
				// Fail poster loading silently:
				trace("WARNING: poster image failed to load at", posterUrl);
			}
		}
		
		public function removePoster():void {
			// Remove the poster image:
			if (posterImage && _viewHelper.mediaContainer.containsMediaElement(posterImage)) {
				_viewHelper.mediaContainer.removeMediaElement(posterImage);
				LoadTrait(posterImage.getTrait(MediaTraitType.LOAD)).unload();
			}
			posterImage = null;
		}
		
		public function processFitToScreenRequest(event:Event):void {
			if (!posterImage) { return; }
			if (event.type == WidgetEvent.REQUEST_FULL_SCREEN_FORCE_FIT) {
				(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.ZOOM;
			} else if (event.type == WidgetEvent.REQUEST_FULL_SCREEN) {
				(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
			}
		}
		
		public function onFullScreen():void {
			if (posterImage) {
				(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
			}
		}
		
		/**
		* Playback event handlers
		*/
		
		private function adCompleteHandler(e:Event):void {
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			var adMediaPlayer:StrobeMediaPlayer = e.currentTarget as StrobeMediaPlayer;
			adMediaPlayer.playing && adMediaPlayer.pause();
			adMediaPlayer.media.metadata.removeValue("Advertisement");
			_viewHelper.mediaContainer.removeMediaElement(adMediaPlayer.media);
			if (adPlayers[adMediaPlayer].pauseMainMediaWhilePlayingAd) {
				dispatchEvent(new Event(RESTORE_MAIN_VIDEO_REQUEST));
				if (adPlayers[adMediaPlayer].resumePlaybackAfterAd) {
					_linearSlotBusy = false;
					_viewHelper.adBlockHeader.removeEventListener(AdBlockHeader.PASS_AD_REQUEST, interruptAllRolls);
					_viewHelper.adBlockHeader.kill();
					continueAdvertising();
				}
			}
			delete adPlayers[adMediaPlayer];
		}
		
		private function interruptAllRolls(e:Event):void {
			for each(var obj:Object in adPlayers) {
				var mp:StrobeMediaPlayer = obj.mediaPlayer as StrobeMediaPlayer;
				mp && mp.dispatchEvent(new TimeEvent(TimeEvent.COMPLETE));
			}
		}
		
		private function continueAdvertising():void {
			if (_linearSlotBusy) { return; }
			if (_linearAdsQueue.length) {
				_linearSlotBusy = true;
				var delayedLinearAd:Array = _linearAdsQueue.shift();
				displayAd(delayedLinearAd[0] as MediaElement, delayedLinearAd[1], delayedLinearAd[2], delayedLinearAd[3]);
			} else {
				dispatchEvent(new Event(RESUME_MAIN_VIDEO_REQUEST));
			}
		}
		
		private function checkForMidrollNeed(e:TimeEvent):void {
			if (_player.currentTime > parseInt(_loaderParams.midRollTime)) {
				e.currentTarget.removeEventListener(e.type, arguments.callee);
				var interruptInterval:int = int(_loaderParams.midRollInterrupt) || int(_loaderParams.interrupt) || 0;
				prepareLinearAd(_loaderParams.midRoll, true, interruptInterval);
			}
		}
		
		private function planPauseRoll(e:Event):void {
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			e.stopImmediatePropagation();
			e.preventDefault();
			prepareLinearAd(_loaderParams.pauseRoll);
		}
		
		private function planPostRoll(e:TimeEvent):void {
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			prepareLinearAd(_loaderParams.postRoll, false);
		}
		
		private function removePosterOnMediaPlayerStateChange(e:MediaPlayerStateChangeEvent):void {
			if (
				e.state == MediaPlayerState.PLAYING ||
				e.state == MediaPlayerState.PLAYBACK_ERROR
			) {
				// Make sure this event is processed only once:
				e.currentTarget.removeEventListener(e.type, arguments.callee);
				removePoster();
			}
		}
	}
}