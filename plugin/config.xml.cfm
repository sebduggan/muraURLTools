<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser
    www.gregmoser.com

    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<plugin>
<name>URL Tools</name>
<package>URLTools</package>
<directoryFormat>packageOnly</directoryFormat>
<loadPriority>7</loadPriority>
<provider>Greg Moser</provider>
<version>2.5</version>
<providerURL>http://www.gregmoser.com/</providerURL>
<category>Application</category>
<settings>
	<setting>
		<name>isSlatwallIntegrationActive</name>
		<label>Enable URLTools integration for Slatwall v3</label>
		<type>RadioGroup</type>
		<required>false</required>
		<optionList>0^1</optionList>
		<optionLabelList>No^Yes</optionLabelList>
		<defaultValue>0</defaultValue>
	</setting>
</settings>
<eventHandlers>
	<eventHandler event="onApplicationLoad" component="eventHandler" persist="false"/>
</eventHandlers>
<displayobjects location="global">
</displayobjects>
</plugin>