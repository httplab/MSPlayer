package org.osmf.player.chrome.widgets {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.elements.ChannelGroup;
	public class ChannelListDialog extends Widget {
		
		private var closeButton:ButtonWidget;
		private var _content:Vector.<ChannelGroup>;
		private var _contentContainer:Sprite;
		private var _currentGroup:ChannelGroup;
		private var _animationInProgress:int = 0;
		private var back:Sprite;
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			back = new ASSET_ChannelsListBack();
			addChild(back);
			_contentContainer = new Sprite();
			addChild(_contentContainer);
			super.configure(xml, assetManager);
			closeButton = getChildWidget(WidgetIDs.CHANNEL_LIST_CLOSE_BUTTON) as ButtonWidget;
			closeButton.addEventListener(MouseEvent.CLICK, onCloseButtonClick);
			addChild(closeButton);
		}
		
		public function show():void {
			visible = true;
		}
		
		public function close():void {
			visible = false;
		}
		
		public function set content(value:Vector.<ChannelGroup>):void {
			var channelGroup:ChannelGroup;
			if (_content) {
				for each (channelGroup in _content) {
					_contentContainer.removeChild(channelGroup);
				}
			}
			_content = value;
			for each (channelGroup in value) {
				channelGroup.removeEventListener(ChannelGroup.ANIMATION_END, channelGroupAnimationEndHandler);
				channelGroup.removeEventListener(MouseEvent.MOUSE_DOWN, doExpand);
				channelGroup.addEventListener(ChannelGroup.ANIMATION_END, channelGroupAnimationEndHandler);
				channelGroup.addEventListener(MouseEvent.MOUSE_DOWN, doExpand);
				channelGroup.y = _contentContainer.height;
				_contentContainer.addChild(channelGroup);
			}
			validateNow();
			_contentContainer.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			_contentContainer.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function onCloseButtonClick(e:MouseEvent):void {
			e && e.updateAfterEvent();
			close();
		}
		
		private function set currentGroup(value:ChannelGroup):void {
			if (_currentGroup) { 
				_currentGroup.collapse();
				_animationInProgress++;
			}
			if (_currentGroup == value) { _currentGroup = null; return; }
			_currentGroup = value;
			if (_currentGroup) {
				_currentGroup.expand();
				_animationInProgress++;
			}
		}
		
		private function doExpand(e:MouseEvent):void {
			currentGroup = (e.currentTarget as ChannelGroup);
		}
		
		private function channelGroupAnimationEndHandler(e:Event):void {
			_animationInProgress--;
		}
		
		override public function set x(value:Number):void {
			parent && (super.x = (parent.width - back.width) / 2);
		}
		
		override public function set y(value:Number):void {
			parent && (super.y = (parent.height - back.height) / 2);
		}
		
		private function enterFrameHandler(e:Event):void {
			//if (!_animationInProgress) { return; }
			for (var i:int = 1; i < _content.length; i++) {
				_content[i].y = _content[i - 1].y + _content[i - 1].height;
			}
		}
	}
}