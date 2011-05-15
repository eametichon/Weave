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

package org.oicweave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import org.oicweave.Weave;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.data.AttributeColumns.AlwaysDefinedColumn;
	import org.oicweave.data.AttributeColumns.ColorColumn;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.visualization.plotters.styles.DynamicFillStyle;
	import org.oicweave.visualization.plotters.styles.DynamicLineStyle;
	import org.oicweave.visualization.plotters.styles.SolidFillStyle;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * This plotter plots rectangles using xMin,yMin,xMax,yMax values.
	 * There is a set of data coordinates and a set of screen offset coordinates.
	 * 
	 * @author adufilie
	 */
	public class RectanglePlotter extends AbstractPlotter
	{
		public function RectanglePlotter()
		{
			registerSpatialProperties(xData, yData, widthData, heightData);
			registerNonSpatialProperties(xMinScreenOffset, yMinScreenOffset, xMaxScreenOffset, yMaxScreenOffset, lineStyle, fillStyle);
			// initialize default line & fill styles
			lineStyle.requestLocalObject(SolidLineStyle, false);
			var fill:SolidFillStyle = fillStyle.requestLocalObject(SolidFillStyle, false);
			fill.color.internalDynamicColumn.requestGlobalObject(Weave.DEFAULT_COLOR_COLUMN, ColorColumn, false);
			
			setKeySource(xData);
		}

		// spatial properties
		/**
		 * This is the minimum X data value associated with the rectangle.
		 */
		public const xData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the minimum Y data value associated with the rectangle.
		 */
		public const yData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the maximum X data value associated with the rectangle.
		 */
		public const widthData:DynamicColumn = new DynamicColumn();
		/**
		 * This is the maximum Y data value associated with the rectangle.
		 */
		public const heightData:DynamicColumn = new DynamicColumn();

		// visual properties
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const xMinScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const yMinScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const xMaxScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is an offset in screen coordinates when projecting the data rectangle onto the screen.
		 */
		public const yMaxScreenOffset:AlwaysDefinedColumn = new AlwaysDefinedColumn(0);
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:DynamicLineStyle = new DynamicLineStyle();
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fillStyle:DynamicFillStyle = new DynamicFillStyle();

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var x:Number = xData.getValueFromKey(recordKey, Number) as Number;
			var y:Number = yData.getValueFromKey(recordKey, Number) as Number;
			var width:Number = widthData.getValueFromKey(recordKey, Number) as Number;
			var height:Number = heightData.getValueFromKey(recordKey, Number) as Number;
			return [getReusableBounds(x, y, x + width, y + height)];
		}

		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;

			// project data coordinates to screen coordinates and draw graphics onto tempShape

			var x:Number = xData.getValueFromKey(recordKey, Number) as Number;
			var y:Number = yData.getValueFromKey(recordKey, Number) as Number;
			var width:Number = widthData.getValueFromKey(recordKey, Number) as Number;
			var height:Number = heightData.getValueFromKey(recordKey, Number) as Number;
			
			// project x,y data coordinates to screen coordinates
			tempPoint.x = x;
			tempPoint.y = y;
			dataBounds.projectPointTo(tempPoint, screenBounds);
			// add screen offsets
			tempPoint.x += xMinScreenOffset.getValueFromKey(recordKey, Number) as Number;
			tempPoint.y += yMinScreenOffset.getValueFromKey(recordKey, Number) as Number;
			// save x,y screen coordinates
			tempBounds.setMinPoint(tempPoint);
			
			// project x+w,y+h data coordinates to screen coordinates
			tempPoint.x = x + width;
			tempPoint.y = y + height;
			dataBounds.projectPointTo(tempPoint, screenBounds);
			// add screen offsets
			tempPoint.x += xMaxScreenOffset.getValueFromKey(recordKey, Number) as Number;
			tempPoint.y += yMaxScreenOffset.getValueFromKey(recordKey, Number) as Number;
			// save x+w,y+h screen coordinates
			tempBounds.setMaxPoint(tempPoint);
			
			// draw graphics
			lineStyle.beginLineStyle(recordKey, graphics);
			fillStyle.beginFillStyle(recordKey, graphics);
			graphics.drawRect(tempBounds.getXMin(), tempBounds.getYMin(), tempBounds.getWidth(), tempBounds.getHeight());
			graphics.endFill();
		}
		
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable object
		private static const tempPoint:Point = new Point(); // reusable object
	}
}
