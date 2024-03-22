public with sharing class ClaimvalidationErrorController {
    
    @AuraEnabled
   public static String claimValidationErrors(String claimId){
       try {
           ElixirSuite__Claim__c c = [select id,ElixirSuite__Validation_Error_Message__c from ElixirSuite__claim__c where id=:claimId WITH SECURITY_ENFORCED Limit 1];
           if(c.ElixirSuite__Validation_Error_Message__c!=null){
               return c.ElixirSuite__Validation_Error_Message__c;
           }
           return 'NO ERRORS FOUND';
       } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
       }
   }
   
   
   public static String validate1(List<ElixirSuite__Claim__c> claimRecData,List<ElixirSuite__Claim_Line_Items__c> lineItems) {
       boolean errorOccured =false;
       ElixirSuite__Claim__c claimData = claimRecData[0];
       List<wrap> finalWrap = new List<wrap>();
       wrap claimWrapper= validateClaims(claimData);
       if(claimWrapper!=null){
           errorOccured =true;
           finalWrap.add(claimWrapper);
       }
       for(ElixirSuite__Claim_Line_Items__c eachLineItem : lineItems){
           wrap lineItemWrapper= validateClaimLineItem(eachLineItem);
           if(lineItemWrapper!=null){
               errorOccured =true;
               finalWrap.add(lineItemWrapper);
           }
       }
       if(errorOccured){
           claimData.ElixirSuite__Claim_Status__c='Claim Validation Error';
           claimData.ElixirSuite__Validation_Error_Message__c = JSON.serialize(finalWrap);
           update claimData;
           
       }
       
       
       return errorOccured?'Validation Error':'Validation passed';
   }
   
   public static wrap validateClaims(ElixirSuite__Claim__c claimData){
       List<errors> claimErrorsList = new List<errors>();
       if(claimData.ElixirSuite__Account__r.ElixirSuite__First_Name__c == null || claimData.ElixirSuite__Account__r.ElixirSuite__First_Name__c == ''){
           errors error = new errors('ElixirSuite_Patient_Name__c','Patient First Name should not be Empty');
           claimErrorsList.add(error); 
       }else if(claimData.ElixirSuite__Account__r.ElixirSuite__First_Name__c != null && (claimData.ElixirSuite__Account__r.ElixirSuite__First_Name__c).length() > 25){
           errors error = new errors('ElixirSuite_Patient_Name__c','Patient First Name should not exceed 25 Characters');
           claimErrorsList.add(error); 
       }
       if(claimData.ElixirSuite__Account__r.ElixirSuite__Last_Name__c == null || claimData.ElixirSuite__Account__r.ElixirSuite__Last_Name__c == ''){
           errors error = new errors('ElixirSuite_Patient_Name__c','Patient Last Name should not be Empty');
           claimErrorsList.add(error); 
       }else if(claimData.ElixirSuite__Account__r.ElixirSuite__Last_Name__c != null && (claimData.ElixirSuite__Account__r.ElixirSuite__Last_Name__c).length() > 35){
           errors error = new errors('ElixirSuite_Patient_Name__c','Patient Last Name should not exceed 25 Characters');
           claimErrorsList.add(error); 
       }
       
       if(claimData.ElixirSuite__Patient_s_Address__c==null){
           errors error = new errors('ElixirSuite__Patient_s_Address__c','Patient Address should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_s_Address__c.length()>55){
           errors error = new errors('ElixirSuite__Patient_s_Address__c','Patient Address should not exceed 55 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Patient_s_City__c==null){
           errors error = new errors('ElixirSuite__Patient_s_City__c','Patient City should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_s_City__c.length()>30){
           errors error = new errors('ElixirSuite__Patient_s_City__c','Patient City should not exceed 30 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Patient_Country_Code__c==null){
           errors error = new errors('ElixirSuite__Patient_Country_Code__c','Patient Country Code should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_Country_Code__c.length()>2){
           errors error = new errors('ElixirSuite__Patient_Country_Code__c','Patient Country Code must be a valid 2 Character Code');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Patient_Sex__c==null){ 
           errors error = new errors('ElixirSuite__Patient_Sex__c','Patient Sex should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_Sex__c != 'F' && claimData.ElixirSuite__Patient_Sex__c != 'M' && claimData.ElixirSuite__Patient_Sex__c != 'U'){ 
           errors error = new errors('ElixirSuite__Patient_Sex__c','Patient Sex must be '+'M'+'/'+'F'+'/'+'U');
           claimErrorsList.add(error);
       }
      
       if(claimData.ElixirSuite__Insured_Address__c==null){
           errors error = new errors('ElixirSuite__Insured_Address__c','Insured Address should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_Address__c.length()>55){
           errors error = new errors('ElixirSuite__Insured_Address__c','Insured Address should not exceed 55 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Insured_City__c==null){
           errors error = new errors('ElixirSuite__Insured_City__c','Insured City should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_City__c.length()>30){
           errors error = new errors('ElixirSuite__Insured_City__c','Insured City should not exceed 30 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Insured_State__c==null){
           errors error = new errors('ElixirSuite__Insured_State__c','Insured State should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_State__c.length()>2){
           errors error = new errors('ElixirSuite__Insured_State__c','Insured State must be a valid 2 Character Code');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Insured_Zip_Code__c==null){
           errors error = new errors('ElixirSuite__Insured_Zip_Code__c','Insured Zip Code should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_Zip_Code__c.length()>15){
           errors error = new errors('ElixirSuite__Insured_Zip_Code__c','Insured Zip Code should not exceed 15 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Insured_Country_Code__c==null){
           errors error = new errors('ElixirSuite__Insured_Country_Code__c','Insured Country Code should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_Country_Code__c.length()>2){
           errors error = new errors('ElixirSuite__Insured_Country_Code__c','Insured Country Code must be a valid 2 Character Code');
           claimErrorsList.add(error);
       }
       String insuredPhone = claimData.ElixirSuite__Insured_Telephone__c;
       String insuredPhoneFinal;
       if(insuredPhone != null && !String.isBlank(insuredPhone) ){
       insuredPhoneFinal = insuredPhone.replaceAll('(?!^\\+)[^\\d]','');
       }
       system.debug('test'+insuredPhoneFinal);
       if(claimData.ElixirSuite__Insured_Telephone__c==null && String.isBlank(insuredPhoneFinal)){
           errors error = new errors('ElixirSuite__Insured_Telephone__c','Insured Phone should not be Empty');
           claimErrorsList.add(error);
       }
       else if(!String.isBlank(insuredPhoneFinal) && insuredPhoneFinal.length()>10){
           errors error = new errors('ElixirSuite__Insured_Telephone__c','Insured Phone must contain only 10 Digits which start with 6,7,8,9');
           claimErrorsList.add(error);
       }
     
       if(claimData.ElixirSuite__Insured_Sex__c==null){
           errors error = new errors('ElixirSuite__Insured_Sex__c','Insured Sex should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_Sex__c != 'F' && claimData.ElixirSuite__Insured_Sex__c != 'M' && claimData.ElixirSuite__Insured_Sex__c != 'U'){
           errors error = new errors('ElixirSuite__Insured_Sex__c','Insured Sex must be '+'M'+'/'+'F'+'/'+'U');
           claimErrorsList.add(error);
       }
       
       if(claimData.ElixirSuite__Patient_s_State__c==null){
           errors error = new errors('ElixirSuite__Patient_s_State__c','Patient State should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_s_State__c.length()!=2){
           errors error = new errors('ElixirSuite__Patient_s_State__c','Patient State must be a valid 2 Character Code');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Patient_Zip_Code__c==null){
           errors error = new errors('ElixirSuite__Patient_Zip_Code__c','Patient Zip Code should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Patient_Zip_Code__c.length()>15){
           errors error = new errors('ElixirSuite__Patient_Zip_Code__c','Patient Zip Code should not exceed 15 characters');
           claimErrorsList.add(error);
       }
       
       if(claimData.ElixirSuite__Insured_s_ID_Number__c==null){
           errors error = new errors('ElixirSuite__Insured_s_ID_Number__c','Insurance Policy Number should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Insured_s_ID_Number__c.length()>32){
           errors error = new errors('ElixirSuite__Insured_s_ID_Number__c','Insurance Policy Number should not exceed 32 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Diagnosis_A__c==null){
           errors error = new errors('ElixirSuite__Diagnosis_A__c','Diagnoses Code A should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Diagnosis_A__c.length()>8){
           errors error = new errors('ElixirSuite__Diagnosis_A__c','Diagnoses Code A should not exceed 8 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_Name__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_Name__c','Billing Provider Name should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_Name__c.length()>32){
           errors error = new errors('ElixirSuite__Billing_Provider_Name__c','Billing Provider Name should not exceed 32 Character');
           claimErrorsList.add(error);
       }
       
       if(claimData.ElixirSuite__Billing_Provider_Info_NPI__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_Info_NPI__c','Billing Provider NPI should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_Info_NPI__c.length()!=10){
           errors error = new errors('ElixirSuite__Billing_Provider_Info_NPI__c','Billing Provider NPI must only be 10 Digits');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_Address_1__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_Address_1__c','Billing Provider Address 1 should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_Address_1__c.length()>128){
           errors error = new errors('ElixirSuite__Billing_Provider_Address_1__c','Billing Provider Address 1 should not exceed 128 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_City__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_City__c','Billing Provider City should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_City__c.length()>32){
           errors error = new errors('ElixirSuite__Billing_Provider_City__c','Billing Provider City should not exceed 32 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_State__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_State__c','Billing Provider State should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_State__c.length()!=2){
           errors error = new errors('ElixirSuite__Billing_Provider_State__c','Billing Provider State must be a valid 2 Character Code');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_Zip__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_Zip__c','Billing Provider zip should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_Zip__c.length()>12){
           errors error = new errors('ElixirSuite__Billing_Provider_Zip__c','Billing Provider zip should not exceed 12 Characters');
           claimErrorsList.add(error);
       }
       String billPhone = claimData.ElixirSuite__Bill_Phone__c;
       if(billPhone != null && !String.isBlank(billPhone)){
       billPhone = billPhone.replaceAll('(?!^\\+)[^\\d]','');
       }
       if(claimData.ElixirSuite__Bill_Phone__c==null && String.isBlank(billPhone)){
           errors error = new errors('ElixirSuite__Bill_Phone__c','Billing Provider Phone should not be Empty');
           claimErrorsList.add(error);
       }
       else if(!String.isBlank(billPhone) && billPhone.length()!=10){
           errors error = new errors('ElixirSuite__Bill_Phone__c','Billing Provider Phone must only contain 10 Digits which start with 6,7,8,9');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Billing_Provider_Tax_ID__c==null){
           errors error = new errors('ElixirSuite__Billing_Provider_Tax_ID__c','Billing Provider Tax ID should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Billing_Provider_Tax_ID__c.length()>16){
           errors error = new errors('ElixirSuite__Billing_Provider_Tax_ID__c','Billing Provider Tax ID should not exceed 16 Character');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Total_Charge__c==null){
           errors error = new errors('ElixirSuite__Total_Charge__c','Total Service Charges cannot be Empty');
           claimErrorsList.add(error);
       }
       else if(String.valueOf(claimData.ElixirSuite__Total_Charge__c.Scale()).length()>2 && String.valueOf(claimData.ElixirSuite__total_charge__c.longValue()).length()>9){
           errors error = new errors('ElixirSuite__Total_Charge__c','Total Service Charges should not exceed 9 Characters and 2 decimal places');
           claimErrorsList.add(error);
       }
       
       if(claimData.ElixirSuite__payor__r.ElixirSuite__Payer_Code__c==null){
           errors error = new errors('ElixirSuite__Payer_Code__c','Payer ID should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__payor__r.ElixirSuite__Payer_Code__c.length()>32){
           errors error = new errors('ElixirSuite__Payer_Code__c','Payer ID should not exceed 32 Characters');
           claimErrorsList.add(error);
       }
   
       if(claimData.ElixirSuite__Federal_Tax_Id_Number__c==null){
           errors error = new errors('ElixirSuite__Federal_Tax_Id_Number__c','Federal Tax ID should not be Empty');
           claimErrorsList.add(error);
       }
       else if(claimData.ElixirSuite__Federal_Tax_Id_Number__c.length()>16){
           errors error = new errors('ElixirSuite__Federal_Tax_Id_Number__c','Federal Tax ID should not exceed 16 Characters');
           claimErrorsList.add(error);
       }
       if(claimData.ElixirSuite__Patient_Condition_Related_To_Accident__c && claimData.ElixirSuite__Auto_Accident_Related__c == null){
          errors error = new errors('ElixirSuite__Auto_Accident_Related__c','Accident State Required if Employment or Auto or Other Accident is [Y]');
          claimErrorsList.add(error); 
       }
       if(claimData.ElixirSuite__Patient_Condition_Related_To_Accident__c && claimData.ElixirSuite__Date_Of_Current_Illness__c == null){
           errors error = new errors('ElixirSuite__Date_Of_Current_Illness__c','Accident Date Required if Employment or Auto or Other Accident is [Y]');
          claimErrorsList.add(error); 
       }
    
        //added by jami for lx3-12691
        Map<String,ElixirSuite__Patient_Relationship_Code__mdt> patRelMap = new Map<String,ElixirSuite__Patient_Relationship_Code__mdt>();
        for(ElixirSuite__Patient_Relationship_Code__mdt patRel : [Select id, developerName, MasterLabel, ElixirSuite__Code__c from ElixirSuite__Patient_Relationship_Code__mdt WITH SECURITY_ENFORCED LIMIT 5000])
        {
            patRelMap.put(patRel.developerName.toLowercase(),patRel);
        }
        if(String.IsBlank(claimData.ElixirSuite__Patient_Relationship_to_Insured__c)){
            errors error = new errors('ElixirSuite__Patient_Relationship_to_Insured__c','Patient Relationship With Insured should not be Empty');
            claimErrorsList.add(error); 
        }else if(claimData.ElixirSuite__Patient_Relationship_to_Insured__c !='' && (!patRelMap.containsKey(claimData.ElixirSuite__Patient_Relationship_to_Insured__c.toLowercase()))){
            errors error = new errors('ElixirSuite__Patient_Relationship_to_Insured__c','Please enter a valid Patient Relationship With Insured');
            claimErrorsList.add(error);   
        }
        //end
       
       List<String> otherInsNames = splitNames1(claimData.ElixirSuite__Other_Insured_s_Name__c);
       if(claimData.ElixirSuite__Other_Insured_s_Name__c== null && claimData.ElixirSuite__Payer_Order__c=='Secondary'){
           errors error = new errors('ElixirSuite__Other_Insured_s_Name__c','Other Insured Name is required');
           claimErrorsList.add(error);
       }else if(claimData.ElixirSuite__Payer_Order__c=='Secondary' && otherInsNames.size() <2){
           errors error = new errors('ElixirSuite__Other_Insured_s_Name__c','Other Insured Full Name is required');
           claimErrorsList.add(error);  
       }
       
       if(claimErrorsList.size()>0){
           wrap wrapper = new wrap();
           wrapper.key=claimData.id;
           wrapper.value = claimErrorsList;
           return wrapper;
       }
       return null;
       
   }
   public static wrap validateClaimLineItem(ElixirSuite__Claim_Line_Items__c lineItem){
       List<errors> lineItemErrorsList = new List<errors>();
       /*if(lineItem.ElixirSuite__CPT_HCPCS_Code__c==null){
errors error = new errors('ElixirSuite__CPT_HCPCS_Code__c','Should not be Empty');
lineItemErrorsList.add(error);
}*/
       if(lineItem.ElixirSuite__Days_Units__c==null){
           errors error = new errors('ElixirSuite__Days_Units__c','Units should not be Empty');
           lineItemErrorsList.add(error);
       }
       else if(String.valueOf(lineItem.ElixirSuite__Days_Units__c.scale()).length()>6){
           errors error = new errors('ElixirSuite__Days_Units__c','Units should not exceed 6 Characters');
           lineItemErrorsList.add(error);
       }
       if(lineItem.ElixirSuite__Procedure_Charge__c==null){
           errors error = new errors('ElixirSuite__Procedure_Charge__c','Charge Amount cannot be Empty');
           lineItemErrorsList.add(error);
       }
       else if(String.valueOf(lineItem.ElixirSuite__Procedure_Charge__c.scale()).length()>9 && String.valueOf(lineItem.ElixirSuite__procedure_charge__c.longValue()).length()>2){
           errors error = new errors('ElixirSuite__Procedure_Charge__c','Charge Amount should not exceed 9 Characters');
           lineItemErrorsList.add(error);
       }
       if(lineItem.ElixirSuite__CPT_HCPCS_Code__c==null){
           errors error = new errors('ElixirSuite__CPT_HCPCS_Code__c','Procedure Code should not be Empty');
           lineItemErrorsList.add(error);
       }
       else if(lineItem.ElixirSuite__CPT_HCPCS_Code__c.length()>5){
           errors error = new errors('ElixirSuite__CPT_HCPCS_Code__c','Procedure Code should not exceed 5 Characters');
           lineItemErrorsList.add(error);
       }
       if(lineItem.ElixirSuite__Diagnosis_Pointer__c==null){
           errors error = new errors('ElixirSuite__Diagnosis_Pointer__c','Diagnosis Reference should not be Empty');
           lineItemErrorsList.add(error);
       }
       /*else if(lineItem.ElixirSuite__Diagnosis_Pointer__c.length()>8){
           errors error = new errors('ElixirSuite__Diagnosis_Pointer__c','Diagnosis Reference should not exceed 8 Characters');
           lineItemErrorsList.add(error);
       }*/
       if(lineItemErrorsList.size()>0){
           wrap wrapper = new wrap();
           wrapper.key=lineItem.id;
           wrapper.value = lineItemErrorsList;
           return wrapper;
       }
       return null;
   }
   public class wrap{
       public String key;
       public List<errors> value;
   }
   public class errors{
       @AuraEnabled public String errorMessage;
       @AuraEnabled public String errorField;
       public errors(String errorField, String errorMessage){
           this.errorField = errorField;
           this.errorMessage = errorMessage;
       }
   }
   public static List<String> splitNames1(String incomingText){
       if(String.isBlank(incomingText)){
           return new List<String>{};
               }
       return incomingText.split(' ');
   }
   public static List<String> splitNames(String incomingText){
       if(String.isBlank(incomingText)){
           return new List<String>{};
               }
       return incomingText.split(',');
   }

}