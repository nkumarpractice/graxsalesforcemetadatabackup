public with sharing class dedup {
    public List<Account> accountList{get;set;}
    public List<cAccount> accList1 {get; set;}
    public List<Account> selectedAccounts{get; set;}
    public Id objSelectedAccountId {get;set;}
    public List<Account> accList {get; set;}
    public String currentRecordId { get;set;}
    public Account account{get;set;}
    public String finalUrl{get;set;}
    public List<cAccount> cAccList{get;set;}
  
    public dedup(ApexPages.StandardController controller)
    {
        System.debug('Current record'+controller.getRecord());
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        account = [select id,Name,WebSite,BillingPostalCode,BillingCity from Account where id = :currentRecordId ];
    }
    
    public PageReference mergeOperation()
    {
       return null;
    }
    
    public void valChange(){
       
        System.debug('Selected recs :: '+ objSelectedAccountId);
    }
    public void accountSelectedCheckeBoxChange()
    {
        accountList=new List<Account>();
        for(Account objAccount:accList)
        {
            if(objAccount.Id==objSelectedAccountId)
            { 
                Integer index=accountList.indexOf(objAccount);
                accountList.remove(index);
                System.debug(accountList);
                System.debug('Remove click'+accountList.size());
            }
            else
            {
                accountList.add(objAccount);
                System.debug(accountList);
                System.debug('CLicked'+accountList.size());
                
            }
        }
    }
    
    public PageReference getAccountsById(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://grax-dev-ravitatiko.herokuapp.com/graxproxy/api/enrich/matches');
        request.setMethod('GET');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Length','0');
        request.setHeader('x-api-key', 'n3ohoPxYOE1lwC9MNlCsv22CHmJlngCG4eJJoqUw');
        request.setHeader('authorizationtoken', 'b46072d5a3a7071b4cbf91f680804b8afc8fed04e209f0c655756cf26e452be3');
        request.setHeader('licensetoken', 'U2FsdGVkX1/SniLKqWipdDuMlwvIVaahqtilR7rCnozbZrknlWHev48cXCcZjKX3Y4Ns0QLyXEAGy38qBrrjrE31YRWtSeVcNkv42onAkYo=');
        request.setHeader('Authorization',
                          'Basic bjNvaG9QeFlPRTFsd0M5TU5sQ3N2MjJDSG1KbG5nQ0c0ZUpKb3FVdzpiNDYwNzJkNWEzYTcwNzFiNGNiZjkxZjY4MDgwNGI4YWZjOGZlZDA0ZTIwOWYwYzY1NTc1NmNmMjZlNDUyYmUz');
        // sObject acc1 = [SELECT Name FROM Account];
        // String name = (String) acc1.get('Name');
        String accountName = account.name;
        
        System.debug('current data : '+ account.name);
        System.debug('current get data : '+ account.get('Name'));
        String str = '{"objectType":"Account","Name":"' + account.name +'"}';
        request.setBody(str);
        Map<String,Object> accMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(account));
        //  removeAttributes(accMap);
        String input=JSON.serializePretty(accMap);
        System.debug('JSON Input'+JSON.serializePretty(accMap));
        System.debug('JSON Updated Input'+input);
        //  request.setBody(input);
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> datas = (List<Object>) results.get('data');
            accList=new List<Account>();
            for(Object account:datas)
            {
                Map<String,Object> oneAccount=(Map<String,Object>) account;        
                Map<String,Object> updatedDoc=(Map<String,Object>) oneAccount.get('doc');
                //   System.debug('Updated Name'+updatedDoc.get('Name')) ;
                //  System.debug('Updated City'+updatedDoc.get('BillingCity')) ;
                //  retrieveAccounts(updatedDoc());
                Account acc=new Account();
                System.debug('Updated Name'+updatedDoc.get('Name')) ;
                System.debug('Updated City'+updatedDoc.get('BillingCity')) ;
                System.debug('Updated Website'+updatedDoc.get('Website')) ;
                System.debug('Updated BillingPostalCode'+updatedDoc.get('BillingPostalCode')) ;
                System.debug('Updated Id'+updatedDoc.get('Id')) ;
                
                acc.Id=(String)updatedDoc.get('Id');
                acc.Name=(String)updatedDoc.get('Name');
                acc.Website=(String)updatedDoc.get('Website');
                acc.BillingPostalCode=(String)updatedDoc.get('BillingPostalCode');
                acc.BillingCity=(String)updatedDoc.get('BillingCity');
                accList.add(acc);
            }   
            cAccList=new List<cAccount>();
            for(Account nAcc: accList){
                cAccList.add(new cAccount(nAcc));
            }
        }   
        return null;
    }
    /*   public List retreiveAccounts (Map<String,Object> upDatedDoc)
{
accList=new List<Account>();

Account acc=new Account();
System.debug('Updated Name'+updatedDoc.get('Name')) ;
System.debug('Updated City'+updatedDoc.get('BillingCity')) ;
System.debug('Updated Website'+updatedDoc.get('Website')) ;
System.debug('Updated BillingPostalCode'+updatedDoc.get('BillingPostalCode')) ;
System.debug('Updated Id'+updatedDoc.get('Id')) ;

acc.Id=(String)updatedDoc.get('Id');
acc.Name=(String)updatedDoc.get('Name');
acc.Website=(String)updatedDoc.get('Website');
acc.BillingPostalCode=(String)updatedDoc.get('BillingPostalCode');
acc.BillingCity=(String)updatedDoc.get('BillingCity');
accList.add(acc);
return accList;
}*/
    public String processRedirect(){
         String str = '';
        selectedAccounts= new List<Account>();
        integer i =0;
        for(cAccount cCon : cAccList) {
            if(cCon.selected == true){
                Account tes = cCon.con;
                String t = (String) tes.get('Id');
                if(i != 0){
                    str += '&';
                }
                String x ='cid=' + t;
                
                str+=x;
                
               
                selectedAccounts.add(cCon.con);
                i++;
            }
        }
         
		String mergeUrl ='https://na85.salesforce.com/merge/accmergewizard.jsp?'+str + '&goNext=1';
         System.debug('Called here mergeUrl ::: ' + mergeUrl);
        finalUrl = mergeUrl;
        return null;
    }
    public List<cAccount> getAccounts(){
        if(accList1 == null){
            accList1 = new List<cAccount>();
            for(Account acc : [select Id from Account ]){
                accList1.add(new cAccount(acc));
            }
        }
        return accList1;
    }
    
    
    public class cAccount {
        public  Account con {get; set;}
        public Boolean selected {get; set;}
        public cAccount(Account c) {
            con = c;
            selected = false;
        }
    }
    
}