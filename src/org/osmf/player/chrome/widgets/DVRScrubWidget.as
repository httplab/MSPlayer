package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;

	public class DVRScrubWidget extends Widget {
		private var backDropLeft:DisplayObject;
		private var backDropMiddle:DisplayObject;
		private var backDropRight:DisplayObject;
		private var backDropLeft_program:DisplayObject;
		private var backDropMiddle_program:DisplayObject;
		private var backDropRight_program:DisplayObject;
		private var container:Sprite;
		private var programContainer:Sprite;
		private var _programMask:Sprite;
		
		public function DVRScrubWidget() {
			super();
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			container = new Sprite();
			programContainer = new Sprite();
			
			backDropLeft = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_LEFT); 
			backDropMiddle = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_MIDDLE); 
			backDropRight = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_BLUE_RIGHT); 
			
			backDropLeft_program = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_LEFT); 
			backDropMiddle_program = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_MIDDLE); 
			backDropRight_program = assetManager.getDisplayObject(AssetIDs.SCRUB_BAR_WHITE_RIGHT); 
			
			container.addChild(backDropLeft);
			container.addChild(backDropMiddle);
			container.addChild(backDropRight);
			
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
			if (availableWidth + availableHeight == 0) { return;}
			backDropMiddle.width = availableWidth - (backDropLeft.width + backDropRight.width);
			backDropMiddle_program.width = availableWidth - (backDropLeft_program.width + backDropRight_program.width);
			
			backDropMiddle.x = backDropLeft.width;
			backDropRight.x = availableWidth - backDropRight.width;
			
			backDropMiddle_program.x = backDropLeft_program.width;
			backDropRight_program.x = availableWidth - backDropRight_program.width;
		}
		
		public function set programPositions(value:Array):void {
			with (_programMask.graphics) {
				clear();
				for (var i:int = 0; i < value.length; i++){
					beginFill(0, 1);
					drawRect(value * width, 0, value[i] * 2, height);
					endFill();
				}
			}
		}
		
		override public function get width():Number {
			return Math.max(container.width, programContainer.width);
		}
		
		override public function get height():Number {
			return Math.max(container.height, programContainer.height);
		}
	}
}