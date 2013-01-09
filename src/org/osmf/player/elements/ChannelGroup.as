package org.osmf.player.elements {
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	public class ChannelGroup extends ASSET_ChannelGroup {
		static public const EXPAND_END:String = "expandEnd";
		static public const COLLAPSE_END:String = "collapseEnd";
		private var groupName:String;
		private var channels:Vector.<Channel>
		private var _mask:Sprite;
		private var boldFormat:TextFormat;
		private var _channelsContaner:Sprite;
		private var _tweener:Tweener;
		
		public function ChannelGroup(name:String) {
			initMask();
			setText(name);
			setHeight(groupNameTxt.textHeight);
			channels = new Vector.<Channel>();
			for (var i:int = 0; i < numChildren; i++) {
				(getChildAt(i) as InteractiveObject) && ((getChildAt(i) as InteractiveObject).mouseEnabled = false);
			}
			bg.mouseEnabled = true;
			bg.addEventListener(MouseEvent.ROLL_OVER, overHandler);
			bg.addEventListener(MouseEvent.ROLL_OUT, outHandler);
		}
		
		private function outHandler(event:MouseEvent):void {
			Mouse.cursor = MouseCursor.ARROW;
		}
		
		private function overHandler(event:MouseEvent):void {
			Mouse.cursor = MouseCursor.BUTTON;
		}
		
		private function setText(name:String):void {
			var tf:TextFormat = groupNameTxt.defaultTextFormat;
			groupNameTxt.text = name;
			tf.bold = true;
			groupNameTxt.setTextFormat(tf);
			groupNameTxt.width = Math.max(groupNameTxt.textWidth, groupNameTxt.width);
			switcher.x = groupNameTxt.x + groupNameTxt.textWidth + 10;
		}
		
		private function initMask():void {
			_channelsContaner = new Sprite();
			_mask = new Sprite();
			with (_mask.graphics) {
				beginFill(0, 0);
				drawRect(0, 0, 1, 1);
				endFill();
			}
			_mask.height = 0;
			_mask.mouseEnabled = false;
			_channelsContaner.mouseEnabled = false;
			_channelsContaner.mask = _mask;
			_channelsContaner.y = groupNameTxt.height;
		}
		
		public function addChannel(channelData:Object):Channel {
			var channel:Channel = new Channel((channelData.title || channelData.id), Boolean(channels.length % 2));
			channel.srcId = (channelData.title) ? (channelData.id) : (channelData.url.split('/#tv/')[1]);
			channel.access = channelData.access;
			channel.authAccess = channelData.auth_access;
			channels.push(channel);
			_mask.width = channel.width;
			channel.y = _channelsContaner.height;
			_channelsContaner.addChild(channel);
			return channel;
		}
		
		public function expand():void {
			_channelsContaner.addChild(_mask);
			addChild(_channelsContaner);
			switcher.gotoAndStop('opened');
			_tweener && _tweener.stop();
			_tweener = new Tweener(_mask, 'height', _channelsContaner.height, int(_channelsContaner.height / 15), expandIsDone);
		}
		
		private function expandIsDone():void { 
			dispatchEvent(new Event(EXPAND_END));
		} 
		
		public function collapse():void {
			_channelsContaner.addChild(_mask);
			addChild(_channelsContaner);
			_tweener && _tweener.stop();
			_tweener = new Tweener(_mask, 'height', 0, 7, collapseIsDone);
		}
		
		private function collapseIsDone():void { 
			switcher.gotoAndStop('closed');
			_mask.height = 0;
			removeChild(_channelsContaner);
			dispatchEvent(new Event(COLLAPSE_END));
		}
		
		private function setHeight(value:Number):void {
			groupNameTxt.height = value;
			groupNameTxt.y = 2;
			bg.height = value + 6;
			_channelsContaner.y = bg.height;
		}
		
		override public function get height():Number {
			return bg.height + _mask.height;
		}
	}
}