public with sharing class OpenAiApiService {

    public class OpenAiWrapper {
        @AuraEnabled
        public Boolean isSuccess { get; set; }

        @AuraEnabled
        public Integer statusCode { get; set; }

        @AuraEnabled
        public String status { get; set; }

        @AuraEnabled
        public String message { get; set; }

        @AuraEnabled
        public String response { get; set; }
    }

    @AuraEnabled
    public static OpenAiWrapper sendRequest(String body) {

        // NOTE: we parse the body to reprocess the request and enforce the org defaults to maintain compatibility
        Map<String, Object> bodyMap = (Map<String, Object>)JSON.deserializeUntyped(body);

        Copado_AI_Companion_Configuration__mdt conf = getConfig();
        bodyMap.put('model', conf.OpenAI_Model__c);
        if(conf.Max_Tokens__c>0) {
            bodyMap.put('max_tokens', Integer.valueOf(conf.Max_Tokens__c));
        }
        bodyMap.put('temperature', conf.OpenAI_Temperature__c);

        body = JSON.serialize(bodyMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:.__OpenAI/v1/chat/completions');
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(body);
        req.setTimeout(110000);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        OpenAiWrapper lwcResponse = new OpenAiWrapper();
        lwcResponse.statusCode = res.getStatusCode();
        lwcResponse.status = res.getStatus();

        if (res.getStatusCode() == 200) {
            lwcResponse.isSuccess = true;
            lwcResponse.message = '';
            lwcResponse.response = res.getBody();
        } else {
            lwcResponse.isSuccess = false;

            try {
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                Map<String, Object> e = (Map<String, Object>)m.get('error');
                lwcResponse.message = (String)e.get('message');
                lwcResponse.status = (String)e.get('type');
            } catch(Exception e) {
                System.debug(LoggingLevel.ERROR, e);
                lwcResponse.message = e.getMessage();
                lwcResponse.status = e.getTypeName();
            }
        }
        return lwcResponse;
    }

    public static Copado_AI_Companion_Configuration__mdt getConfig() {
        Map<String, Copado_AI_Companion_Configuration__mdt> confs = Copado_AI_Companion_Configuration__mdt.getAll();
        for(Copado_AI_Companion_Configuration__mdt c : confs.values()) {
            if(c.DeveloperName!='Default') {
                return c;
            }
        }
        if(!confs.isEmpty()) {
            // returns the default record, since there was no non-default named one.
            return confs.values()[0];
        }
        // not having any record should never happen, but just in case.
        return new Copado_AI_Companion_Configuration__mdt();
    }
}