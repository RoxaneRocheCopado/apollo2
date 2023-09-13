@isTest
private with sharing class OpenAIQuestionProcessorTest {

    @isTest
    private static void testMultipleObjects() {
        System.runAs([SELECT Id FROM User WHERE Username = 'username@myemail.com'][0]) {
            //Setup
            OpenAITestDataFactory.createDefaultTestData('Salesforce');

            // Exercise: unsupported object (pipeline)
            {
                OpenAIQuestionProcessor.getAvailableQuestionsFor(OpenAITestDataFactory.pipeline.Id);
                OpenAIQuestionProcessor.processQuestion(OpenAITestDataFactory.pipeline.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap('', '', '').serialize());
                Assert.isTrue(true, 'called only for code coverage reasons');
            }

            // Exercise: promotion
            {
                OpenAIQuestionProcessor.getAvailableQuestionsFor(OpenAITestDataFactory.promotion.Id);
                Map<String,String> result = OpenAIQuestionProcessor.processQuestion(OpenAITestDataFactory.promotion.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap('logs=====\n{logs}\ndeploymenterrors=====\n{deploymenterrors}\nuserstorylist=====\n{userstorylist}', '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);
                Assert.isTrue(result.get('prompt').startsWith('logs='), 'incorrect result='+result);
            }

            // Exercise: deploymnet
            {
                OpenAIQuestionProcessor.getAvailableQuestionsFor(OpenAITestDataFactory.deployment.Id);
                Map<String,String> result = OpenAIQuestionProcessor.processQuestion(OpenAITestDataFactory.deployment.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap('logs=====\n{logs}\ndeploymenterrors=====\n{deploymenterrors}\nuserstorylist=====\n{userstorylist}', '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);
                Assert.isTrue(result.get('prompt').startsWith('logs='), 'incorrect result='+result);
            }

            // Exercise: user story
            {
                OpenAIQuestionProcessor.getAvailableQuestionsFor(OpenAITestDataFactory.userStory.Id);
                Map<String,String> result = OpenAIQuestionProcessor.processQuestion(OpenAITestDataFactory.userStory.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap('title=====\n{title}', '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);
                Assert.isTrue(result.get('prompt').startsWith('title='), 'incorrect result='+result);
            }

            // Exercise: release
            {
                Map<String, Object> res1 = OpenAIQuestionProcessor.getAvailableQuestionsFor(OpenAITestDataFactory.release.Id);
                Object[] prompts = (Object[])res1.get('prompts');
                String prompt = ((Map<String,String>)prompts[prompts.size()-1]).get('prompt');
                System.debug(prompt);
                Map<String,String> result = OpenAIQuestionProcessor.processQuestion(OpenAITestDataFactory.release.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap(prompt, '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);
            }

            // Exercise: result
            {
                copado__Result__c record = new copado__Result__c(copado__Job_Type__c = 'Manual Tests');
                insert record;

                Map<String, Object> res1 = OpenAIQuestionProcessor.getAvailableQuestionsFor(record.Id);
                Object[] prompts = (Object[])res1.get('prompts');
                String prompt = ((Map<String,String>)prompts[prompts.size()-1]).get('prompt');
                System.debug(prompt);
                Map<String,String> result = OpenAIQuestionProcessor.processQuestion(record.Id, 
                    new OpenAIQuestionProcessor.QuestionWrap(prompt, '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);

                // also with a log.
                ContentVersion cv = new ContentVersion(
                    Title = 'Function logs for DV000000',
                    PathOnClient = 'test_file.txt',
                    VersionData = Blob.valueOf('test content\nsecond line\nthird line'),
                    Description = 'version 1',
                    FirstPublishLocationId = record.id
                );
                insert cv;
                prompt = 'logs: {logs}';
                result = OpenAIQuestionProcessor.processQuestion(record.Id,
                    new OpenAIQuestionProcessor.QuestionWrap(prompt, '', '').serialize());
                // Validate
                Assert.isFalse(result.get('prompt').contains('{'), 'all the merges should have been removed, but result='+result);
            }

        }
    }


    @TestSetup
    private static void makeData() {
        User runAsUser = new User(
            LastName = 'UserLastName',
            Username = 'username@myemail.com',
            Email = 'username@myemail.com',
            Alias = 'MyAlias',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert runAsUser;

        System.runAs(runAsUser) {
            copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
            copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
            userLicense.isCCMEnabled = true;
            userLicense.isCopadoEnabled = true;
            userLicense.userId = runAsUser.Id;
            copadoGlobalAPI.upsertCopadoLicense(userLicense);
            
            PermissionSetAssignment copado = new PermissionSetAssignment();
            copado.PermissionSetId = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Copado_User' LIMIT 1].Id;
            copado.AssigneeId = runAsUser.Id;

            insert copado;
        }
    }

}