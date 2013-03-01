package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.utils.Timer;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	
	public class LiveScrubWidget extends Widget {
		protected var backDropLeft:DisplayObject;
		private var backDropMiddle:DisplayObject;
		protected var backDropLiveRight:DisplayObject;
		protected var backDropLiveCollapsedRight:DisplayObject;
		private var backDropLeft_program:DisplayObject;
		private var backDropMiddle_program:DisplayObject;
		private var backDropRight_program:DisplayObject;
		protected var container:Sprite;
		protected var programContainer:Sprite;
		protected var _programs:Array;
		private var _programMask:Sprite;
		private var _programsShiftTimer:Timer;

		protected var _isExpanded:Boolean;
		protected var backDropLeftFace:String;
		protected var backDropMiddleFace:String;
		protected var backDropLiveRightFace:String;
		protected var backDropLiveCollapsedRightFace:String;
		protected var backDropLeftProgramFace:String;
		protected var backDropMiddleProgramFace:String;
		protected var backDropRightProgramFace:String;
		public static const TWO_HOURS_IN_MILLISECONDS:Number = (1000 * 3600 * 2);
		
		public function LiveScrubWidget() {
			super();
			backDropLeftFace = AssetIDs.SCRUB_BAR_DARK_GRAY_LEFT; 	
			backDropMiddleFace = AssetIDs.SCRUB_BAR_DARK_GRAY_MIDDLE;
			backDropLiveRightFace = AssetIDs.SCRUB_BAR_LIVE_RIGHT;
			backDropLiveCollapsedRightFace = AssetIDs.SCRUB_BAR_LIVE_COLLAPSED_RIGHT;
			backDropLeftProgramFace = AssetIDs.SCRUB_BAR_GRAY_LEFT;
			backDropMiddleProgramFace = AssetIDs.SCRUB_BAR_GRAY_MIDDLE;
			backDropRightProgramFace = AssetIDs.SCRUB_BAR_GRAY_RIGHT;
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			container = new Sprite();
			programContainer = new Sprite();
			
			container.mouseEnabled = programContainer.mouseEnabled = false;
			
			backDropLeft = assetManager.getDisplayObject(backDropLeftFace); 
			backDropMiddle = assetManager.getDisplayObject(backDropMiddleFace); 
			backDropLiveRight = assetManager.getDisplayObject(backDropLiveRightFace); 
			backDropLiveCollapsedRight = assetManager.getDisplayObject(backDropLiveCollapsedRightFace); 
			backDropLiveCollapsedRight.visible = false;
			backDropLeft_program = assetManager.getDisplayObject(backDropLeftProgramFace); 
			backDropMiddle_program = assetManager.getDisplayObject(backDropMiddleProgramFace); 
			backDropRight_program = assetManager.getDisplayObject(backDropRightProgramFace); 
			
			container.addChild(backDropLeft);
			container.addChild(backDropMiddle);
			container.addChild(backDropLiveRight);
			container.addChild(backDropLiveCollapsedRight);
			
			programContainer.addChild(backDropLeft_program);
			programContainer.addChild(backDropMiddle_program);
			programContainer.addChild(backDropRight_program);
			_programMask = new Sprite();
			programContainer.mask = _programMask;
			programContainer.addChild(_programMask);
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			backDropMiddle.x = backDropLeft.width;
			backDropMiddle_program.x = backDropLeft_program.width;
			
			if (_isExpanded) {
				backDropMiddle.width = availableWidth - (backDropLeft.width + backDropLiveRight.width);
				backDropMiddle_program.width = availableWidth - (backDropLeft_program.width + backDropLiveRight.width - backDropRight_program.width);
				backDropLiveRight.x = availableWidth - backDropLiveRight.width;
				backDropRight_program.x = availableWidth - backDropLiveRight.width;
			} else {
				backDropMiddle.width = availableWidth - (backDropLeft.width + backDropLiveCollapsedRight.width);
				backDropMiddle_program.width = availableWidth - (backDropLeft_program.width + backDropLiveCollapsedRight.width - backDropRight_program.width);
				backDropLiveCollapsedRight.x = availableWidth - backDropLiveCollapsedRight.width;
				backDropRight_program.x = availableWidth - backDropLiveCollapsedRight.width;
			}
			
			recreateProgramsShiftTimer();
			_programs && (programPositions = _programs);
		}
		
		private function recreateProgramsShiftTimer():void {
			if (_programsShiftTimer) {
				_programsShiftTimer.stop();
				_programsShiftTimer.reset();
				_programsShiftTimer = null;
			}
			_programsShiftTimer = new Timer(thims / width, 0);
			_programsShiftTimer.addEventListener(TimerEvent.TIMER, shiftPrograms);
			_programsShiftTimer.start();
		}
		
		private function shiftPrograms(e:TimerEvent):void {
			_programs && (programPositions = _programs);
		}
		
		public function set programPositions(value:Array):void {
			var currentDate:Date = new Date();
			var twoHoursAgo:Date = new Date(currentDate.valueOf() - thims);
			_programs = value;
			for each (var shedule:Object in value) {
				var diff:Number = shedule.start - twoHoursAgo.valueOf();
				shedule.position = diff / thims;
			}
			var i:int;
			with (_programMask.graphics) {
				clear();
				for (i = 0; i < value.length; i++) {
					if (_programs[i].position > 1 || _programs[i].position < 0) { continue; }
					beginFill(0, 1);
					drawRect(int(20 * _programs[i].position * width)/20, 0, 2, height);
					endFill();
				}
			}
		}
		
		override public function get width():Number {
			return container.width - backDropLiveRight.width;
		}
		
		override public function get height():Number {
			return container.height;
		}
		
		protected function get thims():Number {
			return TWO_HOURS_IN_MILLISECONDS;
		}
		
		public function set isExpanded(value:Boolean):void {
			_isExpanded = value;
			if (_isExpanded) {
				backDropLiveRight.visible = true;
				backDropLiveCollapsedRight.visible = false;
			} else {
				backDropLiveRight.visible = false;
				backDropLiveCollapsedRight.visible = true;
			}
		}
	}
}