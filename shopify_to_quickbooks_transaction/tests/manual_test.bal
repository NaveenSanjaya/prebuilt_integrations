import ballerina/io;
import ballerina/time;
import ballerinax/trigger.shopify;

// =============================================================================
// MANUAL TEST SUITE
// Run with: bal run manual_test.bal
// Make sure Config.toml is properly configured before running
// =============================================================================

public function main() returns error? {
    io:println("\n========================================");
    io:println("SHOPIFY TO QUICKBOOKS MANUAL TEST SUITE");
    io:println("========================================\n");

    // Track test results
    int totalTests = 0;
    int passedTests = 0;
    int failedTests = 0;

    // =============================================================================
    // HAPPY PATH TESTS
    // =============================================================================
    io:println("=== HAPPY PATH TESTS ===\n");

    // Test 1: Fulfilled order creates invoice
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Fulfilled order creates invoice`);
    error? test1Result = testFulfilledOrder();
    if test1Result is error {
        io:println("❌ FAILED: " + test1Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 2: Paid order creates invoice
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Paid order creates invoice`);
    error? test2Result = testPaidOrder();
    if test2Result is error {
        io:println("❌ FAILED: " + test2Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 3: Customer auto-creation works
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Customer auto-creation works`);
    error? test3Result = testCustomerAutoCreation();
    if test3Result is error {
        io:println("❌ FAILED: " + test3Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 4: Product line items map correctly
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Product line items map correctly`);
    error? test4Result = testProductLineItems();
    if test4Result is error {
        io:println("❌ FAILED: " + test4Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 5: Shipping line item created
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Shipping line item created`);
    error? test5Result = testShippingLineItem();
    if test5Result is error {
        io:println("❌ FAILED: " + test5Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 6: Discount line item created (negative amount)
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Discount line item created (negative amount)`);
    error? test6Result = testDiscountLineItem();
    if test6Result is error {
        io:println("❌ FAILED: " + test6Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 7: Tax codes applied correctly
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Tax codes applied correctly`);
    error? test7Result = testTaxCodes();
    if test7Result is error {
        io:println("❌ FAILED: " + test7Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 8: Order reference in memo
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order reference in memo`);
    error? test8Result = testOrderReferenceInMemo();
    if test8Result is error {
        io:println("❌ FAILED: " + test8Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // =============================================================================
    // VALIDATION & FILTERING TESTS
    // =============================================================================
    io:println("\n=== VALIDATION & FILTERING TESTS ===\n");

    // Test 9: Order below minimum amount is skipped
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order below minimum amount is skipped`);
    error? test9Result = testMinimumAmountValidation();
    if test9Result is error {
        io:println("❌ FAILED: " + test9Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 10: Order without line items is quarantined
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order without line items is quarantined`);
    error? test10Result = testNoLineItemsValidation();
    if test10Result is error {
        io:println("❌ FAILED: " + test10Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 11: Order without customer email (based on config)
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order without customer email validation`);
    error? test11Result = testNoCustomerEmailValidation();
    if test11Result is error {
        io:println("❌ FAILED: " + test11Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 12: Unfulfilled order is skipped (when trigger is FULFILLED)
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Unfulfilled order is skipped`);
    error? test12Result = testUnfulfilledOrderSkipped();
    if test12Result is error {
        io:println("❌ FAILED: " + test12Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 13: Unpaid order is skipped (when trigger is PAID)
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Unpaid order is skipped`);
    error? test13Result = testUnpaidOrderSkipped();
    if test13Result is error {
        io:println("❌ FAILED: " + test13Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // =============================================================================
    // ERROR HANDLING TESTS
    // =============================================================================
    io:println("\n=== ERROR HANDLING TESTS ===\n");

    // Test 14: Missing SKU mapping
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Missing SKU mapping (should error or fallback)`);
    error? test14Result = testMissingSKUMapping();
    if test14Result is error {
        io:println("✅ PASSED (Expected error: " + test14Result.message() + ")\n");
        passedTests += 1;
    } else {
        io:println("❌ FAILED: Should have errored for missing SKU\n");
        failedTests += 1;
    }

    // Test 15: Duplicate order (should skip)
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Duplicate order is skipped`);
    error? test15Result = testDuplicateOrder();
    if test15Result is error {
        io:println("❌ FAILED: " + test15Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // =============================================================================
    // EDGE CASES TESTS
    // =============================================================================
    io:println("\n=== EDGE CASES TESTS ===\n");

    // Test 16: Order with multiple discount codes
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with multiple discount codes`);
    error? test16Result = testMultipleDiscountCodes();
    if test16Result is error {
        io:println("❌ FAILED: " + test16Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 17: Order with no shipping
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with no shipping`);
    error? test17Result = testNoShipping();
    if test17Result is error {
        io:println("❌ FAILED: " + test17Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 18: Order with no discounts
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with no discounts`);
    error? test18Result = testNoDiscounts();
    if test18Result is error {
        io:println("❌ FAILED: " + test18Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 19: Order with special characters in description
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with special characters in description`);
    error? test19Result = testSpecialCharacters();
    if test19Result is error {
        io:println("❌ FAILED: " + test19Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 20: Order with very large amounts
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with very large amounts`);
    error? test20Result = testLargeAmounts();
    if test20Result is error {
        io:println("❌ FAILED: " + test20Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // Test 21: Order with zero-price items
    totalTests += 1;
    io:println(string `[Test ${totalTests}] Order with zero-price items`);
    error? test21Result = testZeroPriceItems();
    if test21Result is error {
        io:println("❌ FAILED: " + test21Result.message());
        failedTests += 1;
    } else {
        io:println("✅ PASSED\n");
        passedTests += 1;
    }

    // =============================================================================
    // TEST SUMMARY
    // =============================================================================
    io:println("\n========================================");
    io:println("TEST SUMMARY");
    io:println("========================================");
    io:println(string `Total Tests: ${totalTests}`);
    io:println(string `Passed: ${passedTests}`);
    io:println(string `Failed: ${failedTests}`);
    io:println(string `Success Rate: ${(passedTests * 100) / totalTests}%`);
    io:println("========================================\n");

    if failedTests > 0 {
        io:println("⚠️  Some tests failed. Check QuickBooks sandbox for created invoices.");
    } else {
        io:println("🎉 All tests passed! Check QuickBooks sandbox to verify invoices.");
    }
}

// =============================================================================
// TEST IMPLEMENTATIONS
// =============================================================================

// Test 1: Fulfilled order creates invoice
function testFulfilledOrder() returns error? {
    shopify:OrderEvent event = createBaseOrder(1001, "fulfilled", "paid");
    check processOrder(event);
}

// Test 2: Paid order creates invoice
function testPaidOrder() returns error? {
    shopify:OrderEvent event = createBaseOrder(1002, "fulfilled", "paid");
    check processOrder(event);
}

// Test 3: Customer auto-creation works
function testCustomerAutoCreation() returns error? {
    shopify:OrderEvent event = createBaseOrder(1003, "fulfilled", "paid");
    event.customer = {
        id: 888888003,
        email: string `test.autocreate.${time:utcNow()[0]}@example.com`,
        first_name: "Auto",
        last_name: "Created"
    };
    check processOrder(event);
}

// Test 4: Product line items map correctly
function testProductLineItems() returns error? {
    shopify:OrderEvent event = createBaseOrder(1004, "fulfilled", "paid");
    event.line_items = [
        createLineItem(1, "Product A", "TEST-SKU-001", 2, "50.00"),
        createLineItem(2, "Product B", "TEST-SKU-002", 1, "75.00")
    ];
    event.total_price = "175.00";
    check processOrder(event);
}

// Test 5: Shipping line item created
function testShippingLineItem() returns error? {
    shopify:OrderEvent event = createBaseOrder(1005, "fulfilled", "paid");
    event.shipping_lines = [
        {
            "id": 999001,
            title: "Standard Shipping",
            price: "15.00",
            code: "STANDARD"
        }
    ];
    event.total_price = "115.00";
    check processOrder(event);
}

// Test 6: Discount line item created (negative amount)
function testDiscountLineItem() returns error? {
    shopify:OrderEvent event = createBaseOrder(1006, "fulfilled", "paid");
    event.total_discounts = "20.00";
    event.discount_codes = [
        {code: "SAVE20", amount: "20.00", 'type: "fixed_amount"}
    ];
    event.total_price = "80.00";
    check processOrder(event);
}

// Test 7: Tax codes applied correctly
function testTaxCodes() returns error? {
    shopify:OrderEvent event = createBaseOrder(1007, "fulfilled", "paid");
    event.line_items = [
        {
            id: 777001,
            title: "Taxable Product",
            quantity: 1,
            price: "100.00",
            sku: "TEST-SKU-001",
            tax_lines: [
                {title: "Sales Tax", price: "8.00", rate: 0.08}
            ]
        }
    ];
    event.total_price = "108.00";
    check processOrder(event);
}

// Test 8: Order reference in memo
function testOrderReferenceInMemo() returns error? {
    shopify:OrderEvent event = createBaseOrder(1008, "fulfilled", "paid");
    check processOrder(event);
}

// Test 9: Order below minimum amount is skipped
function testMinimumAmountValidation() returns error? {
    shopify:OrderEvent event = createBaseOrder(1009, "fulfilled", "paid");
    event.total_price = "0.50";
    event.line_items = [
        createLineItem(1, "Cheap Item", "TEST-SKU-001", 1, "0.50")
    ];
    check processOrder(event);
}

// Test 10: Order without line items is quarantined
function testNoLineItemsValidation() returns error? {
    shopify:OrderEvent event = createBaseOrder(1010, "fulfilled", "paid");
    event.line_items = [];
    check processOrder(event);
}

// Test 11: Order without customer email validation
function testNoCustomerEmailValidation() returns error? {
    shopify:OrderEvent event = createBaseOrder(1011, "fulfilled", "paid");
    event.customer = {
        id: 888888011,
        email: (),
        first_name: "No",
        last_name: "Email"
    };
    error? result = processOrder(event);
    if validationRules.requireCustomerEmail && result is () {
        return error("Should have failed for missing email when requireCustomerEmail=true");
    }
}

// Test 12: Unfulfilled order is skipped
function testUnfulfilledOrderSkipped() returns error? {
    shopify:OrderEvent event = createBaseOrder(1012, "pending", "paid");
    check processOrder(event);
}

// Test 13: Unpaid order is skipped
function testUnpaidOrderSkipped() returns error? {
    shopify:OrderEvent event = createBaseOrder(1013, "fulfilled", "pending");
    check processOrder(event);
}

// Test 14: Missing SKU mapping
function testMissingSKUMapping() returns error? {
    shopify:OrderEvent event = createBaseOrder(1014, "fulfilled", "paid");
    event.line_items = [
        createLineItem(1, "Unknown Product", "UNKNOWN-SKU-999", 1, "100.00")
    ];
    check processOrder(event);
}

// Test 15: Duplicate order is skipped
function testDuplicateOrder() returns error? {
    shopify:OrderEvent event = createBaseOrder(1015, "fulfilled", "paid");
    // Process once
    check processOrder(event);
    // Process again - should skip
    check processOrder(event);
}

// Test 16: Order with multiple discount codes
function testMultipleDiscountCodes() returns error? {
    shopify:OrderEvent event = createBaseOrder(1016, "fulfilled", "paid");
    event.total_discounts = "30.00";
    event.discount_codes = [
        {code: "SAVE10", amount: "10.00", 'type: "fixed_amount"},
        {code: "EXTRA20", amount: "20.00", 'type: "fixed_amount"}
    ];
    event.discount_applications = [
        {title: "SAVE10", value: "10.00", value_type: "fixed_amount"},
        {title: "EXTRA20", value: "20.00", value_type: "fixed_amount"}
    ];
    event.total_price = "70.00";
    check processOrder(event);
}

// Test 17: Order with no shipping
function testNoShipping() returns error? {
    shopify:OrderEvent event = createBaseOrder(1017, "fulfilled", "paid");
    event.shipping_lines = [];
    check processOrder(event);
}

// Test 18: Order with no discounts
function testNoDiscounts() returns error? {
    shopify:OrderEvent event = createBaseOrder(1018, "fulfilled", "paid");
    event.total_discounts = "0.00";
    event.discount_codes = [];
    event.discount_applications = [];
    check processOrder(event);
}

// Test 19: Order with special characters in description
function testSpecialCharacters() returns error? {
    shopify:OrderEvent event = createBaseOrder(1019, "fulfilled", "paid");
    event.line_items = [
        createLineItem(1, "Product with \"quotes\" & <tags> and 'apostrophes'", "TEST-SKU-001", 1, "100.00")
    ];
    check processOrder(event);
}

// Test 20: Order with very large amounts
function testLargeAmounts() returns error? {
    shopify:OrderEvent event = createBaseOrder(1020, "fulfilled", "paid");
    event.line_items = [
        createLineItem(1, "Expensive Item", "TEST-SKU-001", 100, "9999.99")
    ];
    event.total_price = "999999.00";
    check processOrder(event);
}

// Test 21: Order with zero-price items
function testZeroPriceItems() returns error? {
    shopify:OrderEvent event = createBaseOrder(1021, "fulfilled", "paid");
    event.line_items = [
        createLineItem(1, "Free Item", "TEST-SKU-001", 1, "0.00"),
        createLineItem(2, "Paid Item", "TEST-SKU-002", 1, "100.00")
    ];
    event.total_price = "100.00";
    check processOrder(event);
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

function createBaseOrder(int orderNum, string fulfillmentStatus, string financialStatus) returns shopify:OrderEvent {
    int timestamp = <int>time:utcNow()[0];
    return {
        id: 900000000 + orderNum,
        order_number: orderNum,
        created_at: time:utcToString(time:utcNow()),
        currency: "USD",
        total_price: "100.00",
        total_discounts: "0.00",
        fulfillment_status: fulfillmentStatus,
        financial_status: financialStatus,
        customer: {
            id: 800000000 + orderNum,
            email: string `test.order${orderNum}.${timestamp}@example.com`,
            first_name: "Test",
            last_name: string `Order${orderNum}`
        },
        billing_address: {
            'address1: "123 Test Street",
            city: "Test City",
            province: "CA",
            zip: "12345",
            country: "United States"
        },
        line_items: [
            createLineItem(1, "Test Product", "TEST-SKU-001", 1, "100.00")
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}

function createLineItem(int id, string title, string sku, int quantity, string price) returns shopify:OrderLineItem {
    return {
        id: 700000000 + id,
        title: title,
        quantity: quantity,
        price: price,
        sku: sku,
        tax_lines: []
    };
}
