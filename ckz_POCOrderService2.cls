global with sharing class ckz_POCOrderService extends ccrz.ccServiceOrder {
        global override virtual Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        inputData = super.getFieldsMap(inputData); 
            String objectFields = (String)inputData.get(ccrz.ccService.OBJECTFIELDS); 
                    return new Map <String,Object> {ccrz.ccService.OBJECTFIELDS => objectFields};  
    }
    
    // Carrier and Tracking NO example
    global override Map<String, Object> fetch(Map<String, Object> inputData){

        ccrz.ccLog.log('ckz_POCOrderService', 'inputData: ' + JSON.serialize(inputData));

        Map<String, Object> returnMap = super.fetch(inputData);

        ccrz.ccLog.log('ckz_POCOrderService', 'fetch returnMap 1: ' + JSON.serialize(returnMap));

        List<Object> orderList = (List<Object>)returnMap.get('orderList');

        for(Object obj : orderList) {
            Map<String, Object> orderObjMap = (Map<String, Object>)obj;

            Decimal orderNumber = (Decimal)orderObjMap.get('orderNumber');
            ccrz.ccLog.log('ckz_POCOrderService', 'orderNumber: ' + orderNumber);

            String sfdcName = (String)orderObjMap.get('sfdcName');
            ccrz.ccLog.log('ckz_POCOrderService', 'sfdcName: ' + sfdcName);

            // callout here

            Map<String, String> responseMap = fetchOrderTrack(orderNumber.toPlainString());
            //Map<String, String> responseMap = fetchOrderTrack(sfdcName);

            String extCarrier = null;

            String extShipTrackNo = null;

            if(responseMap.containsKey('extCarrier')) {
                extCarrier = responseMap.get('extCarrier');
            }

            if(responseMap.containsKey('extShipTrackNo')) {
                extShipTrackNo = responseMap.get('extShipTrackNo');
            }

            ccrz.ccLog.log('ckz_POCOrderService', 'extCarrier: ' + extCarrier);
            ccrz.ccLog.log('ckz_POCOrderService', 'extShipTrackNo: ' + extShipTrackNo);
           
            if(extCarrier != null) {
                orderObjMap.put('extCarrier', extCarrier);
            }

            if(extShipTrackNo != null) {
                orderObjMap.put('extShipTrackNo', extShipTrackNo);
            }

        } 

        ccrz.ccLog.log('ckz_POCOrderService', 'fetch returnMap 2: ' + JSON.serialize(returnMap));

        return returnMap;

    }
    
    
    /*
        sample order # = 1000342
    */
    private static Map<String, String> fetchOrderTrack(String orderNumber) {

        Map<String, String> responseMap = new Map<String, String>();

        ccrz.ccLog.log('ckz_POCOrderService', 'fetchOrderTrack() begin');

        //Named Credential for External Order System
        String url = 'callout:AWS_Postgres/cmt$ccrz__e_order__c?$filter=ccrz__ordernumber__c';
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

        String ExtCarrier = null;
        String ExtShipTrackNo = null;

        List<Object> valueList = (List<Object>)MyMap.get('value');

        if(valueList != null && valueList.size() > 0) {
            Object obj = valueList.get(0);

            Map<String, Object> objMap = (Map<String, Object>)obj;

            ExtCarrier = (String)objMap.get('ccrz__extcarrier__c'); //case sensitive (external source)
            responseMap.put('extCarrier', ExtCarrier);
            
            ExtShipTrackNo = (String)objMap.get('ccrz__extshiptrackno__c'); //case sensitive (external source)
            responseMap.put('extShipTrackNo', ExtShipTrackNo);

        }

        ccrz.ccLog.log('ckz_POCOrderService', 'ExtCarrier: ' + ExtCarrier);
        
        return responseMap;
    }
}


//-- replaces ccServiceOrder in Service Management serviceOrder
//-- Service Management c.ckz_POCOrderService  (Do not leave off c. when adding to Config)
//--https://odata-3-virginia.heroku.com/odata/v4/b62f804446014ef082d944f3d55751c4/cmt$ccrz__e_order__c?$filter=
