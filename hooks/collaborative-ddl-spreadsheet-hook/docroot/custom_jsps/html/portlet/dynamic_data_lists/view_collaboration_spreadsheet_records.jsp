<%--
/**
 * Copyright (C) 2005-2014 Rivet Logic Corporation.
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; version 3 of the License.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51
 */
--%>
<%--
	NOTE:
	- this is a custom rivet logic file
--%>

<%@ include file="/html/portlet/dynamic_data_lists/init.jsp" %>

<%
DDLRecordSet recordSet = (DDLRecordSet)request.getAttribute(WebKeys.DYNAMIC_DATA_LISTS_RECORD_SET);

boolean editable = false;

if (DDLRecordSetPermission.contains(permissionChecker, recordSet.getRecordSetId(), ActionKeys.ADD_RECORD) && DDLRecordSetPermission.contains(permissionChecker, recordSet.getRecordSetId(), ActionKeys.UPDATE)) {
	editable = DDLUtil.isEditable(request, portletDisplay.getId(), themeDisplay.getScopeGroupId());
}

DDMStructure ddmStructure = recordSet.getDDMStructure();
%>

<div class="lfr-spreadsheet-container">
	<div id="<portlet:namespace />spreadsheet" class="realtime-spreadsheet">
		<div class="collaboration-users">
			<ul class="unstyled">
				<li>
					<a href="" class="user-portrait current-user">
						<img src="//style.anu.edu.au/_anu/4/images/placeholders/person.png" alt="">
						<span class="user-info">User 1</span>
					</a>
				</li>
				<li>
					<a href="" class="user-portrait">
						<img style="border-color: #3FC51B !important;" src="//style.anu.edu.au/_anu/4/images/placeholders/person.png" alt="">
						<span style="background-color: #3FC51B;" class="user-info">User 2</span>                                                    
					</a>
				</li>
			</ul>
		</div>
		<div class="table-striped yui3-widget yui3-datatable" id="<portlet:namespace />dataTable">
			<div class="yui3-datatable-scrollable yui3-datatable-content" id="<portlet:namespace />dataTableContent"></div>
		</div>
	</div>

	<c:if test="<%= editable %>">
		<div class="lfr-spreadsheet-add-rows-buttons">
			<aui:button inlineField="<%= true %>" name="addRecords" value="add" />

			<aui:select inlineField="<%= true %>" label="more-rows-at-bottom" name="numberOfRecords">
				<aui:option label="1" />
				<aui:option label="5" />
				<aui:option label="10" />
				<aui:option label="20" />
				<aui:option label="50" />
			</aui:select>
		</div>
	</c:if>
</div>

<%@ include file="/html/portlet/dynamic_data_lists/custom_spreadsheet_editors.jspf" %>
<%-- CUSTOM  --%>
<aui:script>
	YUI({
		modules:  {
           'rivet-spreadsheet-datatable': {
               fullpath: '/html/portlet/dynamic_data_lists/js/rivet-spreadsheet-datatable.js'
           },
		   'rivet-collaboration-spreadsheet': {
			   fullpath: '/html/portlet/dynamic_data_lists/js/rivet-collaboration-spreadsheet.js'
		   }
       }
	}).use('rivet-collaboration-spreadsheet', function(A) {
		var structure = <%= DDMXSDUtil.getJSONArray(ddmStructure.getXsd()) %>;
		var columns = Liferay.SpreadSheet.buildDataTableColumns(<%= DDLUtil.getRecordSetJSONArray(recordSet) %>, structure, <%= editable %>);

		var ignoreEmptyRecordsNumericSort = function(recA, recB, desc, field) {
			var a = recA.get(field);
			var b = recB.get(field);

			return A.ArraySort.compareIgnoreWhiteSpace(
				a,
				b,
				desc,
				function(a, b, desc) {
					var num1 = parseFloat(a);
					var num2 = parseFloat(b);

					var result;

					if (isNaN(num1) || isNaN(num2)) {
						result = A.ArraySort.compare(a, b, desc);
					}
					else {
						result = desc ? (num2 - num1) : (num1 - num2);
					}

					return result;
				}
			);
		};

		var ignoreEmptyRecordsStringSort = function(recA, recB, desc, field) {
			var a = recA.get(field);
			var b = recB.get(field);

			return A.ArraySort.compareIgnoreWhiteSpace(a, b, desc);
		};

		var numericData = {
			'double': 1,
			integer: 1,
			number: 1
		};

		var keys = A.Array.map(
			columns,
			function(item, index, collection) {
				var key = item.key;

				if (!item.sortFn) {
					if (numericData[item.dataType]) {
						item.sortFn = A.rbind(ignoreEmptyRecordsNumericSort, item, key);
					}
					else {
						item.sortFn = A.rbind(ignoreEmptyRecordsStringSort, item, key);
					}
				}

				return key;
			}
		);

		<%
		int status = WorkflowConstants.STATUS_APPROVED;

		if (DDLRecordSetPermission.contains(permissionChecker, recordSet, ActionKeys.ADD_RECORD)) {
			status = WorkflowConstants.STATUS_ANY;
		}

		List<DDLRecord> records = DDLRecordLocalServiceUtil.getRecords(recordSet.getRecordSetId(), status, 0, 1000, null);
		%>

		var records = <%= DDLUtil.getRecordsJSONArray(records, !editable) %>;

		records.sort(
			function(a, b) {
				return (a.displayIndex - b.displayIndex);
			}
		);

		var data = Liferay.SpreadSheet.buildEmptyRecords(<%= Math.max(recordSet.getMinDisplayRows(), records.size()) %>, keys);

		A.Array.each(
			records,
			function(item, index, collection) {
				data.splice(item.displayIndex, 0, item);
			}
		);

		var spreadSheet = new Liferay.RivetCollaborationSpreadSheet(
			{
				boundingBox: '#<portlet:namespace />dataTable',
				columns: columns,
				contentBox: '#<portlet:namespace />dataTableContent',
				data: data,
				editEvent: 'dblclick',
				plugins: [
					{
						fn: A.Plugin.DataTableHighlight,
						cfg: {
							highlightRange: false
						}
					}
				],
				recordsetId: <%= recordSet.getRecordSetId() %>,
				structure: structure,
				width: '100%'
			}
		);

		spreadSheet.render('#<portlet:namespace />spreadsheet');

		spreadSheet.get('boundingBox').unselectable();

		<c:if test="<%= editable %>">
			var numberOfRecordsNode = A.one('#<portlet:namespace />numberOfRecords');

			A.one('#<portlet:namespace />addRecords').on(
				'click',
				function(event) {
					var numberOfRecords = parseInt(numberOfRecordsNode.val(), 10) || 0;

					spreadSheet.addEmptyRows(numberOfRecords);

					spreadSheet.updateMinDisplayRows(spreadSheet.get('data').size());
				}
			);
		</c:if>

		window.<portlet:namespace />spreadSheet = spreadSheet;
		window.<portlet:namespace />structure = structure;
	});
</aui:script>
<%--  end:CUSTOM --%>

<%-- <aui:script use="liferay-portlet-dynamic-data-lists">
	var structure = <%= DDMXSDUtil.getJSONArray(ddmStructure.getXsd()) %>;
	var columns = Liferay.SpreadSheet.buildDataTableColumns(<%= DDLUtil.getRecordSetJSONArray(recordSet) %>, structure, <%= editable %>);

	var ignoreEmptyRecordsNumericSort = function(recA, recB, desc, field) {
		var a = recA.get(field);
		var b = recB.get(field);

		return A.ArraySort.compareIgnoreWhiteSpace(
			a,
			b,
			desc,
			function(a, b, desc) {
				var num1 = parseFloat(a);
				var num2 = parseFloat(b);

				var result;

				if (isNaN(num1) || isNaN(num2)) {
					result = A.ArraySort.compare(a, b, desc);
				}
				else {
					result = desc ? (num2 - num1) : (num1 - num2);
				}

				return result;
			}
		);
	};

	var ignoreEmptyRecordsStringSort = function(recA, recB, desc, field) {
		var a = recA.get(field);
		var b = recB.get(field);

		return A.ArraySort.compareIgnoreWhiteSpace(a, b, desc);
	};

	var numericData = {
		'double': 1,
		integer: 1,
		number: 1
	};

	var keys = A.Array.map(
		columns,
		function(item, index, collection) {
			var key = item.key;

			if (!item.sortFn) {
				if (numericData[item.dataType]) {
					item.sortFn = A.rbind(ignoreEmptyRecordsNumericSort, item, key);
				}
				else {
					item.sortFn = A.rbind(ignoreEmptyRecordsStringSort, item, key);
				}
			}

			return key;
		}
	);

	<%
	int status = WorkflowConstants.STATUS_APPROVED;

	if (DDLRecordSetPermission.contains(permissionChecker, recordSet, ActionKeys.ADD_RECORD)) {
		status = WorkflowConstants.STATUS_ANY;
	}

	List<DDLRecord> records = DDLRecordLocalServiceUtil.getRecords(recordSet.getRecordSetId(), status, 0, 1000, null);
	%>

	var records = <%= DDLUtil.getRecordsJSONArray(records, !editable) %>;

	records.sort(
		function(a, b) {
			return (a.displayIndex - b.displayIndex);
		}
	);

	var data = Liferay.SpreadSheet.buildEmptyRecords(<%= Math.max(recordSet.getMinDisplayRows(), records.size()) %>, keys);

	A.Array.each(
		records,
		function(item, index, collection) {
			data.splice(item.displayIndex, 0, item);
		}
	);

	var spreadSheet = new Liferay.SpreadSheet(
		{
			boundingBox: '#<portlet:namespace />dataTable',
			columns: columns,
			contentBox: '#<portlet:namespace />dataTableContent',
			data: data,
			editEvent: 'dblclick',
			plugins: [
				{
					fn: A.Plugin.DataTableHighlight,
					cfg: {
						highlightRange: false
					}
				}
			],
			recordsetId: <%= recordSet.getRecordSetId() %>,
			structure: structure,
			width: '100%'
		}
	);

	spreadSheet.render('#<portlet:namespace />spreadsheet');

	spreadSheet.get('boundingBox').unselectable();

	<c:if test="<%= editable %>">
		var numberOfRecordsNode = A.one('#<portlet:namespace />numberOfRecords');

		A.one('#<portlet:namespace />addRecords').on(
			'click',
			function(event) {
				var numberOfRecords = parseInt(numberOfRecordsNode.val(), 10) || 0;

				spreadSheet.addEmptyRows(numberOfRecords);

				spreadSheet.updateMinDisplayRows(spreadSheet.get('data').size());
			}
		);
	</c:if>

	window.<portlet:namespace />spreadSheet = spreadSheet;
	window.<portlet:namespace />structure = structure;
</aui:script> --%>