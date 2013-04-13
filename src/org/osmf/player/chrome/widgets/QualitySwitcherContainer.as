package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.media.MediaElement;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayTrait;
	import org.osmf.traits.SeekTrait;

	public class QualitySwitcherContainer extends Widget {
		private var upFace:String = "qualitySwitcherElementUp";
		private var overFace:String = "qualitySwitcherElementOver";
		private var backFace:String = "qualitySwitcherElementBack";
		
		private var currentFace:DisplayObject;
		private var mouseOver:Boolean;
		private var up:DisplayObject;
		private var over:DisplayObject;
		private var back:DisplayObject;
		private var currentIdx:int = 0;
		
		static public const STREAM_SWITCHED:String = "streamSwitched";
		private var _availableStreams:Array;
		
		
		public function QualitySwitcherContainer() {
			super();
			buttonMode = useHandCursor = true;
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			over = assetManager.getDisplayObject(upFace);
			back = assetManager.getDisplayObject(backFace);
			addEventListener(MouseEvent.ROLL_OVER, onHover);
			addEventListener(MouseEvent.ROLL_OUT, removeSelectBox);
		}
		
		private function removeSelectBox(e:MouseEvent):void {
			up && up.parent && (up.parent == this) && removeChild(up);
			e && e.updateAfterEvent();
		}
		
		public function registerQualities(availableStreams:Array):void {
			currentIdx = 0;
			_availableStreams = availableStreams.concat();
			recreateUpFace();
			over['tf'].text = _availableStreams[currentIdx];
			over['tf'].mouseEnabled = false;
			setFace(over);
			over.visible = true;
			enabled = true;
		}
		
		private function recreateUpFace():void {
			up = new Sprite();
			back = assetManager.getDisplayObject(backFace);
			for (var idx:String in _availableStreams) {
				var option:DisplayObject;
				if (int(idx) == currentIdx) {
					option = assetManager.getDisplayObject(overFace);
				} else {
					option = assetManager.getDisplayObject(upFace);
				}
				option['tf'].text = _availableStreams[idx];
				option['tf'].mouseEnabled = false;
				option['id'] = int(idx);
				option.y = up.height;
				option.addEventListener(MouseEvent.CLICK, selectQuality);
				(up as DisplayObjectContainer).addChild(option);
			}
			//TODO: Fix block jumping
			(up as DisplayObjectContainer).addChildAt(back,0);
			back.height = up.height + 2;
			up.y = -up.height;
		}
		
		private function selectQuality(e:MouseEvent):void {
			removeSelectBox(e);
			if (currentIdx == int(e.currentTarget.id)) { 
				e.preventDefault(); 
				e.stopImmediatePropagation(); 
				return; 
			}
			currentIdx = int(e.currentTarget.id);
			over['tf'].text = _availableStreams[currentIdx];
			dispatchEvent(new Event(STREAM_SWITCHED));
		}
		
		private function onHover(event:MouseEvent):void {
			if (up && up.parent) { return; }
			if (!media /*|| !(media.getTrait(MediaTraitType.SEEK) as SeekTrait)*/) { return; }
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
		
		override public function set y(value:Number):void {
			super.y = (parent.height - over.height) / 2;
		}
		
		override public function measure(deep:Boolean = true):void {
			removeSelectBox(null);
			super.measure();
		}
		
		public function get currentStreamIdx():int {
			return currentIdx;
		}
		
		override public function set media(value:MediaElement):void {
			super.media = value;
			if (media && media.metadata) {
				mouseChildren = mouseEnabled = !State.isAd();
				setSuperVisible(!State.isAd());
			}
		}		
	}
}