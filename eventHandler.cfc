<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser - www.gregmoser.com
    Copyright (C) 2013 Seb Duggan - sebduggan.com

    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfcomponent extends="mura.plugin.pluginGenericEventHandler">

	<cfscript>
	function onApplicationLoad($) {
		variables.pluginConfig.addEventHandler(this);
		verifyMuraClassExtension($);
	}

	function onSiteRequestStart($) {
		var dataQuery = "";
		var i = 0;
		var fileName = $.event('currentFilename');
		var alternateURLList = "";
		var redirectLocation = "";
		var queryResults = getURLQuery(currentFilenameAdjusted=fileName, siteID=$.event('siteID'));

		if (
			(
				NOT listFindNoCase('tag,category',listFirst(fileName))
				AND len($.event('currentFilenameAdjusted'))
			)
			OR
			(
				len(queryResults.overwriteTag) AND queryResults.overwriteTag
				AND listFirst(fileName,'/') EQ 'tag'
			)
			OR
			(
				len(queryResults.overwriteCategory) AND queryResults.overwriteCategory
				AND listFirst(fileName,'/') EQ 'category'
			)
		){

			if( NOT listFindNoCase('tag,category',listFirst(fileName,'/')) ){
				fileName = $.event('currentFilenameAdjusted');
			}

			queryResults = getURLQuery(currentFilenameAdjusted=fileName, siteID=$.event('siteID'));

			for(i=1; i<=queryResults.recordCount; i++) {

				alternateURLList = replace(queryResults.alternateURLList[i], chr(13), "", "all");
				alternateURLList = replace(alternateURLList, " ", "", "all");

				if(listFindNoCase(alternateURLList, fileName, chr(10)) && queryResults.filename[i] != "" && queryResults.filename[i] != fileName){
					if(queryResults.redirectType[i] == "NoRedirect") {
						$.event('currentFilenameAdjusted', queryResults.filename);
					} else {
						redirectLocation = $.createHREF(filename=queryResults.filename);
						if (queryResults.redirectType == "301Redirect") {
							location(redirectLocation, false, "301");
						} else {
							location(redirectLocation, false);
						}
					}
				}
			}
		}
	}

	function verifyMuraClassExtension($) {
		var assignedSites = "";
		var local = {};
		var i=1;
		var t=1;
		var types = ["Page", "Link", "File", "Calendar", "Gallery"];

		if ($.globalconfig("version") lt 6) {
			arrayappend(types, "Portal");
		} else {
			arrayappend(types, "Folder");
		}

		assignedSites = variables.pluginConfig.getAssignedSites();
		for(i=1; i<=assignedSites.recordCount; i++) {
			for(t=1; t<=ArrayLen(types); t++){
				local.thisSiteID = assignedSites["siteID"][i];
				local.thisSubType = application.configBean.getClassExtensionManager().getSubTypeBean();
				local.thisSubType.set( {
					type = types[t],
					subType = "Default",
					siteID = local.thisSiteID
				} );
				// we load the subType (in case it already exists) before it's saved
				local.thisSubType.load();
				local.thisSubType.save();
				// get the extend set. One is created if it doesn't already exist
				local.thisExtendSet = local.thisSubType.getExtendSetByName( "URL Tools" );
				local.thisExtendSet.setSubTypeID(local.thisSubType.getSubTypeID());
				local.thisExtendSet.save();
				// create a new attribute for the extend set
				// getAttributeBy Name will look for it and if not found give me a new bean to use
				// TODO: Internationalize attribute labels and hints
				local.thisAttribute = local.thisExtendSet.getAttributeByName("alternateURL");
				local.thisAttribute.set({
					label = "Alternate URL List (Line Delimited)",
					type = "TextArea",
					validation = "string",
					defaultValue = "",
					orderNo = "1"
				});
				local.thisAttribute.save();

				local.thisAttribute = local.thisExtendSet.getAttributeByName("canonicalURL");
				local.thisAttribute.set({
					label = "Canonical URL (optional)",
					type = "TextBox",
					validation = "string",
					defaultValue = "",
					orderNo = "2"
				});
				local.thisAttribute.save();

				local.thisAttribute = local.thisExtendSet.getAttributeByName("alternateURLRedirect");
				local.thisAttribute.set({
					label = "Alternate URL Redirection Method",
					type = "RadioGroup",
					defaultValue = "Redirect",
					optionList="NoRedirect^Redirect^301Redirect",
					optionLabelList="No Redirect^Redirect^301 Redirect",
					orderNo="3"
				});
				local.thisAttribute.save();

				local.thisAttribute = local.thisExtendSet.getAttributeByName("overwriteTag");
				local.thisAttribute.set({
					label = "Overwriting /tag/ from mura",
					type = "RadioGroup",
					defaultValue = "0",
					optionList="0^1",
					optionLabelList="No^Yes",
					orderNo="4"
				});
				local.thisAttribute.save();

				local.thisAttribute = local.thisExtendSet.getAttributeByName("overwriteCategory");
				local.thisAttribute.set({
					label = "Overwriting /category/ from mura",
					type = "RadioGroup",
					defaultValue = "0",
					optionList="0^1",
					optionLabelList="No^Yes",
					orderNo="5"
				});
				local.thisAttribute.save();
			}
		}
	}
	</cfscript>

	<cffunction name="onRenderEnd">
		<cfargument name="$" />

		<!--- If there is at least 1 alternate URL, no redirect, and a canonicalURL... use the canonical --->
		<cfif len($.content('alternateURL')) and len($.content('canonicalURL')) and $.content('alternateURLRedirect') eq "NoRedirect">
			<cfhtmlhead text='<link rel="canonical" href="#$.createHREF(filename=$.content('canonicalURL'))#" />' >
		<!--- If there is at least 1 alternate URL, no redirect, and NO canonicalURL... use the filename as canonical --->
		<cfelseif len($.content('alternateURL')) and $.content('alternateURLRedirect') eq "NoRedirect">
			<cfhtmlhead text='<link rel="canonical" href="#$.createHREF(filename=$.content('filename'))#" />' >
		</cfif>

	</cffunction>

	<cffunction name="getURLQuery" access="private" returntype="Query">
		<cfargument name="currentFilenameAdjusted" type="string" required="true" />
		<cfargument name="siteID" type="string" required="true" />

		<cfset var rs = "" />
		<cfset var likeCi = "LIKE" />
		<cfset var limitPre = "" />
		<cfset var limitPost = "" />

		<cfswitch expression="#application.configBean.getDBType()#">
			<cfcase value="mssql">
				<cfset limitPre = "TOP 1" />
			</cfcase>
			<cfcase value="mysql">
				<cfset limitPost = "LIMIT 1" />
			</cfcase>
			<cfcase value="postgresql">
				<cfset limitPost = "LIMIT 1" />
				<cfset likeCi = "ILIKE" />
			</cfcase>
			<cfcase value="oracle">
				<cfset limitPost = "AND rownum = 1" />
			</cfcase>
		</cfswitch>

		<cfquery name="rs" datasource="#application.configBean.getDatasource()#" >
			SELECT
				tcontent.contentID,
				tcontent.filename,
				(
					SELECT #limitPre#
						a.attributeValue
					FROM
						tclassextenddata a
					INNER JOIN
						tclassextendattributes b ON a.attributeID = b.attributeID
					WHERE
						b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
					AND
						a.baseID = tclassextenddata.baseID
					#limitPost#
				) AS redirectType,
				(
					SELECT #limitPre#
						a.attributeValue
					FROM
						tclassextenddata a
					INNER JOIN
						tclassextendattributes b ON a.attributeID = b.attributeID
					WHERE
						b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteTag">
					AND
						a.baseID = tclassextenddata.baseID
					#limitPost#
				) AS overwriteTag,
				(
					SELECT #limitPre#
						a.attributeValue
					FROM
						tclassextenddata a
					INNER JOIN
						tclassextendattributes b ON a.attributeID = b.attributeID
					WHERE
						b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteCategory">
					AND
						a.baseID = tclassextenddata.baseID
					 #limitPost#
				) AS overwriteCategory,
				tclassextenddata.attributeValue AS alternateURLList
			FROM
				tclassextenddata
			INNER JOIN
				tclassextendattributes ON tclassextenddata.attributeID = tclassextendattributes.attributeID
			INNER JOIN
				tcontent ON tclassextenddata.baseID = tcontent.contentHistID
			WHERE
				tclassextenddata.attributeValue #likeCi# <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.currentFilenameAdjusted#%">
			AND
				tclassextendattributes.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURL">
			AND
				tcontent.active = 1
			AND
				tclassextenddata.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#">
		</cfquery>


		<cfreturn rs />
	</cffunction>
</cfcomponent>
