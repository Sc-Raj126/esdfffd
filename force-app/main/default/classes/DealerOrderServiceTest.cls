
@IsTest
private class DealerOrderServiceTest {

    @TestSetup
    static void createTestData() {
        String orgToken =
            UserInfo.getOrganizationId().substring(0, 8);

        insert new List<Account>{
            new Account(
                Name = 'Active Dealer Test',
                Dealer_Code__c = 'DHS' + orgToken + 'A',
                Dealer_Status__c = 'Active',
                Dealer_Tier__c = 'Standard'
            ),
            new Account(
                Name = 'Inactive Dealer Test',
                Dealer_Code__c = 'DHS' + orgToken + 'I',
                Dealer_Status__c = 'Inactive',
                Dealer_Tier__c = 'Standard'
            )
        };
    }

    private static Account getDealer(String suffix) {
        String orgToken =
            UserInfo.getOrganizationId().substring(0, 8);
        String dealerCode = 'DHS' + orgToken + suffix;

        return [
            SELECT Id, Dealer_Status__c
            FROM Account
            WHERE Dealer_Code__c = :dealerCode
            LIMIT 1
        ];
    }

    @IsTest
    static void createDraftOrderForActiveDealer() {
        Account dealer = getDealer('A');
        Date deliveryDate = Date.today().addDays(7);

        Test.startTest();
        Id orderId = DealerOrderService.createDraftOrder(
            dealer.Id,
            deliveryDate
        );
        Test.stopTest();

        Dealer_Order__c createdOrder = [
            SELECT Id, Dealer__c, Order_Status__c,
                   Order_Date__c, Requested_Delivery_Date__c,
                   Discount_Percentage__c,
                   Subtotal__c, Final_Amount__c
            FROM Dealer_Order__c
            WHERE Id = :orderId
        ];

        System.assertEquals(
            dealer.Id, createdOrder.Dealer__c,
            'The order should belong to the selected dealer.'
        );
        System.assertEquals(
            'Draft', createdOrder.Order_Status__c
        );
        System.assertEquals(
            Date.today(), createdOrder.Order_Date__c
        );
        System.assertEquals(
            deliveryDate,
            createdOrder.Requested_Delivery_Date__c
        );
        System.assertEquals(
            0, createdOrder.Discount_Percentage__c
        );
        System.assertEquals(0, createdOrder.Subtotal__c);
        System.assertEquals(0, createdOrder.Final_Amount__c);
    }

    @IsTest
    static void getOrdersForDealerReturnsMatchingOrders() {
        Account dealer = getDealer('A');

        Dealer_Order__c existingOrder =
            new Dealer_Order__c(
                Dealer__c = dealer.Id,
                Order_Status__c = 'Draft',
                Order_Date__c = Date.today(),
                Discount_Percentage__c = 0,
                Subtotal__c = 100,
                Final_Amount__c = 100
            );
        insert existingOrder;

        Test.startTest();
        List<Dealer_Order__c> results =
            DealerOrderService.getOrdersForDealer(dealer.Id);
        Test.stopTest();

        System.assertEquals(
            1, results.size(),
            'The dealer should have one matching order.'
        );
        System.assertEquals(
            existingOrder.Id, results[0].Id
        );
    }

    @IsTest
    static void inactiveDealerCannotCreateOrder() {
        Account dealer = getDealer('I');
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            DealerOrderService.createDraftOrder(
                dealer.Id,
                Date.today().addDays(7)
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'An inactive dealer must not be allowed to create an order.'
        );
    }

    @IsTest
    static void nullDealerIsRejected() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            DealerOrderService.getOrdersForDealer(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'A null dealer ID must be rejected.'
        );
    }
}
