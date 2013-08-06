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
<version>2.6</version>
<providerURL>http://www.gregmoser.com/</providerURL>
<category>Application</category>
<settings>
	<setting>
		<name>isResponsibleForCanonicalInHTMLHead</name>
		<label>Add canonical to HTML head</label>
		<hint>The canonical URL is only added to the HTML head, if there is NO redirect and at least 1 alternate URL.</hint>
		<type>RadioGroup</type>
		<required>false</required>
		<optionList>0^1</optionList>
		<optionLabelList>No^Yes</optionLabelList>
		<defaultValue>1</defaultValue>
	</setting>
	<setting>
		<name>isSlatwallIntegrationActive</name>
		<label>Enable URLTools integration for Slatwall v3</label>
		<hint>Enables URLTools for using together with Slatwall v3 products.</hint>
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