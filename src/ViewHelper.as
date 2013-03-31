package {
	import org.osmf.containers.MediaContainer;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMode;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.widgets.BufferingOverlay;
	import org.osmf.player.chrome.widgets.PlayButtonOverlay;
	import org.osmf.player.chrome.widgets.VideoInfoOverlay;
	import org.osmf.player.configuration.ControlBarMode;
	import org.osmf.player.configuration.ControlBarType;
	import org.osmf.player.configuration.PlayerConfiguration;
	import org.osmf.player.containers.StrobeMediaContainer;
	import org.osmf.player.elements.AlertDialogElement;
	import org.osmf.player.elements.AuthenticationDialogElement;
	import org.osmf.player.elements.ChannelListDialogElement;
	import org.osmf.player.elements.ControlBarElement;
	import org.osmf.player.elements.HotkeysScreenElement;
	import org.osmf.player.elements.PlayerTitleElement;
	import org.osmf.player.media.StrobeMediaPlayer;

	public class ViewHelper {
		private static const PLAY_OVERLAY_INDEX:int = 3;
		private static const BUFFERING_OVERLAY_INDEX:int = 4;
		private static const OVERLAY_FADE_STEPS:int = 6;
		private static const POSITION_OVER_OFFSET:int = 20;
		private static const ON_TOP:int = 9998;
		private static const ALWAYS_ON_TOP:int = 9999;
		
		private var _playOverlay:PlayButtonOverlay;
		private var _controlBarContainer:MediaContainer;
		private var _playerTitleContainer:MediaContainer;
		private var _configuration:PlayerConfiguration;
		private var _mainContainer:StrobeMediaContainer;
		private var _mediaContainer:MediaContainer;
		private var _bufferingOverlay:BufferingOverlay;
		private var _alert:AlertDialogElement;
		private var _loginWindow:AuthenticationDialogElement;
		private var _loginWindowContainer:MediaContainer;
		private var _controlBar:ControlBarElement;
		private var _qosOverlay:VideoInfoOverlay;
		private var _player:StrobeMediaPlayer;
		private var _adBlockHeader:AdBlockHeader;
		private var _channelList:ChannelListDialogElement;
		private var _playerTitle:PlayerTitleElement;
		private var _hotkeysScreen:HotkeysScreenElement;
		
		public function ViewHelper(configuration:PlayerConfiguration, player:StrobeMediaPlayer) {
			_configuration = configuration;
			_player = player;
			initAll();
		}
		
		private function initAll():void {
			initMainContainer();
			initMediaContainer();
			initControlBarContainer();
			initPlayerTitleContainer();
			if (_configuration.playButtonOverlay) {
				initPlayOverlay();
			}
			if (_configuration.bufferingOverlay) {
				initBufferingOverlay();
			}
			initAlert();
			initLoginWindow();
			initLoginWindowContainer();
			if (_configuration.controlBarMode != ControlBarMode.NONE) {
				initControlBar();
				initPlayerTitle();
            }
			mainContainer.layoutRenderer.addTarget(mediaContainer);
			initQosOverlay();
			initAdBlockHeader();
			initChanneList();
			initHotkeysScreen()
		}
		
		private function initHotkeysScreen():void {
			_hotkeysScreen = new HotkeysScreenElement();
		}
		
		private function initMainContainer():void {
			_mainContainer = new StrobeMediaContainer();
			_mainContainer.backgroundColor = _configuration.backgroundColor;
			_mainContainer.backgroundAlpha = 0;
			_mainContainer.doubleClickEnabled = true;
			if (_configuration.controlBarMode == ControlBarMode.NONE) {
				_mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
			}
		}
		
		private function initMediaContainer():void {
			_mediaContainer = new MediaContainer();
			_mediaContainer.clipChildren = true;
			_mediaContainer.layoutMetadata.percentWidth = 100;
			_mediaContainer.layoutMetadata.percentHeight = 100;
			_mediaContainer.doubleClickEnabled = true;
		}
		
		private function initControlBarContainer():void {
			_controlBarContainer = new MediaContainer();
			_controlBarContainer.layoutMetadata.verticalAlign = VerticalAlign.TOP;
			_controlBarContainer.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
		}
		
		private function initPlayerTitleContainer():void {
			_playerTitleContainer = new MediaContainer();
			_playerTitleContainer.layoutMetadata.verticalAlign = VerticalAlign.TOP;
			_playerTitleContainer.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			_playerTitleContainer.layoutMetadata.scaleMode = ScaleMode.NONE;
			_playerTitleContainer.layoutMetadata.index = ALWAYS_ON_TOP;
		}
		
		private function initPlayOverlay():void {
			_playOverlay = new PlayButtonOverlay();
			_playOverlay.configure(<default/>, ChromeProvider.getInstance().assetManager);
			_playOverlay.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			_playOverlay.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
			_playOverlay.layoutMetadata.index = PLAY_OVERLAY_INDEX;
			_playOverlay.fadeSteps = OVERLAY_FADE_STEPS;
			_mediaContainer.layoutRenderer.addTarget(_playOverlay);
		}
		
		private function initBufferingOverlay():void {
			_bufferingOverlay = new BufferingOverlay();
			_bufferingOverlay.configure(<default/>, ChromeProvider.getInstance().assetManager);
			_bufferingOverlay.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			_bufferingOverlay.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
			_bufferingOverlay.layoutMetadata.index = BUFFERING_OVERLAY_INDEX;
			_bufferingOverlay.fadeSteps = OVERLAY_FADE_STEPS;
			_mediaContainer.layoutRenderer.addTarget(_bufferingOverlay);
		}
		
		private function initAlert():void {
			_alert = new AlertDialogElement();
			_alert.tintColor = _configuration.tintColor;
		}
		
		private function initLoginWindow():void {
			_loginWindow = new AuthenticationDialogElement();
			_loginWindow.tintColor = _configuration.tintColor;
		}
		
		private function initLoginWindowContainer():void {
			_loginWindowContainer = new MediaContainer();	
			_loginWindowContainer.layoutMetadata.index = ALWAYS_ON_TOP;
			_loginWindowContainer.layoutMetadata.percentWidth = 100;
			_loginWindowContainer.layoutMetadata.percentHeight = 100;
			_loginWindowContainer.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			_loginWindowContainer.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
			_loginWindowContainer.addMediaElement(_loginWindow);
		}
		
		private function initControlBar():void {
			_controlBar = new ControlBarElement(_configuration.controlBarType);
			_controlBar.autoHide = _configuration.controlBarAutoHide;
			_controlBar.autoHideTimeout = _configuration.controlBarAutoHideTimeout * 1000;
			_controlBar.tintColor = _configuration.tintColor;
			if (_configuration.controlBarType == ControlBarType.SMARTPHONE) {
				// The player starts in thumb mode for smartphones
				_controlBar.autoHide = false;
				_controlBar.autoHideTimeout = -1;
				_controlBar.visible = false;
			}
			if (_configuration.controlBarType == ControlBarType.TABLET) {
				// On tablet mode the control bar is visible
				_controlBar.autoHide = false;
			}
			layout();
			_controlBarContainer.layoutMetadata.height = _controlBar.height;
			_controlBarContainer.addMediaElement(_controlBar);
			_mainContainer.layoutRenderer.addTarget(_controlBarContainer);
			_mediaContainer.layoutRenderer.addTarget(_loginWindowContainer);
		}
		
		private function initPlayerTitle():void {
			_playerTitle = new PlayerTitleElement();
			_playerTitle.autoHide = _configuration.controlBarAutoHide;
			_playerTitle.autoHideTimeout = _configuration.controlBarAutoHideTimeout * 1000;
			_playerTitle.tintColor = _configuration.tintColor;
			_playerTitleContainer.layoutMetadata.height = _playerTitle.height;
			_playerTitleContainer.addMediaElement(_playerTitle);
			_mainContainer.layoutRenderer.addTarget(_playerTitleContainer);
		}
		
		private function initQosOverlay():void {
			_qosOverlay = new VideoInfoOverlay();
			_qosOverlay.register(_controlBarContainer, _mainContainer, _player);
			if (_configuration.showVideoInfoOverlayOnStartUp) {
				_qosOverlay.showInfo();
			}
		}
		
		private function initAdBlockHeader():void {
			_adBlockHeader = new AdBlockHeader();
			_adBlockHeader.register(_mainContainer);
		}
		
		private function initChanneList():void {
			_channelList = new ChannelListDialogElement(_configuration);
			_channelList.renewContent(ChannelListDialogElement.DEFAULT_CHANNELS_LIST_URL);
		}
		
		
		//I really can't understand what is it, and why it is `layout`
		public function layout():void {
			_controlBarContainer.layoutMetadata.index = ON_TOP;
			switch(_configuration.controlBarType) {
				case ControlBarType.DESKTOP:
					if (!_controlBar.autoHide && _configuration.controlBarMode == ControlBarMode.DOCKED) {
						// Use a vertical layout:
						_mainContainer.layoutMetadata.layoutMode = LayoutMode.VERTICAL;
						_mediaContainer.layoutMetadata.index = 1;
					} else {
						_mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
						switch(_configuration.controlBarMode) {
							case ControlBarMode.FLOATING:
								_controlBarContainer.layoutMetadata.bottom = POSITION_OVER_OFFSET;
								break;
							case ControlBarMode.DOCKED:
								_controlBarContainer.layoutMetadata.bottom = 0;
								break;
						}
					}
					break;
				case ControlBarType.TABLET:
					_configuration.controlBarMode = ControlBarMode.DOCKED;
					_mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
					_controlBarContainer.layoutMetadata.bottom = 0;
					break;
				case ControlBarType.SMARTPHONE:
					_configuration.controlBarMode = ControlBarMode.FLOATING;
					_mainContainer.layoutMetadata.layoutMode = LayoutMode.NONE;
					_controlBarContainer.layoutMetadata.bottom = POSITION_OVER_OFFSET;
					break;
			}
		}
		
		/**
		* Getters
		*/
		
		public function get mainContainer():StrobeMediaContainer {
			return _mainContainer;
		}
		
		public function get mediaContainer():MediaContainer {
			return _mediaContainer;
		}
		
		public function get controlBarContainer():MediaContainer {
			return _controlBarContainer;
		}
		
		public function get playerTitleContainer():MediaContainer {
			return _playerTitleContainer;
		}
		
		public function get playOverlay():PlayButtonOverlay {
			return _playOverlay;
		}
		
		public function get bufferingOverlay():BufferingOverlay {
			return _bufferingOverlay;
		}
		
		public function get alert():AlertDialogElement {
			return _alert;
		}
		
		public function get loginWindow():AuthenticationDialogElement {
			return _loginWindow;
		}
		
		public function get loginWindowContainer():MediaContainer {
			return _loginWindowContainer;
		}
		
		public function get controlBar():ControlBarElement {
			return _controlBar;
		}
		
		public function get playerTitle():PlayerTitleElement {
			return _playerTitle;
		}
		
		public function get qosOverlay():VideoInfoOverlay {
			return _qosOverlay;
		}
		
		public function get adBlockHeader():AdBlockHeader {
			return _adBlockHeader;
		}
		
		public function get channelList():ChannelListDialogElement {
			return _channelList;
		}
		
		public function get hotkeysScreen():HotkeysScreenElement {
			return _hotkeysScreen;
		}
	}
}