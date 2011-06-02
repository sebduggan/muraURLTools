component extends="mura.plugin.plugincfc" output="false" { 

	variables.config="";
	
	public void function init(any config) {
		variables.config = arguments.config;
	}
	
	// On install
	public void function install() {
		application.appInitialized=false;
	}
	
	// On update
	public void function update() {
		application.appInitialized=false;
	}
	
	// On delete
	public void function delete() {
		// Remove Extended Sets that have been created
		var local = structNew();
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
			// get the extend set. One is created if it doesn't already exist
			local.thisExtendSet = local.thisSubType.getExtendSetByName( "URL Tools" );
			local.thisExtendSet.delete();
		}
	}
	
	
}