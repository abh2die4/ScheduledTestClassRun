/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This batch class runs all the test classes in the org.
*
* Based on the settings in the 'Apex Test Run Setting' metadata either all test classes
* or specified test classes should be run (specified in 'Apex Test Classes' metadata)
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-23
* @modified       
* @systemLayer    Invocation | Service(x) | Utility | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global with sharing class RunApexTestClasses implements Schedulable{
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * Execute method of the Scheduler. This is where all the test classes are run
    * This will be setp up to run at a non-peak time (e.g. midnight at 12)
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    sc      Type: SchedulableContext
    * @return   void    N/A
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    global void execute(SchedulableContext sc) {
        ApexTestAutoRunWrappers.TestRunResult res = ApexTestAutoRunUtility.runTestClasses();
        if(res.isSuccess){
            ApexTestAutoRunUtility.insertContainerRecords(res);
        }
    }
}
