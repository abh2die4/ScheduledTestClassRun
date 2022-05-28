/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* This is the utility class for all the wrappers used in for the 'Auto Test Class Run' module
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
public with sharing class ApexTestAutoRunWrappers {

    public class TestRunResult{
        public Boolean isSuccess;
        public String errMessage;
        public String asyncJobId;
        public String sourceOfTestClassList;
        public Integer numberOfTestClass = 0;
    }

    public class TestRunInsertPayload{
        public String asyncId;
        public String containerId;
        public TestRunInsertPayload(String a, String b){
            this.asyncId = a;
            this.containerId = b;
        }
    }

    public class TestRunInsertResp{
        public Boolean isSuccess;
        public String errMessage;
        public String asyncJobId;
        public String sourceOfTestClassList;
        public Integer numberOfTestClass = 0;
    }
}
