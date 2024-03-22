@isTest
public with sharing class Elixir_LogUtility_Test {

    @isTest
    static void testLogResponse() {
        // Test data setup
        String jsonString = '{"key": "value"}';
        String responseString = 'Sample response';

        // Call the logResponse method
        Test.startTest();
        Elixir_LogUtility.logResponse(jsonString, responseString);
        Elixir_LogUtility.insertLogs();
        Test.stopTest();

        // Verify integration messages list contains the logged response
        List<Integration_Message__c> integrationMessages = [SELECT Id,JSON__c,Elixir_Response_Json__c FROM Integration_Message__c WITH SECURITY_ENFORCED];
        System.assertEquals(1, integrationMessages.size(),'Size  of Integration Messages does not match');
        Integration_Message__c intObj = integrationMessages[0];
        System.assertEquals(jsonString, intObj.JSON__c,'Wrong Request Json');
        System.assertEquals(responseString, intObj.Elixir_Response_Json__c,'Wrong Response Json');
    }

}