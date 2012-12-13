package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.player.chrome.assets.AssetsManager;

	public class QualitySwitcherContainer extends Widget {
		private var upFace:String = "qualitySwitcherElementUp";
		private var overFace:String = "qualitySwitcherElementOver";
		
		private var currentFace:DisplayObject;
		private var mouseOver:Boolean;
		private var up:DisplayObject;
		private var over:DisplayObject;
		private var currentIdx:int = 0;
		
		static public const STREAM_SWITCHED:String = "streamSwitched";
		private var _availableStreams:Array;
		
		public function QualitySwitcherContainer() {
			super();
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			over = assetManager.getDisplayObject(overFace);
			addEventListener(MouseEvent.CLICK, onMouseClick);
			addEventListener(MouseEvent.ROLL_OUT, removeSelectBox);
		}
		
		private function removeSelectBox(e:MouseEvent):void {
			up && up.parent && (up.parent == this) && removeChild(up);
			e.updateAfterEvent();
		}
		
		public function registerQualities(availableStreams:Array):void {
			_availableStreams = availableStreams.concat();
			recreateUpFace();
			over['tf'].text = _availableStreams[currentIdx];
			setFace(over);
			over.visible = true;
			enabled = true;
			useHandCursor = true;
			buttonMode = true;
		}
		
		private function recreateUpFace():void {
			up = new Sprite();
			for (var idx:String in _availableStreams) {
				var option:DisplayObject;
				if (int(idx) == currentIdx) {
					option = assetManager.getDisplayObject(overFace);
				} else {
					option = assetManager.getDisplayObject(upFace);
				}
				option['tf'].text = _availableStreams[idx];
				option['id'] = int(idx);
				option.y = up.height;
				option.addEventListener(MouseEvent.CLICK, selectQuality);
				(up as DisplayObjectContainer).addChild(option);
			}
			//TODO: Fix block jumping
			up.y = -up.height;
		}
		
		private function selectQuality(e:MouseEvent):void {
			up && up.parent && (up.parent == this) && removeChild(up);
			e.updateAfterEvent();
			if (currentIdx == int(e.currentTarget.id)) { e.preventDefault(); e.stopImmediatePropagation(); return; }
			currentIdx = int(e.currentTarget.id);
			over['tf'].text = _availableStreams[currentIdx];
			dispatchEvent(new Event(STREAM_SWITCHED));
		}
		
		private function onMouseClick(event:MouseEvent):void {
			recreateUpFace();
			addChild(up);
			event.updateAfterEvent();
		}
		
		private function setFace(face:DisplayObject):void {
			if (currentFace != face) {
				if (currentFace != null) {
					removeChild(currentFace);
				}
				currentFace = face;
				if (currentFace != null) {
					addChildAt(currentFace, 0);
					width = currentFace.width;
					height = currentFace.height;
				}
			}
		}
		
		public function get currentStreamIdx():int {
			return currentIdx;
		}
	}
}