global with sharing class makeHTTPCall {
    
    @RemoteAction
    global static ccrz.cc_RemoteActionResult getExtOrder(ccrz.cc_RemoteActionContext ctx, String orderStat) {
        ccrz.cc_CallContext.initRemoteContext(ctx);
        System.debug('Start - orderStat: ' + orderStat);
        ccrz.cc_RemoteActionResult result = new ccrz.cc_RemoteActionResult();
        result.success = false;
        result.inputContext = ctx;
        
        List<ccrz.cc_bean_Message> messages = new List<ccrz.cc_bean_Message>();
        
        try {
            
            Map<String, Object> resultMap = fetchOrderStat();

            if(resultMap.size() > 0) {
                ccrz.ccLog.log(System.LoggingLevel.INFO,'makeHTTPCall','updateAccount: successful');
                
                ccrz.cc_bean_Message msg = new ccrz.cc_bean_Message('Account update successful', ccrz.cc_bean_Message.MessageSeverity.INFO);
                msg.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
                msg.classToAppend = 'error_update_contact';
                messages.add(msg);
                
                result.data = resultMap;
                resultMap.put('orderStat', orderStat);
                
                result.success = true;
            }
            else {
                
                System.debug('updateAccount: account not found');
                ccrz.ccLog.log(System.LoggingLevel.INFO,'ckz_makeHTTPCall','updateAccount: account not found');
                
                ccrz.cc_bean_Message msg = new ccrz.cc_bean_Message('Account not found', ccrz.cc_bean_Message.MessageSeverity.ERROR);
                msg.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
                msg.classToAppend = 'error_update_contact';
                messages.add(msg);
                
            }
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Line #: ' + e.getLineNumber());
            ccrz.ccLog.log(System.LoggingLevel.ERROR,'ERR',e);
            
            ccrz.cc_bean_Message msg = new ccrz.cc_bean_Message(e.getMessage(), ccrz.cc_bean_Message.MessageSeverity.ERROR);
            msg.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
            msg.classToAppend = 'error_update_contact';
            messages.add(msg);
            
        } finally {
            ccrz.ccLog.log(System.LoggingLevel.INFO,'M:X','getInventory');
            ccrz.ccLog.close(result);
        }
        
        result.messages.addAll(messages);
        
        return result;
        
    }
    
    private static Map < String,Object > fetchOrderStat( ) {
        String url ='https://odata-2-virginia.heroku.com/odata/v4/f19b42965f9a48078e2b968167ccf736/salesforce$ccrz__e_order__c?$filter=ccrz__ordernumber__c eq 1000342';
        String userName = '';
        String password = '';
        Blob headerValue = Blob.valueOf( username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        // Instantiate a new http object
        Http h = new Http();
        
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', authorizationHeader);  
        req.setMethod('GET');
        req.setEndpoint(url);
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        System.debug('response:--> ' + res.getBody());
        
        // Deserialize the JSON string into collections of primitive data types.
        Map < String,Object > MyMap = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
        system.debug('resultsMap-->' + MyMap);
        
        return MyMap;
    }
}
