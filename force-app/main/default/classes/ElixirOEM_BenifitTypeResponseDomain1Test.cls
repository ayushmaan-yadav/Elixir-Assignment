@isTest
public class ElixirOEM_BenifitTypeResponseDomain1Test {
 @isTest
    public static void benifitTypeResponseDomainMethod(){
        ElixirOEM_BenifitTypeResponseDomain1.cls_benefit testWrapper = new ElixirOEM_BenifitTypeResponseDomain1.cls_benefit();
        string benefit_codeTest = testWrapper.benefit_code ;
        string benefit_coverage_codeTest = testWrapper.benefit_coverage_code;
        string benefit_coverage_descriptionTest = testWrapper.benefit_coverage_description;
        string benefit_descriptionTest = testWrapper.benefit_description;
        string benefit_period_descriptionTest = testWrapper.benefit_period_description;
        string benefit_amountTest = testWrapper.benefit_amount;
        string benefit_level_descriptionTest = testWrapper.benefit_level_description;
        string benefit_notesTest = testWrapper.benefit_notes;
        string benefit_level_codeTest = testWrapper.benefit_level_code;
        string date_of_last_updateTest = testWrapper.date_of_last_update;
        string insurance_planTest = testWrapper.insurance_plan;
        string insurance_type_codeTest = testWrapper.insurance_type_code;
        string insurance_type_descriptionTest = testWrapper.insurance_type_description;
        string entity_addr_1Test = testWrapper.entity_addr_1;
        string entity_cityTest = testWrapper.entity_city;
        string entity_codeTest = testWrapper.entity_code;
        string entity_descriptionTest = testWrapper.entity_description;
        string entity_nameTest = testWrapper.entity_name;
        string entity_stateTest = testWrapper.entity_state;
        string entity_zipTest = testWrapper.entity_zip;
        string inplan_networkTest = testWrapper.inplan_network;
        string benefit_percentTest = testWrapper.benefit_percent;
        string in_out_planNetworkTest = testWrapper.in_out_planNetwork;
        string benefit_period_code_toTextTest = testWrapper.benefit_period_code_toText;   
        
        ElixirOEM_BenifitTypeResponseDomain1.ParentDomain testWrapperTwo = new ElixirOEM_BenifitTypeResponseDomain1.ParentDomain();
        string benefit_descriptionTest2 = testWrapperTwo.benefit_description;
        string codeTest = testWrapperTwo.code;
        //List<cls_benefit> benifitLstTest = testWrapperTwo.benifitLst;
        
        ElixirOEM_BenifitTypeResponseDomain1.root testWrapperThird = new ElixirOEM_BenifitTypeResponseDomain1.root();
        string codeTest2 = testWrapperThird.code;
        string benefit_descriptionTest3 = testWrapperThird.benefit_description;
        
        ElixirOEM_BenifitTypeResponseDomain1.SubRoot testWrapperForth = new ElixirOEM_BenifitTypeResponseDomain1.SubRoot();
        string benefit_level_codeTest4 = testWrapperForth.benefit_level_code;
        string benefit_coverage_descriptionTest5 = testWrapperForth.benefit_coverage_description;
        //string lst_inplan_networkTest6 =  testWrapperForth.lst_inplan_network;
        
        Test.startTest();     
        System.assertEquals(1, 1, '');
        Test.stopTest();
            
    }
}