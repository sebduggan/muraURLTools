<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser
    www.gregmoser.com

    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfcomponent extends="mura.plugin.pluginGenericEventHandler">

	<cfscript>
	function onApplicationLoad() {
		variables.pluginConfig.addEventHandler(this);
		verifyMuraClassExtension();
	}

	function onSiteRequestStart($) {
		var dataQuery = '';
		var fileName = $.event('currentFilename');
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

			for(var i=1; i<=queryResults.recordCount; i++) {

				var alternanteURLList = replace(queryResults.alternateURLList[i], chr(13), "", "all");
				alternanteURLList = replace(alternanteURLList, " ", "", "all");

				if(listFindNoCase(alternanteURLList, fileName, chr(10)) && queryResults.filename[i] != "" && queryResults.filename[i] != fileName){
					if(queryResults.redirectType[i] == "NoRedirect") {
						$.event('currentFilenameAdjusted', queryResults.filename);
					} else {
						var redirectLocation = $.createHREF(filename=queryResults.filename);
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

	function verifyMuraClassExtension() {
		var assignedSites = "";
		var local = {};
		var i=1;

		assignedSites = variables.pluginConfig.getAssignedSites();
		for(i=1; i<=assignedSites.recordCount; i++ ) {
			local.thisSiteID = assignedSites["siteID"][i];
			local.thisSubType = application.configBean.getClassExtensionManager().getSubTypeBean();
			local.thisSubType.set( {
				type = "Page",
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

		<cfif application.configBean.getDBType() eq "postgresql">
			<cfset likeCi = "ILIKE" />
		</cfif>

		<cfif listfindnocase("mysql,postgresql", application.configBean.getDBType())>
			<cfquery name="rs" datasource="#application.configBean.getDatasource()#" >
				SELECT
					tcontent.contentID,
					tcontent.filename,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
						  AND
						  	a.baseID = tclassextenddata.baseID
						LIMIT 1
					) AS redirectType,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteTag">
						  AND
						  	a.baseID = tclassextenddata.baseID
						LIMIT 1
					) AS overwriteTag,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteCategory">
						  AND
						  	a.baseID = tclassextenddata.baseID
						LIMIT 1
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
		<cfelseif application.configBean.getDBType() eq "oracle">
			<cfquery name="rs" datasource="#application.configBean.getDatasource()#" >
				SELECT
					tcontent.contentID,
					tcontent.filename,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
						  AND
						  	a.baseID = tclassextenddata.baseID
						  AND 
						  	rownum = 1
					) as redirectType,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteTag">
						  AND
						  	a.baseID = tclassextenddata.baseID
						  AND
						  	rownum = 1
					) as overwriteTag,
					(
						SELECT
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteCategory">
						  AND
						  	a.baseID = tclassextenddata.baseID
						  AND rownum = 1
					) as overwriteCategory,
					tclassextenddata.attributeValue as alternateURLList
				FROM
					tclassextenddata
				  INNER JOIN
				  	tclassextendattributes on tclassextenddata.attributeID = tclassextendattributes.attributeID
				  INNER JOIN
				  	tcontent on tclassextenddata.baseID = tcontent.contentHistID
				WHERE
					tclassextenddata.attributeValue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.currentFilenameAdjusted#%">
				  AND
				  	tclassextendattributes.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURL">
				  AND
				  	tcontent.active = 1
				  AND
					tclassextenddata.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#">
			</cfquery>
		<cfelse>
			<cfquery name="rs" datasource="#application.configBean.getDatasource()#" >
				SELECT
					tcontent.contentID,
					tcontent.filename,
					(
						SELECT TOP 1
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) AS redirectType,
					(
						SELECT TOP 1
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteTag">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) AS overwriteTag,
					(
						SELECT TOP 1
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b ON a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteCategory">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) AS overwriteCategory,
					tclassextenddata.attributeValue AS alternateURLList
				FROM
					tclassextenddata
				  INNER JOIN
				  	tclassextendattributes ON tclassextenddata.attributeID = tclassextendattributes.attributeID
				  INNER JOIN
				  	tcontent ON tclassextenddata.baseID = tcontent.contentHistID
				WHERE
					tclassextenddata.attributeValue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.currentFilenameAdjusted#%">
				  AND
				  	tclassextendattributes.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURL">
				  AND
				  	tcontent.active = 1
				  AND
					tclassextenddata.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#">
			</cfquery>
		</cfif>

		<cfreturn rs />
	</cffunction>
</cfcomponent>
