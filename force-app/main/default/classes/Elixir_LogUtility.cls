/**
 * @description       : This Class contains method to log the response.
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_LogUtility {

    private static List<Integration_Message__c>  integrationMessages = new List<Integration_Message__c>();

    /**
    * @description add the response in Integration_Message__c global List
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String jsonString String reponseType 
    * @returns None
    **/
    public  static void logResponse(String jsonString,String responseString) {
        Integration_Message__c intObj = new Integration_Message__c();
        if (jsonString != null || jsonString != '' ) { 
            intObj.JSON__c = jsonString;
            intObj.Elixir_Response_Json__c = responseString;
            integrationMessages.add(intObj);
        }
    }

    /**
    * @description Insert All Integration_Message__c Object
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None
    * @returns None
    **/
    public static void insertLogs(){ 
        if (integrationMessages.size() > 0) {
            Elixir_DMLManager.insertAsUser(integrationMessages);
            integrationMessages.clear();
        }

    }
    
}