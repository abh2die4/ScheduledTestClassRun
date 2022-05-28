/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This class will generate the test class run result as a PDF
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-28
* @modified       
* @systemLayer    Invocation | Service(x) | Utility | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class DisplayTestClassResultController {

    public String sandboxname{get;set;} //stores sandbox name to display the same on the report
    public List<Apex_Test_Class_Run_Result__c> testRunRes {get;set;} //list of apex test run result
    public List<Apex_Code_Coverage_Class_Level__c> classCoverage {get;set;} //list of class level coverages

    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This is the constructor of the class
    * 
    * Here the data to be displayed is fetched
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    ---     N/A
    * @return   ---     N/A
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public DisplayTestClassResultController() {
        //Initialize Class level variables
        sandboxname = UserInfo.getUserName().substringAfterLast('@');

        //get the page parameters and confirm that apex test run container id is present
        Map<String, String> parameters = ApexPages.currentPage().getParameters();
        if(!parameters.containsKey('containerId')){
            ApexPages.Message errMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Apex Test Run Container Id not provided');
            ApexPages.addMessage(errMessage);
        }
        else{
            String containerId = parameters.get('containerId');
            //get the conainer related data i.e. Test Run Result and ClassCoverage
            testRunRes = [Select Id,Apex_Test_Class_Name__c,Apex_Test_Method_Name__c,Outcome__c,Exception_Message__c from Apex_Test_Class_Run_Result__c where Apex_Test_Run_Container__c =:containerId];
            classCoverage = [Select Id,Apex_Class_Name__c,Coverage__c,Lines_Uncovered__c from Apex_Code_Coverage_Class_Level__c where Apex_Test_Run_Container__c =:containerId order by Coverage__c ASC];
        }
    }
}
