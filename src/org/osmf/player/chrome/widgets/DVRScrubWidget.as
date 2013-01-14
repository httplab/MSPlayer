package org.osmf.player.chrome.widgets {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import org.osmf.player.chrome.assets.AssetIDs;

	public class DVRScrubWidget extends LiveScrubWidget {
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
			backDropLeftFace = AssetIDs.SCRUB_BAR_BLUE_LEFT;
			backDropMiddleFace = AssetIDs.SCRUB_BAR_BLUE_MIDDLE;
			backDropRightFace = AssetIDs.SCRUB_BAR_BLUE_RIGHT;
			backDropLeftProgramFace = AssetIDs.SCRUB_BAR_WHITE_LEFT;
			backDropMiddleProgramFace = AssetIDs.SCRUB_BAR_WHITE_MIDDLE;
			backDropRightProgramFace = AssetIDs.SCRUB_BAR_WHITE_RIGHT;
		}
	}
}