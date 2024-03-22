/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthorizeCallout {

    
    private static final String RESPONSE = 'Response';
    private static final String REQUEST = 'Request';
    private Integration_Credentials__c  integrationCreds;

    /**
    * @description Constructer of the Class
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None 
    * @returns None
    **/
    public Elixir_AuthorizeCallout() {
        List<Integration_Credentials__c> credList= [SELECT EndPointURL__c,Integration_Key__c,Elixir_Transaction_Key__c FROM Integration_Credentials__c WHERE Name LIKE 'Authorization Dot Net%' AND Elixir_Active__c = true WITH SECURITY_ENFORCED LIMIT 1];
        if (credList.size() > 0){
            integrationCreds = credList[0];
        }
    }

    /**
    * @description Get API key for authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None
    * @returns String
    **/
    public String getAPIKey(){
        return integrationCreds != null ? integrationCreds.Integration_Key__c : null;
    }

    /**
    * @description Get Transaction key for authorize.net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None
    * @returns String
    **/
    public String getTransactionKey(){
        return integrationCreds != null ? integrationCreds.Elixir_Transaction_Key__c : null;
    }

    /**
    * @description Send and Create Http Request
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String requestJson
    * @returns HttpResponse
    **/
    public HttpResponse sendRequest(String requestJson) {

        Http http = new Http();
        HttpResponse httpRes;

        HttpRequest req = createHttpReq(requestJson);
        try {
            httpRes = http.send(req);
            Elixir_LogUtility.logResponse(requestJson,httpRes.getBody());
            if (httpRes.getStatusCode() == 200) {
                // Handle Successful Response Here
                System.debug('Successful Response');
            } else if (httpRes.getStatusCode() >=400 && httpRes.getStatusCode() <= 499) {
                // Handle 400 Series Codes   
                System.debug('400 Series Codes');
            } else if (httpRes.getStatusCode() >=500 && httpRes.getStatusCode() <= 599) {
                // Handle 500 Series Codes 
                System.debug('500 Series Codes');
            } else {
                // Handle Other Status Code
                System.debug('Other Status Code');
            }
        } catch (Exception e) {
            // Log Response in case of Exception 
            Elixir_LogUtility.logResponse(requestJson,e.getStackTraceString());
        }
        
        return httpRes;
    }
    
    /**
    * @description Create Http Request and Add the Required Data 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param None
    * @returns HttpRequest
    **/
    private HttpRequest createHttpReq(String requestJson) {
        HttpRequest req = new  HttpRequest();
        req.setEndpoint(integrationCreds.EndPointURL__c);
        req.setBody(requestJson);
        req.setMethod('POST');
        return req;
    }

}