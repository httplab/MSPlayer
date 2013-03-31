package  org.osmf.player.elements {
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.media.MediaElement;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.widgets.HotkeysWidget;
	import org.osmf.player.chrome.widgets.Widget;
	import org.osmf.traits.DisplayObjectTrait;
	import org.osmf.traits.MediaTraitType;
	
	public class HotkeysScreenElement extends MediaElement {
		static public const HELPER_CALL:String = "helperCall";
		static public const MUTE_CALL:String = "muteCall";
		static public const VOLUME_DOWN:String = "volumeDown";
		static public const VOLUME_UP:String = "volumeUp";
		static public const PAUSE_CALL:String = "pauseCall";
		static public const LIVE_CALL:String = "liveCall";
		static public const FULLSCREEN_CALL:String = "fullscreenCall";
		static public const FULL_WIDTH_CALL:String = "fullWidthCall";
		static public const NORMAL_MODE_CALL:String = "normalModeCall";
		static public const OVER_SCREENS_CALL:String = "overScreensCall";
		static public const PREV_CHANNEL_CALL:String = "prevChannelCall";
		static public const NEXT_CHANNEL_CALL:String = "nextChannelCall";
		static public const FIVE_SECONDS_LEFT_CALL:String = "fiveSecondsLeftCall";
		static public const FIVE_SECONDS_RIGHT_CALL:String = "fiveSecondsRightCall";
		private var _stage:Stage;
		private static var _dispatcher:IEventDispatcher;
		private var view:Widget;
		
		public function HotkeysScreenElement() {
			super();
			_dispatcher = this;
		}
		
		override protected function setupTraits():void {
			view = ChromeProvider.getInstance().createHotkeyScreen();
			view.measure();
			addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, view.layoutMetadata);
			var viewable:DisplayObjectTrait = new DisplayObjectTrait(view, view.measuredWidth, view.measuredHeight);
			addTrait(MediaTraitType.DISPLAY_OBJECT, viewable);				
			super.setupTraits();			
		}
		
		public function set stage(value:Stage):void {
			_stage = value;
			_stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			_stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		
		private function resizeHandler(e:Event):void {
			setTimeout(function ():void {
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			}, 1000);
		}
		
		private function keyDownHandler(e:KeyboardEvent):void {
			switch (e.keyCode) {
				case Keyboard.H:
					_dispatcher.dispatchEvent(new Event(HELPER_CALL));
					break;
				case Keyboard.M:
					_dispatcher.dispatchEvent(new Event(MUTE_CALL));
					break;
				case Keyboard.UP:
					_dispatcher.dispatchEvent(new Event(VOLUME_UP));
					break;
				case Keyboard.DOWN:
					_dispatcher.dispatchEvent(new Event(VOLUME_DOWN));
					break;
				case Keyboard.SPACE:
					_dispatcher.dispatchEvent(new Event(PAUSE_CALL));
					break;
				case Keyboard.E:
					_dispatcher.dispatchEvent(new Event(LIVE_CALL));
					break;
				case Keyboard.L:
					_dispatcher.dispatchEvent(new Event(FULLSCREEN_CALL));
					break;
				case Keyboard.K:
					_dispatcher.dispatchEvent(new Event(FULL_WIDTH_CALL));
					break;
				case Keyboard.J:
					_dispatcher.dispatchEvent(new Event(NORMAL_MODE_CALL));
					break;	
				case Keyboard.P:
					_dispatcher.dispatchEvent(new Event(OVER_SCREENS_CALL));
					break;	
				case Keyboard.COMMA:
					_dispatcher.dispatchEvent(new Event(PREV_CHANNEL_CALL));
					break;	
				case Keyboard.PERIOD:
					_dispatcher.dispatchEvent(new Event(NEXT_CHANNEL_CALL));
					break;	
				case Keyboard.LEFT:
					_dispatcher.dispatchEvent(new Event(FIVE_SECONDS_LEFT_CALL));
					break;	
				case Keyboard.RIGHT:
					_dispatcher.dispatchEvent(new Event(FIVE_SECONDS_RIGHT_CALL));
					break;	
			}
		}
		
		public static function registerButtonCall(type:String, callback:Function):void {
			if (_dispatcher) {
				_dispatcher.addEventListener(type, callback);
			}
		}
	}
}