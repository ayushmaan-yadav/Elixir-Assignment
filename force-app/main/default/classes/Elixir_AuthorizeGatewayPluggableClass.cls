/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
global with sharing class Elixir_AuthorizeGatewayPluggableClass implements Callable {

    /**
    * @description Method Called by the Elxir Plug.
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String action,@param Map<String, Object> args
    * @returns Object
    **/
    global Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'InsurancePayment' {
                Decimal amountPaid = (Decimal) args.get('amountPaid');
                String selectedProcedureRecords = (String)args.get('selectedProcedureRecords');
                String paymentInfoId = (String)args.get('paymentInfoId');
                String acctId = (String) args.get('acctId');
                
                // Payment Info Id is Payment Information SFID 
                if (paymentInfoId != '') {
                    return Elixir_AuthorizeGatewayController.reauthorizeAndCapturePayment(amountPaid,selectedProcedureRecords,paymentInfoId,acctId);  
                } else {
                    return Elixir_AuthorizeGatewayController.authorizeNewPayment(amountPaid,selectedProcedureRecords,acctId);
                }
            }
            when 'PrivatePayment' {
                Decimal amountPaid = (Decimal) args.get('amountPaid');
                String selectedProcedureRecords = (String)args.get('selectedProcedureRecords');
                String paymentInfoId = (String)args.get('paymentInfoId');
                String acctId = (String) args.get('acctId');  

                // Payment Info Id is Payment Information SFID 
                if (paymentInfoId != null && paymentInfoId !='') {
                    return Elixir_AuthorizeGatewayController.reauthorizeAndCapturePayment(amountPaid,selectedProcedureRecords,paymentInfoId,acctId);  
                } else {
                    return Elixir_AuthorizeGatewayController.authorizeNewPayment(amountPaid,selectedProcedureRecords,acctId);
                }
            }
            when 'SchedulePrivatePayment' {
                Decimal amountPaid = (Decimal) args.get('amountPaid');
                String selectedProcedureRecords = (String)args.get('selectedProcedureRecords');
                String acctId = (String) args.get('acctId'); 
                List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLine = (List<ElixirSuite__Payment_Plan_Line_Item__c>) args.get('selectedpaymentplanline');
                String paymentInfoId = (String)args.get('paymentInfoId');

                if (paymentInfoId != null && paymentInfoId !='') {
                    return Elixir_AuthorizeGatewayController.reauthorizeAndCapturePaymentForPaymentPlan(amountPaid,paymentPlanLine,selectedProcedureRecords,paymentInfoId,acctId);  
                } else {
                    return Elixir_AuthorizeGatewayController.authorizeNewPaymentForPaymentPlan(amountPaid,paymentPlanLine,selectedProcedureRecords,acctId,false,null);
                }

            }
            when else {
                return null;
                //throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
    }

}