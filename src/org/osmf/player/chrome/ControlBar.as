/***********************************************************
 * Copyright 2010 Adobe Systems Incorporated.  All Rights Reserved.
 *
 * *********************************************************
 * The contents of this file are subject to the Berkeley Software Distribution (BSD) Licence
 * (the "License"); you may not use this file except in
 * compliance with the License. 
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 *
 * The Initial Developer of the Original Code is Adobe Systems Incorporated.
 * Portions created by Adobe Systems Incorporated are Copyright (C) 2010 Adobe Systems
 * Incorporated. All Rights Reserved.
 * 
 **********************************************************/

package org.osmf.player.chrome {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMode;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.media.MediaElement;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	import org.osmf.player.chrome.widgets.AutoHideWidget;
	import org.osmf.player.chrome.widgets.ChannelListButton;
	import org.osmf.player.chrome.widgets.FreeModeButton;
	import org.osmf.player.chrome.widgets.FullScreenEnterButton;
	import org.osmf.player.chrome.widgets.FullScreenLeaveButton;
	import org.osmf.player.chrome.widgets.FullWidthButton;
	import org.osmf.player.chrome.widgets.MuteButton;
	import org.osmf.player.chrome.widgets.PauseButton;
	import org.osmf.player.chrome.widgets.PlayButton;
	import org.osmf.player.chrome.widgets.PlaylistNextButton;
	import org.osmf.player.chrome.widgets.PlaylistPreviousButton;
	import org.osmf.player.chrome.widgets.QualitySwitcherContainer;
	import org.osmf.player.chrome.widgets.ScrubBar;
	import org.osmf.player.chrome.widgets.Widget;
	import org.osmf.player.chrome.widgets.WidgetIDs;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.PlayTrait;

	/**
	* ControlBar contains all the control widgets and is responsible for their layout.
	*/ 
	
	public class ControlBar extends AutoHideWidget implements IControlBar {
		// Overrides
		//
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			id = WidgetIDs.CONTROL_BAR;
			face = AssetIDs.CONTROL_BAR_BACKDROP;
			fadeSteps = 6;			
			
			layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
			layoutMetadata.verticalAlign = VerticalAlign.TOP;
			layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			super.configure(xml, assetManager);
			
			// Left margin
			var leftMargin:Widget = new Widget();
			leftMargin.face = AssetIDs.CONTROL_BAR_BACKDROP_LEFT;
			leftMargin.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			leftMargin.layoutMetadata.width = 7;
			addChildWidget(leftMargin);
			
			var leftControls:Widget = new Widget();
			leftControls.layoutMetadata.percentHeight = 100;
			leftControls.layoutMetadata.width = 22;
			leftControls.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			leftControls.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			
			// Play/pause
			var playButton:PlayButton = new PlayButton();
            playButton.id = WidgetIDs.PLAY_BUTTON;
			playButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE
			playButton.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			leftControls.addChildWidget(playButton);
			playButton.visible = false;
			
			var pauseButton:PauseButton = new PauseButton();
            pauseButton.id = WidgetIDs.PAUSE_BUTTON;
            pauseButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE
			pauseButton.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			leftControls.addChildWidget(pauseButton);
			pauseButton.visible = false;
			
			// Previous/Next
			var previousButton:PlaylistPreviousButton = new PlaylistPreviousButton();
			previousButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE
			previousButton.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			leftControls.addChildWidget(previousButton);
			
			var nextButton:PlaylistNextButton = new PlaylistNextButton();
			nextButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE
			nextButton.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			leftControls.addChildWidget(nextButton);
			
			addChildWidget(leftControls);		
			
			// Spacer
			var afterPlaySpacer:Widget = new Widget();
			afterPlaySpacer.width = 10;			
			addChildWidget(afterPlaySpacer);
			
			// Scrub bar
			var scrubBar:ScrubBar = new ScrubBar();		
			scrubBar.id = WidgetIDs.SCRUB_BAR;
			scrubBar.layoutMetadata.percentWidth = 100;
			scrubBar.layoutMetadata.horizontalAlign = HorizontalAlign.CENTER;
			scrubBar.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			addChildWidget(scrubBar);
			
			// Right side
 			rightControls = new Widget();
			rightControls.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			rightControls.layoutMetadata.horizontalAlign = HorizontalAlign.LEFT;
			rightControls.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			
			// Spacer
			afterScrubSpacer = new Widget();
			afterScrubSpacer.width = 10;
			rightControls.addChildWidget(afterScrubSpacer);
			
			//ChannelListButton
			channelListButton = new ChannelListButton();
			channelListButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			channelListButton.layoutMetadata.width = 33;
			channelListButton.id = WidgetIDs.CHANNEL_LIST_BUTTON;
			rightControls.addChildWidget(channelListButton);
			
			afterChannelSpacer = new Widget();
			afterChannelSpacer.width = 10;
			rightControls.addChildWidget(afterChannelSpacer);
			
			// Quality switcher
			qualitySwitcherWidget = new QualitySwitcherContainer();
			qualitySwitcherWidget.layoutMetadata.scaleMode = ScaleMode.NONE;
			qualitySwitcherWidget.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			qualitySwitcherWidget.layoutMetadata.width = 48	;
			qualitySwitcherWidget.id = WidgetIDs.QUALITY_SWITCHER_WIDGET;
			rightControls.addChildWidget(qualitySwitcherWidget);
			
			// Spacer
			afterTimeSpacer = new Widget();
			afterTimeSpacer.width = 5;
			rightControls.addChildWidget(afterTimeSpacer);
			
			muteContainerWidget = new Widget();
			muteContainerWidget.layoutMetadata.width = 38;
			muteContainerWidget.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			rightControls.addChildWidget(muteContainerWidget);
			
			// Mute/unmute
			var muteButton:MuteButton = new MuteButton();
			muteButton.id = WidgetIDs.MUTE_BUTTON;
			muteButton.volumeSteps = 3;
			muteButton.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			muteContainerWidget.addChildWidget(muteButton);
			
			//fullWidthContainerWidget = new Widget();
			//fullWidthContainerWidget.layoutMetadata.width = 30;
			//fullWidthContainerWidget.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			//fullWidthContainerWidget.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			//rightControls.addChildWidget(fullWidthContainerWidget);
			//
			//var fullWidthButton:FullWidthButton = new FullWidthButton();
			//fullWidthButton.id = WidgetIDs.FULL_WIDTH_BUTTON; 
			//fullWidthContainerWidget.addChildWidget(fullWidthButton);
			//
			//freeModeContainerWidget = new Widget();
			//freeModeContainerWidget.layoutMetadata.width = 29;
			//freeModeContainerWidget.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			//freeModeContainerWidget.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			//rightControls.addChildWidget(freeModeContainerWidget);
			//
			//var freeModeButton:FreeModeButton = new FreeModeButton();
			//freeModeButton.id = WidgetIDs.FREE_MODE_BUTTON; 
			//freeModeContainerWidget.addChildWidget(freeModeButton);
			
			fullscreenContainerWidget = new Widget();
			fullscreenContainerWidget.layoutMetadata.width = 26;
			fullscreenContainerWidget.layoutMetadata.verticalAlign = VerticalAlign.MIDDLE;
			fullscreenContainerWidget.layoutMetadata.layoutMode = LayoutMode.HORIZONTAL;
			rightControls.addChildWidget(fullscreenContainerWidget);
			
			// FullScreen			
			fullscreenEnterButton = new FullScreenEnterButton();
			fullscreenEnterButton.id = WidgetIDs.FULL_SCREEN_ENTER_BUTTON; 
			fullscreenContainerWidget.addChildWidget(fullscreenEnterButton);
			var fullscreenLeaveButton:FullScreenLeaveButton = new FullScreenLeaveButton();
			fullscreenContainerWidget.addChildWidget(fullscreenLeaveButton);
			addChildWidget(rightControls);
			
			rightControls.layoutMetadata.width = 
				afterScrubSpacer.width + 
				channelListButton.layoutMetadata.width + 
				afterChannelSpacer.width +
				qualitySwitcherWidget.layoutMetadata.width +
				afterTimeSpacer.width +
				muteContainerWidget.layoutMetadata.width + 
				//fullWidthContainerWidget.layoutMetadata.width + 
				//freeModeContainerWidget.layoutMetadata.width+ 
				fullscreenContainerWidget.layoutMetadata.width;
			
			// Spacer
			var afterFullScreenSpacer:Widget = new Widget();
			afterFullScreenSpacer.width = 10;
			addChildWidget(afterFullScreenSpacer);
			
			var rightMargin:Widget = new Widget();
			rightMargin.face = AssetIDs.CONTROL_BAR_BACKDROP_RIGHT;
			rightMargin.layoutMetadata.horizontalAlign = HorizontalAlign.RIGHT;
			rightMargin.layoutMetadata.width = 7;
			addChildWidget(rightMargin);
			
			_widgets = [ 
				leftMargin, 
				pauseButton, 
				playButton, 
				previousButton, 
				nextButton, 
				afterPlaySpacer, 
				leftControls,
				scrubBar, 
				afterScrubSpacer,
				channelListButton,
				afterChannelSpacer,
				qualitySwitcherWidget, 
				afterTimeSpacer,
				muteContainerWidget,
				muteButton, 
				//fullWidthContainerWidget,
				//fullWidthButton,
				//freeModeContainerWidget,
				//freeModeButton,
				fullscreenContainerWidget,
				fullscreenEnterButton,
				fullscreenLeaveButton, 
				afterFullScreenSpacer, 
				rightControls, 
				rightMargin
			];
			configureWidgets(_widgets);
			measure();
		}
		
		override public function layout(availableWidth:Number, availableHeight:Number, deep:Boolean = true):void {
			super.layout(availableWidth, availableHeight, deep);
			for each (var widget:Widget in widgets) {
				if (
					widget.face == AssetIDs.CONTROL_BAR_BACKDROP_LEFT ||
					widget.face == AssetIDs.CONTROL_BAR_BACKDROP_RIGHT
				) {
					widget.height = height;
				}
			}
		}
		
		override public function set width(value:Number):void {
			if (_isExpanded && (value < MIN_EXPANDED_WITDH)) {
				switchToCollapsedState();
				value -= 40;
			} else if (!_isExpanded && (value >= MIN_EXPANDED_WITDH)) {
				switchToExpandedState();
			}
			super.width = value;			
			validateNow();
		}
		
		private function switchToExpandedState():void {
			_isExpanded = true;
			rightControls.addChildWidget(channelListButton);
			rightControls.addChildWidget(afterChannelSpacer);
			rightControls.addChildWidget(qualitySwitcherWidget);
			rightControls.addChildWidget(afterTimeSpacer);
			rightControls.removeChildWidget(muteContainerWidget);
			rightControls.addChildWidget(muteContainerWidget);
			//rightControls.removeChildWidget(fullWidthContainerWidget);
			//rightControls.addChildWidget(fullWidthContainerWidget);
			//rightControls.removeChildWidget(freeModeContainerWidget);
			//rightControls.addChildWidget(freeModeContainerWidget);
			rightControls.removeChildWidget(fullscreenContainerWidget);
			rightControls.addChildWidget(fullscreenContainerWidget);
			rightControls.layoutMetadata.width = afterScrubSpacer.width + 
				channelListButton.layoutMetadata.width + 
				afterChannelSpacer.width +
				qualitySwitcherWidget.layoutMetadata.width +
				afterTimeSpacer.width +
				muteContainerWidget.layoutMetadata.width + 
				//fullWidthContainerWidget.layoutMetadata.width + 
				//freeModeContainerWidget.layoutMetadata.width + 
				fullscreenContainerWidget.layoutMetadata.width
		}
		
		private function switchToCollapsedState():void {
			_isExpanded = false;
			rightControls.removeChildWidget(channelListButton);
			rightControls.removeChildWidget(afterChannelSpacer);
			rightControls.removeChildWidget(qualitySwitcherWidget);
			rightControls.removeChildWidget(afterTimeSpacer);
			rightControls.layoutMetadata.width = afterScrubSpacer.width + 
				muteContainerWidget.layoutMetadata.width + 
				fullscreenContainerWidget.layoutMetadata.width
		}
		
		override public function get height():Number {
			var toReturn:Number;
			var _parent:DisplayObjectContainer;
			if (qualitySwitcherWidget && qualitySwitcherWidget.parent){
				_parent = qualitySwitcherWidget.parent;
				_parent.removeChild(qualitySwitcherWidget);
			}
			toReturn = super.height;
			if (_parent) {
				_parent.addChild(qualitySwitcherWidget);
			}
			return toReturn;
		}
		
		public function get widgets():Array{
			trace("ControlBar: get widgets");
			return _widgets;
		}
		
		// Internals
		//
		
		private function configureWidgets(widgets:Array):void
		{
			for each( var widget:Widget in widgets)
			{
				if (widget)
				{
					widget.configure(<default/>, assetManager);					
				}
			}
		}		
		
		override protected function processRequiredTraitsAvailable(element:MediaElement):void {
			super.processRequiredTraitsAvailable(element);
			visible = true;
		}
		
		override protected function processRequiredTraitsUnavailable(element:MediaElement):void {
			super.processRequiredTraitsUnavailable(element);
			visible = false;
		}
		
		private var fullscreenEnterButton:FullScreenEnterButton;
		
		private var playTrait:PlayTrait;
		
		private var scrubBarLiveTrack:DisplayObject;
		
		private var lastWidth:Number;
		private var lastHeight:Number;
		private var _widgets:Array;
		private static const _requiredTraits:Vector.<String> = new Vector.<String>;
		private var qualitySwitcherWidget:QualitySwitcherContainer;
		private var _isExpanded:Boolean = true;
		static public const MIN_EXPANDED_WITDH:Number = 350;
		private var rightControls:Widget;
		private var channelListButton:ChannelListButton;
		private var afterChannelSpacer:Widget;
		private var afterTimeSpacer:Widget;
		private var muteContainerWidget:Widget;
		private var fullscreenContainerWidget:Widget;
		private var afterScrubSpacer:Widget;
		//private var fullWidthContainerWidget:Widget;
		//private var freeModeContainerWidget:Widget;
		_requiredTraits[0] = MediaTraitType.PLAY;
	}
}