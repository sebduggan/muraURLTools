<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser - www.gregmoser.com
    Copyright (C) 2013 Seb Duggan - sebduggan.com
    
    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfinclude template="plugin/config.cfm" />

<cfsavecontent variable="variables.body">
	<cfoutput>
	<h2>URL Tools</h2>
	<p>
		This plugin is designed to make alternative URLs very simple.<br /> <br />
		For example if you have a URL like this: <strong>http://www.mydomain.com/my-services-section/my-cool-service/</strong><br />
		You can setup an Alternative URL to look like this: <strong>http://www.mydomain.com/cool</strong><br /><br />
		When a user navigates to /cool it can either "Not Redirect" but pull the correct content, Do a Standard Redirect, or a 301 Redirect.<br /><br /><br />
		<strong>To Setup:</strong><br />
		<ol>
			<li>Edit the page that you would like to create an alternative URL for in the Site Manager</li>
			<li>Click on the "Extended Attributes" Tab</li>
			<li>Under the "URL Tools" section, enter an alternative filename, using the example above this would be: cool</li>
			<li>Set you redirect method</li>
			<li>Save</li>
		</ol>
	</p>
	</cfoutput>
</cfsavecontent>

<cfoutput>#application.pluginManager.renderAdminTemplate(body=variables.body,pageTitle=request.pluginConfig.getName())#</cfoutput>