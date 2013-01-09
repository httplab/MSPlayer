package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.elements.Channel;
	import org.osmf.player.elements.ChannelGroup;
	import ru.etcs.ui.MouseWheel;
	
	public class ChannelListDialog extends Widget {
		static private const SCROLL_SPEED:Number = 5;
		private var TOP_GAP:Number = 0;
		private var closeButton:Sprite;
		private var _content:Vector.<ChannelGroup>;
		private var _contentContainer:Sprite;
		private var _currentGroup:ChannelGroup;
		private var _animationInProgress:int = 0;
		private var back:ASSET_ChannelsListBack;
		private var _mask:Sprite;
		private var _dragger:MovieClip;
		private var _tweener:Tweener;
		private var _correctionTweener:Tweener;
		
		/**
		* Init-time methods
		*/
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			back = new ASSET_ChannelsListBack();
			addChild(back);
			TOP_GAP = back.titleText.y * 2 + back.titleText.textHeight;
			prepareContentContainer();
			prepareCloseButton();
			initDragger();
			super.configure(xml, assetManager);
			addEventListener(MouseEvent.ROLL_OVER, catchMouse);
			addEventListener(MouseEvent.ROLL_OUT, releaseMouse);
			addEventListener(MouseEvent.MOUSE_WHEEL, scrollContent);
		}
		
		private function prepareContentContainer():void {
			_contentContainer = new Sprite();
			_contentContainer.y = TOP_GAP;
			_mask = new Sprite();
			with (_mask.graphics) {
				beginFill(0, 0);
				drawRect(0, TOP_GAP, back.width - 15, back.height - (TOP_GAP) - 6);
				endFill();
			}
			_contentContainer.mask = _mask;
			addChild(_mask);
			addChild(_contentContainer);
		}
		
		private function initDragger():void {
			_dragger = new ASSET_ChannelsListDragger();
			_dragger.visible = false;
			_dragger.x = _mask.width;
			_dragger.y = TOP_GAP;
			addChild(_dragger);
			_dragger.addEventListener(MouseEvent.MOUSE_DOWN, startDraggerActions);
		}
		
		private function prepareCloseButton():void {
			closeButton = back.closeButton;
			closeButton.mouseChildren = false;
			closeButton.buttonMode = true;
			closeButton.addEventListener(MouseEvent.CLICK, onCloseButtonClick);
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
				channelGroup.removeEventListener(ChannelGroup.COLLAPSE_END, channelGroupCollapseEndHandler);
				channelGroup.removeEventListener(ChannelGroup.EXPAND_END, channelGroupExpandEndHandler);
				channelGroup.removeEventListener(MouseEvent.MOUSE_DOWN, doExpand);
				channelGroup.addEventListener(ChannelGroup.COLLAPSE_END, channelGroupCollapseEndHandler);
				channelGroup.addEventListener(ChannelGroup.EXPAND_END, channelGroupExpandEndHandler);
				channelGroup.addEventListener(MouseEvent.MOUSE_DOWN, doExpand);
				channelGroup.y = _contentContainer.height;
				_contentContainer.addChild(channelGroup);
			}
			validateNow();
			checkForDraggerAvailability();
			_contentContainer.removeEventListener(Event.EXIT_FRAME, enterFrameHandler);
			_contentContainer.addEventListener(Event.EXIT_FRAME, enterFrameHandler);
		}
		
		/**
		* User actions' handlers
		*/
		
		private function startDraggerActions(e:MouseEvent):void {
			if (_animationInProgress) { return; }
			_dragger.stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraggerActions);
			_dragger.stage.addEventListener(MouseEvent.MOUSE_UP, stopDraggerActions);
			_dragger.startDrag(false, new Rectangle(_dragger.x, TOP_GAP, 0, maxDragY - TOP_GAP));
			_dragger.stage.addEventListener(MouseEvent.MOUSE_MOVE, moveChannelList);
			_dragger.stage.addEventListener(MouseEvent.ROLL_OUT, stopDraggerActions);
		}
		
		private function moveChannelList(e:MouseEvent):void {
			var maxListDeltaY:Number = maxListY - TOP_GAP;
			var maxDragDeltaY:Number = maxDragY - TOP_GAP;
			var currentDragDeltaY:Number = _dragger.y - TOP_GAP;
			var currentListDeltaY:Number = maxListDeltaY * currentDragDeltaY / maxDragDeltaY;
			_contentContainer.y = currentListDeltaY + TOP_GAP;
		}
		
		private function stopDraggerActions(e:MouseEvent):void {
			e.preventDefault();
			e.stopImmediatePropagation();
			_dragger.stopDrag();
			_dragger.stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraggerActions);
			_dragger.stage.removeEventListener(MouseEvent.ROLL_OUT, stopDraggerActions);
			_dragger.stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveChannelList);
		}
		
		private function scrollContent(e:MouseEvent):void {
			_contentContainer.y += SCROLL_SPEED * e.delta;
			honorBorders();
			checkForDraggerAvailability();
			e.preventDefault();
		}
		
		private function onCloseButtonClick(e:MouseEvent):void {
			e && e.updateAfterEvent();
			dispatchEvent(new Event(ChannelListButton.LIST_CALL));
		}
		
		private function doExpand(e:MouseEvent):void {
			if (e.target is Channel) { return; }
			currentGroup = (e.currentTarget as ChannelGroup);
		}
		
		private function channelGroupExpandEndHandler(e:Event):void {
			channelGroupAnimationEndHandler(e);
		}
		
		private function channelGroupCollapseEndHandler(e:Event):void {
			if (_currentGroup) {
				_tweener && _tweener.stop();
				_tweener = new Tweener(_contentContainer, 'y', TOP_GAP - (_content.indexOf(_currentGroup) * _currentGroup.height), 10);
				_currentGroup.expand();
				_animationInProgress++;
			}
			channelGroupAnimationEndHandler(e);
		}
		
		
		private function channelGroupAnimationEndHandler(e:Event):void {
			_animationInProgress--;
			checkForDraggerAvailability();
		}
		
		/**
		* Stuff
		*/
		
		private function enterFrameHandler(e:Event):void {
			for (var i:int = 1; i < _content.length; i++) {
				_content[i].y = _content[i - 1].y + _content[i - 1].height;
			}
			honorBorders();
			checkForDraggerAvailability();
		}
		
		private function set currentGroup(value:ChannelGroup):void {
			_tweener && _tweener.stop();
			if (!_currentGroup) {
				_currentGroup = value;
				channelGroupCollapseEndHandler(null);
				return;
			} 
			_currentGroup.collapse();
			_animationInProgress++;
			_tweener = new Tweener(_contentContainer, 'y', TOP_GAP, 10);
			if (_currentGroup != value) {
				_currentGroup = value;
			} else {
				_currentGroup = null;
			}
		}
		
		private function honorBorders():void {
			_contentContainer.y = Math.max(_contentContainer.y, maxListY);
			_contentContainer.y = Math.min(_contentContainer.y, TOP_GAP);
			_dragger.y = Math.min(_dragger.y, maxDragY - TOP_GAP);
			_dragger.y = Math.max(_dragger.y, 0);
		}
		
		private function get maxListY():Number {
			return _mask.height - _contentContainer.height + TOP_GAP;
		}
		
		private function get maxDragY():Number {
			return _mask.height - _dragger.height + TOP_GAP;
		}
		
		private function checkForDraggerAvailability():void {
			_dragger.visible = (_contentContainer.height > _mask.height);
			if (!_dragger.visible) { return; }
			var maxListDeltaY:Number = maxListY - TOP_GAP;
			var maxDragDeltaY:Number = maxDragY - TOP_GAP;
			var currentListDeltaY:Number = _contentContainer.y - TOP_GAP;
			var currentDragDeltaY:Number = maxDragDeltaY * currentListDeltaY / maxListDeltaY;
			_dragger.y = currentDragDeltaY + TOP_GAP;
		}
		
		private function catchMouse(e:MouseEvent):void {
			MouseWheel.capture();
		}
		
		private function releaseMouse(e:MouseEvent):void {
			MouseWheel.release();
		}
		
		/**
		* OSMF vs. Developers fight
		*/
		
		override public function set x(value:Number):void {
			parent && (super.x = (parent.width - back.width) / 2);
		}
		
		override public function set y(value:Number):void {
			parent && (super.y = (parent.height - back.height) / 2);
		}
		
		override public function measure(deep:Boolean = true):void {
			//OSMF, respect my width/height overrides!
			return;
		}
		
		override public function set height(value:Number):void {
			//TODO: Handle shrinking for little containers
			return;
		}
	}
}