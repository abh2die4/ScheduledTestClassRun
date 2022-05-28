/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This is the helper class for GatherApexTestRunResult
*
* The class orchestrates the various actions needed to generate and email the results
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-28
* @modified       
* @systemLayer    Invocation | Service (x) | Utility | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class GatherApexTestRunResultHelper {
     /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method is used to process the records once the test run is complete
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    ---------   NA
    * @return   ---------   NA    
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void processTestRunResult(){
        //get the latest Conataier record
        List<Apex_Test_Run_Container__c> container = [Select id,Async_Apex_Job_Id__c from Apex_Test_Run_Container__c where Is_Result_Updated__c = false order by createddate limit 1];

        if(container != null && container.size() == 1){ 
            //check if the test run is completed
            Boolean isRunComplete = ApexTestAutoRunUtility.checkStatusOfAsyncJob(container[0].Async_Apex_Job_Id__c);

            if(isRunComplete){
                //consolidate the result
                ApexTestAutoRunUtility.insertTestRunResult(new ApexTestAutoRunWrappers.TestRunInsertPayload(container[0].Async_Apex_Job_Id__c, container[0].Id));

                //call async method which inserted method and class level data
                ID jobID = System.enqueueJob(new ApexTestAutoRunQueable(container[0].Id));
            }
            else{
                system.debug('TEST RUN NOT COMPLETED');
                //have to retry
            }
        }
        else{
            system.debug('NO CONTAINER RECORD');
            //have to retry
        }
    }
}
