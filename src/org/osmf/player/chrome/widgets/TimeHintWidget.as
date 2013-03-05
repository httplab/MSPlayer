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

package org.osmf.player.chrome.widgets
{
	import flash.display.DisplayObject;
	import org.osmf.player.chrome.assets.AssetIDs;
	import org.osmf.player.chrome.assets.AssetsManager;
	

	public class TimeHintWidget extends LabelWidget {
		public function TimeHintWidget() {
			face = AssetIDs.SCRUB_BAR_TIME_HINT;
			contentFace = AssetIDs.SCRUB_BAR_TIME_HINT_CONTENT;
		}
		
		// Overrides
		//
		
		override public function configure(xml:XML, assetManager:AssetsManager):void {
			super.configure(xml, assetManager);
			
			contentFaceDisplayObject = assetManager.getDisplayObject(contentFace);
		}
		
		override public function set text(value:String):void {
			content = null;
			if (value != text) {
				super.text = value;	
				y = 10;
				// center the text horizontally
				// and vertically within the bubble area
				textField.width = textField.textWidth;
				textField.x = getChildAt(0).width/2 - textField.width/2;
				// get the bubble height and substract the stem and the shadow to 
				// find the vertically available space to center in   
				var size:Number = 12;
				if (
					textField && 
					textField.getTextFormat() && 
					textField.getTextFormat().size
				) {
					size = parseInt(textField.getTextFormat().size.toString());
				}
				textField.y = _topPaddings + (_availableBubbleHeight - size) / 2
			}
		}
		
		public function set content(value:DisplayObject):void {
			if (_content) {
				removeChild(_content);
				removeChild(contentFaceDisplayObject)
			}
			_content = value;
			if (_content) {
				_content.x = _content.y = 7;
				var scale:Number = 104 / _content.width;
				_content.scaleX = scale;
				_content.scaleY = scale;
				contentFaceDisplayObject.height = 31 + _content.height;
				addChild(contentFaceDisplayObject);
				addChild(_content);
			}
		}
		
		override public function get width():Number {
			if (!_content) { return super.width; }
			return contentFaceDisplayObject.width;
		}
		
		override public function get height():Number {
			if (!_content) { return super.height; }
			return contentFaceDisplayObject.height + 15;
		}
		
		// Internals
		//
		
		// TODO: need to make these publicly available for future skins that 
		// need different spacing and propagate the properties in xml skin file
		private var _topPaddings:Number = -3;
		private var _availableBubbleHeight:uint = 19;
		private var _content:DisplayObject;
		private var contentFace:String;
		private var contentFaceDisplayObject:DisplayObject;
	}
}