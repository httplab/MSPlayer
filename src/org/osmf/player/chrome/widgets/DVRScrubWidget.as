package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.widgets.Seeker;
	import org.osmf.player.media.StrobeMediaPlayer;
	import org.osmf.player.metadata.MediaMetadata;

	public class DVRScrubWidget extends LiveScrubWidget {
		private var backDropRecorded:DisplayObject;
		private var backDropRecordedFace:String;
		private var seeker:Seeker;
		private var _seekTo:Number;
		private var _hintPosition:Number;
		private var positionContainer:Sprite;
		private var backDropLeft_position:DisplayObject;
		private var backDropMiddle_position:DisplayObject;
		private var backDropRight_position:DisplayObject;
		private var backDropLeftPositionFace:String;
		private var backDropMiddlePositionFace:String;
		private var backDropRightPositionFace:String;
		private var _positionMask:Sprite;
		
		public function DVRScrubWidget() {
			super();
			backDropLeftFace = AssetIDs.SCRUB_BAR_BLUE_LEFT;
			backDropMiddleFace = AssetIDs.SCRUB_BAR_BLUE_MIDDLE;
			backDropLeftProgramFace = AssetIDs.SCRUB_BAR_WHITE_LEFT;
			backDropMiddleProgramFace = AssetIDs.SCRUB_BAR_WHITE_MIDDLE;
			backDropRightProgramFace = AssetIDs.SCRUB_BAR_WHITE_RIGHT;
			backDropRecordedFace = AssetIDs.SCRUB_BAR_RECORDED_RIGHT;
			
			backDropLeftPositionFace = AssetIDs.SCRUB_BAR_SNOW_WHITE_LEFT;
			backDropMiddlePositionFace = AssetIDs.SCRUB_BAR_SNOW_WHITE_MIDDLE;
			backDropRightPositionFace = AssetIDs.SCRUB_BAR_SNOW_WHITE_RIGHT;
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			positionContainer = new Sprite();
			
			backDropRecorded = assetManager.getDisplayObject(backDropRecordedFace); 
			backDropRecorded.addEventListener(MouseEvent.MOUSE_DOWN, goToLive);
			backDropRecorded.visible = false;
			container.addChild(backDropRecorded);
			
			backDropLeft_position = assetManager.getDisplayObject(backDropLeftPositionFace); 
			backDropMiddle_position = assetManager.getDisplayObject(backDropMiddlePositionFace); 
			backDropRight_position = assetManager.getDisplayObject(backDropRightPositionFace); 
			
			positionContainer.addChild(backDropLeft_position);
			positionContainer.addChild(backDropMiddle_position);
			positionContainer.addChild(backDropRight_position);
			
			_positionMask = new Sprite();
			positionContainer.addChild(_positionMask);
			positionContainer.mask = _positionMask;
			
			addChild(container);
			addChild(programContainer);
			addChild(positionContainer)
			
			
			seeker = new Seeker();
			seeker.addEventListener(Seeker.SEEK_START, onSeekerStart);
			seeker.addEventListener(Seeker.SEEK_UPDATE, onSeekerUpdate);
			seeker.addEventListener(Seeker.SEEK_END, onSeekerEnd);
			addChild(seeker);
			
			addEventListener(MouseEvent.ROLL_OVER, callShowHint);
			addEventListener(MouseEvent.MOUSE_MOVE, callShowHint);
			addEventListener(MouseEvent.ROLL_OUT, callHideHint);
		}
		
		private function callShowHint(e:MouseEvent):void {
			if (mouseX / width <= 1) {
				_hintPosition = mouseX / width;
			} else {
				_hintPosition = 1 + (backDropLiveRight.width / width) / 2;
			}
			dispatchEvent(new Event(ScrubBar.SHOW_HINT_CALL));
		}
		
		private function callHideHint(e:MouseEvent):void {
			dispatchEvent(new Event(ScrubBar.HIDE_HINT_CALL));
		}
		
		private function goToLive(event:MouseEvent):void {
			if (!media) { return; }
			var mediaMetadata:MediaMetadata = media.metadata.getValue(MediaMetadata.ID) as MediaMetadata;
			var mediaPlayer:StrobeMediaPlayer = mediaMetadata.mediaPlayer;
			if (mediaPlayer.snapToLive()) {
				backDropRecorded.visible = false;
				playedPosition = NaN;
			}
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			super.layout(availableWidth, availableHeight, deep);
			backDropRecorded.x = backDropLiveRight.x;
			
			backDropMiddle_position.width = availableWidth - (backDropLeft.width + backDropLiveRight.width);
			
			backDropMiddle_position.x = backDropLeft_position.width;
			backDropRight_position.x = availableWidth - backDropLiveRight.width;
			
			seeker.point = new Point(width, height);
		}
		
		private function onSeekerStart(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PAUSE_CALL));
		}
		
		private function onSeekerUpdate(event:Event):void {
			_seekTo = seeker.position;
			dispatchEvent(new Event(ScrubBar.SEEK_CALL));
			backDropRecorded.visible = (_seekTo < 1);
		}
		
		private function onSeekerEnd(event:Event):void {
			dispatchEvent(new Event(ScrubBar.PLAY_CALL));
		}
		
		public function get seekTo():Number {
			return _seekTo;
		}
		
		public function removeHandlers():void {
			seeker.removeHandlers();
		}
		
		public function set playedPosition(value:Number):void {
			with (_positionMask.graphics) {
				clear();
				if(isNaN(value)) { return; }
				beginFill(0, 1);
				drawRect(value * width - 1, 0, 2, height);
				endFill();
			}
		}
		
		public function get hintPosition():Number {
			return _hintPosition;
		}
		
		public function get programText():String {
			if (hintPosition > 1) { return 'Live'; }
			if (!_programs || !_programs.length) { return ""; }
			var toReturn:String = "";
			var date:Date = new Date();
			date.setTime(date.time - (1 - _hintPosition) * thims);
			var minutes:String = String(date.getMinutes());
			var hours:String = String(date.getHours());
			minutes.length < 2 && (minutes = "0" + minutes);
			hours.length < 2 && (hours = "0" + hours);
			toReturn =  hours + ":" + minutes;
			//TODO: Вернуть, когда решат, где показывать название программы.
			//var maxPosition:Number = -20;
			//for each (var program:Object in _programs) {
				//if (_hintPosition < program.position) { continue; }
				//if (maxPosition < program.position) {
					//maxPosition = program.position;
					//var date:Date = new Date(program.start);
					//var minutes:String = String(date.getMinutes());
					//var hours:String = String(date.getHours());
					//minutes.length < 2 && (minutes = "0" + minutes);
					//hours.length < 2 && (hours = "0" + hours);
					//toReturn =  hours + ":" + minutes //+ "\n" + program.title;
				//}
			//}
			return toReturn;
		}
	}
}