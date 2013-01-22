package {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Timer;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.assets.FontAsset;
	import org.osmf.player.chrome.ChromeProvider;
	
	public class AdBlockHeader extends Sprite {	
		static public const PASS_AD_REQUEST:String = "passAdRequest";
		static public const HEIGHT:Number= 20;
		static public const WIDTH:Number = 150;
		static public const SECONDS_IDLE_BGCOLOR:uint = 0x383838;
		static public const SECONDS_OVER_BGCOLOR:uint = 0xFFFF00;
		static public const AD_BLOCK_BGCOLOR:uint = 0x000000;
		static public const DEFAULT_SECONDS_TEXT:String = "Осталось |S| сек.";
		static public const READY_SECONDS_TEXT:String = "Пропустить";
		static public const AD_BLOCK_TEXT:String = "Р Е К Л А М А";
		
		private var _container:Sprite;
		private var _timer:Timer;
		private var secondsLeft:int;
		private var secondsTF:TextField;
		private var adBlockTF:TextField;
		private var boldFormat:TextFormat;
		private var regularFormat:TextFormat;
		
		/**
		* Init-time methods
		*/
		
		public function register(container:Sprite):void {
			_container = container;
			_timer = new Timer(1, 1);
			initTextFormats();
			initMainTextField();
		}
		
		private function initTextFormats():void {
			var assetsManager:AssetsManager = ChromeProvider.getInstance().assetManager;
			var fontAsset:FontAsset = assetsManager.getAsset(AssetIDs.TAHOMA) as FontAsset;
			regularFormat = fontAsset ? fontAsset.format : new TextFormat();
			regularFormat.size = 12;
			regularFormat.align = TextFormatAlign.CENTER;
			fontAsset = assetsManager.getAsset(AssetIDs.TAHOMA_BOLD) as FontAsset;
			boldFormat = fontAsset ? fontAsset.format : new TextFormat();
			boldFormat.size = 12;
			boldFormat.align = TextFormatAlign.CENTER;
		}
		
		private function initMainTextField():void {
			adBlockTF = new TextField();
			adBlockTF.defaultTextFormat = boldFormat;
			adBlockTF.background = true;
			adBlockTF.backgroundColor = AD_BLOCK_BGCOLOR;
			adBlockTF.text = AD_BLOCK_TEXT;
			adBlockTF.height = HEIGHT;
			adBlockTF.setTextFormat(boldFormat);
			adBlockTF.alpha = .8;
			adBlockTF.selectable = false;
		}
		
		private function initNewSecondsTextField():void {
			secondsTF = new TextField();
			secondsTF.alpha = .8;
			secondsTF.defaultTextFormat = regularFormat;
			secondsTF.height = HEIGHT;
			secondsTF.width = WIDTH;
			secondsTF.background = true;
			secondsTF.backgroundColor = SECONDS_IDLE_BGCOLOR;
			secondsTF.selectable = false;
			_timer.removeEventListener(TimerEvent.TIMER, renderSeconds);
			secondsLeft = _timer.repeatCount;
			_timer.addEventListener(TimerEvent.TIMER, renderSeconds);
			renderSeconds(null);
			_container.addChild(secondsTF);
		}
		
		/**
		* Run-time methods
		*/
		
		/**
		* Public interface
		*/
		
		public function startCountdown(delay:Number):void {
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, readyToWork);
			adBlockTF.removeEventListener(Event.ENTER_FRAME, correspondContainerSize);
			_timer.delay = 1000;
			_timer.repeatCount = int(delay / _timer.delay);
			if (delay > 0) {
				initNewSecondsTextField();
			}
			_container.addChild(adBlockTF);
			correspondContainerSize(null);
			adBlockTF.addEventListener(Event.ENTER_FRAME, correspondContainerSize);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, readyToWork);
			_timer.start();
		}
		
		/**
		* Event handlers
		*/
		
		
		private function correspondContainerSize(e:Event):void {
			adBlockTF.width = _container.width;
			if (secondsTF) {
				adBlockTF.width -= secondsTF.width;
				secondsTF.x = _container.width - secondsTF.width;
			}
		}
		
		private function renderSeconds(e:TimerEvent):void {
			secondsTF.text = DEFAULT_SECONDS_TEXT.split('|S|').join(secondsLeft--);
			secondsTF.setTextFormat(regularFormat);
		}
		
		private function readyToWork(e:TimerEvent):void {
			if (secondsTF) {
				secondsTF.removeEventListener(MouseEvent.ROLL_OVER, setOveredState);
				secondsTF.removeEventListener(MouseEvent.ROLL_OUT, setReadyState);
				secondsTF.text = READY_SECONDS_TEXT;
				secondsTF.setTextFormat(regularFormat);
				secondsTF.addEventListener(MouseEvent.ROLL_OVER, setOveredState);
				secondsTF.addEventListener(MouseEvent.ROLL_OUT, setReadyState);
				secondsTF.addEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
			}
		}
		
		private function setOveredState(e:MouseEvent):void {
			if (!secondsTF) { return; }
			Mouse.cursor = MouseCursor.BUTTON;
			var tf:TextFormat = secondsTF.defaultTextFormat;
			tf.color = 0x000000;
			secondsTF.setTextFormat(tf);
			secondsTF.backgroundColor = SECONDS_OVER_BGCOLOR;
		}
		
		private function setReadyState(e:MouseEvent):void {
			Mouse.cursor = MouseCursor.AUTO;
			if (!secondsTF) { return; }
			var tf:TextFormat = secondsTF.defaultTextFormat;
			tf.color = 0xFFFFFF;
			secondsTF.setTextFormat(tf);
			secondsTF.backgroundColor = SECONDS_IDLE_BGCOLOR;
		}
		
		private function processUserPassAdRequest(e:MouseEvent):void {
			secondsTF.removeEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
			e.updateAfterEvent();
			dispatchEvent(new Event(PASS_AD_REQUEST));
		}
		
		/**
		* Destructor
		*/
		
		public function kill():void {
			if (secondsTF && secondsTF.parent && secondsTF.parent == _container) {
				_container.removeChild(secondsTF);
			}
			if (adBlockTF && adBlockTF.parent && adBlockTF.parent == _container) {
				_container.removeChild(adBlockTF);
			}
			_timer.stop();
			_timer.reset();
			removeAllPossibeHandlers();
			
			secondsTF = null;
		}
		
		private function removeAllPossibeHandlers():void {
			_timer.removeEventListener(TimerEvent.TIMER, renderSeconds);
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, readyToWork);
			adBlockTF.removeEventListener(Event.ENTER_FRAME, correspondContainerSize);
			if (secondsTF) {
				secondsTF.removeEventListener(MouseEvent.ROLL_OVER, setOveredState);
				secondsTF.removeEventListener(MouseEvent.ROLL_OUT, setReadyState);
				secondsTF.removeEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
			}
		}
	}
}