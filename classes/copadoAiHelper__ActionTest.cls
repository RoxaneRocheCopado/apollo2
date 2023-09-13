@isTest
private with sharing class ActionTest {
    private final static String actionName = ActionTest.DemoAction1.class.getName();

    @isTest
    private static void testListAction() {
        Action.mockAction = DemoAction1.class;

        Map<String, String> actions = Action.listActions(null);
        Assert.isTrue(actions.size() >= 1, 'could not find class: '+actionName+' found: '+actions.keySet());
    }

    @isTest
    private static void testCallAction() {
        Action.mockAction = DemoAction1.class;

        Map<String, Object> args = new Map<String, Object>();
        ActionResponse response = Action.callAction(null, actionName, args);
        Assert.areEqual('message!', response.message);
    }

    // NOTE: it must be private, hidden, otherwise once installed it WILL show up and fail
    private with sharing class DemoAction1 implements Action.Actionable {
        public String[] appliesTo() {
            return new String[]{};
        }
        public String jsonSchema() {
            return '{"name": "ActionTest.DemoAction1"}';
        }
        public ActionResponse call(Id contextId, Map<String, Object> args) {
            ActionResponse response = new ActionResponse();
            response.message = 'message!';
            return response;
        }
    }
}