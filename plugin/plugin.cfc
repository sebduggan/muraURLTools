<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser - www.gregmoser.com
    Copyright (C) 2013 Seb Duggan - sebduggan.com
    
    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfcomponent extends="mura.plugin.plugincfc" output="false">
	
	<cfset variables.config = "" />
	
	<cffunction name="init">
		<cfargument name="config" />
		
		<cfset variables.config = arguments.config />
	</cffunction>
	
	<cffunction name="install">
		
	</cffunction>
	
	<cffunction name="update">
		
	</cffunction>
	
	<cffunction name="delete">
		
	</cffunction>
</cfcomponent>