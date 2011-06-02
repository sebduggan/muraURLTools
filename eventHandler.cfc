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
		
	public any function onApplicationLoad() {
		variables.pluginConfig.addEventHandler(this);
		verifyMuraClassExtension();
	}
	
	public any function onSiteRequestStart() {
		// If there is a filename in the request Run Logic
		if( len( $.event('currentFilenameAdjusted') ) ) {
			
			// Create new Query
			var dataQuery = new Query();
			dataQuery.setDataSource(application.configBean.getDatasource());
			dataQuery.setUsername(application.configBean.getUsername());
			dataQuery.setPassword(application.configBean.getPassword());
			
			// Set the SQL
			dataQuery.setSql("
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
					) as 'redirectType'
				FROM
					tclassextenddata
				  INNER JOIN
				  	tclassextendattributes on tclassextenddata.attributeID = tclassextendattributes.attributeID
				  INNER JOIN
				  	tcontent on tclassextenddata.baseID = tcontent.contentHistID
				WHERE
					tclassextenddata.attributeValue = :currentFilenameAdjusted
				  AND
				  	tclassextendattributes.name = 'alternateURL'
				  AND
				  	tcontent.active = 1
			");
			
			dataQuery.addParam(name = "currentFilenameAdjusted", value = $.event('currentFilenameAdjusted'), cfsqltype = "cf_sql_varchar");
			
			var queryResults = dataQuery.execute().getResult();
			if(queryResults.recordcount) {
				if(queryResults.filename != "" && queryResults.filename != $.event('currentFilenameAdjusted')){
					if(queryResults.redirectType == "NoRedirect") {
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
	
	private void function verifyMuraClassExtension() {
		var assignedSites = variables.pluginConfig.getAssignedSites();
		for( var i=1; i<=assignedSites.recordCount; i++ ) {
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
				label = "Alternate URL Filename",
				type = "TextBox",
				validation = "string",
				defaultValue = "",
				orderNo = "1"
			});
			local.thisAttribute.save();
			
			local.thisAttribute = local.thisExtendSet.getAttributeByName("alternateURLRedirect");
			local.thisAttribute.set({
				label = "Alternate URL Redirection Method",
				type = "RadioGroup",
				defaultValue = "Redirect",
				optionList="NoRedirect^Redirect^301Redirect",
				optionLabelList="No Redirect^Redirect^301 Redirect",
				orderNo="2"
			});
			local.thisAttribute.save();

		}
	}
	
	</cfscript>
</cfcomponent>