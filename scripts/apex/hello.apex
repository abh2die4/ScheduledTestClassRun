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



# Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
