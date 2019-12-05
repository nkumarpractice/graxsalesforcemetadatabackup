public class EnrichMatches {
    public List<Account> accountList{get;set;}
    public List<Account> selectedAccounts{get; set;}
    public Id objSelectedAccountId {get;set;}
    public List<cAccount> graxMatches {get; set;}
    public Id currentRecordId { get;set;}
    public Account currentRow{get;set;}
    public String finalUrl{get;set;}
    public List<cAccount> finalMatches{get;set;}
    public List<Account> salesforceAccounts{get;set;}
    
    public EnrichMatches(ApexPages.StandardController controller)
    {
        System.debug('Current record'+controller.getRecord());
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        System.debug(' currentRecordId'+ currentRecordId);
        currentRow = [select id,Name,WebSite,BillingPostalCode,BillingCity from Account where id = :currentRecordId ];
        //    System.debug(myId.getSObjectType());
    }
    public PageReference getDatalakeMatches(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        grax__GRAXSettings__c mc = grax__GRAXSettings__c.getOrgDefaults();
        request.setEndpoint(mc.grax__GRAX_API_Url__c+'/enrich/matches');
        System.debug(mc.grax__GRAX_API_Url__c+'/enrich/matches');
        request.setMethod('GET');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Length','0');
        request.setHeader('x-api-key', mc.grax__GatewayToken__c);
        System.debug('x-api-key'+mc.grax__GatewayToken__c);
        request.setHeader('authorizationtoken', mc.grax__ApiToken__c);
        System.debug('authorizationtoken'+mc.grax__ApiToken__c);
        request.setHeader('licensetoken', mc.grax__LicenseToken__c);
        System.debug('licensetoken'+mc.grax__LicenseToken__c);
        request.setHeader('Authorization','Basic '+ EncodingUtil.base64Encode(Blob.valueOf(mc.grax__GatewayToken__c+':'+mc.grax__ApiToken__c)));
        System.debug('Authorization'+'Basic '+ EncodingUtil.base64Encode(Blob.valueOf(mc.grax__GatewayToken__c+':'+mc.grax__ApiToken__c)));
        String accountName = currentRow.name;
        Id accountId=currentRow.Id;
        String billingCity = currentRow.billingCity;
        String billingPostalCode = currentRow.billingPostalCode;
        String name = currentRow.name;
        String website = currentRow.website;
        if(billingCity == null){
            billingCity ='';
        }
        if(billingPostalCode == null){
            billingPostalCode ='';
        }
        if(website == null){
            website ='';
        }
        List<Id> graxMatchIds = new List<Id>();
        String payload = '{"objectType":"'+currentRecordId.getSobjectType()+'","Name":"'
            + name
            +'","website":"'
            + website
            + '","BillingPostalCode":"'
            + billingPostalCode
            + '","sfdcorgid":"'
            //+ //'00D2v000000QW94EAG'
            +UserInfo.getOrganizationId()
            + '","BillingCity":"'
            + billingCity
            + '"}';
        
        System.debug('Payload :'+payload);
        request.setBody(payload);
        Map<String,Object> accMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(currentRow));
        System.debug('accMap'+accMap);
        String input=JSON.serializePretty(accMap);
        System.debug('input'+input);
        request.setTimeout(20000);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        System.debug('response'+response);
        if (response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> matches = (List<Object>) results.get('data');
            graxMatches = new List<cAccount>();
            for(Object account : matches)
            {
                Map<String,Object> duplicateRecord = (Map<String,Object>) account;        
                Map<String,Object> doc = (Map<String,Object>) duplicateRecord.get('doc');
                Account acc = new Account();
                cAccount cAcc;
                acc.Id=(String)doc.get('Id');
                acc.Name=(String)doc.get('Name');
                acc.Website=(String)doc.get('Website');
                acc.BillingPostalCode=(String)doc.get('BillingPostalCode');
                acc.BillingCity=(String)doc.get('BillingCity');
                cAcc = new cAccount(acc);
                cAcc.score = (Decimal)duplicateRecord.get('score');
                // array of IDs from salesforce
                graxMatchIds.add(acc.Id); 
                System.debug('graxMatchIds: '+graxMatchIds);
                graxMatches.add(cAcc);
                System.debug('graxMatches: '+graxMatches);
            }   
            salesforceAccounts = [select id from Account where id in :graxMatchIds ];
            System.debug('All account: '+salesforceAccounts);
            finalMatches=new List<cAccount>();
            for(cAccount graxMatch: graxMatches){
                for(Account salesforceAccount: salesforceAccounts){
                    if(salesforceAccount.Id == graxMatch.sObj.Id){
                        finalMatches.add(graxMatch);
                    }
                }
                
            }
        }   
        return null;
    }
    
    public String processRedirect(){
        String cids = '';
        selectedAccounts= new List<Account>();
        integer i =0;
        for(cAccount cAcc : finalMatches) {
            if(cAcc.selected == true){
                Account acc = cAcc.sObj;
                String id = (String) acc.get('Id');
                if(i != 0){
                    cids += '&';
                }
                String tmp ='cid=' + id;
                cids+=tmp;
                selectedAccounts.add(cAcc.sObj);
                i++;
            }
        }
        finalUrl = 'https://na85.salesforce.com/merge/accmergewizard.jsp?'+cids + '&goNext=1';
        System.debug('final URL :' + finalUrl);
        return null;
    }
    
    public class cAccount {
        public Account sObj {get; set;}
        public Boolean selected {get; set;}
        public Decimal score {get; set;}
        public cAccount(Account c) {
            sObj = c;
            selected = false;
        }
    }
}