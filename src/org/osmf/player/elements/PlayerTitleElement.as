package org.osmf.player.elements {
	import flash.display.DisplayObject;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.media.MediaElement;
	import org.osmf.player.chrome.ChromeProvider;
	import org.osmf.player.chrome.widgets.TitleWidget;
	import org.osmf.player.chrome.widgets.Widget;
	import org.osmf.traits.DisplayObjectTrait;
	import org.osmf.traits.MediaTraitType;
	
	/**
	* ControlBarElement defines a MediaElement implementation which contains the ControlBar UI.
	*/ 

	public class PlayerTitleElement extends MediaElement {
		private var _target:MediaElement;
		private var playerTitle:TitleWidget;
		private var chromeProvider:ChromeProvider;
		
		public function PlayerTitleElement():void {
			super();
		}
		
		/**
		* Defines if the control bar should automatically hide itself
		*  
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/
		public function set autoHide(value:Boolean):void {
			playerTitle.autoHide = value;
		}
		
		public function get autoHide():Boolean {
			return playerTitle.autoHide;
		}
		
		/**
		* Defines the number of milliseconds of idleness required before the
		* control bar should hide (if autoHide is enabled).
		* 
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/		
		public function set autoHideTimeout(value:int):void {
			playerTitle.autoHideTimeout = value;
		}
		
		/**
		* Defines the target media element that this control bar operates on.
		*  
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/
		public function set target(value:MediaElement):void {
			_target = value;
			// Forward the set target to the inner control bar:
			playerTitle.media = _target;
		}				
		
		/**
		* Defines the tint color to aply to the control bar's background.
		*  
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/
		public function set tintColor(value:uint):void {
			playerTitle.tintColor = value;
		}
		
		/**
		* Defines the control bar's width.
		* 
		* Should only be set when dynamically sizing the control bar is
		* required, for example when it's size is relative to the parent
		* container.
		*  
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/
		
		public function set width(value:int):void{
			playerTitle.width = value;
			playerTitle.measure();
			playerTitle.layout(value, height);
		}
		
		public function get width():int {
			return playerTitle.width;
		}
		
		/**
		* Defines the control bar's height.
		*  
		*  @langversion 3.0
		*  @playerversion Flash 10
		*  @playerversion AIR 1.5
		*  @productversion OSMF 1.0
		*/
		
		public function get height():int {
			return playerTitle.height;
		}
		
		public function get visible():Boolean {
			return playerTitle.visible;
		}
		
		public function set visible(value:Boolean):void {
			playerTitle.visible = value;
		}
		
		override protected function setupTraits():void {
			// Setup a control bar using the embedded ChromeProvider:
			chromeProvider = ChromeProvider.getInstance();
			
			playerTitle = chromeProvider.createPlayerTitle();
			
			// Use the control bar's layout metadata as the element's layout metadata:
			addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, playerTitle.layoutMetadata);
			
			// Signal that this media element is viewable: create a DisplayObjectTrait.
			// Assign controlBar (which is a Sprite) to be our view's displayObject.
			// Additionally, use its current width and height for the trait's mediaWidth
			// and mediaHeight properties:
			var viewable:DisplayObjectTrait = new DisplayObjectTrait(DisplayObject(playerTitle));
			addTrait(MediaTraitType.DISPLAY_OBJECT, viewable);
			hide();
		}
		
		public function show():void {
			(playerTitle as Widget).visible = true;
			(playerTitle as Widget).validateNow();
		}
		
		public function hide():void {
			(playerTitle as Widget).visible = false;
		}
	}
}