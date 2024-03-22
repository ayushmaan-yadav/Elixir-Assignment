@isTest
public class ElixirOEM_MapOfBenifitTypeCode1Test {
 @isTest
    public static void unitTest(){
        Map<String,String> expectedbenifitTypeCodeMap = new Map<String,String> {
        '33'  => 'Chiropractic',
        '30' =>'Health Benefit Plan Coverage'
        };
            Test.startTest();
            System.assertEquals(expectedBenifitTypeCodeMap, ElixirOEM_MapOfBenifitTypeCode1.benifitTypeCodeMap);
            Test.stopTest();
        
    }

}