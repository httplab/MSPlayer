package org.osmf.player.chrome.widgets {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.ui.Mouse;

	public class Seeker extends Sprite {
		private var _position:Number;
		static public const SEEK_END:String = "seekEnd";
		static public const SEEK_UPDATE:String = "seekUpdate";
		static public const SEEK_START:String = "seekStart";
		
		public function Seeker() {
			addEventListener(MouseEvent.MOUSE_DOWN, startSeekHandler);
		}
		
		public function initJSHandlers():void {
			if (ExternalInterface.available) {
				ExternalInterface.addCallback('seekInDVR', seekFromJSHandler);
			}
		}
		
		private function seekFromJSHandler(offset:Number):void {
			setPosition(1 - (offset / 7200));
		}
		
		private function startSeekHandler(e:MouseEvent):void {
			Mouse.hide();
			addEventListener(MouseEvent.MOUSE_UP, stopSeekHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, stopSeekHandler);
			root.addEventListener(MouseEvent.ROLL_OUT, stopSeekHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, processSeekHandler);
			e && dispatchEvent(new Event(SEEK_START));
			e && processSeekHandler(e);
			e && e.updateAfterEvent();
		}
		
		private function stopSeekHandler(e:MouseEvent):void {
			Mouse.show();
			removeEventListener(MouseEvent.MOUSE_UP, stopSeekHandler);
			root.removeEventListener(MouseEvent.ROLL_OUT, stopSeekHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopSeekHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, processSeekHandler);
			e && processSeekHandler(e);
			e && dispatchEvent(new Event(SEEK_END));
			e && e.updateAfterEvent();
		}
		
		private function processSeekHandler(e:MouseEvent):void {
			setPosition((e.stageX - getBounds(stage).x) / width);
			e && e.updateAfterEvent();
		}
		
		public function set point(value:Point):void {
			with (graphics) {
				clear();
				beginFill(0, 0);
				drawRect(0, 0, value.x, value.y);
				endFill();
			}
		}
		
		public function removeHandlers():void {
			stopSeekHandler(null);
		}
		
		public function get position():Number{
			return _position;
		}
		
		private function setPosition(value:Number):void {
			_position = Math.min(Math.max(0, value), 1);
			dispatchEvent(new Event(SEEK_UPDATE));
		}
	}
}