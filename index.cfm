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
		This plugin is designed to make alternative URLs very simple.
	</p>
	<p>
		For example if you have a URL like this:<br>
		<strong>http://www.mydomain.com/my-services-section/my-cool-service/</strong>
	</p>
	<p>
		You can setup an Alternative URL to look like this:<br>
		<strong>http://www.mydomain.com/cool</strong>
	</p>
	<p>
		When a user navigates to <strong>/cool</strong> it can:
	</p>
	<ul>
		<li>"Not Redirect" but pull the correct content</li>
		<li>do a Standard Redirect</li>
		<li>do a 301 Redirect.</li>
	</ul>

	<h3>To Setup:</h3>
	<ol>
		<li>Edit the content that you would like to create an alternative URL for in the Site Manager</li>
		<li>Click on the "Extended Attributes" Tab</li>
		<li>Under the "URL Tools" section, enter an alternative filename; using the example above this would be: cool</li>
		<li>Set your redirect method</li>
		<li>Save</li>
	</ol>
	</cfoutput>
</cfsavecontent>

<cfoutput>#application.pluginManager.renderAdminTemplate(body=variables.body,pageTitle=request.pluginConfig.getName())#</cfoutput>