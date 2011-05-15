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

package org.oicweave.data.DataSources
{
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.core.IDisposableObject;
	import org.oicweave.api.core.ILinkableHashMap;
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IAttributeHierarchy;
	import org.oicweave.api.data.IColumnReference;
	import org.oicweave.api.data.IDataSource;
	import org.oicweave.api.getCallbackCollection;
	import org.oicweave.api.getSessionState;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.core.LinkableDynamicObject;
	import org.oicweave.data.AttributeColumns.EquationColumn;
	import org.oicweave.data.AttributeColumns.ProxyColumn;
	import org.oicweave.data.ColumnReferences.HierarchyColumnReference;
	import org.oicweave.primitives.AttributeHierarchy;
	import org.oicweave.services.beans.HierarchicalClusteringResult;
	import org.oicweave.utils.ColumnUtils;
	import org.oicweave.utils.HierarchyUtils;

	/**
	 * MultiDataSource
	 * This is a class to keep an updated list of all the available data sources
	 * 
	 * @author skolman
	*/
	public class MultiDataSource implements IDataSource, IDisposableObject
	{
		public function MultiDataSource()
		{
			var sources:Array = _root.getObjects(IDataSource);
			
			for each(var source:IDataSource in sources)
			{
				if(!(source is MultiDataSource))
				{
					getCallbackCollection(source.attributeHierarchy).addImmediateCallback(this, handleHierarchyChange);
				}
			}
			
			_root.childListCallbacks.addImmediateCallback(this, handleWeaveChildListChange);
			handleHierarchyChange();
		}
		
		private static var _instance:MultiDataSource;
		public static function get instance():MultiDataSource
		{
			if (!_instance)
				_instance = new MultiDataSource();
			return _instance;
		}
		
		private function get _root():ILinkableHashMap { return LinkableDynamicObject.globalHashMap; }
		
		/**
		 * attributeHierarchy
		 * @return An AttributeHierarchy object that will be updated when new pieces of the hierarchy are filled in.
		 */
		private const _attributeHierarchy:AttributeHierarchy = newLinkableChild(this, AttributeHierarchy);
		public function get attributeHierarchy():IAttributeHierarchy
		{
			return _attributeHierarchy;
		}
		
		
		private function handleWeaveChildListChange():void
		{
			// add callback to new IDataSource or IAttributeColumn so we refresh the hierarchy when it changes
			var newObj:ILinkableObject = _root.childListCallbacks.lastObjectAdded;
			if (!(newObj is MultiDataSource))
				if (newObj is IDataSource || newObj is IAttributeColumn)
					getCallbackCollection(newObj).addImmediateCallback(this, handleHierarchyChange);
			
			handleHierarchyChange();
		}
		
		private function handleHierarchyChange():void
		{
			var rootNode:XML = <hierarchy name="DataSources"/>;
			
			// add category for each IDataSource
			var sources:Array = _root.getObjects(IDataSource);
			for each(var source:IDataSource in sources)
			{
				if(!(source is MultiDataSource))
				{
					var xml:XML = getSessionState(source.attributeHierarchy) as XML;
					if (xml != null)
					{
						var category:XML = xml.copy();
						category.setName("category");
						category.@dataSourceName = _root.getName(source);
						rootNode.appendChild(category);
					}
				}
			}
			
			// add category for global column objects
			// TEMPORARY SOLUTION -- only allow EquationColumns
			var eqCols:Array = _root.getObjects(EquationColumn);
			if (eqCols.length > 0)
			{
				var globalCategory:XML = <category title="Equations"/>;
				for each(var col:IAttributeColumn in eqCols)
				{
					globalCategory.appendChild(<attribute name={ _root.getName(col) } title={ ColumnUtils.getTitle(col) }/>);
				}
				rootNode.appendChild(globalCategory);
			}
			
			_attributeHierarchy.value = rootNode;
			
		}
		
		
		/**
		 * initializeHierarchySubtree
		 * @param subtreeNode A node in the hierarchy representing the root of the subtree to initialize, or null to initialize the root of the hierarchy.
		 */
		public function initializeHierarchySubtree(subtreeNode:XML = null):void
		{
			
			var path:XML = _attributeHierarchy.getPathFromNode(subtreeNode);
			if (path == null)
				return;
			
			if (path.category.length() == 0)
				return;
			path = path.category[0];
			
			path.setName("hierarchy");
			
			var sourceName:String = path.@dataSourceName;
			
			var source:IDataSource = _root.getObject(sourceName) as IDataSource;
			
			if (source == null)
				return;
				
			
			delete path.@dataSourceName;
			
			var xml:XML = getSessionState(source.attributeHierarchy) as XML;
			var currentSubTreeNode:XML = HierarchyUtils.getNodeFromPath(xml, path);
			
			source.initializeHierarchySubtree(currentSubTreeNode);
		}
		
		public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			if (columnReference.getDataSource() == null)
			{
				// special case -- global column hack
				var hcr:HierarchyColumnReference = columnReference as HierarchyColumnReference;
				try
				{
					var name:String = HierarchyUtils.getLeafNodeFromPath(hcr.hierarchyPath.value).@name;
					return _root.getObject(name) as IAttributeColumn;
				}
				catch (e:Error)
				{
					// do nothing
				}
				return ProxyColumn.undefinedColumn;
			}
			
			return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
		}
		
		/**
		 * This function is called when the object is no longer needed.
		 */
		public function dispose():void
		{
		}
	}
}