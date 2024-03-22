public  with sharing class VOBPdfGenerationHelper {
    
    public  String VOBResponse {get;set;}
    public static String fetchedDate {get;set;}
    public boolean showAlert { get; set; }
    public static EligibilityDemographicWrappper eligibilityDemograpic { get; set;}
    public static List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit> lstOfBenifit {get;set;}
    public static ElixirOEM_BenifitTypeResponseDomain1.ParentDomain lstOfParentBenifit{ get; set;}
    public static List<ElixirOEM_BenifitTypeResponseDomain1.Root> parentIterationWrapper {get;set;}
    public VOBPdfGenerationHelper(){
        String recId = ApexPages.currentPage().getParameters().get('recId');
        System.debug('recId for ' + recId);
        ElixirSuite__VOB__c[] jsonResponse = [SELECT ID,ElixirSuite__JSON_Dump__c from ElixirSuite__VOB__c
                                              where id = : recId WITH SECURITY_ENFORCED];
        parseResponseForRendering(jsonResponse[0].ElixirSuite__JSON_Dump__c);
       
    }
   
   
    public static void createMapForData(List<Object> benifitLst){ 
        
        Map<String,String> benifitTypeCodeMap = new Map<String,String>();
        for(Object sObj : benifitLst){
            Map<String, Object> mapOfBenifitDetails = (Map<String, Object>) sObj; 
            if(String.isNotBlank(String.valueOf(mapOfBenifitDetails.get('benefit_code'))) && String.isNotBlank(String.valueOf(mapOfBenifitDetails.get('benefit_description')))){
                benifitTypeCodeMap.put(String.valueOf(mapOfBenifitDetails.get('benefit_code')),String.valueOf(mapOfBenifitDetails.get('benefit_description')));
            }
        }
        ElixirOEM_MapOfBenifitTypeCode1.benifitTypeCodeMap = benifitTypeCodeMap;
    }
    public static void parseResponseForRendering(String VOBResponse){        
        Map<String, Object> mainJson =(Map<String, Object>) JSON.deserializeUntyped(VOBResponse);        
        Map<String, Object> vobResult = (Map<String, Object>) mainJson.get('result');
        Map<String, Object> demoGraphicInformation =(Map<String, Object>) vobResult.get('elig');
        List<Object> benifitLst = (List<Object>) demoGraphicInformation.get('benefit');
        createMapForData(benifitLst); 
        eligibilityDemograpic = new EligibilityDemographicWrappper(valueOfStringified(demoGraphicInformation.get('ins_name_f')),
                                                                   valueOfStringified(demoGraphicInformation.get('ins_name_l')),
                                                                   'policy number',
                                                                   valueOfStringified(demoGraphicInformation.get('group_number')),
                                                                   'plan 101',
                                                                   String.valueOf(demoGraphicInformation.get('ins_dob')),
                                                                   valueOfStringified(demoGraphicInformation.get('ins_sex')),
                                                                   valueOfStringified(demoGraphicInformation.get('ins_addr_1')),
                                                                   valueOfStringified(demoGraphicInformation.get('plan_begin_date')));       
        fetchedDate = String.valueOf(demoGraphicInformation.get('elig_result_date'));
        lstOfBenifit = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
        Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfSerializedCodeAndData = new  Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>();       
        for(Object sObj : benifitLst){
            Map<String, Object> mapOfBenifitDetails = (Map<String, Object>) sObj;    
            String benefit_code = String.valueOf(mapOfBenifitDetails.get('benefit_code'));          
            if(ElixirOEM_MapOfBenifitTypeCode1.benifitTypeCodeMap.containsKey(benefit_code)){                
                ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] lstOf_In_Plan_Network = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
                ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] lstOf_Out_Plan_Network = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
                ElixirOEM_BenifitTypeResponseDomain1.cls_benefit sObjBenifit = new  ElixirOEM_BenifitTypeResponseDomain1.cls_benefit(); // instanciate wrapper doamin object                                  
                sObjBenifit.benefit_code= benefit_code;//30
                sObjBenifit.benefit_amount = benefit_amount_ValueSort(String.valueOf(mapOfBenifitDetails.get('benefit_amount')));
                sObjBenifit.benefit_percent = benefit_percent_ValueSort(String.valueOf(mapOfBenifitDetails.get('benefit_percent')));
                sObjBenifit.benefit_coverage_code= String.valueOf(mapOfBenifitDetails.get('benefit_coverage_code'));//1
                sObjBenifit.benefit_period_description = String.valueOf(mapOfBenifitDetails.get('benefit_period_description'));
                sObjBenifit.benefit_coverage_description= String.valueOf(mapOfBenifitDetails.get('benefit_coverage_description'));//Active Coverage
                sObjBenifit.benefit_level_description = String.valueOf(mapOfBenifitDetails.get('benefit_level_description'));//Individual
                sObjBenifit.benefit_description=String.valueOf(mapOfBenifitDetails.get('benefit_description')); //Health Benefit Plan Coverage
                sObjBenifit.benefit_notes= String.valueOf(mapOfBenifitDetails.get('benefit_notes'));//FUNDING TYPE = FULLY INSURED
                sObjBenifit.date_of_last_update=String.valueOf(mapOfBenifitDetails.get('date_of_last_update')); //20160702
                sObjBenifit.insurance_plan=String.valueOf(mapOfBenifitDetails.get('insurance_plan')); //AETNA CHOICE PLUS
                sObjBenifit.insurance_type_code=String.valueOf(mapOfBenifitDetails.get('insurance_type_code')); //C1
                sObjBenifit.insurance_type_description=String.valueOf(mapOfBenifitDetails.get('insurance_type_description')); //Commercial
                sObjBenifit.entity_addr_1= String.valueOf(mapOfBenifitDetails.get('entity_addr_1'));//P.O. BOX 30555
                sObjBenifit.entity_city=String.valueOf(mapOfBenifitDetails.get('entity_city')); //SALT LAKE CITY
                sObjBenifit.entity_code=String.valueOf(mapOfBenifitDetails.get('entity_code')); //PR
                sObjBenifit.entity_description=String.valueOf(mapOfBenifitDetails.get('entity_description')); //Payer
                sObjBenifit.entity_name=String.valueOf(mapOfBenifitDetails.get('entity_name')); //AETNA
                sObjBenifit.entity_state=String.valueOf(mapOfBenifitDetails.get('entity_state')); //UT
                sObjBenifit.entity_zip=String.valueOf(mapOfBenifitDetails.get('entity_zip')); //841300555
                sObjBenifit.inplan_network = String.valueOf(mapOfBenifitDetails.get('inplan_network')); //841300555
                sObjBenifit.benefit_level_code = String.valueOf(mapOfBenifitDetails.get('benefit_level_code')); //841300555
                compileBenifitLevelCode(sObjBenifit,mapOfBenifitDetails);
                //   serializeHeirarchyOnTileLevel(sObjBenifit);
                
                if(mapOfSerializedCodeAndData.containsKey(benefit_code)){                    
                    mapOfSerializedCodeAndData.get(benefit_code).add(sObjBenifit);
                }else{
                    List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit> benifitLstData = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
                    benifitLstData.add(sObjBenifit);
                    mapOfSerializedCodeAndData.put(benefit_code,benifitLstData);
                }
                //system.debug('benefit_coverage_description '+String.valueOf(mapOfBenifitDetails.get('benefit_coverage_description')));        
            }
        }
        levelHeirarchyDrill(mapOfSerializedCodeAndData);
        
    }
    
    
    public static void levelHeirarchyDrill(Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfSerializedCodeAndData){
        
        Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfSerializedCodeAndData_ToIterate = new  Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>();
        Map<String, Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>> rootMap = new  Map<String, Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>>();
        ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] allRecordsSorted = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
        for(String obj : mapOfSerializedCodeAndData.keySet()){ // 1. Chiropractic 2. Health Plan Benifit 3.etc
            // System.debug('obj --> '+obj);
            Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfTiles = new  Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>();
            mapOfTiles.put(' ',new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>());
            for(ElixirOEM_BenifitTypeResponseDomain1.cls_benefit sObjBenifit : mapOfSerializedCodeAndData.get(obj)){
                String benefit_level_code = sObjBenifit.benefit_level_code;
                if(String.isNotBlank(benefit_level_code)){
                    if(mapOfTiles.containsKey(benefit_level_code)){      // IND, FAM, ETC              
                        mapOfTiles.get(benefit_level_code).add(sObjBenifit);
                    }else{
                        List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit> benifitLst_PerTile = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
                        benifitLst_PerTile.add(sObjBenifit);
                        mapOfTiles.put(benefit_level_code,benifitLst_PerTile);
                    }  
                    //   System.debug('mapoftiles '+mapOfTiles);  
                }
                else {
                    system.debug('else');
                    mapOfTiles.get(' ').add(sObjBenifit);
                    
                    
                    // IF --> String.isBlank(benefit_level_code)
                    
                }
              
            }
            rootMap.put(obj,mapOfTiles);
            //*************ADD HERE MAP OF RECORDS FOR DISPALY ON UI *******************
            //   mapOfSerializedCodeAndData_ToIterate.put(obj,allRecordsSorted);
        }
        
        parentIterationWrapper = new List<ElixirOEM_BenifitTypeResponseDomain1.Root>();
        
        for(String key : rootMap.keySet()){ // Chiropracter , etc
            ElixirOEM_BenifitTypeResponseDomain1.Root object_Root = new ElixirOEM_BenifitTypeResponseDomain1.Root();
            System.debug('rootmap key '+key);
            object_Root.code = key;
            object_Root.benefit_description = ElixirOEM_MapOfBenifitTypeCode1.benifitTypeCodeMap.get(key);
            Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfTiles = rootMap.get(key);
            // ADD HERE THE KEY FOR IND,IND-IN PLAN , IND  -- OON , FAM ETC
            object_Root.lst_benefit_level_code = new List<ElixirOEM_BenifitTypeResponseDomain1.SubRoot>();
            for(String tileKey : mapOfTiles.keySet()){ // IND , FAM ETC
                ElixirOEM_BenifitTypeResponseDomain1.SubRoot obj = new ElixirOEM_BenifitTypeResponseDomain1.SubRoot();
                System.debug('tileKey  '+tileKey);
                obj.benefit_level_code = tileKey;  
                obj.benefit_coverage_description = tileKey;
                Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfIn_Out_Network_Data = new  Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>();
                for(ElixirOEM_BenifitTypeResponseDomain1.cls_benefit obj_Tile : mapOfTiles.get(tileKey)){
                    String inplan_network = obj_Tile.inplan_network;
                    System.debug('inplan_network  '+inplan_network);
                    if(mapOfIn_Out_Network_Data.containsKey(inplan_network)) {      // Y,N,W ETC            
                        mapOfIn_Out_Network_Data.get(inplan_network).add(obj_Tile);
                    } else{
                        List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit> benifitLst_Per_In_Out_Network_Data = new List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>();
                        benifitLst_Per_In_Out_Network_Data.add(obj_Tile);
                        mapOfIn_Out_Network_Data.put(inplan_network,benifitLst_Per_In_Out_Network_Data);
                    }  
                }
                Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> newKeyMapOfData = new  Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>>(); 
                for(String sub_key : mapOfIn_Out_Network_Data.keySet()){
                    system.debug('sub_key 1'+sub_key);
                    
                    
                    String cardTitle = ElixirOEM_MapOfBenifitTypeCode1.benefitLevelCodeMap.get(tileKey)+ElixirOEM_MapOfBenifitTypeCode1.planNetworkMap.get(sub_key); 
                    if(cardTitle.contains('null')){
                        cardTitle = '';
                    }
                    system.debug('cardTitle 2'+cardTitle);
                    newKeyMapOfData.put(cardTitle,mapOfIn_Out_Network_Data.get(sub_key)); 
                }
                obj.mapOfCodeAndData = newKeyMapOfData;
                object_Root.lst_benefit_level_code.add(obj);
                
                
            }
            
            System.debug('obj parent '+ object_Root.code);
            parentIterationWrapper.add(object_Root);
        }
        System.debug('size '+parentIterationWrapper.size());
        for(ElixirOEM_BenifitTypeResponseDomain1.root toDebug : parentIterationWrapper){
            System.debug('1st '+toDebug.code);
        }
        generateDomianWrapper(mapOfSerializedCodeAndData_ToIterate);      
    }
    public static String decisionNull(String sub_key,String tileKey){
        String phoenixString = '';
        if(String.isBlank(sub_key)){
            return phoenixString;
        }
        else {
            phoenixString = ElixirOEM_MapOfBenifitTypeCode1.benefitLevelCodeMap.get(tileKey)+ElixirOEM_MapOfBenifitTypeCode1.planNetworkMap.get(sub_key); 
            return phoenixString;
        } 
    }
    
    public static void generateDomianWrapper(Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfSerializedCodeAndData){
        lstOfParentBenifit = new  ElixirOEM_BenifitTypeResponseDomain1.ParentDomain();
        for(String cleanSObj : mapOfSerializedCodeAndData.keySet()){
            lstOfParentBenifit.code = cleanSObj;
            lstOfParentBenifit.benefit_description = ElixirOEM_MapOfBenifitTypeCode1.benifitTypeCodeMap.get(cleanSObj);
            lstOfParentBenifit.benifitLst = mapOfSerializedCodeAndData.get(cleanSObj);
        }
    }
    public static void addAllRecords(Map<String,List<ElixirOEM_BenifitTypeResponseDomain1.cls_benefit>> mapOfIn_Out_Network_Data,
                                     ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] allRecordsSorted){                                        
                                         for(String rec_Obj : mapOfIn_Out_Network_Data.keySet()){
                                             allRecordsSorted.addAll(mapOfIn_Out_Network_Data.get(rec_Obj));
                                         }
                                     }
    public static void serializeHeirarchyOnTileLevel(ElixirOEM_BenifitTypeResponseDomain1.cls_benefit sObjBenifit, ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] lstOf_In_Plan_Network,
                                                     ElixirOEM_BenifitTypeResponseDomain1.cls_benefit[] lstOf_Out_Plan_Network){
                                                         
                                                         if(ElixirOEM_MapOfBenifitTypeCode1.inPlanNetworkValues.contains(sObjBenifit.inplan_network)){
                                                             
                                                         }
                                                     }
    public static void compileBenifitLevelCode(ElixirOEM_BenifitTypeResponseDomain1.cls_benefit sObjBenifit,Map<String, Object> mapOfBenifitDetails){
        String sObj_benifitRecord =  String.valueOf(mapOfBenifitDetails.get('benefit_level_code'));
        if(String.isNotBlank(sObj_benifitRecord)){
            if(ElixirOEM_MapOfBenifitTypeCode1.benefitLevelCodeMap.containsKey(sObj_benifitRecord)){
                if(String.valueOf(mapOfBenifitDetails.get('inplan_network')) == 'Y'){
                    sObjBenifit.in_out_planNetwork = ElixirOEM_MapOfBenifitTypeCode1.benefitLevelCodeMap.get(sObj_benifitRecord)+' In-Plan-Network';
                }
                else if(String.valueOf(mapOfBenifitDetails.get('inplan_network')) == 'N'){
                    sObjBenifit.in_out_planNetwork = ElixirOEM_MapOfBenifitTypeCode1.benefitLevelCodeMap.get(sObj_benifitRecord)+' Out-Of-Plan-Network';
                }
                else if(String.valueOf(mapOfBenifitDetails.get('inplan_network')) == 'W'){
                    
                }
                
            }
        }
        compile_Benifit_PeriodCode(sObjBenifit,mapOfBenifitDetails);
    }
    public static void compile_Benifit_PeriodCode(ElixirOEM_BenifitTypeResponseDomain1.cls_benefit sObjBenifit,Map<String, Object> mapOfBenifitDetails){
        String sObj_benifitRecord =  String.valueOf(mapOfBenifitDetails.get('benefit_period_code'));
        if(String.isNotBlank(sObj_benifitRecord)){
            if(ElixirOEM_MapOfBenifitTypeCode1.benefitPeriodCode.containsKey(sObj_benifitRecord)){
                sObjBenifit.benefit_period_code_toText = ElixirOEM_MapOfBenifitTypeCode1.benefitPeriodCode.get(sObj_benifitRecord);              
            }
        }
    }
    public static String benefit_percent_ValueSort(String benefit_percent){
        if(String.isBlank(benefit_percent)){
            return null;
        }
        else {
            return  benefit_percent + '%';
        }
        
    }
    public static String benefit_amount_ValueSort(String benefit_amount){
        if(String.isBlank(benefit_amount)){
            return '';
        }
        else {
            return '$ ' + benefit_amount;
        }
        
    }
    public static String valueOfStringified(Object param){
        return String.valueOf(param);
    }
    public  class EligibilityDemographicWrappper {
        public String InsuredFName {get; set;}
        public String InsuredLName {get; set;}
        public String policy {get; set;}
        public String insuredGroup {get; set;}
        public String plan {get; set;}
        public String insuredDOB {get; set;}
        public String insuredGender {get; set;}
        public String insuredAdress {get; set;}
        public String planBegin{get; set;}
        public  EligibilityDemographicWrappper(String InsuredFName,
                                               String InsuredLName,
                                               String policy,
                                               String insuredGroup,
                                               String plan,
                                               String insuredDOB,
                                               String insuredGender,
                                               String insuredAdress,
                                               String planBegin){
                                                   this.InsuredFName =InsuredFName;
                                                   this.InsuredLName =InsuredLName;
                                                   this.policy =policy;
                                                   this.insuredGroup = insuredGroup;
                                                   this.plan =plan;
                                                   this.insuredDOB =insuredDOB;
                                                   this.insuredGender =insuredGender;
                                                   this.insuredAdress =insuredAdress;
                                                   this.planBegin =planBegin;
                                                   
                                               }
    }
    public static void generatePDFAndAttachToFiles(String recordID){
        PageReference PDf =  Page.VOBPdfGeneration;//Replace attachmentPDf with the page you have rendered as PDF
        PDf.getParameters().put('Id',recordID);
        PDf.setRedirect(true);
        Attachment attach = new Attachment();
        Blob b ;
        b = PDf.getContent();
        attach.Body = b;
        attach.Name = 'Confirmation of pdf';
        attach.IsPrivate = false;
        attach.ParentId = recordID;
        if (Schema.sObjectType.Attachment.fields.Body.isCreateable() &&
            Schema.sObjectType.Attachment.fields.Name.isCreateable() &&
            Schema.sObjectType.Attachment.fields.IsPrivate.isCreateable() &&
            Schema.sObjectType.Attachment.fields.ParentId.isCreateable() ) {
                insert attach;
            }
    }
   
}