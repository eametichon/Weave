/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/


package org.oicweave.data.AttributeColumns
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.getCallbackCollection;
	import org.oicweave.services.URLRequestUtils;

	public class ImageColumn extends DynamicColumn
	{
		public function ImageColumn()
		{
		}
		
		[Embed( source="/org/oicweave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;
		
		/**
		 * This is the image cache.
		 */
		private static const _urlToImageMap:Object = new Object(); // maps a url to a BitmapData

		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType != null)
				return super.getValueFromKey(key, dataType);
			var _imageURL:String = super.getValueFromKey(key, String) as String;
			if(_imageURL == null)
				return _missingImage;
			if( _urlToImageMap[_imageURL] == undefined ){
		
				_urlToImageMap[_imageURL] = _missingImage;
				URLRequestUtils.getContent(new URLRequest(_imageURL), handleImageDownload, handleFault, _imageURL);
				
			}
			
			if( (_urlToImageMap[_imageURL] ) != null ){
				return _urlToImageMap[_imageURL];
			}
			return null;
		}
		
		private function handleImageDownload(event:ResultEvent, token:Object = null):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[token] = bitmap.bitmapData;
			getCallbackCollection(this).triggerCallbacks();
		}
				
		/**
		 * This function is called when there is an error downloading an image.
		 */
		private function handleFault(event:FaultEvent, token:Object=null):void
		{
			//trace("Error downloading image:", ObjectUtil.toString(event.message), token);
			_urlToImageMap[token] = _missingImage;
			getCallbackCollection(this).triggerCallbacks();
		}		
		
	}
}