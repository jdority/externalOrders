global with sharing class ckzPOCCartDetailController {

    @RemoteAction
    global static ccrz.cc_RemoteActionResult getCartItemInfo(ccrz.cc_RemoteActionContext ctx, String [] skuList) {

        ccrz.cc_CallContext.initRemoteContext(ctx);
        ccrz.ccLog.log(System.LoggingLevel.INFO,'ckzPOCCartDetailController','getCartItemInfo');

        System.debug('ctx: ' + ctx);
        System.debug('skuList: ' + skuList);

        String userName = UserInfo.getName();
        ccrz.ccLog.log(System.LoggingLevel.INFO,'ckzPOCCartDetailController','userName: ' + userName);

        String userId = UserInfo.getUserId();
        ccrz.ccLog.log(System.LoggingLevel.INFO,'ckzPOCCartDetailController','userId: ' + userId);

        ccrz.cc_RemoteActionResult result = new ccrz.cc_RemoteActionResult();
        result.success = false;
        result.inputContext = ctx;

        List<ccrz.cc_bean_Message> messages = new List<ccrz.cc_bean_Message>();        

        Map<String, Object> resultMap = new Map<String, Object>();

        // Contains the canned data
        Map<String, Object> newDeliveryInfoMap = new Map<String, Object>();

        // What is sent back to the page
        Map<String, Object> deliveryInfoMap = parse();

        try {

            for(String sku : skuList) {

                if(sku == '25204') {

                    List<Object> deliveryInfoList = new List<Object>();

                    if(deliveryInfoMap.containsKey(sku)) {
                        deliveryInfoList = (List<Object>)deliveryInfoMap.get(sku);
                    }

                    newDeliveryInfoMap.put(sku, deliveryInfoMap.get(sku));
                }

            }

            resultMap.put('deliveryInfoMap', newDeliveryInfoMap);

            result.data = resultMap;
            result.success = true;

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Line #: ' + e.getLineNumber());
            ccrz.ccLog.log(System.LoggingLevel.ERROR,'ERR',e);

            ccrz.cc_bean_Message msg = new ccrz.cc_bean_Message(e.getMessage(), ccrz.cc_bean_Message.MessageSeverity.ERROR);
            msg.type = ccrz.cc_bean_Message.MessageType.CUSTOM;
            msg.classToAppend = 'messagingSection-Error';
            messages.add(msg);

        } finally {
            ccrz.ccLog.log(System.LoggingLevel.INFO,'ckzPOCCartDetailController','getCartItemInfo');
            ccrz.ccLog.close(result);
        }

        result.messages.addAll(messages);

        return result;

    }

    public static Map<String, Object> createMockData(String [] skuList) {

        Map<String, Object> deliveryInfoMap = new Map<String, Object>();

        for(String sku : skuList) {

            if(sku == '25204') {

                List<Object> deliveryInfoList = null;

                if(deliveryInfoMap.containsKey(sku)) {
                    deliveryInfoList = (List<Object>)deliveryInfoMap.get(sku);
                }
                else {
                    deliveryInfoList = new List<Object>();
                }

                ProductDeliveryInfo p = new ProductDeliveryInfo();
                p.scheduleNumber = '01';
                p.warehouse = 'U71';
                p.schedArrivalDate = Date.newInstance(2019,06,25).format();
                p.planShipDate = Date.newInstance(2019,06,24).format();
                p.offer = 'EXPRESS';
                p.qty = 8;

                deliveryInfoList.add(p);

                p = new ProductDeliveryInfo();
                p.scheduleNumber = '02';
                p.warehouse = 'U61';
                p.schedArrivalDate = Date.newInstance(2019,06,26).format();
                p.planShipDate = Date.newInstance(2019,06,23).format();
                p.offer = 'REPLENISHEMENT';
                p.qty = 8;

                deliveryInfoList.add(p);

                deliveryInfoMap.put(sku, deliveryInfoList);
            }

        }

        return deliveryInfoMap;
    }

    public static Map<String, Object> parseDocument(XmlStreamReader reader) {

        ProductDeliveryInfo info = null;
        Map<String, Object> deliveryInfoMap = new Map<String, Object>();
        List<Object> deliveryInfoList;
        String currentElement;
        String previousElement;
        String sku = null;
        Boolean isOfferList = false;

        boolean isSafeToGetNextXmlElement = true;

        deliveryInfoMap = new Map<String, Object>();

        while(isSafeToGetNextXmlElement) {

            // Start at the beginning of the book and make sure that it is a book
            if (reader.getEventType() == XmlTag.START_ELEMENT) {

                previousElement = currentElement;
                currentElement = reader.getLocalName();

                System.debug('currentElement: ' + currentElement);

                if(currentElement == 'ITEM_ID') {
                    sku = '';

                    for (integer i = 0; i < reader.getAttributeCount(); i++) {
                        if (reader.getAttributeLocalName(i) == 'Value') {
                            //Check if this attribute matches
                            sku = reader.getAttributeValueAt(i);
                        }
                    }

                    System.debug('sku: ' + sku);

                    if(deliveryInfoMap.containsKey(sku)) {
                        deliveryInfoList = (List<Object>)deliveryInfoMap.get(sku);
                    }
                    else {
                        deliveryInfoList = new List<Object>();
                    }

                }

                if(currentElement == 'SCHEDULE') {
                    info = new ProductDeliveryInfo();
                }

                if(currentElement == 'OFFERS_LIST') {
                    isOfferList = true;
                }

            }

            if (reader.getEventType() == XmlTag.CHARACTERS) {

                System.debug('inside chars event for: ' + currentElement);

                System.debug(reader.getText());

                if(currentElement == 'SCHEDULE_NBR') {
                    info.scheduleNumber = reader.getText();
                }
                if(currentElement == 'SCHEDULED_ARRIVAL_DATE') {
                    info.schedArrivalDate = reader.getText();
                }
                if(currentElement == 'PLANNED_SHIP_DATE') {
                    info.planShipDate = reader.getText();
                }
                if(currentElement == 'OFFER' && !isOfferList) {
                    info.offer = reader.getText();
                }
                if(currentElement == 'WAREHOUSE') {
                    info.warehouse = reader.getText();
                }
                if(currentElement == 'QTY') {
                    Decimal temp = Decimal.valueOf(reader.getText());
                    info.qty = temp;
                }
            }

            if(reader.getEventType() == XmlTag.END_ELEMENT) {
                currentElement = reader.getLocalName();

                if(currentElement == 'SCHEDULE') {
                    deliveryInfoList.add(info);
                }
                if(currentElement == 'ORDER_LINE_ITEM') {
                    deliveryInfoMap.put(sku, deliveryInfoList);
                }
                if(currentElement == 'OFFERS_LIST') {
                    isOfferList = false;
                }

            }

            // Always use hasNext() before calling next() to confirm
            // that we have not reached the end of the stream
            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }

        return deliveryInfoMap;

    }

    public static Map<String, Object> parse() {

        XmlStreamReader reader = new XmlStreamReader(orderData);
        Map<String, Object> deliveryInfoMap = parseDocument(reader);

        System.debug('deliveryInfoMap:');
        System.debug(deliveryInfoMap);

        return deliveryInfoMap;

    }

    class ProductDeliveryInfo {

        public String scheduleNumber {get; set;}
        public String warehouse {get; set;}
        public String schedArrivalDate {get; set;}
        public String planShipDate {get; set;}
        public String offer {get; set;}
        public Decimal qty {get; set;}
    }

    public static final String orderData = '' + 
    '<inquiry>' + 
	'<CUSTOMER_ORDER>' + 
		'<Bill_TO Value="1254889"/>' + 
		'<ORDER_TYPE_ID Value="INQUIRY"/>' + 
		'<CUSTOMER_ORG_ID Value="NOT_USED"/>' + 
		'<CUSTOMER_ORG_NAME Value="NOT_USED"/>' + 
		'<ORDER_POINT_ID Value="NOT_USED"/>' + 
		'<SELLING_ORG_ID Value="NOT_USED"/>' + 
		'<ORDER_LINE_ITEMS>' + 
			'<!--this section is repeated for each inquiry line-->' + 
			'<ORDER_LINE_ITEM>' + 
				'<LINE_NBR>001</LINE_NBR>' + 
				'<ITEM_ID Value="25204"/>' + 
				'<ORDERED_QTY Value="8"/>' + 
				'<OFFERS_LIST>' + 
					'<OFFER>REPLENISHEMENT</OFFER>' + 
					'<OFFER>EXPRESS</OFFER>' + 
				'</OFFERS_LIST>' + 
				'<REQUESTED_DELIVERY_DATE Value="06/25/2019"/>' + 
				'<SHIP_TO_ID Value="1357446"/>' + 
				'<PROMISED_SCHEDULES>' + 
					'<!--this section is repeated for each response of the availability check for the inquiry line-->' + 
					'<SCHEDULE>' + 
						'<SCHEDULE_NBR>01</SCHEDULE_NBR>' + 
						'<SCHEDULED_ARRIVAL_DATE>06/25/2019</SCHEDULED_ARRIVAL_DATE>' + 
						'<PLANNED_SHIP_DATE>06/24/2019</PLANNED_SHIP_DATE>' + 
						'<QTY>8</QTY>' + 
						'<OFFER>EXPRESS</OFFER>' + 
						'<WAREHOUSE>U71</WAREHOUSE>' + 
					'</SCHEDULE>' + 
					'<SCHEDULE>' + 
						'<SCHEDULE_NBR>02</SCHEDULE_NBR>' + 
						'<SCHEDULED_ARRIVAL_DATE>06/26/2019</SCHEDULED_ARRIVAL_DATE>' + 
						'<PLANNED_SHIP_DATE>06/23/2019</PLANNED_SHIP_DATE>' + 
						'<QTY>8</QTY>' + 
						'<OFFER>REPLENISHEMENT</OFFER>' + 
						'<WAREHOUSE>U61</WAREHOUSE>' + 
					'</SCHEDULE>' + 
				'</PROMISED_SCHEDULES>' + 
			'</ORDER_LINE_ITEM>' + 
		'</ORDER_LINE_ITEMS>' + 
	'</CUSTOMER_ORDER>' + 
'</inquiry>'
    ;
    
}