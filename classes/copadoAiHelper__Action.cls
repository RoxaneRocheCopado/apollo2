global with sharing class Action {
    private final static String NAMESPACE = Action.class.getName().contains('.') ?Action.class.getName().substringBefore('.') :'';

    @auraEnabled
    global static Map<String,String> listActions(Id contextId) { 
        Map<String,String> result = new Map<String,String>();
        Map<String, Actionable> actions = getActionables(contextId);
        for(String actionName : actions.keySet()) {
            result.put(actionName, actions.get(actionName).jsonSchema());
        }
        return result;
    }

    @auraEnabled
    global static ActionResponse callAction(Id contextId, String name, Map<String, Object> args) { 
        ActionResponse response = new ActionResponse();
        Map<String, Actionable> actions = getActionables(contextId);
        if(actions.containsKey(name)) {
            try{
                args.put('autoContextId', contextId);
                response = actions.get(name).call(contextId, args);
            }catch(Exception e) {
                response.error = 'There was an error calling ' + name+': '+e.getMessage()+' (line: '+e.getLineNumber()+')';
            }
        }else{
            response.error = 'Could not find the Action ' + name;
        }
        return response;
    }

    global interface Actionable {
        String[] appliesTo();
        String jsonSchema();
        ActionResponse call(Id contextId, Map<String, Object> args);
    }

    // PRIVATE

    @testVisible
    private static Type mockAction = null;

    private static Map<String, Actionable> getActionables(String contextId) {
        String sobjectName = getSobjectType(contextId).replace('copado__','').replace('__c', '');
        Map<String, Actionable> result = new  Map<String, Actionable>();

        // NOTE: remove the namespace from the interface. Once pacakged, it has it
        String name = Action.Actionable.class.getName();
        name = String.isEmpty(NAMESPACE) ?name :name.replaceFirst(NAMESPACE+'.', '');

        // NOTE: the code is implemented in a special way because we should not package a visible apex class, so, we mock the empty query, and we aggregate in another structure
        List<String[]> classes = new List<String[]>();
        // NOTE: no user mode for this. Regular users do not have access to ApexTypeImplementor
        // Security is still managed, because only classes that implement our custom interface will be available
        ApexTypeImplementor[] classes1 = [SELECT ClassNamespacePrefix, ClassName FROM ApexTypeImplementor WHERE InterfaceName = :name AND InterfaceNamespacePrefix = :namespace ];
        for(ApexTypeImplementor c: classes1) { classes.add( new String[]{c.ClassNamespacePrefix, c.ClassName}); }

        if(mockAction!=null) {
            classes = new List<String[]>{new String[]{NAMESPACE, mockAction.getName().replaceFirst(NAMESPACE+'.', '')}};
        }

        for(String[] c : classes) {
            Type t = Type.forName(c[0], c[1]);
            t = mockAction==null ?t :mockAction;
            if(t==null) {
                System.debug('Error: could not find type'+c+' namespace:'+NAMESPACE+' name:'+name+'.');
                continue;
            }
            String key = String.isEmpty(c[0]) ? c[1] : c[0]+'.'+c[1];
            Actionable act = (Actionable)t.newInstance();
            if(act.appliesTo().isEmpty() || act.appliesTo().contains(sobjectName)) {
                result.put(key, (Actionable)t.newInstance());
            }
        }
        return result;
    }

    private static String getSobjectType(String contextId) {
        return String.isEmpty(contextId) ?'' :Id.valueOf(contextId).getSobjectType().getDescribe().getName();
    }
}