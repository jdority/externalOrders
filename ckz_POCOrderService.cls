global with sharing class ckz_POCOrderService extends ccrz.ccServiceOrder {

    global override virtual Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        inputData = super.getFieldsMap(inputData); 
            String objectFields = (String)inputData.get(ccrz.ccService.OBJECTFIELDS); 
                objectFields += ', ExtOrderStatus__c';
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

            String extOrderStatus = fetchOrderStat(orderNumber.toPlainString());
           
           if(extOrderStatus != null) {
                orderObjMap.put('extOrderStatus', extOrderStatus); //ExtOrderStatus__c   
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

        //Named Credential for External Order System
        String url = 'callout:B2BexternalData/salesforce$ccrz__e_order__c?$filter=ccrz__ordernumber__c';
        String encoded = url + EncodingUtil.urlEncode(' eq ' + orderNumber, 'UTF-8');
        String encoded1 = encoded.replace('+', '%20');

        // Instantiate a new http object
        Http h = new Http();

        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint 
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(encoded1);
        
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

            herokuStatus = (String)objMap.get('extorderstatus__c'); //case sensitive (external source)

        }

        ccrz.ccLog.log('ckz_POCOrderService', 'herokuStatus: ' + herokuStatus);
        
        return herokuStatus;
    }

}
//-- replaces ccServiceOrder in Service Management serviceOrder
//-- Service Management c.ckz_POCOrderService  (Do not leave off c. when adding to Config)