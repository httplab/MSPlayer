package {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	public class Tweener {
		private var _obj:Object;
		private var _paramName:String;
		private var _endValue:Number;
		private var _frames:Number;
		private var eventDispatcher:IEventDispatcher;
		private var increment:Number;
		private var currentValue:Number;
		private var _callBack:Function;
		
		public function Tweener(obj:Object, paramName:String, endValue:Number, frames:Number, callBack:Function = null) {
			_callBack = callBack;
			_obj = obj;
			_paramName = paramName;
			_endValue = endValue;
			_frames = frames;
			currentValue = Number(obj[paramName]);
			increment = (endValue - Number(obj[paramName]))/frames;
			eventDispatcher = new Shape();
			eventDispatcher.addEventListener(Event.ENTER_FRAME, tween);
			if (obj is DisplayObjectContainer) {
				(obj as DisplayObjectContainer).addChild(eventDispatcher as DisplayObject);
			}
		}
		
		public function stop():void {
			eventDispatcher.removeEventListener(Event.ENTER_FRAME, tween);
		}
	 
		private function tween(e:Event):void {
			if (_frames == 0) {
				e.currentTarget.removeEventListener(e.type, tween);
				_obj[_paramName] = _endValue;
				if (_callBack != null) { 
					_callBack.call();
				}
				return;
			}
			currentValue += increment;
			_obj[_paramName] = currentValue;
			_frames--;
		}
	}
}