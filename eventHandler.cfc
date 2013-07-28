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
	function onApplicationLoad($) {
		variables.pluginConfig.addEventHandler(this);
		verifyMuraClassExtension($);
		verifySlatwallAttributeSet($);
	}

	function onSiteRequestInit($) {
		var dataQuery = '';
		var fileName = normalizeFileName($.event('currentFilename'));
		var queryResults = getURLQuery(currentFilenameAdjusted=fileName, siteID=$.event('siteID'));
		var muraContentRedirectExists = false;

		verifySlatwallRequest($);

		if (
			(
				NOT listFindNoCase('tag,category',listFirst(fileName,'/'))
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
						muraContentRedirectExists = true;

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

		if( getIsSlatwallIntegrationActive() AND NOT muraContentRedirectExists ){
			local.product = getSlatwallProductFromFileName(fileName);

			if( NOT isNull(local.product) ){
				var alternateURLRedirect	= local.product.getAttributeValue('alternateURLRedirect');
				var redirectLocation			= $.globalConfig('context');

				if( yesNoFormat($.globalConfig('indexFileInURLs')) ){
					redirectLocation = '#redirectLocation#/index.cfm';
				}
				redirectLocation = '#redirectLocation##local.product.getProductURL()#';

				if( alternateURLRedirect EQ 'NoRedirect' ){
					$.event('currentFilenameAdjusted',local.product.getProductURL());
					$.event('path',local.product.getProductURL());

				} else if( alternateURLRedirect EQ '301Redirect' ) {
					location(redirectLocation,false,'301');

				} else {
					location(redirectLocation,false);
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

	public boolean function getIsSlatwallIntegrationActive(){
		if( NOT structKeyExists(variables,'isSlatwallIntegrationActive') ){
			variables.isSlatwallIntegrationActive = variables.pluginConfig.getSetting('isSlatwallIntegrationActive') AND fileExists(expandPath('/Slatwall/Application.cfc'));
		}

		return variables.isSlatwallIntegrationActive;
	}

	private any function getSlatwallApplication(){
		if( NOT structKeyExists(variables,'slatwallApplication') ){
			variables.slatwallApplication = createObject('Slatwall.Application');
		}

		return variables.slatwallApplication;
	}

	private any function getSlatwallProductFromFileName(fileName){
		var fileName = normalizeFileName(arguments.fileName);

		local.products = ormExecuteQuery('
			FROM SlatwallProduct
				WHERE urlTitle = :urlTitle
					AND publishedFlag = :publishedFlag
					AND activeFlag = :activeFlag',{
			urlTitle=fileName,
			publishedFlag=true,
			activeFlag=true
		});

		if( arrayLen(local.products) EQ 1 ){
			local.product = local.products[1];

		} else {
			local.productService = getSlatwallApplication().getBeanFactory().getBean('productService');

			local.possibleProductIDList = ormExecuteQuery('
				SELECT p.productID FROM SlatwallProduct AS p
					INNER JOIN p.attributeValues AS v
					INNER JOIN v.attribute AS a
				WHERE a.attributeCode = :attributeCode
					AND v.attributeValue LIKE :attributeValue
					AND p.publishedFlag = :publishedFlag
					AND p.activeFlag = :activeFlag',{
				attributeCode='alternateURL',
				attributeValue='%#fileName#%',
				publishedFlag=true,
				activeFlag=true
			});

			for( local.possibleProductID IN local.possibleProductIDList ){
				local.possibleProduct = local.productService.getProduct(local.possibleProductID);

				if( listFindNoCase(local.possibleProduct.getAttributeValue('alternateURL'),fileName,chr(10)) ){
					local.product = local.possibleProduct;
					break;
				}
			}
		}

		if( NOT isNull(local.product) ){
			return local.product;
		}
	}

	private void function verifySlatwallRequest($){
		if( getIsSlatwallIntegrationActive() ){
			if( NOT structKeyExists(request,'slatwallScope') ){
				getSlatwallApplication().setupGlobalRequest();
			}

			$.setCustomMuraScopeKey('slatwall',request.slatwallScope);
		}
	}

	private void function verifySlatwallAttributeSet($) {
		if( getIsSlatwallIntegrationActive() ){
			verifySlatwallRequest($);

			local.hibachiService			= getSlatwallApplication().getBeanFactory().getBean('hibachiService');
			local.attributeSetService	= local.hibachiService.getServiceByEntityName('attributeSet');
			local.attributeService		= local.hibachiService.getServiceByEntityName('attribute');
			local.attributeSet				= local.attributeSetService.getAttributeSetByAttributeSetCode('urlTools');

			if( isNull(local.attributeSet) ){
				local.attributeSet = local.attributeSetService.newAttributeSet();
			}

			local.attributeSet.populate({
				attributeSetName='URL Tools',
				attributeSetCode='urlTools'
			});
			local.attributeSet.setAttributeSetType(local.attributeSetService.getType({ systemCode='astProduct' }));
			local.attributeSetService.saveAttributeSet(local.attributeSet);

			local.attributeItems = [{
				attributeName='Alternate URL List (Line Delimited)',
				attributeCode='alternateURL',
				attributeType={
					systemCode='atTextArea'
				},
				attributeSet={
					attributeSetCode='urlTools'
				}
			},{
				attributeName='Canonical URL (optional)',
				attributeCode='canonicalURL',
				attributeType={
					systemCode='atText'
				},
				attributeSet={
					attributeSetCode='urlTools'
				}
			},{
				attributeName='Alternate URL Redirection Method',
				attributeCode='alternateURLRedirect',
				defaultValue='Redirect',
				attributeType={
					systemCode='atSelect'
				},
				attributeSet={
					attributeSetCode='urlTools'
				},
				attributeOptions=[{
					attributeOptionID='',
					attributeOptionValue='NoRedirect',
					attributeOptionLabel='No Redirect',
					sortOrder=1
				},{
					attributeOptionID='',
					attributeOptionValue='Redirect',
					attributeOptionLabel='Redirect',
					sortOrder=2
				},{
					attributeOptionID='',
					attributeOptionValue='301Redirect',
					attributeOptionLabel='301 Redirect',
					sortOrder=3
				}]
			}];

			for( local.attributeItem IN local.attributeItems ){
				local.attribute = local.attributeService.getAttributeByAttributeCode(local.attributeItem.attributeCode);

				if( isNull(local.attribute) ){
					local.attribute = local.attributeService.newAttribute();
				}

				if( local.attribute.hasAttributeOption()  ){
					structDelete(local.attributeItem,'attributeOptions');
				}

				local.attribute.populate(local.attributeItem);
				local.attribute.setAttributeSet(local.attributeSet);
				local.attribute.setAttributeType(local.attributeService.getType(local.attributeItem.attributeType));

				local.attributeService.saveAttribute(local.attribute);
			}

			getSlatwallApplication().getBeanFactory().getBean('hibachiDAO').flushORMSession();
		}
	}

	private string function getSlatwallSettingValue(settingKey){
		var settingValue = '';

		if( getIsSlatwallIntegrationActive() ){
			param name="variables.slatwallSettingValue" type="struct" default="#structNew()#";

			if( NOT structKeyExists(variables.slatwallSettingValue,arguments.settingKey) ){
				variables.slatwallSettingValue[arguments.settingKey] = getSlatwallApplication().getBeanFactory().getBean('settingService').getSettingValue(arguments.settingKey);
			}

			settingValue = variables.slatwallSettingValue[arguments.settingKey];
		}

		return settingValue;
	}

	private string function normalizeFileName(fileName){
		if( left(arguments.fileName,1) EQ '/' ){
			arguments.fileName = replace(arguments.fileName,'/','');
		}

		if( right(arguments.fileName,1) EQ '/' ){
			arguments.fileName = left(arguments.fileName,len(arguments.fileName) - 1);
		}

		if( listLen(arguments.fileName,'/') GT 1 AND listFirst(arguments.fileName,'/') EQ getSlatwallSettingValue('globalURLKeyProduct') ){
			arguments.fileName = listDeleteAt(arguments.fileName,1,'/');
		}

		return arguments.fileName;
	}
	</cfscript>

	<cffunction name="onRenderEnd">
		<cfargument name="$" />

		<cfset local.product			= getSlatwallProductFromFileName(listDeleteAt($.event('path'),1,'/')) />
		<cfset local.canonicalURL	= '' />

		<cfif isNull(local.product)>
			<!--- If there is at least 1 alternate URL, no redirect, and a canonicalURL... use the canonical --->
			<cfif len($.content('alternateURL')) and len($.content('canonicalURL')) and $.content('alternateURLRedirect') eq "NoRedirect">
				<cfset local.canonicalURL = $.createHREF(filename=$.content('canonicalURL'),complete=true) />

			<!--- If there is at least 1 alternate URL, no redirect, and NO canonicalURL... use the filename as canonical --->
			<cfelseif len($.content('alternateURL')) and $.content('alternateURLRedirect') eq "NoRedirect">
				<cfset local.canonicalURL = $.createHREF(filename=$.content('filename'),complete=true) />
			</cfif>

		<cfelse>
			<!--- If there is no redirect, and a canonicalURL... use the canonical from product (as we want to support /sp/{productKey} as well as /{productKey} there are always two urls for one product if no mura content with the same filename is available --->
			<cfif len(local.product.getAttributeValue('canonicalURL')) AND local.product.getAttributeValue('alternateURLRedirect') EQ 'NoRedirect'>
				<cfset local.canonicalURL = $.createHREF(filename=local.product.getAttributeValue('canonicalURL'),complete=true) />

			<!--- If there is NO canonicalURL... use the productURL as canonical --->
			<cfelseif local.product.getAttributeValue('alternateURLRedirect') EQ 'NoRedirect'>
				<cfset local.canonicalURL = $.createHREF(filename=local.product.getProductURL(),complete=true) />
			</cfif>
		</cfif>

		<cfif len(local.canonicalURL)>
			<cfset $.event('__muraresponse__',replace($.event('__muraresponse__'),'</head>','<link rel="canonical" href="#local.canonicalURL#" /></head>')) />
		</cfif>
	</cffunction>

	<cffunction name="getURLQuery" access="private" returntype="Query">
		<cfargument name="currentFilenameAdjusted" type="string" required="true" />
		<cfargument name="siteID" type="string" required="true" />

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
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
						  AND
						  	a.baseID = tclassextenddata.baseID
						LIMIT 1
					) as 'redirectType',
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
						LIMIT 1
					) as 'overwriteTag',
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
						LIMIT 1
					) as 'overwriteCategory',
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
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="alternateURLRedirect">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) as 'redirectType',
					(
						SELECT TOP 1
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteTag">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) as 'overwriteTag',
					(
						SELECT TOP 1
							a.attributeValue
						FROM
							tclassextenddata a
						  INNER JOIN
				  			tclassextendattributes b on a.attributeID = b.attributeID
						WHERE
							b.name = <cfqueryparam cfsqltype="cf_sql_varchar" value="overwriteCategory">
						  AND
						  	a.baseID = tclassextenddata.baseID
					) as 'overwriteCategory',
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
