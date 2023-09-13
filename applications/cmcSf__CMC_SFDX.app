<?xml version="1.0" encoding="UTF-8"?>
<CustomApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionOverrides>
        <actionName>View</actionName>
        <comment>Action override created by Lightning App Builder during activation.</comment>
        <content>cmcSf__Package_Record_Page_SFDX</content>
        <formFactor>Large</formFactor>
        <skipRecordTypeSelect>false</skipRecordTypeSelect>
        <type>Flexipage</type>
        <pageOrSobjectType>copado__Artifact__c</pageOrSobjectType>
    </actionOverrides>
    <actionOverrides>
        <actionName>View</actionName>
        <comment>Action override created by Lightning App Builder during activation.</comment>
        <content>cmcSf__Package_Version_Record_Page_SFDX</content>
        <formFactor>Large</formFactor>
        <skipRecordTypeSelect>false</skipRecordTypeSelect>
        <type>Flexipage</type>
        <pageOrSobjectType>copado__Artifact_Version__c</pageOrSobjectType>
    </actionOverrides>
    <actionOverrides>
        <actionName>View</actionName>
        <comment>Action override updated by Lightning App Builder during activation.</comment>
        <content>cmcSf__DX_Snapshot_Record_Page</content>
        <formFactor>Large</formFactor>
        <skipRecordTypeSelect>false</skipRecordTypeSelect>
        <type>Flexipage</type>
        <pageOrSobjectType>copado__Git_Backup__c</pageOrSobjectType>
    </actionOverrides>
    <brand>
        <headerColor>#00C3EF</headerColor>
        <logoVersion>1</logoVersion>
        <shouldOverrideOrgTheme>true</shouldOverrideOrgTheme>
    </brand>
    <description>This application is enabling users to work with their Copado Multi-Cloud Extension for SFDX (CMC SFDX).</description>
    <formFactors>Small</formFactors>
    <formFactors>Large</formFactors>
    <isNavAutoTempTabsDisabled>false</isNavAutoTempTabsDisabled>
    <isNavPersonalizationDisabled>false</isNavPersonalizationDisabled>
    <isNavTabPersistenceDisabled>false</isNavTabPersistenceDisabled>
    <label>CMC SFDX</label>
    <navType>Standard</navType>
    <tabs>copado__Project__c</tabs>
    <tabs>copado__Release__c</tabs>
    <tabs>copado__Epic__c</tabs>
    <tabs>copado__Sprint__c</tabs>
    <tabs>copado__User_Story__c</tabs>
    <tabs>copado__Promotion__c</tabs>
    <tabs>copado__JobExecution__c</tabs>
    <tabs>copado__Artifact__c</tabs>
    <tabs>copado__Pipeline_Manager</tabs>
    <tabs>copado__Deployment_Flow__c</tabs>
    <tabs>copado__Environment__c</tabs>
    <tabs>copado__Org__c</tabs>
    <tabs>copado__Connection_Behavior__c</tabs>
    <tabs>copado__Git_Repository__c</tabs>
    <tabs>copado__JobTemplate__c</tabs>
    <tabs>copado__StandardRecordStatus</tabs>
    <tabs>copado__License_Manager</tabs>
    <tabs>copado__Account_Summary</tabs>
    <tabs>copado__Git_Backup__c</tabs>
    <tabs>copado__ExtensionConfiguration__c</tabs>
    <tabs>copado__Function__c</tabs>
    <uiType>Lightning</uiType>
    <utilityBar>cmcSf__CMC_SFDX_UtilityBar</utilityBar>
</CustomApplication>
