/***********************************************************
 * Copyright 2010 Adobe Systems Incorporated.  All Rights Reserved.
 *
 * *********************************************************
 * The contents of this file are subject to the Berkeley Software Distribution (BSD) Licence
 * (the "License"); you may not use this file except in
 * compliance with the License.
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 *
 * The Initial Developer of the Original Code is Adobe Systems Incorporated.
 * Portions created by Adobe Systems Incorporated are Copyright (C) 2010 Adobe Systems
 * Incorporated. All Rights Reserved.
 **********************************************************/

package
{
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
import flash.net.SharedObject;
import flash.net.drm.DRMManager;
	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.utils.Timer;
    import flash.utils.Dictionary;

    import org.osmf.containers.MediaContainer;
	import org.osmf.elements.*;
	import org.osmf.events.*;
	import org.osmf.layout.*;
	import org.osmf.media.*;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.configuration.ConfigurationUtils;
	import org.osmf.player.chrome.events.WidgetEvent;
	import org.osmf.player.chrome.widgets.BufferingOverlay;
	import org.osmf.player.chrome.widgets.PlayButtonOverlay;
	import org.osmf.player.chrome.widgets.VideoInfoOverlay;
	import org.osmf.player.configuration.*;
	import org.osmf.player.containers.StrobeMediaContainer;
	import org.osmf.player.elements.*;
	import org.osmf.player.elements.playlistClasses.*;
	import org.osmf.player.errors.*;
	import org.osmf.player.media.*;
import org.osmf.player.metadata.MediaMetadata;
import org.osmf.player.plugins.PluginLoader;
	import org.osmf.player.utils.StrobeUtils;
	import org.osmf.traits.DVRTrait;
	import org.osmf.traits.LoadState;
	import org.osmf.traits.LoadTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayState;
	import org.osmf.traits.PlayTrait;
import org.osmf.traits.SeekTrait;
import org.osmf.utils.OSMFSettings;
	import org.osmf.utils.OSMFStrings;
	import org.osmf.vast.loader.VASTLoadTrait;
	import org.osmf.vast.loader.VASTLoader;
	import org.osmf.vast.media.CompanionElement;
	import org.osmf.vast.media.VASTMediaGenerator;

	CONFIG::LOGGING
	{
		import org.osmf.player.debug.DebugStrobeMediaPlayer;
		import org.osmf.player.debug.LogHandler;
		import org.osmf.player.debug.StrobeLoggerFactory;
		import org.osmf.player.debug.StrobeLogger;
		import org.osmf.logging.Log;
		import org.osmf.elements.LightweightVideoElement;
	}
	/**
	 * StrobeMediaPlayback is responsible for initializing a StrobeMediaPlayer and
	 * setting up the control bar behaviour and layout.
	 */
	[SWF(frameRate="25", backgroundColor="#000000")]
	public class MSPlayer extends Sprite
	{
		// These should be accessible from the preloader for the performance measurement to work.
		public var configuration:PlayerConfiguration;
		public var player:StrobeMediaPlayer;
		public var factory:StrobeMediaFactory;

		private var vastLoader:VASTLoader;
		private var vastLoadTrait:VASTLoadTrait;
//		private var vastMediaGenerator:VASTMediaGenerator;
//		private var playInMediaPlayer:MediaElement;

//		public static const VAST_1_LINEAR_FLV:String = "http://cdn1.eyewonder.com/200125/instream/osmf/vast_1_linear_flv.xml";

//		public static const chosenAdFile:String = VAST_1_LINEAR_FLV;
		public static const chosenPlacement:String = VASTMediaGenerator.PLACEMENT_LINEAR;
		public static const MAX_NUMBER_REDIRECTS:int = 5;

		public function MSPlayer()
		{
			super();

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

			CONFIG::LOGGING
			{
				// Setup the custom logging factory
				Log.loggerFactory = new StrobeLoggerFactory(new LogHandler(false));
				logger = Log.getLogger("StrobeMediaPlayback") as StrobeLogger;
			}
		}

		/**
		 * Initializes the player with the parameters and it's context (stage).
		 *
		 * We need the stage at this point because we need
		 * to setup the fullscreen event handlers in the initialization phase.
		 */
		public function initialize(parameters:Object, stage:Stage, loaderInfo:LoaderInfo, pluginHostWhitelist:Array):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

			// Keep a reference to the stage (when a preloader is used, the
			// local stage property is null at this time):
			if (stage != null)
			{
				_stage = stage;
			}

			// Keep a reference to the stage (when a preloader is used, the
			// local stage property is null at this time):
			if (loaderInfo != null)
			{
				_loaderInfo = loaderInfo;
			}


			this.pluginHostWhitelist = new Vector.<String>();
			if (pluginHostWhitelist)
			{
				for each(var pluginHost:String in pluginHostWhitelist)
				{
					this.pluginHostWhitelist.push(pluginHost);
				}

				// Add the current domain only if the pluginHostWhitelist != null
				// (since for null we want to disable the whitelist protection).
				var currentDomain:String = StrobeUtils.retrieveHostNameFromUrl(loaderInfo.loaderURL);
				this.pluginHostWhitelist.push(currentDomain);
			}

			CONFIG::FLASH_10_1
			{
    			//Register the global error handler.
				if (_loaderInfo != null && _loaderInfo.hasOwnProperty("uncaughtErrorEvents"))
				{
					_loaderInfo["uncaughtErrorEvents"].addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

				}
			}

			var assetManager:AssetsManager = new AssetsManager();

			injector = new InjectorModule();
			var configurationLoader:ConfigurationLoader = injector.getInstance(ConfigurationLoader);

			configurationLoader.addEventListener(Event.COMPLETE, onConfigurationReady);

			configuration = injector.getInstance(PlayerConfiguration);

			player = injector.getInstance(MediaPlayer);

			player.addEventListener(TimeEvent.COMPLETE, onComplete);
			player.addEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
//            player.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);


            // Add DRM error handler
			var drmManager:DRMManager = DRMManager.getDRMManager();
			drmManager.addEventListener(DRMErrorEvent.DRM_ERROR, onDRMError);

			// this is used for DVR rolling window
			// TODO: Add this event only when the resource is DVR rolling window not all the time
			player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChange);

            var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
            if (sharedObj.data.currentVolume) {
                player.volume = sharedObj.data.currentVolume;
            }
            if (sharedObj.data.mutedState) {
                player.muted = sharedObj.data.mutedState;
            }

//            var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
            player.addEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
            function onVolumeChange (event:AudioEvent = null):void {
//                var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
                sharedObj.data.currentVolume = event.volume;
            }
            player.addEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
            function onMutedChange (event:AudioEvent = null):void {
//                var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
                sharedObj.data.mutedState = event.muted;
            }

            player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChangeForSaveState);
            function onCurrentTimeChangeForSaveState(event:TimeEvent):void
            {
                sharedObj.data.currentTimePosition = event.time;
            }

            configurationLoader.load(parameters, configuration);

			function onConfigurationReady(event:Event):void
			{
				OSMFSettings.enableStageVideo = configuration.enableStageVideo;

				CONFIG::LOGGING
				{
					logger.trackObject("PlayerConfiguration", configuration);
				}

				if (configuration.skin != null && configuration.skin != "")
				{
					var skinLoader:XMLFileLoader = new XMLFileLoader();
					skinLoader.addEventListener(IOErrorEvent.IO_ERROR, onSkinLoaderFailure);
					skinLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSkinLoaderFailure);
					skinLoader.addEventListener(Event.COMPLETE, onSkinLoaderComplete);
					skinLoader.load(configuration.skin);
				}
				else
				{
					onSkinLoaderComplete();
				}
			}

			function onSkinLoaderComplete(event:Event = null):void
			{
				if (event != null)
				{
					var skinLoader:XMLFileLoader = event.target as XMLFileLoader;
					var skinParser:SkinParser = new SkinParser();
					skinParser.parse(skinLoader.xml, assetManager);
				}

				var chromeProvider:ChromeProvider = ChromeProvider.getInstance();
				chromeProvider.addEventListener(Event.COMPLETE, onChromeProviderComplete);
				if (chromeProvider.loaded == false && chromeProvider.loading == false)
				{
					chromeProvider.load(assetManager);
				}
				else
				{
					onChromeProviderComplete();
				}
			}

			function onSkinLoaderFailure(event:Event):void
			{
				trace("WARNING: failed to load skin file at " + configuration.skin);
				onSkinLoaderComplete();
			}

			if (configuration.javascriptCallbackFunction != "" && ExternalInterface.available && mediaPlayerJSBridge == null)
			{
				mediaPlayerJSBridge = new JavaScriptBridge(this, player, StrobeMediaPlayer, configuration.javascriptCallbackFunction);
			}
		}

		private function reportError(message:String):void
		{
			// If an alert widget is available, use it. Otherwise, trace the message:
			if (alert)
			{
				if (_media != null && mediaContainer.containsMediaElement(_media))
				{
					mediaContainer.removeMediaElement(_media);
				}
				if (controlBar != null && controlBarContainer.containsMediaElement(controlBar))
				{
					controlBarContainer.removeMediaElement(controlBar);
				}
				if (posterImage && mediaContainer.containsMediaElement(posterImage))
				{
					mediaContainer.removeMediaElement(posterImage);
				}
				if (playOverlay != null && mediaContainer.layoutRenderer.hasTarget(playOverlay))
				{
					mediaContainer.layoutRenderer.removeTarget(playOverlay);
				}
				if (bufferingOverlay != null && mediaContainer.layoutRenderer.hasTarget(bufferingOverlay))
				{
					mediaContainer.layoutRenderer.removeTarget(bufferingOverlay);
				}

				mediaContainer.addMediaElement(alert);
				alert.alert("Error", message);
			}
			else
			{
				trace("Error:", message);
			}
		}

		private function onDRMError(event:DRMErrorEvent):void
		{
			switch(event.errorID)
			{
				// Use the following link for the error codes
				// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/runtimeErrors.html
				case 3305:
				case 3328:
				case 3315:
					if (configuration.verbose)
					{
						reportError("Unable to connect to the authentication server. Error ID " + event.errorID);
					}
					else
					{
						reportError("We are unable to connect to the authentication server. We apologize for the inconvenience.");
					}
					break;

				default:
					if (configuration.verbose)
					{
						reportError("DRM Error " + event.errorID);
					}
					else
					{
						reportError("Unexpected DRM error");
					}
					break;
			}
		}

		// Internals
		//
		private function onChromeProviderComplete(event:Event = null):void
		{
			initializeView();

			// After initialization, either load the assigned media, or
			// load requested plug-ins first, and then load the assigned
			// media:
			var pluginConfigurations:Vector.<MediaResourceBase> = ConfigurationUtils.transformDynamicObjectToMediaResourceBases(configuration.plugins);
			var pluginResource:MediaResourceBase;

			CONFIG::LOGGING
			{
				var p:uint = 0;
				for each(pluginResource in pluginConfigurations)
				{
					logger.trackObject("PluginResource"+(p++), pluginResource);
				}
			}

			// EXPERIMENTAL: Ad plugin integration
			for each(pluginResource in pluginConfigurations)
			{
				pluginResource.addMetadataValue("MediaContainer", mediaContainer);
				pluginResource.addMetadataValue("MediaPlayer", player);
			}

			var pluginLoader:PluginLoader;
			factory = injector.getInstance(MediaFactory);
			pluginLoader = new PluginLoader(pluginConfigurations, factory, pluginHostWhitelist);
			pluginLoader.haltOnError = configuration.haltOnError;

//			pluginLoader.addEventListener(Event.COMPLETE, loadMediaWithAd);
			pluginLoader.addEventListener(Event.COMPLETE, loadMedia);
            pluginLoader.addEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
			pluginLoader.loadPlugins();
		}

		private function initializeView():void
		{
			// Set the SWF scale mode, and listen to the stage change
			// dimensions:
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			_stage.addEventListener(Event.RESIZE, onStageResize);
			_stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);

			mainContainer = new StrobeMediaContainer();
			mainContainer.backgroundColor = configuration.backgroundColor;
			mainContainer.backgroundAlpha = 0;
			mainContainer.addEventListener(MouseEvent.DOUBLE_CLICK, onFullScreenRequest);
			mainContainer.addEventListener(MouseEvent.CLICK, onMainClick, false);
			mainContainer.doubleClickEnabled = true;

			addChild(mainContainer);

			mediaContainer.clipChildren = true;
			mediaContainer.layoutMetadata.percentWidth = 100;
			mediaContainer.layoutMetadata.percentHeight = 100;
			mediaContainer.doubleClickEnabled = true;

			controlBarContainer = new MediaContainer();
			controlBarContainer.layoutMetadata.verticalAlign = VerticalAlign.TOP;
			controlBarContainer.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;

			// Setup play button overlay:
			if (configuration.playButtonOverlay == true) {
				playOverlay = new PlayButtonOverlay();
				playOverlay.configure(<default/>, ChromeProvider.getInstance().assetManager);
				playOverlay.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				playOverlay.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				playOverlay.layoutMetadata.index = PLAY_OVERLAY_INDEX;
				playOverlay.fadeSteps = OVERLAY_FADE_STEPS;
				mediaContainer.layoutRenderer.addTarget(playOverlay);
			}

			// Setup buffer overlay:
			if (configuration.bufferingOverlay == true) {
				bufferingOverlay = new BufferingOverlay();
				bufferingOverlay.configure(<default/>, ChromeProvider.getInstance().assetManager);
				bufferingOverlay.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				bufferingOverlay.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				bufferingOverlay.layoutMetadata.index = BUFFERING_OVERLAY_INDEX;
				bufferingOverlay.fadeSteps = OVERLAY_FADE_STEPS;
				mediaContainer.layoutRenderer.addTarget(bufferingOverlay);
			}

			// Setup alert dialog:
			alert = new AlertDialogElement();
			alert.tintColor = configuration.tintColor;

			// Setup authentication dialog:
			loginWindow = new AuthenticationDialogElement();
			loginWindow.tintColor = configuration.tintColor;

			loginWindowContainer = new MediaContainer();
			loginWindowContainer.layoutMetadata.index = ALWAYS_ON_TOP;
			loginWindowContainer.layoutMetadata.percentWidth = 100;
			loginWindowContainer.layoutMetadata.percentHeight = 100;
			loginWindowContainer.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			loginWindowContainer.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;

			loginWindowContainer.addMediaElement(loginWindow);

			if (configuration.controlBarMode == ControlBarMode.NONE)
			{
				mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
			}
			else
			{
				// Setup control bar:
				controlBar = new ControlBarElement(configuration.controlBarType);
				controlBar.autoHide = configuration.controlBarAutoHide;
				controlBar.autoHideTimeout = configuration.controlBarAutoHideTimeout * 1000;
				controlBar.tintColor = configuration.tintColor;
				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					// The player starts in thumb mode for smartphones
					controlBar.autoHide = false;
					controlBar.autoHideTimeout = -1;
					controlBar.visible = false;
				}

				if (configuration.controlBarType == ControlBarType.TABLET) {
					// On tablet mode the control bar is visible
					controlBar.autoHide = false;
				}

				player.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onSetAutoHide);

				layout();

				controlBarContainer.layoutMetadata.height = controlBar.height;
                controlBarContainer.addMediaElement(controlBar);

				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN, onFitToScreenRequest);
					controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN_FORCE_FIT, onFitToScreenRequest);
				}
				else {
					controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN, onFullScreenRequest);
				}

				mainContainer.layoutRenderer.addTarget(controlBarContainer);
//                controlBarContainer.visible = false;
				mediaContainer.layoutRenderer.addTarget(loginWindowContainer);
            }

			mainContainer.layoutRenderer.addTarget(mediaContainer);

			qosOverlay = new VideoInfoOverlay();
			qosOverlay.register(controlBarContainer, mainContainer, player);
			qosOverlay.addEventListener(WidgetEvent.VIDEO_INFO_OVERLAY_CLOSE,
				function (event:WidgetEvent):void
				{
					dispatchEvent(event);
				}
			);
			if (configuration.showVideoInfoOverlayOnStartUp)
			{
				qosOverlay.showInfo();
			}

			// update the dimensions of the container
			onStageResize();
		}

//		public function loadMediaWithAd(..._):void
//		{
//			// Try to load the URL set on the configuration:
//			var resource:MediaResourceBase  = injector.getInstance(MediaResourceBase);
//
//			CONFIG::LOGGING
//			{
//				logger.trackObject("AssetResource", resource);
//			}
//
//			// Loading ad
//			var adFile:String = loaderInfo.parameters.preRoll;
//			var vastResource:URLResource = new URLResource(adFile);
//			vastLoader = new VASTLoader(MAX_NUMBER_REDIRECTS);
//			vastLoadTrait = new VASTLoadTrait(vastLoader, vastResource);
//			vastLoader.addEventListener(LoaderEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);
//			vastLoader.load(vastLoadTrait);
//
//			function onVASTLoadStateChange(event:LoaderEvent):void
//			{
//				if (event.newState == LoadState.READY)
//				{
//					vastLoadTrait.removeEventListener(LoadEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);
//
//					var generator:VASTMediaGenerator = new VASTMediaGenerator();
//					var mediaElements:Vector.<MediaElement> =
//						generator.createMediaElements(vastLoadTrait.vastDocument);
//
//					var serialElement:SerialElement = new SerialElement();
//
//					adElement = mediaElements[0];
//					if (adElement != null)
//					{
//						serialElement.addChild(adElement);
//					}
//
//					serialElement.addChild(factory.createMediaElement(resource));
//					serialElement.addEventListener(SerialElementEvent.CURRENT_CHILD_CHANGE, onSerialElementChildChange)
////					player.addEventListener(SerialElementEvent.CURRENT_CHILD_CHANGE, onSerialElementChildChange);
//
//					trace("ControlBarElement: before set scrubBarAndPlaybackButtonsVisible");
////					media = factory.createMediaElement(resource);
//                    //controlBar.scrubBarAndPlaybackButtonsVisible = false;
//					media = serialElement;
//                    if (_media == null)
//					{
//						var mediaError:MediaError
//						= new MediaError
//							( MediaErrorCodes.MEDIA_LOAD_FAILED
//								, OSMFStrings.CAPABILITY_NOT_SUPPORTED
//							);
//
//						player.dispatchEvent
//							( new MediaErrorEvent
//								( MediaErrorEvent.MEDIA_ERROR
//									, false
//									, false
//									, mediaError
//								)
//							);
//					}
//
//				}
//			}
//
//
//
////			media = factory.createMediaElement(resource);
//		}

//		public function onSerialElementChildChange(event:SerialElementEvent):void {
//            //controlBar.scrubBarAndPlaybackButtonsVisible = true;
//            trace("serial element change");
//		}

        public function displayPreRollAdAndPlayMedia(adMediaElement:MediaElement, mediaElement:MediaElement):void {
	        var adMediaPlayer:StrobeMediaPlayer = new StrobeMediaPlayer();
	        adMediaPlayer.media = adMediaElement;
            adMediaPlayer.volume = player.volume;
            adMediaPlayer.muted = player.muted;
            adMediaPlayer.addEventListener(TimeEvent.COMPLETE, onAdComplete);

            mediaContainer.addMediaElement(adMediaElement);
            adMediaElement.metadata.addValue("Advertisement", "Advertisement");

            displayNonLinearAd();

            var mediaMetadata:MediaMetadata = new MediaMetadata();
            mediaMetadata.mediaPlayer = adMediaPlayer;
            adMediaElement.metadata.addValue(MediaMetadata.ID, mediaMetadata);

            if (controlBar != null)
            {
                controlBar.target = adMediaElement;
            }
            adMediaPlayer.play();

            adMediaPlayer.addEventListener(AudioEvent.VOLUME_CHANGE, onVolumeChange);
            function onVolumeChange (event:AudioEvent = null):void {
                var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
                sharedObj.data.currentVolume = event.volume;
            }

            adMediaPlayer.addEventListener(AudioEvent.MUTED_CHANGE, onMutedChange);
            function onMutedChange (event:AudioEvent = null):void {
                var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
                sharedObj.data.mutedState = event.muted;
            }



            function onAdComplete(event:Event):void
            {
                var adMediaPlayer:StrobeMediaPlayer = event.target as StrobeMediaPlayer;
                adMediaPlayer.removeEventListener(TimeEvent.COMPLETE, onAdComplete);

                // Romove the ad from the media container
                mediaContainer.removeMediaElement(adMediaPlayer.media);
                adMediaPlayer.media.metadata.removeValue("Advertisement");
                media = mediaElement;
            }
        }


		/**
		 * Loads the media or displays an error message on fail.
		 */
		public function loadMedia(..._):void
		{
			trace("Load media");

			// Try to load the URL set on the configuration:
			var resource:MediaResourceBase  = injector.getInstance(MediaResourceBase);
            var mediaElement:MediaElement = factory.createMediaElement(resource);

            CONFIG::LOGGING
			{
				logger.trackObject("AssetResource", resource);
			}

            if (loaderInfo.parameters.preRoll) {
                var vastResource:URLResource = new URLResource(loaderInfo.parameters.preRoll);
                vastLoader = new VASTLoader(MAX_NUMBER_REDIRECTS);
                vastLoadTrait = new VASTLoadTrait(vastLoader, vastResource);
                vastLoader.addEventListener(LoaderEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);
                vastLoader.load(vastLoadTrait);

                function onVASTLoadStateChange(event:LoaderEvent):void
                {
                    if (event.newState == LoadState.READY)
                    {
                        vastLoadTrait.removeEventListener(LoadEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);

                        var generator:VASTMediaGenerator = new VASTMediaGenerator();
                        var mediaElements:Vector.<MediaElement> =
                                generator.createMediaElements(vastLoadTrait.vastDocument);

                        displayPreRollAdAndPlayMedia(mediaElements[0], mediaElement);
                    }
                }
            }
            else {
                media = mediaElement;
            }

            player.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferingChange);
            function onBufferingChange(event:BufferEvent):void
            {
                if (event.buffering == false)
                {
                    var currentSrc:String  = loaderInfo.parameters.src;
                    var sharedObj:SharedObject = SharedObject.getLocal("MSPlayer");
                    if (sharedObj.data.src && sharedObj.data.src == currentSrc) {
                        if (sharedObj.data.currentTimePosition && player.canSeek) {
                            player.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferingChange);
                            player.seek(sharedObj.data.currentTimePosition);
                        }
                    }
                    else {
                        sharedObj.data.src = currentSrc;
                    }

                }
            }


            // По идее нужно вынести отсюда и запускать только после того, как проинициализирован
            // основной media
            if (loaderInfo.parameters.streamType != "live" && loaderInfo.parameters.midRoll
                    && loaderInfo.parameters.midRollTime) {
                player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onMidrollCurrentTimeChange);


                function onMidrollCurrentTimeChange(event:TimeEvent):void {
                    if (player.currentTime > parseInt(loaderInfo.parameters.midRollTime))
                    {
                        player.removeEventListener(TimeEvent.CURRENT_TIME_CHANGE, onMidrollCurrentTimeChange);
                        displayLinearAd(loaderInfo.parameters.midRoll);
                    }
                }
            }

            if (loaderInfo.parameters.streamType != "live" && loaderInfo.parameters.pauseRoll) {


                controlBar.addEventListener("playButtonClick", onPlayButtonClick);
                function onPlayButtonClick(evt:Event):void {
                    controlBar.removeEventListener("playButtonClick", onPlayButtonClick);
                    displayLinearAd(loaderInfo.parameters.pauseRoll);
                }
            }

            if (loaderInfo.parameters.streamType == "recorded" && loaderInfo.parameters.postRoll) {
                player.addEventListener(TimeEvent.COMPLETE, onMediaComplete);
                function onMediaComplete(evt:Event):void {
                    player.removeEventListener(TimeEvent.COMPLETE, onMediaComplete);
                    displayLinearAd(loaderInfo.parameters.postRoll, false);
                }
            }

        }

		private function processNewMedia(value:MediaElement):MediaElement
		{
			trace("processNewMedia");

			var processedMedia:MediaElement;

			if (value != null)
			{
				processedMedia = value;
				var layoutMetadata:LayoutMetadata = processedMedia.metadata.getValue(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata;
				if (layoutMetadata == null)
				{
					layoutMetadata = new LayoutMetadata();
					processedMedia.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
				}

				layoutMetadata.scaleMode = configuration.scaleMode;
				layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				layoutMetadata.percentWidth = 100;
				layoutMetadata.percentHeight = 100;
				layoutMetadata.index = 1;
				if 	(	configuration
					&&	configuration.poster != null
					&&	configuration.poster != ""
					&&	player.autoPlay == false
					&&	player.playing == false
				)
				{
					if (configuration.endOfVideoOverlay == "")
					{
						configuration.endOfVideoOverlay = configuration.poster;
					}
					processPoster(configuration.poster);
				}
				processedMedia.metadata.addValue(MEDIA_PLAYER, player);
			}

			return processedMedia;
		}

		private function layout():void
		{
			controlBarContainer.layoutMetadata.index = ON_TOP;

			if (configuration.controlBarType == ControlBarType.DESKTOP)
			{
				if	(
					controlBar.autoHide == false &&
					configuration.controlBarMode == ControlBarMode.DOCKED
				)
				{
					// Use a vertical layout:
					mainContainer.layoutMetadata.layoutMode = LayoutMode.VERTICAL;
					mediaContainer.layoutMetadata.index = 1;
				}
				else
				{
					mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
					switch(configuration.controlBarMode)
					{
						case ControlBarMode.FLOATING:
							controlBarContainer.layoutMetadata.bottom = POSITION_OVER_OFFSET;
							break;
						case ControlBarMode.DOCKED:
							controlBarContainer.layoutMetadata.bottom = 0;
							break;
					}
				}
			}
			else
			{
				if (configuration.controlBarType == ControlBarType.TABLET)
				{
					configuration.controlBarMode = ControlBarMode.DOCKED;
					mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
					controlBarContainer.layoutMetadata.bottom = 0;
				}
				else if (configuration.controlBarType == ControlBarType.SMARTPHONE)
				{
					configuration.controlBarMode = ControlBarMode.FLOATING;
					mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
					controlBarContainer.layoutMetadata.bottom = POSITION_OVER_OFFSET;
				}
			}
		}

    private function displayAd(adMediaElement:MediaElement,
                               //url:String,
                               pauseMainMediaWhilePlayingAd:Boolean = true,
                               resumePlaybackAfterAd:Boolean = true,
                               preBufferAd:Boolean = true,
                               layoutInfo:Object = null):void
    {
        // Set up the ad
//        var adMediaElement:MediaElement = factory.createMediaElement(new URLResource(url));

        // Set the layout metadata, if present
        if (layoutInfo != null)
        {
            var layoutMetadata:LayoutMetadata = new LayoutMetadata();
            for (var key:String in layoutInfo)
            {
                layoutMetadata[key] = layoutInfo[key];
            }

            if (!layoutInfo.hasOwnProperty("index"))
            {
                // Make sure we add the last ad on top of any others
                layoutMetadata.index = adPlayerCount + 100;
            }

            adMediaElement.metadata.addValue(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
        }

        var adMediaPlayer:StrobeMediaPlayer =  new StrobeMediaPlayer();
        adMediaPlayer.media = adMediaElement;

        // Save the reference to the ad player, so that we can adjust the volume/mute of all the ads
        // whenever the volume or mute values change in the video player.
        adPlayers[adMediaPlayer] = true;
        adPlayerCount++;

        adMediaPlayer.addEventListener(TimeEvent.COMPLETE, onAdComplete);

        if (!preBufferAd)
        {
            // Wait until the ad fills the buffer and is ready to be played.
            adMediaPlayer.muted = true;
            adMediaPlayer.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferingChange);
            function onBufferingChange(event:BufferEvent):void
            {
                if (event.buffering == false)
                {
                    adMediaPlayer.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferingChange);
                    playAd();
                }
            }
        }
        else
        {
            playAd();
        }

        function playAd():void
        {
//            controlBar.scrubBarAndPlaybackButtonsVisible = false;

            // Copy the player's current volume values
            adMediaPlayer.volume = player.volume;
            adMediaPlayer.muted = player.muted;

            adMediaPlayer.media.metadata.addValue("Advertisement", "1");

            if (pauseMainMediaWhilePlayingAd)
            {
                // Indicates to the player that we currently are playing an ad,
                // so the player can adjust its UI.
                // FIXME: Скорее всего комментировать не нужно.
                //player.media.metadata.addValue("Advertisement", url);

                // TODO: We assume that playback pauses immediately,
                // but this is not the case for all types of content.
                // The linear ads should be inserted only after the player state becomes 'paused'.
                player.pause();

                // If we are playing a linear ad, we need to remove it from the media container.
                if (mediaContainer.containsMediaElement(player.media))
                {
                    mediaContainer.removeMediaElement(player.media);
                }
                else
                {
                    // Wait until the media gets added to the container, so that we can remove it
                    // immediately afterwards.
                    player.media.addEventListener(ContainerChangeEvent.CONTAINER_CHANGE, onContainerChange);
                    function onContainerChange(event:ContainerChangeEvent):void
                    {
                        if (mediaContainer.containsMediaElement(player.media))
                        {
                            player.media.removeEventListener(ContainerChangeEvent.CONTAINER_CHANGE, onContainerChange);
                            mediaContainer.removeMediaElement(player.media);
                        }
                    }
                }
            }


            var mediaMetadata:MediaMetadata = new MediaMetadata();
            mediaMetadata.mediaPlayer = adMediaPlayer;
            adMediaElement.metadata.addValue(MediaMetadata.ID, mediaMetadata);

            if (controlBar != null)
            {
                controlBar.target = adMediaElement;
            }

            // Add the ad to the container
            mediaContainer.addMediaElement(adMediaElement);
            adMediaPlayer.play();
        }


        function onAdComplete(event:Event):void
        {
            var adMediaPlayer:StrobeMediaPlayer = event.target as StrobeMediaPlayer;
            adMediaPlayer.removeEventListener(TimeEvent.COMPLETE, onAdComplete);
            adMediaPlayer.media.metadata.removeValue("Advertisement");

            // Romove the ad from the media container
            mediaContainer.removeMediaElement(adMediaPlayer.media);

            // Remove the saved references
            adPlayerCount--;
            delete adPlayers[adMediaPlayer];

            if (pauseMainMediaWhilePlayingAd)
            {
                // Remove the metadata that indicates that we are playing a linear ad.

                // Add the main video back to the container.
                mediaContainer.addMediaElement(player.media);
            }

            if (pauseMainMediaWhilePlayingAd && resumePlaybackAfterAd)
            {

                // WORKAROUND: http://bugs.adobe.com/jira/browse/ST-397 - GPU Decoding issue on stagevideo: Win7, Flash Player version WIN 10,2,152,26 (debug)
// Возможно закоментировано зря.
//                if (seekWorkaround && player.canSeek)
//                {
//                    player.seek(player.currentTime);
//                }

                // Resume playback
//                controlBar.scrubBarAndPlaybackButtonsVisible = true;
                player.play();
                if (controlBar != null)
                {
                    controlBar.target = player.media;
                }
            }
        }
    }

    /**
     * Displays a linear advertisement.
     *
     * The method does not check if an ad is currently being played or not.
     * This is up to the caller to check.
     *
     * The ad will use the same layout as the main media.
     *
     * @param url - the path to the ad media to be displayed.
     * @resumePlaybackAfterAd - indicates if the playback of the main media should resume after the playback of the ad.
     */
    public function displayLinearAd(adFile:String, resumePlaybackAfterAd:Boolean = true):void
    {
        var vastResource:URLResource = new URLResource(adFile);
        vastLoader = new VASTLoader(MAX_NUMBER_REDIRECTS);
        vastLoadTrait = new VASTLoadTrait(vastLoader, vastResource);
        vastLoader.addEventListener(LoaderEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);
        vastLoader.load(vastLoadTrait);

        function onVASTLoadStateChange(event:LoaderEvent):void
        {
            if (event.newState == LoadState.READY)
            {
                vastLoadTrait.removeEventListener(LoadEvent.LOAD_STATE_CHANGE, onVASTLoadStateChange);

                var generator:VASTMediaGenerator = new VASTMediaGenerator();
                var mediaElements:Vector.<MediaElement> =
                        generator.createMediaElements(vastLoadTrait.vastDocument);

                displayAd(mediaElements[0], true, resumePlaybackAfterAd, true, null);
            }
        }
    }

//    public function displayNonLinearAd(url:String, layoutInfo:Object):void
    public function displayNonLinearAd():void
    {
        var overlayMetadata:Object = {
            right: 10,
            bottom: 10,
            width: 200,
            height: 140,
            scaleMode: ScaleMode.STRETCH
        };

        var overlayUrl:String = "http://gcdn.2mdn.net/MotifFiles/html/1379578/PID_938961_1237818260000_women.flv";
        var adMediaElement:MediaElement = factory.createMediaElement(new URLResource(overlayUrl));

        displayAd(adMediaElement, false, false, true, overlayMetadata);
    }



    private function set media(value:MediaElement):void
		{
			if (alert && mediaContainer.containsMediaElement(alert))
			{
				mediaContainer.removeMediaElement(alert);
				initializeView();
			}

			if (value != _media)
			{
				// Remove the current media from the container:
				if (_media)
				{
					mediaContainer.removeMediaElement(_media);
				}

				var processedNewValue:MediaElement = processNewMedia(value);
				if (processedNewValue)
				{
					value = processedNewValue;
				}

				// Set the new main media element:
				_media = player.media = value;




                if (_media)
				{
					// Add the media to the media container:
//					var vastElements:Vector.<MediaElement> = vastMediaGenerator.createMediaElements(vastLoadTrait.vastDocument, chosenPlacement);
					//
					//
//					for each(var mediaElement:MediaElement in vastElements) {
//						mediaContainer.addMediaElement(mediaElement);
//					}
					mediaContainer.addMediaElement(_media);

                    // Forward a reference to controlBar:
					if (controlBar != null)
					{
						controlBar.target = _media;
					}
                    //controlBar.scrubBarAndPlaybackButtonsVisible = false;

                    // Forward a reference to the play overlay:
					if (playOverlay != null)
					{
						playOverlay.media = _media;
					}

					// Forward a reference to the buffering overlay:
					if (bufferingOverlay != null)
					{
						bufferingOverlay.media = _media;
					}

					// Forward a reference to login window:
					if (loginWindow != null)
					{
						loginWindow.target = _media;
					}
                }
				else
				{
					if (playOverlay != null)
					{
						playOverlay.media = null;
					}

					if (bufferingOverlay != null)
					{
						bufferingOverlay.media = null;
					}
				}
			}
		}

		private function processPoster(posterUrl:String):void
		{
			// Show a poster if there's one set, and the content is not yet playing back:
			try
			{
				if (posterImage)
				{
					removePoster();
				}

				posterImage = new ImageElement(new URLResource(posterUrl), new ImageLoader(false));

				// Setup the poster image:
				//posterImage.smoothing = true;
				var layoutMetadata:LayoutMetadata = new LayoutMetadata();
				layoutMetadata.scaleMode = (configuration.posterScaleMode ? configuration.posterScaleMode : configuration.scaleMode);
				layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				layoutMetadata.percentWidth = 100;
				layoutMetadata.percentHeight = 100;
				layoutMetadata.index = POSTER_INDEX;
				posterImage.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
				LoadTrait(posterImage.getTrait(MediaTraitType.LOAD)).load();
				mediaContainer.addMediaElement(posterImage);

				// Listen for the main content player to reach a playing, or playback error
				// state. At that time, we remove the poster:
				player.addEventListener
					( MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE
					, onMediaPlayerStateChange
					);

				function onMediaPlayerStateChange(event:MediaPlayerStateChangeEvent):void
				{
					if	(	event.state == MediaPlayerState.PLAYING
						||	event.state == MediaPlayerState.PLAYBACK_ERROR
						)
					{
						// Make sure this event is processed only once:
						player.removeEventListener(event.type, arguments.callee);

						removePoster();
					}
				}
			}
			catch (error:Error)
			{
				// Fail poster loading silently:
				trace("WARNING: poster image failed to load at", configuration.poster);
			}
		}

		public function removePoster():void
		{
			// Remove the poster image:
			if (posterImage != null)
			{
				mediaContainer.removeMediaElement(posterImage);
				LoadTrait(posterImage.getTrait(MediaTraitType.LOAD)).unload();
			}
			posterImage = null;
		}

		public function setSize(w:Number, h:Number):void
		{
			strobeWidth = w;
			strobeHeight = h;
			onStageResize();
		}

		public function showVideoInfo(value:Boolean):void
		{
			if (qosOverlay)
			{
				if (value)
				{
					qosOverlay.showInfo();
				}
				else
				{
					qosOverlay.hideInfo();
				}
			}
		}

		// Handlers
		//

		private function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			initialize(loaderInfo.parameters, stage, loaderInfo, null);
		}

		private function onMainClick(event:MouseEvent):void
		{
			if (_stage.displayState == StageDisplayState.NORMAL)
			{
				if (configuration.controlBarType == ControlBarType.SMARTPHONE)
				{
					onFullScreenRequest();
				}
				if (configuration.controlBarType == ControlBarType.TABLET &&
					(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).playState != PlayState.PLAYING
				) {
					controlBar.visible = !controlBar.visible;
				}
			}
			else {
				if ((player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).playState != PlayState.PLAYING)
				{
					controlBar.visible = !controlBar.visible;
				}
				event.stopImmediatePropagation();
			}
		}

		/**
		 * Toggles full screen state.
		 */
		private function onFullScreenRequest(event:Event=null):void
		{
			if (_stage.displayState == StageDisplayState.NORMAL)
			{
				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo)
					|| configuration.removeContentFromStageOnFullScreenWithStageVideo)
				{
					removeChild(mainContainer);
				}

				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo)
					|| configuration.useFullScreenSourceRectOnFullScreenWithStageVideo)
				{
					_stage.fullScreenSourceRect = player.getFullScreenSourceRect(_stage.fullScreenWidth, _stage.fullScreenHeight);
				}

				CONFIG::LOGGING
				{
					if (_stage.fullScreenSourceRect != null)
					{
						logger.info("Setting fullScreenSourceRect = {0}", _stage.fullScreenSourceRect.toString());
					}
					else
					{
						logger.info("fullScreenSourceRect not set.");
					}
					if (_stage.fullScreenSourceRect !=null)
					{
						logger.qos.rendering.fullScreenSourceRect =
							_stage.fullScreenSourceRect.toString();
						logger.qos.rendering.fullScreenSourceRectAspectRatio = _stage.fullScreenSourceRect.width / _stage.fullScreenSourceRect.height;
					}
					else
					{
						logger.qos.rendering.fullScreenSourceRect =	"";
						logger.qos.rendering.fullScreenSourceRectAspectRatio = NaN;
					}
					logger.qos.rendering.screenWidth = _stage.fullScreenWidth;
					logger.qos.rendering.screenHeight = _stage.fullScreenHeight;
					logger.qos.rendering.screenAspectRatio = logger.qos.rendering.screenWidth  / logger.qos.rendering.screenHeight;
				}

				try
				{
					_stage.displayState = StageDisplayState.FULL_SCREEN;
				}
				catch (error:SecurityError)
				{
					CONFIG::LOGGING
					{
						logger.info("Failed to go to FullScreen. Check if allowfullscreen is set to false in HTML page.");
					}
					// This exception is thrown when the allowfullscreen is set to false in HTML
					addChild(mainContainer);
					mainContainer.validateNow();
				}
			}
			else
			{
				_stage.displayState = StageDisplayState.NORMAL;
			}
		}

		private function onFitToScreenRequest(event:Event):void
		{
			if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
				if (event.type == WidgetEvent.REQUEST_FULL_SCREEN_FORCE_FIT) {
					if (player.media != null) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.ZOOM;
					}
					if (posterImage != null) {
						(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.ZOOM;
					}
				}
				else if (event.type == WidgetEvent.REQUEST_FULL_SCREEN)
				{
					if (player.media != null) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
					if (posterImage != null) {
						(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
				}
			}
		}

		/**
		 * FullScreen state changed handler.
		 */
		private function onFullScreen(event:FullScreenEvent=null):void
		{
			if (_stage.displayState == StageDisplayState.NORMAL)
			{
				if (controlBar)
				{
					// Set the autoHide property to the value set by the user.
					// If the autoHide property changed we need to adjust the layout settings
					if (
						configuration.controlBarType == ControlBarType.DESKTOP &&
						controlBar.autoHide!=configuration.controlBarAutoHide
					)
					{
						controlBar.autoHide = configuration.controlBarAutoHide;
						layout();
					}

					// getting back to thumb mode
					if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
						(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).stop();
						controlBar.autoHide = false;
						controlBar.autoHideTimeout = -1;
						controlBar.visible = false;
					}

					if (configuration.controlBarType == ControlBarType.TABLET) {
						controlBar.autoHide = false;
					}
				}
				Mouse.show();

				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					if (player.media != null) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
					if (posterImage != null) {
						(posterImage.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
				}
			}
			else if (_stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				if (controlBar)
				{
					if (configuration.controlBarType == ControlBarType.DESKTOP) {
						// We force the autohide of the controlBar in fullscreen
						controlBarWidth = controlBar.width;
						controlBarHeight = controlBar.height;

						controlBar.autoHideTimeout = configuration.controlBarAutoHideTimeout * 1000;
						controlBar.autoHide = true;

						// If the autoHide property changed we need to adjust the layout settings
						if (controlBar.autoHide!=configuration.controlBarAutoHide)
						{
							layout();
						}
					}

					if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
						// In tabled mode we show the control bar when switching from thumb mode to full screen
						controlBar.autoHideTimeout = configuration.controlBarAutoHideTimeout * 1000;
						controlBar.visible = true;
					}
				}

				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo)
					|| configuration.removeContentFromStageOnFullScreenWithStageVideo)
				{
					addChild(mainContainer);
				}

				mainContainer.validateNow();
			}
		}

		private function onSetAutoHide(event:PlayEvent):void {
			if (controlBar) {
				if (configuration.controlBarType != ControlBarType.DESKTOP) {
					if (event.playState != PlayState.PLAYING) {
						// Set the control bar back to auto hide
						controlBar.autoHide = false;
					}
					else {
						// Set the control bar back to auto hide
						controlBar.autoHide = true;
					}
				}
			}
		}

		private function onStageResize(event:Event = null):void
		{
			// Propagate dimensions to the main container:
			var newWidth:Number = isNaN(strobeWidth) ? _stage.stageWidth : strobeWidth;
			var newHeigth:Number = isNaN(strobeHeight) ? _stage.stageHeight : strobeHeight;

			if (mainContainer != null) {
				mainContainer.width = newWidth;
				mainContainer.height = newHeigth;
			}

			// Propagate dimensions to the control bar:
			if (controlBar != null)
			{
				if	(	configuration.controlBarMode != ControlBarMode.FLOATING
					||	controlBar.width > newWidth
					||	newWidth < MAX_OVER_WIDTH
					)
				{
					controlBar.width = newWidth;
				}
				else if (configuration.controlBarMode == ControlBarMode.FLOATING)
				{
					switch(configuration.controlBarType){
						case ControlBarType.SMARTPHONE:
							controlBar.width = MAX_OVER_WIDTH_SMARTPHONE;
						break;
						case ControlBarType.TABLET:
							controlBar.width = MAX_OVER_WIDTH_TABLET;
						break;
						default:
							controlBar.width = MAX_OVER_WIDTH;
						break;
					}
				}
			}
		}
		CONFIG::FLASH_10_1
		{
			private function onUncaughtError(event:UncaughtErrorEvent):void
			{
				event.preventDefault();
				var timer:Timer = new Timer(3000, 1);
				var mediaError:MediaError
					= new MediaError(StrobePlayerErrorCodes.UNKNOWN_ERROR
						, event.error.name + " - " + event.error.message);

				timer.addEventListener
					( 	TimerEvent.TIMER
					,	function(event:Event):void
						{
							onMediaError
								( new MediaErrorEvent
									( MediaErrorEvent.MEDIA_ERROR
									, false
									, false
									, mediaError
									)
								);
						}
				);
				timer.start();
			}
		}

		private function onCurrentTimeChange(event:TimeEvent):void
		{
			if  (	player.state == MediaPlayerState.BUFFERING
				||	player.state == MediaPlayerState.PLAYING
				||	player.state == MediaPlayerState.PAUSED
			) // If the player is in a relevant state
			{
				var dvrTrait:DVRTrait = player.media.getTrait(MediaTraitType.DVR) as DVRTrait;
				if  (	dvrTrait != null
					&&	dvrTrait.windowDuration != -1
				) // If rolling window is present
				{
					if (event.time < DEFAULT_FRAGMENT_SIZE) // If we're too close to the left-most side of the rolling window
					{
						// Seek to a safe area
						player.seek(DEFAULT_SEGMENT_SIZE);
					}
				}
			}
		}

		private function onComplete(event:TimeEvent):void
		{
			if 	(	configuration
				&&	configuration.endOfVideoOverlay != null
				&&	configuration.endOfVideoOverlay != ""
				&&	player.loop == false
				&&	player.playing == false
			)
			{
				processPoster(configuration.endOfVideoOverlay);
			}
		}

		private function onMediaError(event:MediaErrorEvent):void
		{
			// Make sure this event gets handled only once:
			player.removeEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);

			// Reset the current media:
			player.media = null;
			media = null;

			// Translate error message:
			var message:String;
			if (configuration.verbose)
			{
				message = event.error.message + "\n" + event.error.detail;
			}
			else
			{
				message = ErrorTranslator.translate(event.error).message;
			}

			CONFIG::FLASH_10_1
			{
				var tokens:Array = Capabilities.version.split(/[\s,]/);
				var flashPlayerMajorVersion:int = parseInt(tokens[1]);
				var flashPlayerMinorVersion:int = parseInt(tokens[2]);
				if (flashPlayerMajorVersion < 10 || (flashPlayerMajorVersion  == 10 && flashPlayerMinorVersion < 1))
				{
					if (configuration.verbose)
					{
						message += "\n\nThe content that you are trying to play requires the latest Flash Player version.\nPlease upgrade and try again.";
					}
					else
					{
						message = "The content that you are trying to play requires the latest Flash Player version.\nPlease upgrade and try again.";
					}
				}
			}

			reportError(message);

			// Forward the raw error message to JavaScript:
			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call
						( EXTERNAL_INTERFACE_ERROR_CALL
							, ExternalInterface.objectID
							, event.error.errorID, event.error.message, event.error.detail
						);

					//JavaScriptBridge.call(["org.strobemediaplayback.triggerHandler", ExternalInterface.objectID, "error", {}]);
					JavaScriptBridge.error(event);
				}
				catch(_:Error)
				{
					trace(_.toString());
				}
			}
		}

		private var _stage:Stage;
		private var _loaderInfo:LoaderInfo;

		private var injector:InjectorModule;
		private var pluginHostWhitelist:Vector.<String>;

		private var mediaPlayerJSBridge:JavaScriptBridge = null;
		private var mainContainer:StrobeMediaContainer;
		private var mediaContainer:MediaContainer = new MediaContainer();
		private var controlBarContainer:MediaContainer;
		private var loginWindowContainer:MediaContainer;
		private var _media:MediaElement;

		private var volumeBar:VolumeBarElement;
		private var controlBar:ControlBarElement;
		private var alert:AlertDialogElement;
		private var loginWindow:AuthenticationDialogElement;
		private var posterImage:ImageElement;
		private var playOverlay:PlayButtonOverlay;
		private var bufferingOverlay:BufferingOverlay;

		private var controlBarWidth:Number;
		private var controlBarHeight:Number;

		private var strobeWidth:Number;
		private var strobeHeight:Number;

		private var qosOverlay:VideoInfoOverlay;

		/* static */
		private static const ALWAYS_ON_TOP:int = 9999;
		private static const ON_TOP:int = 9998;
		private static const POSITION_OVER_OFFSET:int = 20;
		private static const MAX_OVER_WIDTH:int = 400;
		private static const MAX_OVER_WIDTH_SMARTPHONE:int = 550;
		private static const MAX_OVER_WIDTH_TABLET:int = 600;
		private static const POSTER_INDEX:int = 2;
		private static const PLAY_OVERLAY_INDEX:int = 3;
		private static const BUFFERING_OVERLAY_INDEX:int = 4;
		private static const OVERLAY_FADE_STEPS:int = 6;
		private static const MEDIA_PLAYER:String = "org.osmf.media.MediaPlayer";

		// used for DVR rolling window
		private static const DEFAULT_FRAGMENT_SIZE:Number = 4;
		private static const DEFAULT_SEGMENT_SIZE:Number = 16;


        private var adPlayerCount:int = 0;

//        var adElement:MediaElement = null;

        // Weak references for the currently playing ads
        private var adPlayers:Dictionary = new Dictionary(true);

        private static const EXTERNAL_INTERFACE_ERROR_CALL:String
		 	= "function(playerId, code, message, detail)"
			+ "{"
			+ "	if (onMediaPlaybackError != null)"
			+ "		onMediaPlaybackError(playerId, code, message, detail);"
			+ "}";


		CONFIG::LOGGING
		{
			protected var logger:StrobeLogger = Log.getLogger("StrobeMediaPlayback") as StrobeLogger;
		}
	}
}
