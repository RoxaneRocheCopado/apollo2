public with sharing class OpenAIQuestionProcessor {

    @AuraEnabled
    public static Map<String,String> processQuestion(String contextId, Map<String,String> questionRec) {
        String sobjectName = String.isEmpty(contextId) ?'' : Id.valueOf(contextId).getSobjectType().getDescribe().getName();
        QuestionWrap question = new QuestionWrap(questionRec);
        Copado_AI_Companion_Configuration__mdt conf = OpenAiApiService.getConfig();

        // for security reasons we only support copado objects or specified ones
        // otherwise end user could expose account, contact, lead, user, ...
        if(!isAllowedObject(conf, sobjectName)) {
            return question.serialize();
        }

        // first, we preprocess some legacy replacements, plus some very specific per-ojbect ones
        // such as logs and indirectly related user stories
        switch on sobjectName {
            when 'copado__Promotion__c' {
                question = getPromotionDataForQuestion(contextId, question);
            }
            when 'copado__Deployment__c' {
                question = getDeploymentForQuestion(contextId, question);
            }
            when 'copado__User_Story__c' {
                question = getUserStoryForQuestion(contextId, question);
            }
            when 'copado__Result__c' {
                question = getResultQuestion(contextId, question);
            }
        }
        return getGenericObjectData(contextId, question).serialize();
    }

    @AuraEnabled
    public static Map<String, Object> getAvailableQuestionsFor(String contextId) {
        String sobjectName = String.isEmpty(contextId) ?'' : Id.valueOf(contextId).getSobjectType().getDescribe().getName();
        Map<String, Object> resp = new Map<String, Object>{'objectLabel'=> '...', 'prompts'=> new String[]{} };
        Copado_AI_Companion_Configuration__mdt conf = OpenAiApiService.getConfig();

        // for security reasons we only support copado objects or specified ones
        // otherwise end user could expose account, contact, lead, user, ...
        if(!isAllowedObject(conf, sobjectName)) {
            return resp;
        }

        String sobjectNameLike = sobjectName.replace('copado__','').replace('__c','');
        String langLike = UserInfo.getLanguage().replace('_.*', '');
        Copado_AI_Companion_Prompt__mdt[] prompts = [SELECT Label, Language__c, Order__c, 
            Object__c, Prompt__c, System_prompt_before__c FROM Copado_AI_Companion_Prompt__mdt 
            WHERE Active__c=true AND Object__c = :sobjectNameLike AND (Language__c = '' OR Language__c = :langLike)
            WITH USER_MODE
            ORDER BY Order__c ASC, SystemModstamp ASC LIMIT 100];

        // if there is at least one translated question, use language exclusively. If not, fallback to the default language
        String language=null;
        for(Copado_AI_Companion_Prompt__mdt p : prompts) {
            if(!String.isBlank(p.Language__c)) {
                language = p.Language__c;
                break;
            }
        }

        System.debug(logginglevel.INFO, 'getAvailableQuestionsFor '+contextId+'; '+language+'; '+langLike+'; '+prompts.size());

        // NOTE: due to the dangers of namespaces, nested classes and CMDT access, we should not return the CMDT or a wrapper
        List<Map<String,Object>> questions = new List<Map<String,Object>>();
        for(Copado_AI_Companion_Prompt__mdt p : prompts) {
            if(p.Language__c == language) {
                questions.add(new Map<String,Object>{'label'=>p.Label, 'prompt'=>p.Prompt__c, 
                'before'=>p.System_prompt_before__c, 'after'=>''});
            }
        }

        if(String.isNotBlank(sobjectName)) {
            Map<String, String> fieldsAndLabels = getFieldsAndLabelsFor(sobjectName);
            String userStoryRelationshipName = fieldsAndLabels.remove('user story list');
            String predefined = '';
            for(String label : fieldsAndLabels.values()) {
                predefined+='\n- '+label+': {'+label.toLowerCase()+'}';
            }
            if(String.isNotEmpty(userStoryRelationshipName)) {
                // NOTE: hack to give the Sprint a different default
                if(sobjectName=='copado__Sprint__c') {
                    predefined+='\n\n- User Story List: {user story list with points}';
                }else{
                    predefined+='\n\n- User Story List: {user story list}';
                }
            }
            String genericPrompt = String.format(System.Label.CHAT_GENERIC_PROMPT_FORMAT, 
                new String[]{sobjectNameLike, predefined.trim()});

            questions.add(new Map<String,String>{
                'label' => System.Label.CHAT_GENERIC_PROMPT_LABEL, 
                'prompt' => genericPrompt, 
                'before' => '', 
                'after' => ''
            });
        }
        resp.put('prompts', questions);

        if(String.isNotBlank(sobjectName)) {
            // NOTE: this only works reliably with custom objects... standard objects might not have a Name field
            String objectName = '';
            try{
                SOBject s = Database.queryWithBinds('SELECT Name FROM '+sobjectName+' WHERE Id = :id',
                    new Map<String, Object>{'id' => contextId}, 
                    AccessLevel.USER_MODE);
                objectName = (String)s.get('Name');
            }catch(QueryException ex) {
                System.debug('error querying sobject '+ex);
            }
            resp.put('objectLabel', sobjectNameLike.replace('_', ' ')+' '+objectName );
        }

        // ALSO add any Action (OpenAI Function) if there are any defined and it is allowed
        if(conf.Allows_Functions__c) {
            Map<String,String> actions = Action.listActions(contextId);
            resp.put('actions', actions);
        }
        return resp;
    }

    /**
     * Based on a promotion Id and the template of a question, return the text to be sent to OpenAI
     */
    private static QuestionWrap getPromotionDataForQuestion(Id promotionId, QuestionWrap question) {
        String logs = '';
        String deploymentErrors = '';
        String lastDeploymentId;
        Boolean isClassic;

        copado__Promotion__c promotion = [SELECT copado__Status__c, copado__Platform__c,
            (SELECT Title, Body FROM Notes ORDER By CreatedDate DESC LIMIT 1), 
            (SELECT Id FROM copado__Deployments__r ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT copado__User_Story__r.Name, copado__User_Story__r.copado__User_Story_Title__c , 
                copado__User_Story__r.copado__Status__c, 
                copado__User_Story__r.copado__Total_Actual_Points__c, 
                copado__User_Story__r.copado__Total_Story_Points__c
                FROM copado__Promoted_User_Stories__r ORDER BY Name DESC LIMIT 80)
            FROM copado__Promotion__c WHERE Id = :promotionId WITH SECURITY_ENFORCED LIMIT 1];

            isClassic = String.isEmpty(promotion.copado__Platform__c) || promotion.copado__Platform__c=='Salesforce';
        lastDeploymentId = promotion.copado__Deployments__r.size() >0 ? promotion.copado__Deployments__r[0].Id : null;

        // check if the US is 1stgen or 2ndgen based on copado__Platform__c
        if(isClassic) {
            logs = promotion.Notes.size()>0 ? promotion.Notes[0].Body : null;
            // TODO: check the SIZE of the file, to avoid memory errors, and also chatgpt limits (?)
            deploymentErrors = [SELECT Body FROM Attachment WHERE ParentId = :lastDeploymentId AND Name LIKE 'ERRORs%.txt' ORDER BY CreatedDate DESC LIMIT 1]?.Body?.toString();
        }

        Map<String, String> params = new Map<String, String>{
            'logs' => logs,
            'deployment errors' => deploymenterrors,
            'deploymenterrors' => deploymenterrors,
            '' => ''
        };

        copado__User_Story__c[] userStories = new copado__User_Story__c[]{};
        for(copado__Promoted_User_Story__c pus : promotion.copado__Promoted_User_Stories__r) {
            userStories.add(pus.copado__User_Story__r);
        }
        processUserStoryList(userStories, params);

        question.prompt = processQuestionParams(question.prompt, params);
        question.before = processQuestionParams(question.before, params);
        //question.after = processQuestionParams(question.after, params);

        return question;
    }

    private static QuestionWrap getDeploymentForQuestion(Id deploymentId, QuestionWrap question) {
        String logs = '';
        String deploymentErrors = '';
        Boolean isClassic;

        copado__Deployment__c deployment = [SELECT copado__Promotion__c FROM copado__Deployment__c WHERE Id = :deploymentId WITH SECURITY_ENFORCED LIMIT 1];
        String promotionId = deployment.copado__Promotion__c;

        copado__Promotion__c promotion = new copado__Promotion__c();
        if(!String.isEmpty(promotionId)) {
            promotion = [SELECT copado__Status__c, copado__Platform__c,
                    (SELECT Id FROM copado__Deployments__r ORDER BY CreatedDate DESC LIMIT 1),
                    (SELECT copado__User_Story__r.Name, 
                    copado__User_Story__r.copado__User_Story_Title__c, 
                    copado__User_Story__r.copado__Status__c, 
                    copado__User_Story__r.copado__Total_Actual_Points__c, 
                    copado__User_Story__r.copado__Total_Story_Points__c
                    FROM copado__Promoted_User_Stories__r ORDER BY Name DESC LIMIT 80)
                FROM copado__Promotion__c WHERE Id = :promotionId WITH SECURITY_ENFORCED LIMIT 1];
        }
        isClassic = String.isEmpty(promotion.copado__Platform__c) || promotion.copado__Platform__c=='Salesforce';

        // check if the US is 1stgen or 2ndgen based on copado__Platform__c
        if(isClassic) {
            copado__Step__c[] steps = [SELECT Id, 
                (SELECT Id FROM copado__Deployment_Jobs__r ORDER BY CreatedDate DESC LIMIT 1) 
                    FROM copado__Step__c WHERE copado__Deployment__c = :deploymentId 
                    AND copado__Type__c = 'Git Promotion' WITH SECURITY_ENFORCED LIMIT 1];
            Id lastJobId = (!steps.isEmpty() && !steps[0].copado__Deployment_Jobs__r.isEmpty())
                ? steps[0].copado__Deployment_Jobs__r[0].Id
                :null;
            Note[] notes = [SELECT Title, Body FROM Note WHERE ParentId = :lastJobId WITH SECURITY_ENFORCED ORDER By CreatedDate DESC LIMIT 1];
            logs = notes.isEmpty() ? '' : notes[0].Body;

            // TODO: check the SIZE of the file, to avoid memory errors, and also chatgpt limits (?)
            deploymentErrors = [SELECT Body FROM Attachment WHERE ParentId = :deploymentId AND Name LIKE 'ERRORs%.txt' ORDER BY CreatedDate DESC LIMIT 1]?.Body?.toString();
        }

        Map<String, String> params = new Map<String, String>{
            'logs' => logs,
            'deployment errors' => deploymenterrors,
            'deploymenterrors' => deploymenterrors,
            '' => ''
        };

        copado__User_Story__c[] userStories = new copado__User_Story__c[]{};
        for(copado__Promoted_User_Story__c pus : promotion.copado__Promoted_User_Stories__r) {
            userStories.add(pus.copado__User_Story__r);
        }
        processUserStoryList(userStories, params);

        question.prompt = processQuestionParams(question.prompt, params);
        question.before = processQuestionParams(question.before, params);
        //question.after = processQuestionParams(question.after, params);

        return question;
    }

    private static QuestionWrap getUserStoryForQuestion(Id userStoryId, QuestionWrap question) {
        copado__User_Story__c userStory = [SELECT 
            copado__User_Story_Title__c, 
            copado__Acceptance_Criteria__c,
            copado__userStory_Role__c, 
            copado__userStory_need__c, 
            copado__userStory_reason__c,
            copado__Functional_Specifications__c, 
            copado__Technical_Specifications__c,
            copado__Project__r.Name,
            copado__Project__r.copado__Description__c,
            copado__Epic__r.copado__Epic_Title__c,
            copado__Epic__r.copado__Description__c,
            copado__Epic__r.copado__Epic_Details__c,
            copado__Epic__r.copado__Technical_Assumptions__c,
            copado__US_Feature__r.Name,
            copado__US_Feature__r.copado__Description__c,
            copado__US_Feature__r.copado__Technical_Assumptions__c
            FROM copado__User_Story__c WHERE Id = :userStoryId WITH SECURITY_ENFORCED LIMIT 1];

        Map<String, String> params = new Map<String, String>{
            'title' => userStory.copado__User_Story_Title__c,
            'project' => userStory.copado__Project__r.Name,
            'project description' => userStory.copado__Project__r.copado__Description__c,
            'epic' => userStory.copado__Epic__r.copado__Epic_Title__c,
            'epic description' => userStory.copado__Epic__r.copado__Description__c,
            'epic details' => userStory.copado__Epic__r.copado__Epic_Details__c,
            'epic technical assumptions' => userStory.copado__Epic__r.copado__Technical_Assumptions__c,
            'feature' => userStory.copado__US_Feature__r.Name,
            'feature description' => userStory.copado__US_Feature__r.copado__Description__c,
            'feature technical assumptions' => userStory.copado__US_Feature__r.copado__Technical_Assumptions__c,
            'acceptance criteria' => userStory.copado__Acceptance_Criteria__c,
            'functional specifications' => userStory.copado__Functional_Specifications__c,
            'technical specifications' => userStory.copado__Technical_Specifications__c,
            'as a' => userStory.copado__userStory_Role__c,
            'want to' => userStory.copado__userStory_need__c,
            'so that' => userStory.copado__userStory_reason__c,
            '' => ''
        };
        question.prompt = processQuestionParams(question.prompt, params);
        question.before = processQuestionParams(question.before, params);
        //question.after = processQuestionParams(question.after, params);

        return question;
    }


    /**
     * Based on a promotion Id and the template of a question, return the text to be sent to OpenAI
     */
    private static QuestionWrap getGenericObjectData(Id contextId, QuestionWrap question) {

        // get the subset of fields we will allow
        String sobjectName = String.isEmpty(contextId) ?'' : Id.valueOf(contextId).getSobjectType().getDescribe().getName();
        Map<String, String> fieldsAndLabels = getFieldsAndLabelsFor(sobjectName);
        
        String userStoryRelationshipName = fieldsAndLabels.remove('user story list');

        // query the fields of the sobject dynamically
        String flist = String.join(new List<String>(fieldsAndLabels.keySet()), ',');
        if(String.isNotEmpty(userStoryRelationshipName)) {
            flist += ',\n(SELECT Name, copado__User_Story_Title__c, copado__Status__c, copado__Total_Actual_Points__c, copado__Total_Story_Points__c FROM '+userStoryRelationshipName+' ORDER BY CreatedDate DESC LIMIT 80)';
        }
        // NOTE: we need SYSTEM_MODE to be able to query fields in managed packages without license for this user
        // describe() will always return them after this code runs packaged, but the user does not have access
        // stripInaccessible() will take care of removing any non-allowed field
        SObject s = Database.queryWithBinds('SELECT '+flist+' FROM '+sobjectName+' WHERE Id = :id',
            new Map<String, Object>{'id' => contextId}, 
            AccessLevel.SYSTEM_MODE);

        Map<String, String> params = new Map<String, String>{};

        if(String.isNotEmpty(userStoryRelationshipName)) {
            processUserStoryList(s.getSObjects(userStoryRelationshipName), params);
        }
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, new SObject[]{s});
        s = securityDecision.getRecords()[0];

        for(String fieldName : fieldsAndLabels.keySet()) {
            SObject o = s;
            String[] parts = fieldName.split('\\.');
            for(integer i=0 ; i < parts.size()-1; i++) {
                o = o.getSObject(parts[i]);
            }
            Object value = o?.get(parts[parts.size()-1]);
            if(value instanceOf Datetime) { value = ((Datetime)value).format(); }
            else if(value instanceOf Date) { value = ((Date)value).format(); }
            params.put(fieldsAndLabels.get(fieldName).toLowerCase(), String.valueOf(value));
        }

        question.prompt = processQuestionParams(question.prompt, params);
        question.before = processQuestionParams(question.before, params);
        //question.after = processQuestionParams(question.after, params);

        question.prompt = processSOQLParams(contextId, question.prompt);
        question.before = processSOQLParams(contextId, question.before);
        //question.after = processSOQLParams(contextId, question.after);

        return question;
    }

    private static QuestionWrap getResultQuestion(Id resultId, QuestionWrap question) {

        copado__Result__c result = [SELECT copado__Status__c, copado__Duration__c,
            copado__Error_Message__c, copado__Job_Type__c, copado__Result_Data__c
            FROM copado__Result__c WHERE Id = :resultId WITH SECURITY_ENFORCED LIMIT 1];

        String logs = getFileByParentAndPatternIfNotTooBig(resultId, 'Function logs for %');

        Map<String, String> params = new Map<String, String>{
            'logs' => logs,
            'Status' => result.copado__Status__c,
            'Duration (in seconds)' => String.valueOf(result.copado__Duration__c),
            'Error Message' => result.copado__Error_Message__c,
            '' => ''
        };

        question.prompt = processQuestionParams(question.prompt, params);
        question.before = processQuestionParams(question.before, params);
        //question.after = processQuestionParams(question.after, params);

        return question;
    }
    
    
    private static void processUserStoryList(copado__User_Story__c[] userStories, Map<String, String> params) {
        if(userStories == null) {
            return;
        }
        String userStoryList = '';
        String userStoryListWithStatus = '';
        String userStoryListWithPoints = '';
        // the user story list is the same for 1st and 2nd gen
        for(copado__User_Story__c pus : userStories) {
            userStoryList += String.format('{0}: `{1}`\n', new List<Object> {pus.Name, pus.copado__User_Story_Title__c});
            userStoryListWithStatus += String.format('{0}: `{1}` (status: {2})\n', new List<Object> {pus.Name, pus.copado__User_Story_Title__c,pus.copado__Status__c});
            userStoryListWithPoints += String.format('{0}: `{1}` (status: {2}, actual points: {3}, planned points: {4})\n', new List<Object> {pus.Name, pus.copado__User_Story_Title__c, pus.copado__Status__c, 
                pus.copado__Total_Actual_Points__c, pus.copado__Total_Story_Points__c});
        }
        params.put('userstorylist', userStoryList.trim());
        params.put('user story list', userStoryListWithStatus.trim());
        params.put('user story list with points', userStoryListWithPoints.trim());
    }

    public static String processSOQLParams(Id contextId, String question) {
        while(true) {
            String soql = question.substringBetween('{SELECT ','}');
            if(String.isempty(soql)) {
                break;
            }
            System.debug('context/soql: '+contextId+' '+soql);
            String jsonResult = '';
            try{
                SOBject[] s = Database.queryWithBinds('SELECT '+soql,
                    new Map<String, Object>{'contextId' => contextId}, 
                    AccessLevel.USER_MODE);
                jsonResult = JSON.serialize(s);
                // attempt to reduce the number of tokens

                jsonResult = jsonResult.replaceAll('"attributes":\\{.*?\\},?', '');
            }catch(Exception ex) {
                System.debug('error querying sobject '+ex);
                jsonResult = 'There was an error querying the data, please notify the user of this error: '+ex;
            }
            question = question.replace('{SELECT '+soql+'}', jsonResult);
        }
        return question;
    }

    private static String processQuestionParams(String question, Map<String, String> params) {
        for(String key : params.keySet()) {
            String value = textWithName(key, params.get(key));
            question = question.replace('{'+key+'}', ''+value);
        }
        return question;
    }

    private static String textWithName(String name, String value) {
        value = String.isBlank(value) ?'' :value; // null check first
        if(value.startsWith('<')) {
            // consider this rich text... converting it is REALLY annoying due to stripHtmlTags() removing whitespaces
            value = value
                .replaceAll('<\\s*li\\s*>', '~á~')
                .replaceAll('<\\s*/?\\s*(?:p|br|li|div|h\\d|tr|dt|blockquote)\\s*/?\\s*>', '~ñ~')
                .stripHtmlTags().replaceAll('~ñ~', '\n').replaceAll('~á~', '\n- ')
                .replaceAll('\n\n', '\n').replaceAll('\n\n', '\n').replaceAll('\n\n', '\n');
            value = '\n'+value;
        }else if(value.contains('\n')) {
            value = '\n'+value;
        }
        value = String.isBlank(value) ?System.Label.FIELD_EMPTY_PROMPT_TEXT :value;
        return value;
    }

    private static Map<String, String> getFieldsAndLabelsFor(String sobjectType) {
        Map<String, String> result = new Map<String, String>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        DescribeSObjectResult objDescribe = schemaMap.get(sobjectType).getDescribe();
        
        if(!objDescribe.isAccessible()) {
            return result;
        }
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (String fieldName: fieldMap.keySet()) {
            Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
            if(!field.isAccessible()) {
                continue;
            }
            String fieldLabel = field.getLabel();
            Schema.DisplayType fielddataType = field.getType();
            boolean isValidField = fielddataType==Schema.DisplayType.TEXTAREA || fielddataType==Schema.DisplayType.STRING || fielddataType==Schema.DisplayType.INTEGER || fielddataType==Schema.DisplayType.DOUBLE || fielddataType==Schema.DisplayType.PICKLIST || fielddataType==Schema.DisplayType.DATETIME || fielddataType==Schema.DisplayType.DATE || fielddataType==Schema.DisplayType.PERCENT || fielddataType==Schema.DisplayType.BOOLEAN;
            isValidField = isValidField 
                && fieldName != 'createddate'
                && fieldName != 'createdbyid'
                && fieldName != 'lastmodifieddate'
                && fieldName != 'systemmodstamp'
                && fieldName != 'ownerid'
                && fieldName != 'isdeleted'
                && fieldName != 'lastreferenceddate'
                && fieldName != 'lastvieweddate'
                && !fieldName.startsWith('copadoaihelper__') // NOTE: packaging fails without this
                ;
            if(isValidField) {
                result.put(fieldName, fieldLabel);
            }else if(fielddataType==Schema.DisplayType.REFERENCE && fieldName.contains('copado__')) {
                result.put(field.getRelationshipName()+'.Name', fieldLabel);
            }
        }

        for(Schema.ChildRelationship cr : objDescribe.getChildRelationships()) {
            if(cr.getChildSObject()==copado__User_Story__c.SObjectType && cr.getRelationshipName().startsWith('copado__')) {
                result.put('user story list', cr.getRelationshipName());
            }
        }

        return result;
    }

    private static boolean isAllowedObject(Copado_AI_Companion_Configuration__mdt conf, String sobjectName) {
        // for security reasons we only support copado objects or specified ones
        // otherwise end user could expose account, contact, lead, user, ...
        String[] objects = conf.Allowed_Objects__c!=null ?conf.Allowed_Objects__c.toLowerCase().split('[\r\n\t ]+') :new String[]{};
        return !String.isEmpty(sobjectName) && (sobjectName.startsWith('copado__') || objects.contains(sobjectName.toLowerCase()));
    }

    private static String getFileByParentAndPatternIfNotTooBig(String parentId, String namePattern) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId, 
                ContentDocument.LatestPublishedVersion.ContentSize
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId AND ContentDocument.Title like :namePattern
            WITH SECURITY_ENFORCED ORDER BY ContentDocument.ContentModifiedDate DESC LIMIT 1
        ];
        Integer latestVersionSize = links.isEmpty() 
            ? 0
            :links[0].ContentDocument.LatestPublishedVersion.ContentSize;

        if(latestVersionSize == 0){
            return '(empty)';
        }else if( latestVersionSize <= 1000000 ) { // limit to 1mb...
            Blob versionData = [SELECT VersionData FROM ContentVersion WHERE Id = :links[0].ContentDocument.LatestPublishedVersionId WITH SECURITY_ENFORCED].VersionData;
            String[] logs = versionData.toString().split('\r?\n');
            versionData = null; // free memory

            integer MAX_LINES = 256; // reduce the number of lines we have to scan, apex limits
            integer MAX_TOKENS = 3000; // this is an approximation, so keep it low. token calculation is complex
            integer wordCount = 0;
            String tokens = '(?i)\'s|\'t|\'re|\'ve|\'m|\'ll|\'d| ?[a-z]+| ?[0-9]+| ?[^ \\t0-9a-z]+|[ \\t]+(?![^ \\t])|[ \\t]+';
            String[] lastNlines = new String[]{};
            Integer startIndex = Math.max(0, logs.size() - 256);
            for (Integer i = logs.size()-1; i > 0 && wordCount < MAX_TOKENS; i--) {
                wordCount += logs[i].replaceAll(tokens, 'a').countMatches('a');
                lastNlines.add(logs[i]);
            }
            logs = null; // free memory

            // reverse the array
            integer n = lastNlines.size();
            for(Integer i=0; i < n/2; i++) {
                String o = lastNlines[i];
                lastNlines[i] = lastNlines[n-i-1];
                lastNlines[n-i-1] = o;
            }

            return String.join(lastNlines, '\n');
        }else{
            return '... the logs are too long to be processed ('+latestVersionSize+' bytes)';
        }
    }

    @testVisible
    private with sharing class QuestionWrap {
        public String prompt;
        public String before;
        public String after;

        public QuestionWrap(String prompt, String before, String after) {
            this.prompt = prompt;
            this.before = before;
            this.after = after;
        }

        public QuestionWrap(Map<String, Object> p) {
            this.prompt = (String)p.get('prompt');
            this.prompt = String.isEmpty(this.prompt) ?'' : this.prompt;
            this.before = (String)p.get('before');
            this.before = String.isEmpty(this.before) ?'' : this.before;
            this.after = (String)p.get('after');
            this.after = String.isEmpty(this.after) ?'' : this.after;
        }

        public Map<String, String> serialize() {
            return new Map<String, String>{'prompt' => this.prompt, 'before' => this.before, 'after' => this.after};
        }
    }
}