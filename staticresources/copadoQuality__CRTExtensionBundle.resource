{
  "recordTypeMap": {},
  "RecordSetBundles": [
    {
      "Records": [
        {
          "attributes": {
            "type": "copado__JobTemplate__c",
            "url": "/services/data/v54.0/sobjects/copado__JobTemplate__c/a0u7Z00000BeqzxQAB"
          },
          "copado__ApiName__c": "RunCrtTests",
          "copado__Type__c": "Standard",
          "copado__Version__c": 1,
          "Id": "a0u7Z00000BeqzxQAB",
          "LastReferencedDate": "2022-04-25T15:13:34.000+0000",
          "LastViewedDate": "2022-04-25T15:13:34.000+0000",
          "Name": "Run Copado Robotic Tests"
        }
      ],
      "ObjectType": "copado__JobTemplate__c"
    },
    {
      "Records": [
        {
          "attributes": {
            "type": "copado__JobStep__c",
            "url": "/services/data/v56.0/sobjects/copado__JobStep__c/a0t7Z00000JUbgpQAD"
          },
          "copado__ApiName__c": "OrchestrateTestsExecution",
          "copado__ConfigJson__c": "{\"flowName\":\"copadoQuality.RunCrtTests\",\"parameters\":[{\"name\":\"stepId\",\"value\":\"{$context.Id}\"},{\"name\":\"sourceCredentialBaseUrl\",\"value\":\"{$Source.Credential.Endpoint}\"},{\"name\":\"sourceCredentialSessionId\",\"value\":\"{$Source.Credential.SessionId}\"},{\"name\":\"destinationCredentialBaseUrl\",\"value\":\"{$Destination.Credential.Endpoint}\"},{\"name\":\"destinationCredentialSessionId\",\"value\":\"{$Destination.Credential.SessionId}\"}]}",
          "copado__CustomType__c": "Salesforce Flow",
          "copado__JobTemplate__c": "a0u7Z00000BeqzxQAB",
          "copado__Order__c": 2,
          "copado__Type__c": "Flow",
          "Id": "a0t7Z00000JUbgpQAD",
          "Name": "Orchestrate Tests Execution"
        },
        {
          "attributes": {
            "type": "copado__JobStep__c",
            "url": "/services/data/v56.0/sobjects/copado__JobStep__c/a0t7Z00000JUbgqQAD"
          },
          "copado__ApiName__c": "Run Copado Robotic Tests_Set Source Environment On CRT Job Execution",
          "copado__ConfigJson__c": "{\"flowName\":\"copadoQuality.SetSourceEnvironmentOnCrtJobExecution\",\"parameters\":[{\"name\":\"jobExecutionId\",\"value\":\"{$Context.JobExecution__r.Id}\"},{\"name\":\"testIds\",\"value\":\"{$Context.JobExecution__r.DataJson.testIds}\"},{\"name\":\"environmentId\",\"value\":\"{$Context.JobExecution__r.DataJson.environmentId}\"}]}",
          "copado__CustomType__c": "Salesforce Flow",
          "copado__JobTemplate__c": "a0u7Z00000BeqzxQAB",
          "copado__Order__c": 1,
          "copado__Type__c": "Flow",
          "Id": "a0t7Z00000JUbgqQAD",
          "Name": "Set Source Environment On CRT Job Execution"
        }
      ],
      "ObjectType": "copado__JobStep__c"
    }
  ],
  "blobsByUID": {}
}
