package org.osmf.player.chrome.widgets {
	import flash.display.Sprite;
	import org.osmf.player.chrome.assets.AssetsManager;
	
	public class HotkeysWidget extends Widget {
		private var back:Sprite;
		
		public function HotkeysWidget() {
			super();
		}
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			back = new ASSET_hotkeys_helper();
			addChild(back);
		}
		
		override public function set x(value:Number):void {
			parent && (super.x = (parent.width - back.width) / 2);
		}
		
		override public function set y(value:Number):void {
			parent && (super.y = (parent.height - back.height) / 2);
		}
	}
}