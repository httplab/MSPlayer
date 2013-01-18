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
package {
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.drm.DRMManager;
	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import io.ratchet.notifier.Ratchet;
	import org.osmf.elements.*;
	import org.osmf.events.*;
	import org.osmf.layout.*;
	import org.osmf.logging.Log;
	import org.osmf.media.*;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.configuration.ConfigurationUtils;
	import org.osmf.player.chrome.events.WidgetEvent;
	import org.osmf.player.chrome.widgets.ChannelListButton;
	import org.osmf.player.chrome.widgets.QualitySwitcherContainer;
	import org.osmf.player.configuration.*;
	import org.osmf.player.debug.LogHandler;
	import org.osmf.player.debug.StrobeLogger;
	import org.osmf.player.debug.StrobeLoggerFactory;
	import org.osmf.player.elements.*;
	import org.osmf.player.elements.playlistClasses.*;
	import org.osmf.player.errors.*;
	import org.osmf.player.media.*;
	import org.osmf.player.plugins.PluginLoader;
	import org.osmf.player.utils.StrobeUtils;
	import org.osmf.traits.DVRTrait;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayState;
	import org.osmf.traits.PlayTrait;
	import org.osmf.utils.OSMFSettings;
	import org.osmf.vast.media.VASTMediaGenerator;

	CONFIG::LOGGING {
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
	public class MSPlayer extends Sprite {
			
			
		[Embed(source='../assets/GAConfig.xml', mimeType="application/octet-stream")]
			private static const GAConfigClass:Class;
			
		public static const RATCHET_ACCESS_TOKEN:String = "584b28b15c44406884afbeab3709761f";
		public static const chosenPlacement:String = VASTMediaGenerator.PLACEMENT_LINEAR;
		private static const MAX_OVER_WIDTH:int = 400;
		private static const MAX_OVER_WIDTH_SMARTPHONE:int = 550;
		private static const MAX_OVER_WIDTH_TABLET:int = 600;
		private static const MEDIA_PLAYER:String = "org.osmf.media.MediaPlayer";
		// used for DVR rolling window
		private static const DEFAULT_FRAGMENT_SIZE:Number = 4;
		private static const DEFAULT_SEGMENT_SIZE:Number = 16;
		
		private var injector:InjectorModule;
		private var pluginHostWhitelist:Vector.<String>;
		private var mediaPlayerJSBridge:JavaScriptBridge = null;
		private var _media:MediaElement;
		private var controlBarWidth:Number;
		private var controlBarHeight:Number;
		private var strobeWidth:Number;
		private var strobeHeight:Number;
		
        private static const EXTERNAL_INTERFACE_ERROR_CALL:String = "function(playerId, code, message, detail)" + 
		"{" + 
		"if (onMediaPlaybackError != null)" +
		"onMediaPlaybackError(playerId, code, message, detail);" +
		"}";
		
		CONFIG::LOGGING {
			protected var logger:StrobeLogger = Log.getLogger("StrobeMediaPlayback") as StrobeLogger;
		}
		
		// These should be accessible from the preloader for the performance measurement to work.
		public var configuration:PlayerConfiguration;
		public var player:StrobeMediaPlayer;
		public var factory:StrobeMediaFactory;
		private var viewHelper:ViewHelper;
		private var _adController:AdController;
		private var _mainVideoTimeSetted:Boolean;
		
		public function MSPlayer() {
			CONFIG::LOGGING {
				// Setup the custom logging factory
				Log.loggerFactory = new StrobeLoggerFactory(new LogHandler(false));
				logger = Log.getLogger("StrobeMediaPlayback") as StrobeLogger;
			}
			if (stage) {
				onAddedToStage(null);
			} else {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
		}
		
		private function onAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			initialize(loaderInfo.parameters, stage, loaderInfo, null);
		}
		
		/**
		* Initializes the player with the parameters and it's context (stage).
		*
		* We need the stage at this point because we need
		* to setup the fullscreen event handlers in the initialization phase.
		*/
		
		/**
		* Init-time methods
		*/
		
		private function isDebug():Boolean {
			//TODO: Should be false, when production
			return true;
		}
		
		public function initialize(parameters:Object, stage:Stage, loaderInfo:LoaderInfo, pluginHostWhitelist:Array):void {
			var environment:String = isDebug() ? "development" : "production";
			Ratchet.init(this, RATCHET_ACCESS_TOKEN, environment);
			injector = new InjectorModule();
			//initUncaughtErrorsHandler();
			initPluginsWhitelist(pluginHostWhitelist);
			initPlayerItself();
			// Add DRM error handler
			var drmManager:DRMManager = DRMManager.getDRMManager();
			drmManager.addEventListener(DRMErrorEvent.DRM_ERROR, onDRMError);
			initConfiguration();
			if (
				configuration.javascriptCallbackFunction != "" && 
				ExternalInterface.available && 
				mediaPlayerJSBridge == null
			) {
				mediaPlayerJSBridge = new JavaScriptBridge(
					this, 
					player, 
					StrobeMediaPlayer, 
					configuration.javascriptCallbackFunction
				);
			}
		}
		
		private function initUncaughtErrorsHandler():void {
			CONFIG::FLASH_10_1 {
				//Register the global error handler.
				loaderInfo && 
					loaderInfo.hasOwnProperty("uncaughtErrorEvents") && 
					loaderInfo["uncaughtErrorEvents"].addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
			}
		}
		
		private function initPluginsWhitelist(pluginHostWhitelist:Array):void {
			this.pluginHostWhitelist = new Vector.<String>();
			if (pluginHostWhitelist) {
				for each(var pluginHost:String in pluginHostWhitelist) {
					this.pluginHostWhitelist.push(pluginHost);
				}
				// Add the current domain only if the pluginHostWhitelist != null
				// (since for null we want to disable the whitelist protection).
				var currentDomain:String = StrobeUtils.retrieveHostNameFromUrl(loaderInfo.loaderURL);
				this.pluginHostWhitelist.push(currentDomain);
			}
		}
		
		private function initPlayerItself():void {
			player = injector.getInstance(MediaPlayer);
			player.addEventListener(TimeEvent.COMPLETE, onPlayerComplete);
			player.addEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
			// this is used for DVR rolling window
			// TODO: Add this event only when the resource is DVR rolling window not all the time
			player.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, onCurrentTimeChange);
			if (!_mainVideoTimeSetted) {
				player.addEventListener(BufferEvent.BUFFERING_CHANGE, setCurrentVideoTime);
			}
			SOWrapper.processPlayer(player);
		}
		
		private function initConfiguration():void {
			configuration = injector.getInstance(PlayerConfiguration);
			var configurationLoader:ConfigurationLoader = injector.getInstance(ConfigurationLoader);
			configurationLoader.addEventListener(Event.COMPLETE, onConfigurationReady);
			configurationLoader.load(loaderInfo.parameters, configuration);
		}
		
		private function initSkins():void {
			if (configuration.skin != null && configuration.skin != "") {
				var skinLoader:XMLFileLoader = new XMLFileLoader();
				skinLoader.addEventListener(IOErrorEvent.IO_ERROR, onSkinLoaderFailure);
				skinLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSkinLoaderFailure);
				skinLoader.addEventListener(Event.COMPLETE, onSkinLoaderComplete);
				skinLoader.load(configuration.skin);
			} else {
				onSkinLoaderComplete();
			}
		}
		
		private function initializeView():void {
			configureStage();
			viewHelper = new ViewHelper(configuration, player);
			viewHelper.mainContainer.addEventListener(MouseEvent.DOUBLE_CLICK, onFullScreenRequest);
			viewHelper.mainContainer.addEventListener(MouseEvent.CLICK, onMainClick);
			addChild(viewHelper.mainContainer);
			if (configuration.controlBarMode != ControlBarMode.NONE) {
				player.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onSetAutoHide);
				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					viewHelper.controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN, onFitToScreenRequest);
					viewHelper.controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN_FORCE_FIT, onFitToScreenRequest);
				} else {
					viewHelper.controlBarContainer.addEventListener(WidgetEvent.REQUEST_FULL_SCREEN, onFullScreenRequest);
				}
            }
			viewHelper.qosOverlay.addEventListener(WidgetEvent.VIDEO_INFO_OVERLAY_CLOSE, dispatchEvent);
			// update the dimensions of the container
			onStageResize();
		}
		
		private function configureStage():void {
			// Set the SWF scale mode, and listen to the stage change dimensions:
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
		}
		
		private function initPlugins():Vector.<MediaResourceBase> {
			var pluginConfigurations:Vector.<MediaResourceBase> = ConfigurationUtils.transformDynamicObjectToMediaResourceBases(configuration.plugins);
			var pluginResource:MediaResourceBase;	
			pluginResource = new URLResource(loaderInfo.parameters.GTrackPluginURL || 'GTrackPlugin.swf');
			var contentFile:ByteArray = new GAConfigClass();
			var contentStr:String = contentFile.readUTFBytes( contentFile.length );
			pluginResource.addMetadataValue('http://www.realeyes.com/osmf/plugins/tracking/google', new XML(contentStr));
			pluginConfigurations.push(pluginResource);
			CONFIG::LOGGING {
				var p:uint = 0;
				for each(pluginResource in pluginConfigurations) {
					logger.trackObject("PluginResource"+(p++), pluginResource);
				}
			}
			// EXPERIMENTAL: Ad plugin integration
			for each(pluginResource in pluginConfigurations) {
				pluginResource.addMetadataValue("MediaContainer", viewHelper.mediaContainer);
				pluginResource.addMetadataValue("MediaPlayer", player);
			}
			return pluginConfigurations;
		}
		
		private function startLoadPlugins(pluginConfigurations:Vector.<MediaResourceBase>):void {
			factory = injector.getInstance(MediaFactory);
			var pluginLoader:PluginLoader = new PluginLoader(pluginConfigurations, factory, pluginHostWhitelist);
			pluginLoader.haltOnError = configuration.haltOnError;
			pluginLoader.addEventListener(Event.COMPLETE, loadMedia);
			pluginLoader.addEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
			pluginLoader.loadPlugins();
		}
		
		/**
		* Init-time handlers
		*/
		
		private function onConfigurationReady(event:Event):void {
			OSMFSettings.enableStageVideo = configuration.enableStageVideo;
			CONFIG::LOGGING {
				logger.trackObject("PlayerConfiguration", configuration);
			}
			initSkins();
		}
		
		private function onSkinLoaderFailure(event:ErrorEvent):void {
			Ratchet.handleErrorEvent(event);
			trace("WARNING: failed to load skin file at " + configuration.skin);
			onSkinLoaderComplete();
		}
		
		private function onSkinLoaderComplete(event:Event = null):void {
			var assetManager:AssetsManager = new AssetsManager();
			if (event) {
				var skinLoader:XMLFileLoader = event.target as XMLFileLoader;
				var skinParser:SkinParser = new SkinParser();
				skinParser.parse(skinLoader.xml, assetManager);
			}
			var chromeProvider:ChromeProvider = ChromeProvider.getInstance();
			chromeProvider.addEventListener(Event.COMPLETE, onChromeProviderComplete);
			if (chromeProvider.loaded == false && chromeProvider.loading == false) {
				chromeProvider.load(assetManager);
			} else {
				onChromeProviderComplete();
			}
		}
		
		private function onChromeProviderComplete(event:Event = null):void {
			initializeView();
			// After initialization, either load the assigned media, or load requested plug-ins first, and then load the assigned media:
			startLoadPlugins(initPlugins());
		}
		
		/**
		* Run-time methods. All loaded, start playback
		*/
		
		/**
		* Loads the media or displays an error message on fail.
		*/
		
		public function loadMedia(e:Event = null):void {
			trace("Load media");
			viewHelper.controlBar.hide();
			// Try to load the URL set on the configuration:
			var resource:MediaResourceBase = injector.getInstance(MediaResourceBase);
			if (resource is MultiQualityStreamingResource) {
				(resource as MultiQualityStreamingResource).addEventListener(MultiQualityStreamingResource.STREAM_CHANGED, continueMediaLoad);
				(resource as MultiQualityStreamingResource).initialize();
				return;
			} else {
				continueMediaLoad(null, resource);
			}
        }
		
		private function continueMediaLoad(e:Event = null, resource:MediaResourceBase = null):void {
			if (e) {
				e.currentTarget.removeEventListener(e.type, arguments.callee);
				resource = (e.currentTarget as MultiQualityStreamingResource);
				e.currentTarget.addEventListener(e.type, changeStreamQuality);
				(resource as MultiQualityStreamingResource).registerOwnButton(viewHelper.controlBar);
				viewHelper.controlBar.removeEventListener(ChannelListButton.LIST_CALL, switchChannelListVisible);
				viewHelper.channelList.removeEventListener(ChannelListButton.LIST_CALL, switchChannelListVisible);
				viewHelper.controlBar.addEventListener(ChannelListButton.LIST_CALL, switchChannelListVisible);
				viewHelper.channelList.addEventListener(ChannelListButton.LIST_CALL, switchChannelListVisible);
			}
			CONFIG::LOGGING {
				logger.trackObject("AssetResource", resource);
			}
			viewHelper.controlBar.show();
			resource.addMetadataValue("timeWatched", { pageURL: "Analytics Test Video" } );
			_adController = new AdController(player, viewHelper, factory);
			media = factory.createMediaElement(resource);
			_adController.addEventListener(AdController.PAUSE_MAIN_VIDEO_REQUEST, pauseMainVideoForAd);
			_adController.addEventListener(AdController.RESTORE_MAIN_VIDEO_REQUEST, restoreMainVideoAfterAd);
			_adController.addEventListener(AdController.RESUME_MAIN_VIDEO_REQUEST, resumeMainVideoAfterAd);
			_adController.checkForAd(loaderInfo.parameters);
			viewHelper.channelList.jsCallbackFunctionName = loaderInfo.parameters.channelChangedCallback;
			viewHelper.channelList.removeEventListener(ChannelListDialogElement.CHANNEL_CHANGED, loadMedia);
			viewHelper.channelList.addEventListener(ChannelListDialogElement.CHANNEL_CHANGED, loadMedia);
			
		}
		
		private function switchChannelListVisible(e:Event):void {
			viewHelper.mainContainer.containsMediaElement(viewHelper.channelList) ?
				viewHelper.mainContainer.removeMediaElement(viewHelper.channelList) :
				viewHelper.mainContainer.addMediaElement(viewHelper.channelList);
			viewHelper.controlBar.processListState(viewHelper.mainContainer.containsMediaElement(viewHelper.channelList));
		}
		
		private function changeStreamQuality(e:Event):void {
			var resource:MultiQualityStreamingResource = (e.currentTarget as MultiQualityStreamingResource);
			_mainVideoTimeSetted = false;
			player.addEventListener(BufferEvent.BUFFERING_CHANGE, setCurrentVideoTime);
			media = factory.createMediaElement(resource);
		}
		
		/**
		* Run-time handlers
		*/
		
		private function resumeMainVideoAfterAd(e:Event):void {
			// WORKAROUND: http://bugs.adobe.com/jira/browse/ST-397 - GPU Decoding issue on stagevideo: Win7, Flash Player version WIN 10,2,152,26 (debug)
			viewHelper.controlBar.enableMultiQualityButton();
			player.play();
			if (viewHelper.controlBar) {
				viewHelper.controlBar.target = player.media;
			}
		}
		
		private function restoreMainVideoAfterAd(e:Event):void {
			SOWrapper.processPlayer(player);
			viewHelper.mediaContainer.addMediaElement(player.media);
		}
		
		private function setCurrentVideoTime(e:BufferEvent):void {
			if (e.buffering) { return; }
			e.currentTarget.removeEventListener(e.type, arguments.callee);
			SOWrapper.setCurrentVideoTime(player, loaderInfo.parameters);
			SOWrapper.processPlayer(player);
			_mainVideoTimeSetted = true;
		}
		
		private function pauseMainVideoForAd(e:Event):void {
			player.removeEventListener(PlayEvent.CAN_PAUSE_CHANGE, pauseMainVideoForAd);
			if (!player.canPause) {
				player.addEventListener(PlayEvent.CAN_PAUSE_CHANGE, pauseMainVideoForAd);
				return;
			}
			player.pause();
			removeMainVideoFromContainer(null);
			// FIXME: Скорее всего комментировать не нужно.
			//player.media.metadata.addValue("Advertisement", url);
		}
		
		private function removeMainVideoFromContainer(e:ContainerChangeEvent):void {
			if (e) {
				e.currentTarget.removeEventListener(e.type, arguments.callee);
			}
			//TODO: Remove, when we will have own Media and Traits for multi-quality streaming:
			viewHelper.controlBar && viewHelper.controlBar.disableMultiQualityButton();
			if (viewHelper.mediaContainer.containsMediaElement(player.media)) {
				viewHelper.mediaContainer.removeMediaElement(player.media);
			} else {
				player && player.media && player.media.addEventListener(ContainerChangeEvent.CONTAINER_CHANGE, removeMainVideoFromContainer);
			}
		}
		
		/**
		* User actions
		*/
		
		private function onMainClick(event:MouseEvent):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					onFullScreenRequest();
				}
				if (
					configuration.controlBarType == ControlBarType.TABLET &&
					player &&
					player.media &&
					(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).playState != PlayState.PLAYING
				) {
					viewHelper.controlBar.visible = !viewHelper.controlBar.visible;
				}
			} else {
				if (
					player &&
					player.media && 
					(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait) &&
					(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).playState != PlayState.PLAYING
				) {
					viewHelper.controlBar.visible = !viewHelper.controlBar.visible;
				}
				event.stopImmediatePropagation();
			}
		}
		
		private function onFullScreenRequest(event:Event=null):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (
					!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo) || 
					configuration.removeContentFromStageOnFullScreenWithStageVideo
				){
					removeChild(viewHelper.mainContainer);
				}
				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (
					!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo) || 
					configuration.useFullScreenSourceRectOnFullScreenWithStageVideo
				) {
					stage.fullScreenSourceRect = player.getFullScreenSourceRect(
						stage.fullScreenWidth, 
						stage.fullScreenHeight
					);
				}
				CONFIG::LOGGING {
					if (stage.fullScreenSourceRect != null) {
						logger.info("Setting fullScreenSourceRect = {0}", stage.fullScreenSourceRect.toString());
					} else {
						logger.info("fullScreenSourceRect not set.");
					}
					if (stage.fullScreenSourceRect != null) {
						logger.qos.rendering.fullScreenSourceRect = stage.fullScreenSourceRect.toString();
						logger.qos.rendering.fullScreenSourceRectAspectRatio = stage.fullScreenSourceRect.width / stage.fullScreenSourceRect.height;
					} else {
						logger.qos.rendering.fullScreenSourceRect =	"";
						logger.qos.rendering.fullScreenSourceRectAspectRatio = NaN;
					}
					logger.qos.rendering.screenWidth = stage.fullScreenWidth;
					logger.qos.rendering.screenHeight = stage.fullScreenHeight;
					logger.qos.rendering.screenAspectRatio = logger.qos.rendering.screenWidth / logger.qos.rendering.screenHeight;
				}
				try {
					stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch (error:SecurityError) {
					CONFIG::LOGGING {
						logger.info("Failed to go to FullScreen. Check if allowfullscreen is set to false in HTML page.");
					}
					// This exception is thrown when the allowfullscreen is set to false in HTML
					addChild(viewHelper.mainContainer);
					viewHelper.mainContainer.validateNow();
				}
			} else {
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		private function onFitToScreenRequest(event:Event):void {
			if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
				if (event.type == WidgetEvent.REQUEST_FULL_SCREEN_FORCE_FIT) {
					if (player.media) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.ZOOM;
					}
				} else if (event.type == WidgetEvent.REQUEST_FULL_SCREEN) {
					if (player.media) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
				}
				_adController && _adController.processFitToScreenRequest(event);
			}
		}
		
		/**
		* Screen manulations
		*/
		
		private function onFullScreen(event:FullScreenEvent=null):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				if (viewHelper.controlBar) {
					//Set the autoHide property to the value set by the user.
					//If the autoHide property changed we need to adjust the layout settings
					if (
						configuration.controlBarType == ControlBarType.DESKTOP &&
						viewHelper.controlBar.autoHide != configuration.controlBarAutoHide
					) {
						viewHelper.controlBar.autoHide = configuration.controlBarAutoHide;
						viewHelper.layout();
					}
					//getting back to thumb mode
					if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
						(player.media.getTrait(MediaTraitType.PLAY) as PlayTrait).stop();
						viewHelper.controlBar.autoHide = false;
						viewHelper.controlBar.autoHideTimeout = -1;
						viewHelper.controlBar.visible = false;
					}
					if (configuration.controlBarType == ControlBarType.TABLET) {
						viewHelper.controlBar.autoHide = false;
					}
				}
				Mouse.show();
				if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
					if (player.media) {
						(player.media.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata).scaleMode = ScaleMode.LETTERBOX;
					}
					_adController && _adController.onFullScreen();
				}
			} else if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				if (viewHelper.controlBar) {
					if (configuration.controlBarType == ControlBarType.DESKTOP) {
						// We force the autohide of the controlBar in fullscreen
						controlBarWidth = viewHelper.controlBar.width;
						controlBarHeight = viewHelper.controlBar.height;
						viewHelper.controlBar.autoHideTimeout = configuration.controlBarAutoHideTimeout * 1000;
						viewHelper.controlBar.autoHide = true;
						// If the autoHide property changed we need to adjust the layout settings
						if (viewHelper.controlBar.autoHide != configuration.controlBarAutoHide) {
							viewHelper.layout();
						}
					}
					if (configuration.controlBarType == ControlBarType.SMARTPHONE) {
						// In tabled mode we show the control bar when switching from thumb mode to full screen
						viewHelper.controlBar.autoHideTimeout = configuration.controlBarAutoHideTimeout * 1000;
						viewHelper.controlBar.visible = true;
					}
				}
				// NOTE: Exploration code - exploring some issues arround full screen and stage video
				if (
					!(OSMFSettings.enableStageVideo && OSMFSettings.supportsStageVideo) || 
					configuration.removeContentFromStageOnFullScreenWithStageVideo
				) {
					addChild(viewHelper.mainContainer);
				}
				viewHelper.mainContainer.validateNow();
			}
		}
		
		private function onSetAutoHide(event:PlayEvent):void {
			if (viewHelper.controlBar) {
				if (configuration.controlBarType != ControlBarType.DESKTOP) {
					if (event.playState != PlayState.PLAYING) {
						viewHelper.controlBar.autoHide = false;
					} else {
						viewHelper.controlBar.autoHide = true;
					}
				}
			}
		}
		
		private function onStageResize(event:Event = null):void {
			// Propagate dimensions to the main container:
			var newWidth:Number = isNaN(strobeWidth) ? stage.stageWidth : strobeWidth;
			var newHeigth:Number = isNaN(strobeHeight) ? stage.stageHeight : strobeHeight;
			if (viewHelper.mainContainer) {
				viewHelper.mainContainer.width = newWidth;
				viewHelper.mainContainer.height = newHeigth;
			}
			// Propagate dimensions to the control bar:
			if (viewHelper.controlBar) {
				if (
					configuration.controlBarMode != ControlBarMode.FLOATING ||
					viewHelper.controlBar.width > newWidth ||
					newWidth < MAX_OVER_WIDTH
				){
					viewHelper.controlBar.width = newWidth;
				} else if (configuration.controlBarMode == ControlBarMode.FLOATING) {
					switch(configuration.controlBarType) {
						case ControlBarType.SMARTPHONE:
							viewHelper.controlBar.width = MAX_OVER_WIDTH_SMARTPHONE;
						break;
						case ControlBarType.TABLET:
							viewHelper.controlBar.width = MAX_OVER_WIDTH_TABLET;
						break;
						default:
							viewHelper.controlBar.width = MAX_OVER_WIDTH;
						break;
					}
				}
			}
		}
		
		private function onCurrentTimeChange(event:TimeEvent):void {
			if (
				player.state == MediaPlayerState.BUFFERING ||
				player.state == MediaPlayerState.PLAYING ||
				player.state == MediaPlayerState.PAUSED
			) {// If the player is in a relevant state 
				var dvrTrait:DVRTrait = player.media.getTrait(MediaTraitType.DVR) as DVRTrait;
				if (dvrTrait != null && dvrTrait.windowDuration != -1) { // If rolling window is present
					if (event.time < DEFAULT_FRAGMENT_SIZE) {// If we're too close to the left-most side of the rolling window
						// Seek to a safe area
						player.seek(DEFAULT_SEGMENT_SIZE);
					}
				}
			}
		}
		
		private function onPlayerComplete(event:TimeEvent):void {
			if (
				configuration &&
				configuration.endOfVideoOverlay != null &&
				configuration.endOfVideoOverlay != "" &&	
				player.loop == false &&	
				player.playing == false
			) {
				_adController.processPoster(configuration.endOfVideoOverlay, configuration.posterScaleMode || configuration.scaleMode);
			}
		}
		
		
		/**
		* Public interface
		*/
		
		public function removePoster():void {
			_adController && _adController.removePoster();
		}
		
		public function setSize(w:Number, h:Number):void {
			strobeWidth = w;
			strobeHeight = h;
			onStageResize();
		}
		
		public function showVideoInfo(value:Boolean):void {
			if (viewHelper.qosOverlay) {
				if (value) {
					viewHelper.qosOverlay.showInfo();
				} else {
					viewHelper.qosOverlay.hideInfo();
				}
			}
		}
		
		
		/**
		* Stuff
		*/
		
		private function set media(value:MediaElement):void {
			if (viewHelper.alert && viewHelper.mediaContainer.containsMediaElement(viewHelper.alert)) {
				viewHelper.mediaContainer.removeMediaElement(viewHelper.alert);
				initializeView();
			}
			if (value != _media) {
				// Remove the current media from the container:
				if (_media && viewHelper.mediaContainer.containsMediaElement(_media)) {
					viewHelper.mediaContainer.removeMediaElement(_media);
				}
				viewHelper.mainContainer.containsMediaElement(viewHelper.channelList) && 
					viewHelper.mainContainer.removeMediaElement(viewHelper.channelList);
				viewHelper.controlBar.processListState(false);
				processNewMedia(value);
				// Set the new main media element:
				SOWrapper.releasePlayer(player);
				_media = player.media = value;
                if (_media) {
					viewHelper.mediaContainer.addMediaElement(_media);
                    // Forward a reference to controlBar:
					viewHelper.controlBar && (viewHelper.controlBar.target = _media);
					// Forward a reference to login window:
					viewHelper.loginWindow && (viewHelper.loginWindow.target = _media);
                }
				viewHelper.playOverlay && (viewHelper.playOverlay.media = _media);
				viewHelper.bufferingOverlay && (viewHelper.bufferingOverlay.media = _media);
			}
		}
		
		private function processNewMedia(value:MediaElement):void {
			trace("processNewMedia");
			if (value) {
				var layoutMetadata:LayoutMetadata = value.metadata.getValue(
					LayoutMetadata.LAYOUT_NAMESPACE
				) as LayoutMetadata;
				if (!layoutMetadata) {
					layoutMetadata = new LayoutMetadata();
					value.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, layoutMetadata);
				}
				layoutMetadata.scaleMode = configuration.scaleMode;
				layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
				layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
				layoutMetadata.percentWidth = 100;
				layoutMetadata.percentHeight = 100;
				layoutMetadata.index = 1;
				if 	(
					configuration &&
					configuration.poster != null &&
					configuration.poster != "" &&
					player.autoPlay == false &&
					player.playing == false
				) {
					if (configuration.endOfVideoOverlay == "") {
						configuration.endOfVideoOverlay = configuration.poster;
					}
					_adController.processPoster(configuration.poster, configuration.posterScaleMode || configuration.scaleMode);
				}
				value.metadata.addValue(MEDIA_PLAYER, player);
			}
		}
		
		/**
		* In fact, handling this event means unit's death
		*/
		
		private function onMediaError(event:MediaErrorEvent):void {
			// Make sure this event gets handled only once:
			player.removeEventListener(MediaErrorEvent.MEDIA_ERROR, onMediaError);
			// Reset the current media:
			player.media = null;
			media = null;
			// Translate error message:
			var message:String;
			var nonTranslatedMessage:String = event.error.message + "\n" + event.error.detail;
			if (!configuration.verbose) {
				message = ErrorTranslator.translate(event.error).message;
			}
			!message && (message = nonTranslatedMessage);
			CONFIG::FLASH_10_1 {
				var tokens:Array = Capabilities.version.split(/[\s,]/);
				var flashPlayerMajorVersion:int = parseInt(tokens[1]);
				var flashPlayerMinorVersion:int = parseInt(tokens[2]);
				if (flashPlayerMajorVersion < 10 || (flashPlayerMajorVersion  == 10 && flashPlayerMinorVersion < 1)) {
					if (configuration.verbose) {
						message += "\n\nThe content that you are trying to play requires the latest Flash Player version.\nPlease upgrade and try again.";
					} else {
						message = "The content that you are trying to play requires the latest Flash Player version.\nPlease upgrade and try again.";
					}
				}
			}
			reportError(message, nonTranslatedMessage);
			// Forward the raw error message to JavaScript:
			if (ExternalInterface.available) {
				try {
					ExternalInterface.call(
						EXTERNAL_INTERFACE_ERROR_CALL,
						ExternalInterface.objectID,
						event.error.errorID, 
						event.error.message, 
						event.error.detail
					);
					JavaScriptBridge.error(event);
				} catch(e:Error) {
					trace(e.toString());
				}
			}
		}
		
		private function reportError(message:String, nonTranslatedMessage:String = ""):void {
			try { 
				//TODO: Remove on release!
				throw new Error(nonTranslatedMessage || message, int(8036 * Math.random()));
			} catch (e:Error) {
				Ratchet.handleError(e);
				return;
				//throw e;
			}
			// If an alert widget is available, use it. Otherwise, trace the message:
			if (viewHelper.alert) {
				if (_media && viewHelper.mediaContainer.containsMediaElement(_media)) {
					viewHelper.mediaContainer.removeMediaElement(_media);
				}
				if (viewHelper.controlBar && viewHelper.controlBarContainer.containsMediaElement(viewHelper.controlBar)) {
					viewHelper.controlBarContainer.removeMediaElement(viewHelper.controlBar);
				}
				if (_adController) {
					_adController.removePoster();
				}
				if (viewHelper.playOverlay && viewHelper.mediaContainer.layoutRenderer.hasTarget(viewHelper.playOverlay)) {
					viewHelper.mediaContainer.layoutRenderer.removeTarget(viewHelper.playOverlay);
				}
				if (viewHelper.bufferingOverlay && viewHelper.mediaContainer.layoutRenderer.hasTarget(viewHelper.bufferingOverlay)) {
					viewHelper.mediaContainer.layoutRenderer.removeTarget(viewHelper.bufferingOverlay);
				}
				viewHelper.mediaContainer.addMediaElement(viewHelper.alert);
				viewHelper.alert.alert("Error", message);
			} else {
				trace("Error:", message);
			}
		}
		
		private function onDRMError(event:DRMErrorEvent):void {
			Ratchet.handleErrorEvent(event);
			switch(event.errorID) {
				// Use the following link for the error codes
				// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/runtimeErrors.html
				case 3305:
				case 3328:
				case 3315:
					if (configuration.verbose) {
						reportError("Unable to connect to the authentication server. Error ID " + event.errorID);
					} else {
						reportError("We are unable to connect to the authentication server. We apologize for the inconvenience.");
					} 
					break;
				default:
					if (configuration.verbose) {
						reportError("DRM Error " + event.errorID);
					} else {
						reportError("Unexpected DRM error");
					}
					break;
			}
		}
		
		CONFIG::FLASH_10_1 {
			private function onUncaughtError(event:UncaughtErrorEvent):void {
				Ratchet.handleErrorEvent(event);
				event.preventDefault();
				var timer:Timer = new Timer(3000, 1);
				var mediaError:MediaError = new MediaError(
					StrobePlayerErrorCodes.UNKNOWN_ERROR,
					event.error.name + " - " + event.error.message
				);
				timer.addEventListener(
					TimerEvent.TIMER,
					function(event:Event):void {
						onMediaError(
							new MediaErrorEvent( 
								MediaErrorEvent.MEDIA_ERROR,
								false,
								false,
								mediaError
							)
						);
					}
				);
				timer.start();
			}
		}
	}
}