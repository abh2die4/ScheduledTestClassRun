/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This is the class that is used to process the apex test run results
*
* The test class run is initiated in the RunApexTestClasses schedulable job and this class
* runs evey 30 min after the RunApexTestClasses run at 12 am (say)
*
* Cron Expression Used - ?????
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-23
* @modified       
* @systemLayer    Invocation | Service (x) | Utility | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global with sharing class GatherApexTestRunResult implements Schedulable, Database.AllowsCallouts, Database.Stateful {
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method processes the result of the apex test run initiated by RunApexTestClasses
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    sc           SchedulableContext
    * @return   -----        
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    global void execute(SchedulableContext sc) {
        GatherApexTestRunResultHelper.processTestRunResult();
    }
}
