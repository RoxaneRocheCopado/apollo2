@isTest
public with sharing class OpenAiApiServiceTest {

  private class SingleRequestMock implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Blob bodyAsBlob;
    protected Map<String, String> responseHeaders;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public SingleRequestMock(Integer code, String status, String body,
        Map<String, String> responseHeaders) {
      this.code = code;
      this.status = status;
      this.bodyAsString = body;
      this.bodyAsBlob = null;
      this.responseHeaders = responseHeaders;
    }
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse resp = new HttpResponse();
      resp.setStatusCode(code);
      resp.setStatus(status);
      if (bodyAsBlob != null) {
        resp.setBodyAsBlob(bodyAsBlob);
      } else {
        resp.setBody(bodyAsString);
      }

      if (responseHeaders != null) {
        for (String key : responseHeaders.keySet()) {
          resp.setHeader(key, responseHeaders.get(key));
        }
      }
      return resp;
    }
  }

  @isTest
  static void calloutSuccess() {
    SingleRequestMock errResponse = new SingleRequestMock(200, 'Success',
        '{ "object": "chat.completion", "model": "text-davinci-003", '+
        '"choices":[{"text":"Hello World" }]'+
        '}',null);
    Test.setMock(HttpCalloutMock.class, errResponse);
    try {
      OpenAiApiService.OpenAiWrapper result = OpenAiApiService.sendRequest('{}');
      System.assertEquals(true, result.isSuccess, 'values do not match');
      System.assertEquals(200, result.statusCode, 'values do not match');
      System.assertEquals('Success', result.status, 'values do not match');
      System.assertEquals('', result.message, 'values do not match');
      Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(result.response);
      System.assertEquals('chat.completion', m.get('object'), 'values do not match');
      System.assertEquals('text-davinci-003', (String)m.get('model'), 'values do not match');
      List<Object> choices = (List<Object>)m.get('choices');
      System.assertEquals(1, choices.size(), 'values do not match');
      Map<String, Object> choice = (Map<String, Object>)choices.get(0);
      String choiceText = (String)choice.get('text');
      System.assertEquals('Hello World', choiceText, 'values do not match');
    } catch(Exception e) {
      system.assert(false, 'Expected success but Exception was caught.');
    }
        }

        @isTest
    static void calloutBadApiKey() {
      SingleRequestMock errResponse = new SingleRequestMock(401, 'Error',
          '{ "error": {'+
          '"message": "You didn\'t provide an API key. You need to provide your API key in an Authorization header using Bearer auth (i.e. Authorization: Bearer YOUR_KEY), or as the password field (with blank username) if you\'re accessing the API from your browser and are prompted for a username and password. You can obtain an API key from https://platform.openai.com/account/api-keys.",'+
          '"type": "invalid_request_error",'+
          '"param": null, '+
          '"code": null }}',null);
      Test.setMock(HttpCalloutMock.class, errResponse);
      try {
        OpenAiApiService.OpenAiWrapper result = OpenAiApiService.sendRequest('{}');
        System.assertEquals(false, result.isSuccess, 'values do not match');
        System.assertEquals(401, result.statusCode, 'values do not match');
        System.assertEquals('invalid_request_error', result.status, 'values do not match');
        String expectedMessage = 'You didn\'t provide an API key. You need to provide your API key in an Authorization header using Bearer auth (i.e. Authorization: Bearer YOUR_KEY), or as the password field (with blank username) if you\'re accessing the API from your browser and are prompted for a username and password. You can obtain an API key from https://platform.openai.com/account/api-keys.';
        System.assertEquals(expectedMessage, result.message, 'values do not match');
      } catch(Exception e) {
        System.debug(e);
        System.assert(false, 'expected exception');
      }
    }

    @isTest
    static void triggerCatchException() {
      SingleRequestMock errResponse = new SingleRequestMock(500, 'Error','<html>Some Other Error</html>',null);
      Test.setMock(HttpCalloutMock.class, errResponse);
      try {
        OpenAiApiService.OpenAiWrapper result = OpenAiApiService.sendRequest('{}');
        System.assertEquals(false, result.isSuccess, 'values do not match');
        System.assertEquals(500, result.statusCode, 'values do not match');
        System.assert(result.message.contains('Unexpected character'), 'values do not match');
        System.assertEquals('System.JSONException', result.status, 'values do not match');
      } catch(Exception e) {
        System.debug(e);
        System.assert(false, 'expected exception');
      }
    }
  }