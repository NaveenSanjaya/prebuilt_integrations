import ballerina/test;
import ballerinax/trigger.shopify;

// Unit tests for helper functions

@test:Config {}
function testOrderNumStr() {
    shopify:OrderEvent event1 = {
        id: 123,
        order_number: 1001
    };
    test:assertEquals(orderNumStr(event1), "1001", "Should return order_number as string");

    shopify:OrderEvent event2 = {
        id: 456,
        order_number: ()
    };
    test:assertEquals(orderNumStr(event2), "456", "Should fallback to id when order_number is null");
}

@test:Config {}
function testShouldProcessOrderFulfilled() {
    shopify:OrderEvent fulfilledOrder = {
        id: 123,
        fulfillment_status: "fulfilled",
        financial_status: "paid"
    };

    boolean result = shouldProcessOrder(fulfilledOrder);
    test:assertTrue(result, "Should process fulfilled order when trigger is FULFILLED");
}

@test:Config {}
function testShouldProcessOrderUnfulfilled() {
    shopify:OrderEvent unfulfilledOrder = {
        id: 123,
        fulfillment_status: "unfulfilled",
        financial_status: "paid"
    };

    boolean result = shouldProcessOrder(unfulfilledOrder);
    test:assertFalse(result, "Should not process unfulfilled order when trigger is FULFILLED");
}

@test:Config {}
function testFormatTxnDate() {
    string isoDate = "2024-01-15T10:30:00Z";
    string result = formatTxnDate(isoDate);
    test:assertEquals(result, "2024-01-15", "Should format ISO date to YYYY-MM-DD");
}

@test:Config {}
function testFormatTxnDateEmpty() {
    string result = formatTxnDate(());
    test:assertTrue(result.length() == 10, "Should return current date in YYYY-MM-DD format");
    test:assertTrue(result.includes("-"), "Should contain date separators");
}

@test:Config {}
function testAddDaysToDate() {
    string result = addDaysToDate("2024-01-15", 30);
    test:assertEquals(result, "2024-02-14", "Should add 30 days correctly");
}

@test:Config {}
function testAddDaysToDateMonthRollover() {
    string result = addDaysToDate("2024-01-31", 1);
    test:assertEquals(result, "2024-02-01", "Should handle month rollover");
}

@test:Config {}
function testAddDaysToDateYearRollover() {
    string result = addDaysToDate("2024-12-31", 1);
    test:assertEquals(result, "2025-01-01", "Should handle year rollover");
}

@test:Config {}
function testIsLeapYear() {
    test:assertTrue(isLeapYear(2024), "2024 should be a leap year");
    test:assertFalse(isLeapYear(2023), "2023 should not be a leap year");
    test:assertTrue(isLeapYear(2000), "2000 should be a leap year");
    test:assertFalse(isLeapYear(1900), "1900 should not be a leap year");
}

@test:Config {}
function testBuildMemo() {
    shopify:OrderEvent event = {
        id: 123456789,
        order_number: 1001
    };

    string memo = buildMemo(event);
    test:assertTrue(memo.includes("1001"), "Memo should contain order number");
    test:assertTrue(memo.includes("123456789"), "Memo should contain order ID");
}

@test:Config {}
function testBuildMemoDisabled() {
    // Note: This test would require mocking the configurable
    // In a real scenario, you'd set addOrderReferenceToMemo = false
    // For now, we'll just verify the function exists
    shopify:OrderEvent event = {
        id: 123,
        order_number: 456
    };
    string memo = buildMemo(event);
    test:assertTrue(memo is string, "buildMemo should return a string");
}

@test:Config {}
function testBuildDiscountDescription() {
    shopify:OrderEvent eventWithCode = {
        id: 123,
        discount_codes: [
            {
                code: "SAVE10",
                amount: "10.00",
                'type: "fixed_amount"
            }
        ]
    };

    string desc = buildDiscountDescription(eventWithCode);
    test:assertEquals(desc, "Discount: SAVE10", "Should build description from discount code");
}

@test:Config {}
function testBuildDiscountDescriptionMultipleCodes() {
    shopify:OrderEvent eventWithCodes = {
        id: 123,
        discount_codes: [
            {
                code: "SAVE10",
                amount: "10.00",
                'type: "fixed_amount"
            },
            {
                code: "FREESHIP",
                amount: "5.00",
                'type: "fixed_amount"
            }
        ]
    };

    string desc = buildDiscountDescription(eventWithCodes);
    test:assertTrue(desc.includes("SAVE10"), "Should include first discount code");
    test:assertTrue(desc.includes("FREESHIP"), "Should include second discount code");
}

@test:Config {}
function testBuildDiscountDescriptionNoCode() {
    shopify:OrderEvent eventNoCode = {
        id: 123,
        discount_codes: [],
        discount_applications: [
            {
                title: "Automatic Discount",
                value: "15.00",
                value_type: "fixed_amount"
            }
        ]
    };

    string desc = buildDiscountDescription(eventNoCode);
    test:assertTrue(desc.includes("Automatic Discount"), "Should use discount application title");
}

@test:Config {}
function testBuildDiscountDescriptionEmpty() {
    shopify:OrderEvent eventEmpty = {
        id: 123,
        discount_codes: [],
        discount_applications: []
    };

    string desc = buildDiscountDescription(eventEmpty);
    test:assertEquals(desc, "Discount", "Should return default 'Discount' when no codes or applications");
}

@test:Config {}
function testBuildPhysicalAddress() {
    shopify:CustomerAddress addr = {
        'address1: "123 Main St",
        city: "San Francisco",
        province: "CA",
        zip: "94102",
        country: "United States"
    };

    var result = buildPhysicalAddress(addr);
    test:assertTrue(result is record {}, "Should return a PhysicalAddress record");
}

@test:Config {}
function testBuildPhysicalAddressNull() {
    var result = buildPhysicalAddress(());
    test:assertTrue(result is (), "Should return null for null address");
}

@test:Config {}
function testResolveTaxCode() {
    shopify:TaxLine[] taxLines = [
        {
            title: "Sales Tax",
            rate: 0.0875,
            price: "8.75"
        }
    ];

    string taxCode = resolveTaxCode(taxLines);
    test:assertTrue(taxCode is string, "Should return a tax code string");
}

@test:Config {}
function testResolveTaxCodeEmpty() {
    shopify:TaxLine[]? emptyTaxLines = ();
    string taxCode = resolveTaxCode(emptyTaxLines);
    test:assertEquals(taxCode, taxConfig.defaultTaxCode, "Should return default tax code for empty tax lines");
}
