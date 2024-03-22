/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/
public with sharing class Elixir_TransactionUtility {

    
    private static final String PATIENT = 'Patient';
    private static final String INPROGRESS = 'In Progress';
    private static final String PAYMENT = 'Payment';
    private static final String PENDING = 'Pending';
    private static final String SUCCESSFUL = 'Successful';
    private static final String UNALLOCATED_PAYEMNT = 'Unallocated Payment';
    private static final String ALLOCATED_PAYEMNT = 'Allocated Payment';
    private static final String APPLIED_PAYEMNT = 'Applied Payment';
    private static final String CREDIT_CARD = 'Credit Card';
    private static final String OK = 'Ok';
    private static final String FAILED = 'Failed';

    public static Map<String,Decimal> idAndRemainingAmt = new Map<String,Decimal>();
    
    /**
    * @description Create Transaction Records Before Callout 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param String procedureId, @param String uniqueKey
    * @returns None
    **/
    public static void insertTransactionBeforePayment(String accId,Decimal amountToCharge,String procedureId,String uniqueKey) {

        // Insert Other Transaction Before the Callout 
        ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
        otherTransaction.ElixirSuite__Account__c = accId;
        otherTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
        otherTransaction.ElixirSuite__Total_Amount_Paid__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Mode_of_Payment__c = CREDIT_CARD;
        otherTransaction.ElixirSuite__Reason_Of_Payment__c = ALLOCATED_PAYEMNT;
        otherTransaction.Elixir_Payment_Status__c = PENDING;
        otherTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
        otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
        Elixir_DMLManager.insertAsUser(otherTransaction);

        // Get Master Transaction for the Procedure.
        List<ElixirSuite__Payment_Transaction__c> masterTransactionList = getMasterTranscation(procedureId.split(','));  

        List<ElixirSuite__Transactions__c> transactionList = new List<ElixirSuite__Transactions__c>();  

        Decimal remainingAllocatedAmmount = amountToCharge;

        for (ElixirSuite__Payment_Transaction__c masterTransaction : masterTransactionList) {

            if (remainingAllocatedAmmount <= 0) {
                break;
            }

            Decimal appliedAmount = Math.min(remainingAllocatedAmmount,masterTransaction.ElixirSuite__PatientOutstanding__c);

            // Insert Transaction Before the Callout 
            ElixirSuite__Transactions__c newTransaction = new ElixirSuite__Transactions__c();
            newTransaction.ElixirSuite__Master_Transaction__c = masterTransaction.id; 
            newTransaction.ElixirSuite__Amount_Paid__c = appliedAmount;
            newTransaction.ElixirSuite__Other_Transactions__c = otherTransaction.id;
            newTransaction.ElixirSuite__Payment_DateTime__c = System.now();
            newTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
            newTransaction.ElixirSuite__Payment_Status__c = INPROGRESS;
            newTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
            newTransaction.ElixirSuite__Type_of_Payment__c = PAYMENT;
            newTransaction.ElixirSuite__Transaction_Status__c = PENDING;
            transactionList.add(newTransaction);
            remainingAllocatedAmmount -= appliedAmount;
        }
        Elixir_DMLManager.insertAsUser(transactionList);  

        ElixirSuite__Master_Transaction__c updateotherTransaction = new ElixirSuite__Master_Transaction__c();
        updateotherTransaction.id  = otherTransaction.id;
        updateotherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = remainingAllocatedAmmount;
        Elixir_DMLManager.updateAsUser(updateotherTransaction);
    }

    /**
    * @description Create Transaction Records after Callout 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param String masterTransactionIds, @param String uniqueKey  
    * @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns None
    **/
    public static void insertTransactionAfterPayment(String accId,Decimal amountToCharge,String masterTransactionIds,String uniqueKey,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper) {

        // Insert Other Transaction After the Callout 
        ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
        otherTransaction.ElixirSuite__Account__c = accId;
        otherTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
        otherTransaction.ElixirSuite__Total_Amount_Paid__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Mode_of_Payment__c = CREDIT_CARD;
        otherTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
        otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
        if (resWrapper?.messages?.resultCode == OK) {
            otherTransaction.Elixir_Payment_Status__c = SUCCESSFUL;
            otherTransaction.Elixir_External_Transaction_ID__c = externalTransId;
            otherTransaction.ElixirSuite__Reason_Of_Payment__c = APPLIED_PAYEMNT;
        } else {
            otherTransaction.Elixir_Payment_Status__c = FAILED;
            otherTransaction.ElixirSuite__Reason_Of_Payment__c = ALLOCATED_PAYEMNT;
            otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = 0;
        }
        Elixir_DMLManager.insertAsUser(otherTransaction);

        // Get Master Transaction for the Procedure.
        List<ElixirSuite__Payment_Transaction__c> masterTransactionList = getMasterTranscation(masterTransactionIds.split(','));  
        List<ElixirSuite__Transactions__c> transactionList = new List<ElixirSuite__Transactions__c>();  
        Decimal remainingAllocatedAmmount = amountToCharge;

        for (ElixirSuite__Payment_Transaction__c masterTransaction : masterTransactionList) {

            if (remainingAllocatedAmmount <= 0) {
                break;
            }

            Decimal appliedAmount = Math.min(remainingAllocatedAmmount,masterTransaction.ElixirSuite__PatientOutstanding__c);

            // Insert Transaction Before the Callout 
            ElixirSuite__Transactions__c newTransaction = new ElixirSuite__Transactions__c();
            newTransaction.ElixirSuite__Master_Transaction__c = masterTransaction.id; 
            newTransaction.ElixirSuite__Amount_Paid__c = appliedAmount;
            newTransaction.ElixirSuite__Other_Transactions__c = otherTransaction.id;
            newTransaction.ElixirSuite__Payment_DateTime__c = System.now();
            newTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
            newTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
            newTransaction.ElixirSuite__Type_of_Payment__c = PAYMENT;
            if (resWrapper?.messages?.resultCode == OK) {
                newTransaction.ElixirSuite__Payment_Status__c = SUCCESSFUL;
                newTransaction.ElixirSuite__Transaction_Status__c = SUCCESSFUL;
                newTransaction.Elixir_External_Transaction_ID__c = externalTransId;
            } else {
                newTransaction.ElixirSuite__Payment_Status__c = FAILED;
                newTransaction.ElixirSuite__Transaction_Status__c = FAILED;
            }
            transactionList.add(newTransaction);
            remainingAllocatedAmmount -= appliedAmount; 
        }
        Elixir_DMLManager.insertAsUser(transactionList);

        ElixirSuite__Master_Transaction__c updateotherTransaction = new ElixirSuite__Master_Transaction__c();
        updateotherTransaction.id  = otherTransaction.id;
        updateotherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = remainingAllocatedAmmount;
        Elixir_DMLManager.updateAsUser(updateotherTransaction);
    }

    /**
    * @description Querry Master Transaction Object via Procedure Id
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param List<Id> masterTransactionIds 
    * @returns List<ElixirSuite__Payment_Transaction__c>
    **/
    private static List<ElixirSuite__Payment_Transaction__c> getMasterTranscation(List<String> masterTransactionIds) {
        return [SELECT id,ElixirSuite__PatientOutstanding__c FROM ElixirSuite__Payment_Transaction__c WHERE Id IN : masterTransactionIds WITH SECURITY_ENFORCED ORDER BY ElixirSuite__Date_Of_Service__c DESC];
    }

    /**
    * @description Querry Transcations Object via uniqueKey
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String uniqueKey 
    * @returns List<ElixirSuite__Payment_Transaction__c>
    **/
    private static List<ElixirSuite__Transactions__c> getTranscationFromUniqueKey(String uniqueKey) {
        return [SELECT id FROM ElixirSuite__Transactions__c WHERE Elixir_Unique_Transaction_Key__c  =: uniqueKey WITH SECURITY_ENFORCED];
    }

    /**
    * @description Querry OtherTranscations Object via uniqueKey
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String uniqueKey 
    * @returns List<ElixirSuite__Payment_Transaction__c>
    **/
    private static List<ElixirSuite__Master_Transaction__c> getOtherTranscationFromUniqueKey(String uniqueKey) {
        return [SELECT id,ElixirSuite__Total_Amount_Paid__c FROM ElixirSuite__Master_Transaction__c WHERE Elixir_Unique_Transaction_Key__c =: uniqueKey WITH SECURITY_ENFORCED LIMIT 1];
    }

    /**
    * @description Create New Other Transaction Before Callout
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param String uniqueKey
    * @returns None
    **/
    public static void insertOtherTransactionBeforePayment(String accId,Decimal amountToCharge,String uniqueKey) {

        // Insert Other Transaction Before the Callout 
        ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
        otherTransaction.ElixirSuite__Account__c = accId;
        otherTransaction.ElixirSuite__Total_Amount_Paid__c = amountToCharge;
        otherTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
        otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Mode_of_Payment__c = CREDIT_CARD;
        otherTransaction.ElixirSuite__Reason_Of_Payment__c = ALLOCATED_PAYEMNT;
        otherTransaction.Elixir_Payment_Status__c = PENDING;
        otherTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
        otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
        Elixir_DMLManager.insertAsUser(otherTransaction);
    }

    /**
    * @description Update the Transction After Payment For Payment Plan
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accID, @param String uniqueKey, @param String selectedProcedureRecords, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList
    * @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns None
    **/
    public static void updateTransactionalRecordsForPaymentPlan(String accID,String uniqueKey,String selectedProcedureRecords,List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper) {
        
        List<ElixirSuite__Master_Transaction__c> otherTransactionProcedureList = getOtherTranscationFromUniqueKey(uniqueKey);

        List<ElixirSuite__Payment_Transaction_Line_Item__c> paymentTranscationLineList  = insertPaymentTransactionLine(accId,paymentPlanLineList);
       
        List<ElixirSuite__Master_Transaction__c> otherTransactionList = insertOtherTransactionRecords(accId,paymentTranscationLineList,externalTransId,resWrapper);

        Elixir_DMLManager.updateAsUser(otherTransactionProcedureList[0]);

        updateOtherTransactionAfterPayment(uniqueKey,externalTransId,resWrapper);

        if (selectedProcedureRecords != null && selectedProcedureRecords != '') {
            paymentAllocationEngine(accId,otherTransactionProcedureList[0].ElixirSuite__Total_Amount_Paid__c,fetchProcedureMasterTransactionSorted(selectedProcedureRecords),otherTransactionProcedureList[0],otherTransactionList);
        }

    } 


    /**
    * @description Insert the Transctional Recors After Payment For Payment Plan
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param String uniqueKey, @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper,
    * @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList, @param String selectedProcedureRecords 
    * @returns None
    **/
    public static void insertOtherTransactionAfterPaymentForPaymentPlan(String accId,Decimal amountToCharge,String uniqueKey,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper,List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList,String selectedProcedureRecords) {
 
        // Insert Other Transaction Before the Callout
        List<ElixirSuite__Payment_Transaction_Line_Item__c> paymentTranscationLineList  = insertPaymentTransactionLine(accId,paymentPlanLineList);
       
        List<ElixirSuite__Master_Transaction__c> otherTransactionList = insertOtherTransactionRecords(accId,paymentTranscationLineList,externalTransId,resWrapper);
    
        if (selectedProcedureRecords != null && selectedProcedureRecords != '') {
            ElixirSuite__Master_Transaction__c otherTransactionprocedure = new ElixirSuite__Master_Transaction__c(
                    ElixirSuite__Total_Amount_Paid__c = amountToCharge,
                    ElixirSuite__Account__c = accId,
                    ElixirSuite__Transaction_Date__c = System.today() , 
                    ElixirSuite__Mode_of_Payment__c = CREDIT_CARD,
                    ElixirSuite__Reason_Of_Payment__c = APPLIED_PAYEMNT,
                    ElixirSuite__Payment_Received_By__c=PATIENT);  
            Elixir_DMLManager.insertAsUser(otherTransactionprocedure);
            paymentAllocationEngine(accId,amountToCharge,fetchProcedureMasterTransactionSorted(selectedProcedureRecords),otherTransactionprocedure,otherTransactionList);
        }
    }

    /**
    * @description Insert Payment Tansaction Line for the Payment Line Items
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList
    * @returns List<ElixirSuite__Payment_Transaction_Line_Item__c>
    **/
    private static List<ElixirSuite__Payment_Transaction_Line_Item__c> insertPaymentTransactionLine(String accId,List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList) {
        List<ElixirSuite__Payment_Transaction_Line_Item__c> paymentTranscationLineList  = new List<ElixirSuite__Payment_Transaction_Line_Item__c>();
        for(ElixirSuite__Payment_Plan_Line_Item__c ps : paymentPlanLineList){  
            ElixirSuite__Payment_Transaction_Line_Item__c ptl = new ElixirSuite__Payment_Transaction_Line_Item__c();
            ptl.ElixirSuite__Payment_Plan_Line_Item__c = ps.Id;
            ptl.ElixirSuite__Payment_Date__c = System.today();
            ptl.ElixirSuite__Account__c = accId;
            ptl.ElixirSuite__Payment_Amount__c = ps.ElixirSuite__Balance_Due__c; 
            ptl.ElixirSuite__Payment_Type__c = CREDIT_CARD;
            paymentTranscationLineList.add(ptl);  
        }
        if(paymentTranscationLineList !=null && paymentTranscationLineList.size() >0){
            Elixir_DMLManager.insertAsUser(paymentTranscationLineList);
        }
        return paymentTranscationLineList;
    }

    /**
    * @description Insert Other Transactions for the Payment Line Items
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge, @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList 
    * @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns List<ElixirSuite__Master_Transaction__c>
    **/
    private static List<ElixirSuite__Master_Transaction__c> insertOtherTransactionRecords(String accId,List<ElixirSuite__Payment_Transaction_Line_Item__c> toInsertLineLst,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper){
        List<ElixirSuite__Master_Transaction__c> otherTransactionList = new List<ElixirSuite__Master_Transaction__c>();
        for( ElixirSuite__Payment_Transaction_Line_Item__c  paymentPlanLine : toInsertLineLst) {
            ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
            otherTransaction.ElixirSuite__Account__c = accId;
            otherTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
            otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = paymentPlanLine.ElixirSuite__Payment_Amount__c;
            otherTransaction.ElixirSuite__Total_Amount_Paid__c = paymentPlanLine.ElixirSuite__Payment_Amount__c;
            otherTransaction.ElixirSuite__Total_Unallocated_Amount__c = paymentPlanLine.ElixirSuite__Payment_Amount__c;
            otherTransaction.ElixirSuite__Mode_of_Payment__c = CREDIT_CARD;
            otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
            if (resWrapper?.messages?.resultCode == OK) {
                otherTransaction.Elixir_Payment_Status__c = SUCCESSFUL;
                otherTransaction.Elixir_External_Transaction_ID__c = externalTransId;
                otherTransaction.ElixirSuite__Reason_Of_Payment__c = UNALLOCATED_PAYEMNT;
            } else {
                otherTransaction.Elixir_Payment_Status__c = FAILED;
                otherTransaction.ElixirSuite__Reason_Of_Payment__c = ALLOCATED_PAYEMNT;
                otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = 0;
            }
            otherTransactionList.add(otherTransaction);
        } 
        if(otherTransactionList !=null && otherTransactionList.size() >0){
            Elixir_DMLManager.insertAsUser(otherTransactionList);
        }

        return otherTransactionList;
    }

    /**
    * @description Create New Other Transaction After Callout
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String accId, @param Decimal amountToCharge , @param String uniqueKey, @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns None
    **/
    public static void insertOtherTransactionAfterPayment(String accId,Decimal amountToCharge,String uniqueKey,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper) {

        // Insert Other Transaction Before the Callout 
        ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
        otherTransaction.ElixirSuite__Account__c = accId;
        otherTransaction.ElixirSuite__Payment_Received_By__c = PATIENT;
        otherTransaction.ElixirSuite__Total_Amount_Paid__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Total_Unallocated_Amount__c = amountToCharge;
        otherTransaction.ElixirSuite__Mode_of_Payment__c = CREDIT_CARD;
        otherTransaction.Elixir_Unique_Transaction_Key__c = uniqueKey;
        otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
        if (resWrapper?.messages?.resultCode == OK) {
            otherTransaction.Elixir_Payment_Status__c = SUCCESSFUL;
            otherTransaction.Elixir_External_Transaction_ID__c = externalTransId;
            otherTransaction.ElixirSuite__Reason_Of_Payment__c = UNALLOCATED_PAYEMNT;
        } else {
            otherTransaction.Elixir_Payment_Status__c = FAILED;
            otherTransaction.ElixirSuite__Reason_Of_Payment__c = ALLOCATED_PAYEMNT;
            otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = 0;
        }
        Elixir_DMLManager.insertAsUser(otherTransaction);
    }

    /**
    * @description Update the Transaction Status after Callout is made to Authorize.Net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String uniqueKey, @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns None
    **/
    public static void updateTransactionAfterPayment(String uniqueKey,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper) {

        updateOtherTransactionAfterPayment(uniqueKey,externalTransId,resWrapper);
        List<ElixirSuite__Transactions__c> newTransactionForId = getTranscationFromUniqueKey(uniqueKey);
        List<ElixirSuite__Transactions__c> updateTransactionList = new List<ElixirSuite__Transactions__c>();
        for (ElixirSuite__Transactions__c transactionRec : newTransactionForId) {

            ElixirSuite__Transactions__c newTransaction = new ElixirSuite__Transactions__c();
            newTransaction.id = transactionRec.id;
            if (resWrapper?.messages?.resultCode == OK) {
                newTransaction.ElixirSuite__Payment_Status__c = SUCCESSFUL;
                newTransaction.ElixirSuite__Transaction_Status__c = SUCCESSFUL;
                newTransaction.Elixir_External_Transaction_ID__c = externalTransId;
            } else {
                newTransaction.ElixirSuite__Payment_Status__c = FAILED;
                newTransaction.ElixirSuite__Transaction_Status__c = FAILED;
            }
            updateTransactionList.add(newTransaction);
        }
        Elixir_DMLManager.updateAsUser(updateTransactionList);
    }

    /**
    * @description Update the Other Transaction Status after Callout is made to Authorize.Net
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String uniqueKey, @param String externalTransId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns None
    **/
    public static void updateOtherTransactionAfterPayment(String uniqueKey,String externalTransId,Elixir_AuthorizeResponseWrappers resWrapper) {

        List<ElixirSuite__Master_Transaction__c> otherTransactionForId = getOtherTranscationFromUniqueKey(uniqueKey);

        ElixirSuite__Master_Transaction__c otherTransaction = new ElixirSuite__Master_Transaction__c();
        if (otherTransactionForId.size() > 0) {
            otherTransaction.id = otherTransactionForId[0].id;
        }
        otherTransaction.id = otherTransactionForId[0].id;
        if (resWrapper?.messages?.resultCode == OK) {
            otherTransaction.Elixir_Payment_Status__c = SUCCESSFUL;
            otherTransaction.Elixir_External_Transaction_ID__c = externalTransId;
            otherTransaction.ElixirSuite__Reason_Of_Payment__c = UNALLOCATED_PAYEMNT;
        } else {
            otherTransaction.Elixir_Payment_Status__c = FAILED;
            otherTransaction.ElixirSuite__Total_Remaining_Unallocated_Amount__c = 0;
        }
        otherTransaction.ElixirSuite__Transaction_Date__c = System.today();
        Elixir_DMLManager.updateAsUser(otherTransaction);
    }

    /**
    * @description Retruns External Transaction Id from the Res Wrapper
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String transId, @param Elixir_AuthorizeResponseWrappers resWrapper
    * @returns Object
    **/
    public static Object getExternalTransaction(String uniqueKey,Elixir_AuthorizeResponseWrappers resWrapper) {
        if (resWrapper.transactionResponse != null) {
            return resWrapper.transactionResponse;
        } else if (resWrapper.transactions != null && resWrapper.transactions.size() > 0) {
            Map<String,Elixir_AuthorizeResponseWrappers.Transactions> transMap = getTransactionMapFromList(resWrapper.transactions);
            return transMap.get(uniqueKey);
        }
        return null;
    }

    /**
    * @description Returns the Map of Transactions vs the Invoice Number
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param List<Elixir_AuthorizeResponseWrappers.Transaction> transactions
    * @returns Map<Sting,Elixir_AuthorizeResponseWrappers.Transaction>
    **/
    private static Map<String,Elixir_AuthorizeResponseWrappers.Transactions> getTransactionMapFromList(List<Elixir_AuthorizeResponseWrappers.Transactions> transactions) {
        Map<String,Elixir_AuthorizeResponseWrappers.Transactions> transMap = new Map<String,Elixir_AuthorizeResponseWrappers.Transactions>();
        for (Elixir_AuthorizeResponseWrappers.Transactions trans : transactions ) {
            transMap.put(trans.invoiceNumber,trans);
        }
        return transMap;
    }

    /**
    * @description Allocate the payments to the Reqiured procedures
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String acctId, @param Decimal totalAppliedAmount, @param ElixirSuite__Payment_Transaction__c[] masterTranRecLst,
    * @param ElixirSuite__Master_Transaction__c otherTransactionprocedure, @param ElixirSuite__Master_Transaction__c[] otherTransaction
    * @returns None
    **/
    public static void paymentAllocationEngine(String acctId,Decimal totalAppliedAmount,ElixirSuite__Payment_Transaction__c[] masterTranRecLst,ElixirSuite__Master_Transaction__c otherTransactionprocedure,ElixirSuite__Master_Transaction__c[] otherTransaction) {
        decimal amount = totalAppliedAmount;
        ElixirSuite__Transactions__c [] allTransactionForMT = new List<ElixirSuite__Transactions__c>();
        ElixirSuite__Master_Transaction__c [] othertransUpadte = new List<ElixirSuite__Master_Transaction__c>();
        for(ElixirSuite__Payment_Transaction__c sObj : masterTranRecLst){
            if(totalAppliedAmount>0){                
                if(idAndRemainingAmt.containsKey(sObj.Id)){                       
                    Decimal remainingAmt = idAndRemainingAmt.get(sObj.Id);
                    if(totalAppliedAmount>remainingAmt){     // 900>991                                               
                        ElixirSuite__Transactions__c transactionRec = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = remainingAmt,ElixirSuite__Master_Transaction__c = sObj.Id,
                                                                                                       ElixirSuite__Payment_DateTime__c = System.now(),ElixirSuite__Mode_of_Payment__c = CREDIT_CARD,
                                                                                                       ElixirSuite__Other_Transactions__c = otherTransactionprocedure.Id,ElixirSuite__Payment_Received_By__c = PATIENT,
                                                                                                       ElixirSuite__Type_of_Payment__c = PAYMENT);
                        
                        totalAppliedAmount = totalAppliedAmount - remainingAmt;
                        allTransactionForMT.add(transactionRec);
                    }
                    else {                                                   
                        ElixirSuite__Transactions__c transactionRec = new ElixirSuite__Transactions__c(ElixirSuite__Amount_Paid__c = totalAppliedAmount,ElixirSuite__Master_Transaction__c = sObj.Id,
                                                                                                       ElixirSuite__Payment_DateTime__c = System.now(),ElixirSuite__Mode_of_Payment__c = CREDIT_CARD,
                                                                                                       ElixirSuite__Other_Transactions__c = otherTransactionprocedure.Id,ElixirSuite__Payment_Received_By__c = PATIENT,
                                                                                                       ElixirSuite__Type_of_Payment__c = PAYMENT);
                        
                        totalAppliedAmount = 0;
                        allTransactionForMT.add(transactionRec);
                        break;
                    }                        
                }                
            }
        }
        
        for (ElixirSuite__Master_Transaction__c mt : otherTransaction) {
            if (mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c != null && mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c > 0) {
                if (amount > mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c) {
                    amount = amount - mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c;
                    mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c = 0;
                    othertransUpadte.add(mt);
                } else {
                    mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c = mt.ElixirSuite__Total_Remaining_Unallocated_Amount__c - amount;
                    amount = 0;
                    othertransUpadte.add(mt);
                    break;
                }
            }
        }
        if(allTransactionForMT!=null && allTransactionForMT.size() >0){
            Elixir_DMLManager.insertAsUser(allTransactionForMT); 
        }
        if(othertransUpadte!=null && othertransUpadte.size() >0){
            Elixir_DMLManager.updateAsUser(othertransUpadte); 
        }
    }

    /**
    * @description Fetch the Master Transaction Sorted by Date Of Serive in ascending order.
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String selectedProcedureRecords
    * @returns List<ElixirSuite__Payment_Transaction__c>
    **/
    public static List<ElixirSuite__Payment_Transaction__c> fetchProcedureMasterTransactionSorted(String selectedProcedureRecords){
        return  [SELECT ID,ElixirSuite__Expected_Receivable_amount__c,ElixirSuite__Other_Discounts__c,ElixirSuite__Total_Paid_Amount__c,ElixirSuite__PatientOutstanding__c,ElixirSuite__Total_Actual_Patient_Paid_Amount__c FROM ElixirSuite__Payment_Transaction__c WHERE 
                 ID IN : collectProcedureMasterTransactionIds(selectedProcedureRecords) with security_enforced order By ElixirSuite__Date_Of_Service__c asc ];
    }

    /**
    * @description Collect Master Transction Id in a set 
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String selectedProcedureRecords
    * @returns Set<Id>
    **/
    public static Set<Id> collectProcedureMasterTransactionIds(String selectedProcedureRecords){
        Set<Id> recordIds = new Set<Id>();
        for(Object obj : utilityMapDeserialize(selectedProcedureRecords,'procedures')){
            Map<String, Object> mapOfSelectedProcedures = (Map<String, Object>) obj;
            recordIds.add(String.valueOf(mapOfSelectedProcedures.get('Id')));
            idAndRemainingAmt.put(String.valueOf(mapOfSelectedProcedures.get('Id')),Decimal.valueOf(String.valueOf(mapOfSelectedProcedures.get('ElixirSuite__PatientOutstanding__c')))); 
        }
        return recordIds;
    }

    /**
    * @description Deserialize Json into List of Objects
    * @author Ayushmaan Yadav | 11th Feburary 2024
    * @param String String stringifiedJSON, @param String keyToGet
    * @returns List<Object>
    **/
    public static List<Object> utilityMapDeserialize(String stringifiedJSON,String keyToGet){         
        Map<String, Object> tableLstJSON =(Map<String, Object>) JSON.deserializeUntyped(stringifiedJSON);
        return  (List<Object>) tableLstJSON.get(keyToGet);
    }
    
}