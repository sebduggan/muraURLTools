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