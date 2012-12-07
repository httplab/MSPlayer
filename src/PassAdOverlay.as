package {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class PassAdOverlay extends Sprite {	
		static public const PASS_AD_REQUEST:String = "passAdRequest";
		
		private var _container:Sprite;
		private var _timer:Timer;
		private var passAdOverlay:Sprite;
		
		public function register(container:Sprite):void	{
			_container = container;
			_timer = new Timer(1,1);
			passAdOverlay = new Sprite();
			passAdOverlay.buttonMode = true;
			passAdOverlay.useHandCursor = true;
			passAdOverlay.addChild(new Bitmap(new ASSET_next_normal()));
		}
		
		public function startCountdown(delay:Number):void {
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, readyToWork);
			_timer.delay = delay;
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, readyToWork);
			_timer.start();
		}
		
		public function kill():void {
			if (passAdOverlay.parent && passAdOverlay.parent == _container) {
				_container.removeChild(passAdOverlay);
			}
			_timer.stop();
			_timer.reset();
			_timer.removeEventListener(TimerEvent.TIMER, readyToWork);
			passAdOverlay.removeEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
		}
		
		private function readyToWork(e:TimerEvent):void {
			_container.addChild(passAdOverlay);
			passAdOverlay.x = _container.width - passAdOverlay.width - 5;
			passAdOverlay.y = 5;
			passAdOverlay.addEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
		}
		
		private function processUserPassAdRequest(e:MouseEvent):void {
			passAdOverlay.removeEventListener(MouseEvent.MOUSE_DOWN, processUserPassAdRequest);
			e.updateAfterEvent();
			dispatchEvent(new Event(PASS_AD_REQUEST));
		}
	}
}