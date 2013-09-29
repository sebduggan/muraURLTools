<!---
    URL Tools - A Plugin for Mura CMS
    Copyright (C) 2011 Greg Moser - www.gregmoser.com
    Copyright (C) 2013 Seb Duggan - sebduggan.com
    
    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<plugin>
<name>URL Tools</name>
<package>URLTools</package>
<directoryFormat>packageOnly</directoryFormat>
<provider>Seb Duggan</provider>
<version>2.7</version>
<providerURL>http://sebduggan.com/</providerURL>
<category>Application</category>
<settings>
	<setting>
		<name>isResponsibleForCanonicalInHTMLHead</name>
		<label>Add canonical to HTML head</label>
		<hint>The canonical URL is only added to the HTML head, if there is NO redirect and at least 1 alternate URL.</hint>
		<type>Select</type>
		<required>false</required>
		<optionList>1^0</optionList>
		<optionLabelList>Yes^No</optionLabelList>
		<defaultValue>1</defaultValue>
	</setting>
</settings>
<eventHandlers>
	<eventHandler event="onApplicationLoad" component="eventHandler" persist="false"/>	
</eventHandlers>
<displayobjects location="global">
</displayobjects>
</plugin>