global with sharing class ckz_POCOrderService extends ccrz.ccServiceOrder {

    global override virtual Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        inputData = super.getFieldsMap(inputData); 
            String objectFields = (String)inputData.get(ccrz.ccService.OBJECTFIELDS); 
                objectFields += ',ExtOrderStatus__c';
                    return new Map <String,Object> {ccrz.ccService.OBJECTFIELDS => objectFields};  
    }

    global override Map<String, Object> fetch(Map<String, Object> inputData){

        ccrz.ccLog.log('ckz_POCOrderService', 'inputData: ' + JSON.serialize(inputData));

        Map<String, Object> returnMap = super.fetch(inputData);

        ccrz.ccLog.log('ckz_POCOrderService', 'fetch returnMap 1: ' + JSON.serialize(returnMap));

        List<Object> orderList = (List<Object>)returnMap.get('orderList');

        for(Object obj : orderList) {
            Map<String, Object> orderObjMap = (Map<String, Object>)obj;

            Decimal orderNumber = (Decimal)orderObjMap.get('orderNumber');

            // TODO make callout here

            String extOrderStatus = '';

            String orderStatus = fetchOrderStat(orderNumber.toPlainString());

            if(orderStatus != null) {
                orderObjMap.put('orderStatus', orderStatus);
            }

            ccrz.ccLog.log('ckz_POCOrderService', 'orderNumber: ' + orderNumber);
        }

        ccrz.ccLog.log('ckz_POCOrderService', 'fetch returnMap 2: ' + JSON.serialize(returnMap));

        return returnMap;

    }

    /*
        sample order # = 1000342
    */
    private static String fetchOrderStat(String orderNumber) {

        ccrz.ccLog.log('ckz_POCOrderService', 'fetchOrderStat() begin');

        String url ='https://odata-2-virginia.heroku.com/odata/v4/f19b42965f9a48078e2b968167ccf736/salesforce$ccrz__e_order__c?$filter=ccrz__ordernumber__c%20eq%20' + orderNumber;
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

        String herokuStatus = null;

        List<Object> valueList = (List<Object>)MyMap.get('value');

        if(valueList != null && valueList.size() > 0) {
            Object obj = valueList.get(0);

            Map<String, Object> objMap = (Map<String, Object>)obj;

            herokuStatus = (String)objMap.get('ccrz__orderstatus__c');

        }

        ccrz.ccLog.log('ckz_POCOrderService', 'herokuStatus: ' + herokuStatus);
        
        return herokuStatus;
    }

}
//-- replaces 	cclxrep.cclxrepServiceOrder in Service Management serviceOrder
//-- Service Management c.ckz_POCOrderService  (Don't forget c.)
