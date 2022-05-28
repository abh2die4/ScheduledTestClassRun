/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This is the utility class for the 'Auto Test Class Run' module
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Abhijit Debadutta
* @modifiedBy     Abhijit Debadutta
* @maintainedBy   Abhijit Debadutta
* @version        1.0
* @created        2022-05-23
* @modified       
* @systemLayer    Invocation | Service | Utility(x) | Selector | Domain | Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            <author>
* YYYY-MM-DD      <Description>
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class ApexTestAutoRunUtility {
     /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method returns list of test classes.
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    ---     N/A
    * @return   ApexTestAutoRunWrappers.ApexTestClassDetails    Details of all Apex Test Classes
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static List<ApexClass> getListOfTestClasses(){
        Apex_Test_Run_Setting__mdt setting = Apex_Test_Run_Setting__mdt.getInstance('Default');//get the setting data

        List<ApexClass> testClasses = new List<ApexClass>(); //list of test classes that are to be run

        if(setting != null && setting.List_of_Apex_Test_Classes__c == 'Classes in Apex_Test_Classes__mdt'){
            List<Apex_Test_Classes__mdt> testClassData  = Apex_Test_Classes__mdt.getAll().values(); //get metadata with list of test classes
            
            Set<String> testClassNames = new Set<String>(); // set to store all test class names
            if(testClassData != null && testClassData.size()>0){
                for(Apex_Test_Classes__mdt tc : testClassData){
                    testClassNames.add(tc.Apex_Test_Class_Name__c);
                }
                testClasses = [Select Id, Name from ApexClass where Name =: testClassNames];
            }
        }
        else if(setting != null && setting.List_of_Apex_Test_Classes__c == 'Apex Test Suite'){
            List<TestSuiteMembership> testSuiteDetails = [select id, ApexClass.Name from TestSuiteMembership where ApexTestSuite.TestSuiteName =: setting.Apex_Test_Suite_Name__c];

            Set<String> testClassNames = new Set<String>(); // set to store all test class names
            if(testSuiteDetails != null && testSuiteDetails.size()>0){
                for(TestSuiteMembership tsm : testSuiteDetails){
                    testClassNames.add(tsm.ApexClass.Name);
                }
                testClasses = [Select Id, Name from ApexClass where Name =: testClassNames];
            }
        }
        else{
            testClasses = [FIND '@istest or testmethod' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];
        }

        return testClasses;
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method runs the test classes. The list of test classes to run is specified in the settings.
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    ---     N/A
    * @return   void    N/A
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static ApexTestAutoRunWrappers.TestRunResult runTestClasses(){
        ApexTestAutoRunWrappers.TestRunResult resp = new ApexTestAutoRunWrappers.TestRunResult();//Response Wrapper

        List<ApexClass> testClasses = getListOfTestClasses();

        Apex_Test_Run_Setting__mdt setting = Apex_Test_Run_Setting__mdt.getInstance('Default');//get the setting data
        resp.sourceOfTestClassList = setting!=null?setting.List_of_Apex_Test_Classes__c:'All Test Class';

        if(testClasses.size() > 0) {
            resp.numberOfTestClass = testClasses.size();

            List<ApexTestQueueItem> testQueueItems = new List<ApexTestQueueItem>();
            for (ApexClass cls : testClasses) {
                testQueueItems.add(new ApexTestQueueItem(ApexClassId=cls.Id));
            }
            try{
                insert testQueueItems; // this will run all the test classes

                list<ApexTestQueueItem> updatedQueueItems = [select id,ParentJobId from ApexTestQueueItem where id=:testQueueItems];
                resp.isSuccess = true;
                resp.asyncJobId = updatedQueueItems[0].ParentJobId;
            }
            catch(Exception e){
                //DML exception to be handled
                resp.isSuccess = false;
                resp.errMessage = e.getMessage();
            }
        }
        else{
            //no test classes found
            resp.isSuccess = false;
            resp.errMessage = 'No Test Class Found';
        }

        return resp;
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method inserts records into the Apex_Test_Run_Container__c object
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    ApexTestAutoRunWrappers.TestRunResult     This holds all the data of the apextest run
    * @return   void    N/A
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void insertContainerRecords(ApexTestAutoRunWrappers.TestRunResult res){
        if(res!=null){
            Apex_Test_Run_Container__c c = new Apex_Test_Run_Container__c();
            c.All_Test_Classes_Processed__c = res.sourceOfTestClassList;
            c.Number_of_Test_Classes_Processed__c = res.numberOfTestClass;
            c.Async_Apex_Job_Id__c = res.asyncJobId;

            try{
                insert c;
            }
            catch(Exception e){
                //some issue in container record insertion
            }
        }
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method checks if the apex test run is completed
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    asyncJobId     This is the Job Id which is started when all test classses were run
    * @return   Boolean        Indicates the job is complete
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static Boolean checkStatusOfAsyncJob(String asyncJobId){
        List<ApexTestQueueItem> testQueueItems = [select id, Status from ApexTestQueueItem where ParentJobId =: asyncJobId]; 

        List<ApexTestQueueItem> completedTestCls = new List<ApexTestQueueItem>();
        for(ApexTestQueueItem q:testQueueItems){
            if(q.Status == 'Completed'){
                completedTestCls.add(q);
            }
        }
        
        return testQueueItems.size() == completedTestCls.size();
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method creates records in the Apex_Test_Class_Run_Result__c object. The result is
    * obtained from the ApexTestResult object 
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    asyncJobId     This is the Job Id which is started when all test classses were run
    * @return   -----        Indicates the job is complete
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void insertTestRunResult(ApexTestAutoRunWrappers.TestRunInsertPayload ip){
        List<ApexTestResult> detailedTestResults = [select id,MethodName, AsyncApexJobId,ApexClassId, ApexClass.Name,StackTrace, Message, Outcome, RunTime from ApexTestResult  where AsyncApexJobId =: ip.asyncId]; //each record corresponds to a test method of a test class

        if(detailedTestResults != null && detailedTestResults.size()>0){
            List<Apex_Test_Class_Run_Result__c> l_testRunResults = new List<Apex_Test_Class_Run_Result__c>();
            for(ApexTestResult tr : detailedTestResults){
                Apex_Test_Class_Run_Result__c r = new Apex_Test_Class_Run_Result__c();
                r.Apex_Test_Class_Name__c = tr.ApexClass.Name;
                r.Apex_Test_Method_Name__c = tr.MethodName;
                r.Apex_Test_Run_Container__c = ip.containerId;
                r.Exception_Message__c = tr.Message;
                r.Exception_Stack_Trace__c = tr.StackTrace;
                r.Outcome__c = tr.Outcome;
                r.Runtime_ms__c = tr.RunTime;
                l_testRunResults.add(r);
            }

            if(l_testRunResults!=null && l_testRunResults.size()>0){
                try{
                    insert l_testRunResults;
                }
                catch(Exception e){

                }
            }
        }
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method does a REST callout to get details from ApexCodeCoverage (Tooling API object)
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    containerId                                  Type:String
    * @return   List<Apex_Code_Coverage_Method_Level__c>     List of Method level coverages inserted
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static List<Apex_Code_Coverage_Method_Level__c> getCoverageDetails(String containerId){
        
        List<Apex_Code_Coverage_Method_Level__c> methodCov = new List<Apex_Code_Coverage_Method_Level__c>();//response

        //get list of test classes
        /*List<ApexClass> testClasses = getListOfTestClasses();

        if(testClasses !=null && testClasses.size()>0){
            Set<Id> apexTestClassIds = new Set<Id>();
            for(ApexClass c:testClasses){
                apexTestClassIds.add(c.Id);
            }

            HttpResponse resp = doCalloutForTestCoverage(apexTestClassIds);

            //insert records into Apex_Code_Coverage_Method_Level__c
            methodCov = insertMTestCodeCovDetails(resp, containerId);
        }*/
        List<Apex_Class__mdt> classes = [Select Id, Label, DeveloperName from Apex_Class__mdt];    
        
        if(classes.size()>0){
            Set<String> clsNames = new Set<String>();
            for(Apex_Class__mdt cMdt : classes){
                clsNames.add(cMdt.DeveloperName);
            }
            List<ApexClass> clsList = [Select Id from ApexClass where Name =: clsNames];

            Set<Id> classIds = new Set<Id>();
            for(ApexClass c:clsList){
                classIds.add(c.Id);
            }
            HttpResponse resp = doCalloutForTestCoverage(classIds);
            methodCov = insertMTestCodeCovDetails(resp, containerId);
        }

        return methodCov;

    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * [Utility] This method does a REST callout to get details from ApexCodeCoverage (Tooling API object)
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    apexTestClassIds   Type:Set<Id> - set of Apex Test Class Ids
    * @return   HttpResponse       Response from Tooling API callout
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static HttpResponse doCalloutForTestCoverage(Set<Id> apexTestClassIds){
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        String URL = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v53.0/tooling/query/?q=Select+id,ApexTestClassId,ApexTestClass.name,TestMethodName,Coverage,ApexClassorTrigger.Name,ApexClassorTriggerId+from+ApexCodeCoverage+Where+ApexClassorTriggerId+IN(' ;
        for(String clsId:apexTestClassIds){
            URL = URL + '\''+clsId+'\',';
        }
        URL = URL.removeEnd(',');
        URL+= ')';
        req.setEndpoint(URL);
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(req);
        return response;
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method is used to insert records in the Apex_Code_Coverage_Method_Level__c object
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    resp   Type:HTTPResponse - ApexCodeCoverage Details
    * @return   List<Apex_Code_Coverage_Method_Level__c> List of method level coverages inserted    
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static List<Apex_Code_Coverage_Method_Level__c> insertMTestCodeCovDetails(HttpResponse response, String containerId){
        List<Apex_Code_Coverage_Method_Level__c> allCoverageResults = new List<Apex_Code_Coverage_Method_Level__c>(); //final list of method level coverage to be inserted

        Map<String, Object> allcoverageData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        List<object> allrecords = (list<object>)allcoverageData.get('records');
        for(Object rec : allrecords){
            //get data from response
            Map<String, Object> recDetails = (Map<String, Object>)rec;
            String testMethodName = String.valueOf(recDetails.get('TestMethodName'));
            String mainClassId  = String.valueOf(recDetails.get('ApexClassOrTriggerId'));

            Map<String, Object> coverageDetails = (Map<String, Object>)recDetails.get('Coverage');
            List<Object> coveredLines  = (List<Object>)coverageDetails.get('coveredLines');
            List<Object> uncoveredLines  = (List<Object>)coverageDetails.get('uncoveredLines');       

            Map<String, Object> classHeader = (Map<String, Object>)recDetails.get('ApexClassOrTrigger');
            String mainClassName = String.valueOf(classHeader.get('Name'));

            Map<String, Object> testClassHeader = (Map<String, Object>)recDetails.get('ApexTestClass');
            String testClassName = String.valueOf(testClassHeader.get('Name'));

            //create Apex_Code_Coverage_Method_Level__c records
            Apex_Code_Coverage_Method_Level__c methodLevelCoverage = new Apex_Code_Coverage_Method_Level__c();
            methodLevelCoverage.Apex_Test_Run_Container__c = containerId;
            methodLevelCoverage.Apex_Class_Name__c = mainClassName;
            methodLevelCoverage.Apex_Test_Class_Name__c = testClassName;
            methodLevelCoverage.Apex_Test_Method_Name__c = testMethodName;

            List<String> allLines = new List<String>();

            String allCoveredLines ='';
            for(Object o : coveredLines){
                allCoveredLines+=Integer.valueOf(o)+',';
                allLines.add(String.valueOf(o));
            }
            methodLevelCoverage.Lines_Covered__c = allCoveredLines.removeEnd(',');
            methodLevelCoverage.Number_of_Lines_Covered__c = coveredLines?.size();
            
            String allUncoveredLines ='';
            for(Object o : uncoveredLines){
                allUncoveredLines+=Integer.valueOf(o)+',';
                allLines.add(String.valueOf(o));
            }
            methodLevelCoverage.Uncovered_Lines__c = allUncoveredLines.removeEnd(',');
            methodLevelCoverage.Number_of_Lines_Uncovered__c = uncoveredLines?.size();

            methodLevelCoverage.Total_Lines__c = methodLevelCoverage.Number_of_Lines_Uncovered__c + methodLevelCoverage.Number_of_Lines_Covered__c;
            if(allLines.size() > 0){
                String al = '';
                allLines.sort();
                for(String s:allLines){
                    al += s+',';
                }
                methodLevelCoverage.All_Lines__c = al.removeEnd(',');
            }

            allCoverageResults.add(methodLevelCoverage);
        }

        try{
            insert allCoverageResults;
        }
        catch(Exception e){
            //issue in creating method level coverage
        }

        return allCoverageResults;
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method is used to create Apex_Code_Coverage_Class_Level__c records from 
    * Apex_Code_Coverage_Method_Level__c records
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    methodCov   Type:List<Apex_Code_Coverage_Method_Level__c>
    * @param    containerId Type:String
    * @return   ---------   NA    
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static void insertCTestCodeCovDetails(List<Apex_Code_Coverage_Method_Level__c> methodCov, String containerId){
        Map<String, Set<String>> coveredLines = new Map<String, Set<String>>();
        Map<String, Set<String>> uncoveredLines = new Map<String, Set<String>>();
        Set<String> apexClasses = new Set<String>();

        //sum up the covered lines
        for(Apex_Code_Coverage_Method_Level__c mlc : methodCov){
            apexClasses.add(mlc.Apex_Class_Name__c);
            if(mlc.Lines_Covered__c != null){
                Set<String> covLines;
                if(coveredLines.containsKey(mlc.Apex_Class_Name__c)){
                    covLines = coveredLines.get(mlc.Apex_Class_Name__c);
                } 
                else{
                    covLines = new Set<String>();
                }
                covLines.addall(mlc.Lines_Covered__c.split(','));
                coveredLines.put(mlc.Apex_Class_Name__c, covLines);
            }
        }

        //process the uncovered lines
        for(Apex_Code_Coverage_Method_Level__c mlc : methodCov){
            if(!uncoveredLines.containsKey(mlc.Apex_Class_Name__c) && coveredLines.containsKey(mlc.Apex_Class_Name__c) && mlc.All_Lines__c != null){
                Set<String> uncovLine = new Set<String>();
                Set<String> covLines = coveredLines.get(mlc.Apex_Class_Name__c);
                for(String currLine : mlc.All_Lines__c.split(',')){
                    if(!covLines.contains(currLine)){
                        uncovLine.add(currLine);
                    }
                }
                uncoveredLines.put(mlc.Apex_Class_Name__c, uncovLine);
            }
        }


        //create Apex_Code_Coverage_Class_Level__c records
        List<Apex_Code_Coverage_Class_Level__c> allClassCoverages = new List<Apex_Code_Coverage_Class_Level__c>();
        for(String cls : apexClasses){
            Apex_Code_Coverage_Class_Level__c c = new Apex_Code_Coverage_Class_Level__c();
            c.Apex_Class_Name__c = cls;
            c.Apex_Test_Run_Container__c = containerId;
            c.Number_of_Lines_Covered__c = coveredLines.containsKey(cls)?coveredLines.get(cls).size():0;
            c.Number_of_Lines_Uncovered__c = uncoveredLines.containsKey(cls)?uncoveredLines.get(cls).size():0;
            if(coveredLines.containsKey(cls)){
                String covLines='';
                for(String s : coveredLines.get(cls)){
                    covLines += s+',';
                }
                c.Lines_Covered__c = covLines.removeEnd(',');
            }
            if(uncoveredLines.containsKey(cls)){
                String unCovLines='';
                for(String s : uncoveredLines.get(cls)){
                    unCovLines += s+',';
                }
                c.Lines_Uncovered__c = unCovLines.removeEnd(',');
            }
            allClassCoverages.add(c);
        }

        List<Apex_Class__mdt> classes = [Select Id, Label, DeveloperName from Apex_Class__mdt];   
        for(Apex_Class__mdt cmdt : classes){
            if(!apexClasses.contains(cmdt.DeveloperName)){
                Apex_Code_Coverage_Class_Level__c c = new Apex_Code_Coverage_Class_Level__c();
                c.Apex_Class_Name__c = cmdt.DeveloperName;
                c.Apex_Test_Run_Container__c = containerId;
                c.Lines_Uncovered__c = 'All';
                c.Lines_Covered__c = 'None'; 
                allClassCoverages.add(c);
            }
        }
        try{
            insert allClassCoverages;
        }
        catch(Exception e){
            //some issuue with insertion of Class_Level_Coverage__c records
        }
    }
    /************************************************************************************************
    * ───────────────────────────────────────────────────────────────────────────────────────────────┐
    * This method sends email to specified users
    * ────────────────────────────────────────────────────────────────────────────────────────────────
    * @param    containerid   Type:String
    * @return   sendEmailTo   Type:List<User>    
    * ───────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @future(callout=true)
    public static void generatePDFAndSendMail(String containerId){
        //Page is - /apex/DisplayTestClassResult?containerId=a085j000005UaGI
        PageReference defaultPage = new PageReference('/apex/DisplayTestClassResult'); //page location
        defaultPage.getParameters().put('containerId',containerId);
        Blob pdf; //variable to hold binary PDF data.
        system.debug('URL is'+defaultPage);
        try{
            pdf = defaultPage.getContentAsPDF();
        }catch(Exception e){
            pdf = Blob.valueOf(e.getMessage());
        }

        //create Attachment
        Attachment att = new Attachment();
        att.Body = pdf;
        att.Name = 'Test Run Report';
        att.IsPrivate = false;
        att.ParentId = containerId;
        att.Description = 'Test Run Report Details';
        insert att;

        //create and send email 
        Messaging.EmailFileAttachment matt = new Messaging.EmailFileAttachment();
        matt.setBody(pdf);
        matt.setContentType('application/pdf');
        matt.setFileName('attachment.pdf');
        Messaging.SingleEmailMessage mess = new Messaging.SingleEmailMessage();
        mess.setSubject('Email');
        mess.setToAddresses(new String[]{'abh2die4@gmail.com'});
        //mess.setTargetObjectId(param0)
        mess.setPlainTextBody('PFA Test Class Run Report.');
        mess.setFileAttachments(new Messaging.EmailFileAttachment[]{matt});
        Messaging.sendEmail(new Messaging.Email[]{mess},false);
    }
}