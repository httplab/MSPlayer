package org.osmf.player.chrome.widgets {
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.elements.Channel;
	import org.osmf.player.elements.ChannelGroup;
	import ru.etcs.ui.MouseWheel;
	
	public class ChannelListDialog extends Widget {
		static private const SCROLL_SPEED:Number = 5;
		private var TOP_GAP:Number = 0;
		private var closeButton:ButtonWidget;
		private var _content:Vector.<ChannelGroup>;
		private var _contentContainer:Sprite;
		private var _currentGroup:ChannelGroup;
		private var _currentChannel:Channel;
		private var back:ASSET_ChannelsListBack;
		private var _mask:Sprite;
		private var _dragger:MovieClip;
		private var _tweener:Tweener;
		private var _correctionTweener:Tweener;
		private var _arrowsContainer:Sprite;
		private var _leftArrow:Sprite;
		private var _rightArrow:Sprite;
		private var _isHided:Boolean;
		
		/**
		* Init-time methods
		*/
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			back = new ASSET_ChannelsListBack();
			addChild(back);
			TOP_GAP = back.titleText.y * 2 + back.titleText.textHeight;
			prepareContentContainer();
			prepateArrowsContainer();
			prepareCloseButton();
			closeButton.configure(xml, assetManager);
			closeButton.x = back.width - 35;
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
		
		private function prepateArrowsContainer():void {
			_arrowsContainer = new Sprite();
			_leftArrow = new Sprite();
			_rightArrow = new Sprite();
			_leftArrow.addChild(new Bitmap(new ASSET_previous_channel()));
			_rightArrow.addChild(new Bitmap(new ASSET_next_channel()));
			_arrowsContainer.addChild(_leftArrow);
			_arrowsContainer.addChild(_rightArrow);
			_leftArrow.addEventListener(MouseEvent.MOUSE_DOWN, selectPreviousChannel);
			_rightArrow.addEventListener(MouseEvent.MOUSE_DOWN, selectNextChannel);
			_leftArrow.buttonMode = true;
			_rightArrow.buttonMode = true;
			_leftArrow.useHandCursor = true;
			_rightArrow.useHandCursor = true;
			addChild(_arrowsContainer);
		}
		
		private function selectPreviousChannel(e:MouseEvent):void {
			_currentChannel.previousChannel.dispatchEvent(e);
		}
		
		private function selectNextChannel(e:MouseEvent):void {
			_currentChannel.nextChannel.dispatchEvent(e);
		}
		
		private function initDragger():void {
			_dragger = new ASSET_ChannelsListDragger();
			_dragger.visible = false;
			_dragger.x = _mask.width;
			_dragger.y = TOP_GAP;
			addChild(_dragger);
			_dragger.addEventListener(MouseEvent.MOUSE_DOWN, startDraggerActions);
			_dragger.addEventListener(MouseEvent.ROLL_OVER, draggerOverHandler);
			_dragger.addEventListener(MouseEvent.ROLL_OUT, draggerOutHandler);
		}
		
		private function prepareCloseButton():void {
			closeButton = new ButtonWidget();
			closeButton.id = WidgetIDs.CLOSE_BUTTON;
			closeButton.upFace = AssetIDs.AUTH_CANCEL_BUTTON_NORMAL;
			closeButton.overFace = AssetIDs.AUTH_CANCEL_BUTTON_OVER;
			closeButton.downFace = AssetIDs.AUTH_CANCEL_BUTTON_DOWN;
			addChild(closeButton);
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
		
		private function draggerOutHandler(event:MouseEvent):void {
			Mouse.cursor = MouseCursor.ARROW;
		}
		
		private function draggerOverHandler(event:MouseEvent):void {
			Mouse.cursor = MouseCursor.BUTTON;
		}
		
		private function startDraggerActions(e:MouseEvent):void {
			_dragger.stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraggerActions);
			_dragger.removeEventListener(MouseEvent.ROLL_OUT, draggerOutHandler);
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
			_dragger.addEventListener(MouseEvent.ROLL_OUT, draggerOutHandler);
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
			dispatchEvent(new Event(ChannelListButton.LIST_CLOSE_CALL));
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
			}
			channelGroupAnimationEndHandler(e);
		}
		
		
		private function channelGroupAnimationEndHandler(e:Event):void {
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
			parent && placeArrows();
		}
		
		override public function set y(value:Number):void {
			parent && (super.y = (parent.height - back.height) / 2);
			parent && placeArrows();
		}
		
		override public function measure(deep:Boolean = true):void {
			//OSMF, respect my width/height overrides!
			return;
		}
		
		public function showDialog():void {
			x = 0;
			y = 0;
			_contentContainer.visible = !_isHided;
			back.visible = !_isHided;
			closeButton.visible = !_isHided;
			_arrowsContainer.visible = false;
		}
		
		public function showArrows():void {
			_contentContainer.visible = false;
			back.visible = false;
			closeButton.visible = false;
			_arrowsContainer.visible = !_isHided;
			parent && placeArrows();
		}
		
		private function placeArrows():void {
			_leftArrow.x = -parent.width / 2;
			_rightArrow.x = parent.width / 2 - _rightArrow.width;
			_arrowsContainer.x = back.width / 2;
			_arrowsContainer.y = (back.height - _arrowsContainer.height) / 2;
		}
		
		public function show():void {
			_isHided = false;
			showArrows();
		}
		
		public function hide():void {
			_isHided = true;
			_contentContainer.visible = false;
			back.visible = false;
			closeButton.visible = false;
			_arrowsContainer.visible = false;
		}
		
		override public function set height(value:Number):void {
			//TODO: Handle shrinking for little containers
			return;
		}
		
		public function set currentChannel(value:Channel):void {
			_currentChannel = value;
		}		
	}
}