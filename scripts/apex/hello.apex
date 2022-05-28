ApexTestAutoRunWrappers.TestRunResult res = ApexTestAutoRunUtility.runTestClasses();
if(res.isSuccess){
    ApexTestAutoRunUtility.insertContainerRecords(res);
}

GatherApexTestRunResultHelper.processTestRunResult();

List<ApexClass> testClasses = [FIND '@istest or testmethod' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];
List<ApexClass> allClasses = [Select id, Name from ApexClass];
Set<String> filteredClasses = new Set<String>();
for(ApexClass c : allClasses){
    for(Apexclass tc : testClasses){
        if(c.Name != tc.Name){
            filteredClasses.add(c.Name);
        }
    }
}
Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

for(String cls : filteredClasses){
    // Setup custom metadata to be created in the subscriber org.
    Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
    customMetadata.fullName = 'Apex_Class__mdt.'+cls;
    customMetadata.Label = cls;
    mdContainer.addMetadata(customMetadata);
}

Id deployRequestId = Metadata.Operations.enqueueDeployment(mdContainer, null);

delete[select id from Apex_Test_Run_Container__c];

HttpResponse resp = ApexTestAutoRunUtility.doCalloutForTestCoverage(new Set<Id>{'01p5j000000xaEhAAI'});
system.debug(resp);
 Map<String, Object> allcoverageData = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
 system.debug(resp.getBody());
List<object> allrecords = (list<object>)allcoverageData.get('records');
system.debug(allrecords == null);