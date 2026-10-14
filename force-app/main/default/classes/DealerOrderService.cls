public with sharing class DealerOrderService {

    @AuraEnabled(cacheable=true)
    public static List<Dealer_Order__c> getOrdersForDealer(
        Id dealerId
    ) {
        if (dealerId == null) {
            throw new AuraHandledException(
                'Please select a dealer.'
            );
        }

        return [
            SELECT Id,
                   Name,
                   Dealer__c,
                   Dealer__r.Name,
                   Order_Status__c,
                   Order_Date__c,
                   Requested_Delivery_Date__c,
                   Discount_Percentage__c,
                   Subtotal__c,
                   Final_Amount__c,
                   CreatedDate
            FROM Dealer_Order__c
            WHERE Dealer__c = :dealerId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static Id createDraftOrder(
        Id dealerId,
        Date requestedDeliveryDate
    ) {
        if (dealerId == null) {
            throw new AuraHandledException(
                'Please select a dealer.'
            );
        }

        List<Account> dealers = [
            SELECT Id, Dealer_Status__c
            FROM Account
            WHERE Id = :dealerId
            WITH USER_MODE
            LIMIT 1
        ];

        if (dealers.isEmpty()) {
            throw new AuraHandledException(
                'Dealer not found or access denied.'
            );
        }

        if (dealers[0].Dealer_Status__c != 'Active') {
            throw new AuraHandledException(
                'Only active dealers can place orders.'
            );
        }

        Dealer_Order__c orderRecord =
            new Dealer_Order__c(
                Dealer__c = dealerId,
                Order_Status__c = 'Draft',
                Order_Date__c = Date.today(),
                Requested_Delivery_Date__c =
                    requestedDeliveryDate,
                Discount_Percentage__c = 0,
                Subtotal__c = 0,
                Final_Amount__c = 0
            );

        Database.SaveResult result =
            Database.insert(
                orderRecord,
                AccessLevel.USER_MODE
            );

        if (!result.isSuccess()) {
            throw new AuraHandledException(
                'Unable to create the order. Check your access and required fields.'
            );
        }

        return orderRecord.Id;
    }
}