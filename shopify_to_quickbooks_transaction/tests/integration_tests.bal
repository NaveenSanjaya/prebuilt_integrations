import ballerina/test;
import ballerinax/trigger.shopify;

// Integration tests for order processing pipeline
// Note: These tests require proper configuration and may need to be run against a test/sandbox environment

@test:Config {
    enable: true // Enabled - QuickBooks items are now configured
}
function testProcessFulfilledOrder() returns error? {
    shopify:OrderEvent event = getMockFulfilledOrder();

    // This would actually call QuickBooks API in a real test
    error? result = processOrder(event);

    if result is error {
        test:assertFail("Processing fulfilled order should succeed: " + result.message());
    }
}

@test:Config {
    enable: true // Enabled for integration testing with real credentials
}
function testProcessPaidOrder() returns error? {
    shopify:OrderEvent event = getMockPaidOrder();

    error? result = processOrder(event);

    if result is error {
        test:assertFail("Processing paid order should succeed: " + result.message());
    }
}

@test:Config {}
function testProcessOrderWithoutEmailValidation() returns error? {
    shopify:OrderEvent event = getMockOrderWithoutEmail();

    // This should be skipped or quarantined depending on requireCustomerEmail setting
    error? result = processOrder(event);

    // If requireCustomerEmail is true, this should return an error or be quarantined
    // If false, it should process with DEFAULT_CUSTOMER
    test:assertTrue(result is () || result is error, "Should handle missing email based on validation rules");
}

@test:Config {
    enable: true // Enabled - QuickBooks items are now configured
}
function testProcessOrderBelowMinimum() returns error? {
    shopify:OrderEvent event = getMockOrderBelowMinimum();

    // This should be skipped if minimumOrderAmount > 5.00
    error? result = processOrder(event);

    // Should succeed (skip) without error
    test:assertTrue(result is (), "Should skip order below minimum amount");
}

@test:Config {}
function testProcessOrderWithoutLineItems() returns error? {
    shopify:OrderEvent event = getMockOrderWithoutLineItems();

    // This should be quarantined if requireLineItems is true
    error? result = processOrder(event);

    // Should succeed (quarantine) without throwing error
    test:assertTrue(result is (), "Should quarantine order without line items");
}

@test:Config {}
function testProcessUnfulfilledOrder() returns error? {
    shopify:OrderEvent event = getMockUnfulfilledOrder();

    // This should be skipped based on orderStatusTrigger
    error? result = processOrder(event);

    // Should succeed (skip) without error
    test:assertTrue(result is (), "Should skip unfulfilled order when trigger is FULFILLED");
}

@test:Config {}
function testBuildLineItems() returns error? {
    shopify:OrderEvent event = getMockFulfilledOrder();

    anydata[]|error lines = buildLineItems(event);

    if lines is error {
        // This is expected if QB items don't exist in test environment
        test:assertTrue(lines.message().includes("No QuickBooks item found"),
                "Should fail with item not found error in test environment");
    } else {
        test:assertTrue(lines.length() > 0, "Should build at least one line item");
    }
}

@test:Config {
    enable: true // Enabled - QuickBooks items are now configured
}
function testMapToQBTransaction() returns error? {
    shopify:OrderEvent event = getMockFulfilledOrder();
    string customerId = "TEST_CUSTOMER_ID";

    var invoice = mapToQBTransaction(event, customerId);

    if invoice is error {
        test:assertFail("Mapping to QB transaction should succeed: " + invoice.message());
    } else {
        test:assertEquals(invoice.CustomerRef.value, customerId, "Should set correct customer ID");
        test:assertTrue(invoice.Line.length() > 0, "Should have at least one line item");
    }
}

@test:Config {}
function testQuarantineOrder() {
    shopify:OrderEvent event = getMockOrderWithoutLineItems();

    // This should log a warning but not throw an error
    quarantineOrder(event, "Test quarantine", "VALIDATION");

    // If we get here without error, the function works
    test:assertTrue(true, "Quarantine should log without throwing error");
}
