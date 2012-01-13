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
		var dataQuery = "";
		
		// If there is a filename in the request Run Logic
		if( len( $.event('currentFilenameAdjusted') ) ) {

			var queryResults = getURLQuery(currentFilenameAdjusted=$.event('currentFilenameAdjusted'));

			for(var i=1; i<=queryResults.recordCount; i++) {
				
				var alternanteURLList = replace(queryResults.alternateURLList[i], chr(13), "", "all");
				alternanteURLList = replace(alternanteURLList, " ", "", "all");
				
				if(listFindNoCase(alternanteURLList, $.event('currentFilenameAdjusted'), chr(10)) && queryResults.filename[i] != "" && queryResults.filename[i] != $.event('currentFilenameAdjusted')){
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
	
	<cffunction name="getURLQuery">
		<cfargument name="currentFilenameAdjusted" type="string" required="true" />
		 
		<cfset var rs = "" />
		
		<cfif application.configBean.getDBType() eq "mysql">
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
							b.name = 'alternateURLRedirect'
						  AND
						  	a.baseID = tclassextenddata.baseID
						LIMIT 1
					) as 'redirectType',
					tclassextenddata.attributeValue as 'alternateURLList'
				FROM
					tclassextenddata
				  INNER JOIN
				  	tclassextendattributes on tclassextenddata.attributeID = tclassextendattributes.attributeID
				  INNER JOIN
				  	tcontent on tclassextenddata.baseID = tcontent.contentHistID
				WHERE
					tclassextenddata.attributeValue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.currentFilenameAdjusted#%">
				  AND
				  	tclassextendattributes.name = 'alternateURL'
				  AND
				  	tcontent.active = 1
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
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = 'alternateURLRedirect'
						  AND
						  	a.baseID = tclassextenddata.baseID
					) as 'redirectType',
					tclassextenddata.attributeValue as 'alternateURLList'
				FROM
					tclassextenddata
				  INNER JOIN
				  	tclassextendattributes on tclassextenddata.attributeID = tclassextendattributes.attributeID
				  INNER JOIN
				  	tcontent on tclassextenddata.baseID = tcontent.contentHistID
				WHERE
					tclassextenddata.attributeValue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.currentFilenameAdjusted#%">
				  AND
				  	tclassextendattributes.name = 'alternateURL'
				  AND
				  	tcontent.active = 1
			</cfquery>
		</cfif>
		
		<cfreturn rs />
	</cffunction>
</cfcomponent>
