package {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class StreamQualitySwitcher extends Sprite {	
		static public const STREAM_SWITCHED:String = "passAdRequest";
		
		private var _container:Sprite;
		private var currentButton:MovieClip;
		private var bigContainer:Sprite;
		private var doubledButton:MovieClip;
		
		/**
		* Init-time methods
		*/
		
		//TODO: Переписать полностью, как один из элеметов ControlBarElement -> Widgets.
		
		public function register(container:Sprite):void {
			_container = container;
			bigContainer = new Sprite();
		}
		
		public function registerButtons(availableStreams:Object):void {
			for (var quality:String in availableStreams) {
				initStreamButton(quality, availableStreams[quality]);
			}
			doubledButton = new MovieClip();
			doubledButton.graphics.beginFill(0x383838, 5);
			doubledButton.graphics.drawRoundRect(0, 0, 40, 15, 4, 4);
			doubledButton.graphics.endFill();
			doubledButton.tf = new TextField();
			doubledButton.tf.defaultTextFormat = new TextFormat('Tahoma', 12, 0xffff00, true, null, null, null, null, TextFormatAlign.CENTER);
			doubledButton.tf.text = quality;
			doubledButton.tf.selectable = false;
			doubledButton.tf.background = true;
			doubledButton.tf.backgroundColor = 0x0000ff;
			doubledButton.tf.width = 40;
			doubledButton.tf.height = 20;
			doubledButton.addChild(doubledButton.tf);
			doubledButton.idx = availableStreams[quality];
		}
		
		private function initStreamButton(quality:String, streamUrl:String):void {
			var streamButton:MovieClip = new MovieClip();
			streamButton.graphics.beginFill(0x383838, 5);
			streamButton.graphics.drawRoundRect(0, 0, 40, 20, 4, 4);
			streamButton.graphics.endFill();
			streamButton.tf = new TextField();
			streamButton.tf.defaultTextFormat = new TextFormat('Tahoma', 12, 0xffff00, true, null, null, null, null, TextFormatAlign.CENTER);
			streamButton.tf.text = quality;
			streamButton.tf.background = true;
			streamButton.tf.width = 40;
			streamButton.tf.height = 20;
			streamButton.tf.selectable = false;
			streamButton.tf.backgroundColor = 0x383838;
			streamButton.addChild(streamButton.tf);
			streamButton.idx = streamUrl;
			streamButton.addEventListener(MouseEvent.MOUSE_DOWN, switchToStream);
			streamButton.y = - streamButton.height - bigContainer.height;
			currentButton = streamButton;
			bigContainer.addChild(streamButton);
		}
		
		private function switchToStream(e:MouseEvent):void {
			if (currentButton == e.currentTarget) { return; }
			if (currentButton) {
				currentButton.tf.backgroundColor = 0x383838;
			}
			currentButton = e.currentTarget as MovieClip;
			currentButton.tf.backgroundColor = 0x0000ff;
			doubledButton.tf.text = currentButton.tf.text;
			dispatchEvent(new Event(STREAM_SWITCHED));
			e.updateAfterEvent();
		}
		
		public function show():void {
			doubledButton.removeEventListener(MouseEvent.ROLL_OVER, showBig);
			bigContainer.removeEventListener(MouseEvent.ROLL_OUT, hideBig);
			_container.addChild(doubledButton);
			doubledButton.y = _container.height - doubledButton.height;
			doubledButton.x = 30;
			doubledButton.addEventListener(MouseEvent.ROLL_OVER, showBig);
			bigContainer.addEventListener(MouseEvent.ROLL_OUT, hideBig);
		}
		
		private function showBig(e:MouseEvent):void {
			bigContainer.y = doubledButton.y + doubledButton.height;
			bigContainer.x = doubledButton.x;
			_container.addChild(bigContainer);
			if (doubledButton.parent) {
				doubledButton.parent.removeChild(doubledButton);
			}
			
		}
		
		private function hideBig(e:MouseEvent):void {
			_container.addChild(doubledButton);
			if (bigContainer.parent) {
				bigContainer.parent.removeChild(bigContainer);
			}
		}
		
		public function get currentStreamIdx():int {
			return currentButton.idx;
		}
	}
}