package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	
	public class LiveScrubWidget extends Widget {
		private var backDropLeft:DisplayObject;
		private var backDropMiddle:DisplayObject;
		protected var backDropLiveRight:DisplayObject;
		private var backDropLeft_program:DisplayObject;
		private var backDropMiddle_program:DisplayObject;
		private var backDropRight_program:DisplayObject;
		protected var container:Sprite;
		private var programContainer:Sprite;
		private var _programMask:Sprite;
		protected var _programs:Array;
		private var programs:Array;
		
		protected var backDropLeftFace:String;
		protected var backDropMiddleFace:String;
		protected var backDropLiveRightFace:String;
		protected var backDropLeftProgramFace:String;
		protected var backDropMiddleProgramFace:String;
		protected var backDropRightProgramFace:String;
		
		public function LiveScrubWidget() {
			super();
			backDropLeftFace = AssetIDs.SCRUB_BAR_DARK_GRAY_LEFT;
			backDropMiddleFace = AssetIDs.SCRUB_BAR_DARK_GRAY_MIDDLE;
			backDropLiveRightFace = AssetIDs.SCRUB_BAR_LIVE_RIGHT;
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
			
			backDropLeft_program = assetManager.getDisplayObject(backDropLeftProgramFace); 
			backDropMiddle_program = assetManager.getDisplayObject(backDropMiddleProgramFace); 
			backDropRight_program = assetManager.getDisplayObject(backDropRightProgramFace); 
			
			container.addChild(backDropLeft);
			container.addChild(backDropMiddle);
			container.addChild(backDropLiveRight);
			
			programContainer.addChild(backDropLeft_program);
			programContainer.addChild(backDropMiddle_program);
			programContainer.addChild(backDropRight_program);
			_programMask = new Sprite();
			programContainer.mask = _programMask;
			programContainer.addChild(_programMask);
			
			addChild(container);
			addChild(programContainer);
			
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			backDropMiddle.width = availableWidth - (backDropLeft.width + backDropLiveRight.width);
			backDropMiddle_program.width = availableWidth - (backDropLeft_program.width + backDropLiveRight.width - backDropRight_program.width);
			
			backDropMiddle.x = backDropLeft.width;
			backDropLiveRight.x = availableWidth - backDropLiveRight.width;
			
			backDropMiddle_program.x = backDropLeft_program.width;
			backDropRight_program.x = availableWidth - backDropLiveRight.width;
		}
		
		public function set programPositions(value:Array):void {
			var thims:Number = (1000 * 3600 * 2);
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
			return container.width - backDropLiveRight.width + backDropLeft.width;
		}
		
		override public function get height():Number {
			return container.height;
		}
	}
}