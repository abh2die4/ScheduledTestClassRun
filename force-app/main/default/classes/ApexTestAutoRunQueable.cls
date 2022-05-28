/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This is the class that is used to processing after the callout is done to get the ApexCodeCoverage
*
* Here records are inserted into Apex_Code_Coverage_Method_Level__c and Apex_Code_Coverage_Class_Level__c
* records
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-24
* @modified       
* @systemLayer    Invocation | Service (x) | Utility | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class ApexTestAutoRunQueable implements Queueable, Database.AllowsCallouts {
    
    public String containerId;

    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This is the contructor where the data send to constructor is set on the class variables
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    containerId   Type:String
    * @return   -----        
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public ApexTestAutoRunQueable(String containerId) {
        this.containerId = containerId;
    }
    
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method inerts records into Apex_Code_Coverage_Method_Level__c and 
    * Apex_Code_Coverage_Class_Level__c records
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    context      Type:QueueableContext
    * @return   -----        
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public void execute(QueueableContext context) {
        //REST callout to Tooling API object ApexCodeCoverage and create records in Apex Code Coverage objects
        List<Apex_Code_Coverage_Method_Level__c> methodCov = ApexTestAutoRunUtility.getCoverageDetails(containerId);

        //create Method Level Coverage records
        ApexTestAutoRunUtility.insertCTestCodeCovDetails(methodCov,containerId);

        //update the container records to indicate results are inserted
        update new Apex_Test_Run_Container__c(Id = containerId, Is_Result_Updated__c = true);

        //send Email with attached PDF
        ApexTestAutoRunUtility.generatePDFAndSendMail(containerId);
    }
}
