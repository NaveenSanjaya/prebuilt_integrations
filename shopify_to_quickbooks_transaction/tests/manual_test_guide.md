# Manual Testing Guide

This guide explains how to manually test the Shopify-to-QuickBooks integration.

## Prerequisites

1. **QuickBooks Sandbox Account**
   - Sign up at https://developer.intuit.com/
   - Create a sandbox company
   - Get OAuth2 credentials (Client ID, Client Secret, Refresh Token)

2. **Shopify Development Store**
   - Create a development store at https://partners.shopify.com/
   - Generate API credentials
   - Get the API Secret Key for webhook validation

3. **Test Configuration**
   - Copy `Config.toml.example` to `tests/Config.toml`
   - Fill in your test credentials

## Test Configuration File

Create `tests/Config.toml` with:

```toml
[shopifyConfig]
apiSecretKey = "your-shopify-api-secret-key"

[quickbooksConfig]
clientId = "your-qb-client-id"
clientSecret = "your-qb-client-secret"
refreshToken = "your-qb-refresh-token"
realmId = "your-qb-realm-id"
serviceUrl = "https://sandbox-quickbooks.api.intuit.com"

transactionType = "SALES_RECEIPT"
orderStatusTrigger = "FULFILLED"
createCustomerIfNotFound = true

# Test product mapping - map your test SKUs to QB item IDs
productMappingJson = """{"TEST-SKU-001": "1", "TEST-SKU-002": "2", "TEST-SKU-003": "3"}"""

[taxConfig]
defaultTaxCode = "TAX"
taxMappingJson = """{"Sales Tax": "TAX"}"""

[accountConfig]
productSalesAccountId = "79"
shippingAccountId = "79"
discountAccountId = "79"

mapShippingAsSeparateLine = true
shippingItemName = "Shipping"
discountItemName = "Discount"
includeDiscountLineItems = true
addOrderReferenceToMemo = true

[validationRules]
requireCustomerEmail = true
requireLineItems = true
minimumOrderAmount = 0.0
```

## Running Unit Tests

Unit tests don't require external API access:

```bash
bal test --tests unit_tests.bal
```

These tests verify:
- Date formatting and arithmetic
- Order status filtering logic
- Discount description building
- Helper function behavior

## Running Integration Tests

Integration tests require valid credentials and may make actual API calls:

1. **Enable integration tests** by setting `enable: true` in test annotations
2. **Set up test data in QuickBooks**:
   - Create test items with IDs matching your productMappingJson
   - Create a "Shipping" item
   - Create a "Discount" item
   - Note the income account IDs

3. **Run tests**:
```bash
bal test --tests integration_tests.bal
```

## Manual End-to-End Testing

### Method 1: Using Shopify Webhooks (Recommended)

1. **Start the integration**:
   ```bash
   bal run
   ```

2. **Expose your local server** (using ngrok or similar):
   ```bash
   ngrok http 8090
   ```

3. **Configure Shopify webhook**:
   - Go to Settings → Notifications → Webhooks
   - Add webhook: `https://your-ngrok-url.ngrok.io/`
   - Select events: `Order fulfillment` and `Order payment`
   - Use your API Secret Key

4. **Create a test order in Shopify**:
   - Add products with SKUs matching your productMappingJson
   - Use a test customer email
   - Complete the order and mark as fulfilled/paid

5. **Verify in QuickBooks**:
   - Check that an invoice was created
   - Verify customer, line items, amounts match

### Method 2: Using cURL to Simulate Webhooks

1. **Start the integration**:
   ```bash
   bal run
   ```

2. **Send a test webhook** (you'll need to generate a valid HMAC signature):
   ```bash
   curl -X POST http://localhost:8090/ \
     -H "Content-Type: application/json" \
     -H "X-Shopify-Topic: orders/fulfilled" \
     -H "X-Shopify-Hmac-Sha256: YOUR_HMAC_SIGNATURE" \
     -H "X-Shopify-Shop-Domain: your-shop.myshopify.com" \
     -d @test_order.json
   ```

3. **Check logs** for processing results

### Method 3: Direct Function Testing

Create a test file `manual_test.bal`:

```ballerina
import ballerina/io;
import ballerinax/trigger.shopify;

public function main() returns error? {
    // Create a test order event
    shopify:OrderEvent testEvent = {
        id: 999999999,
        order_number: 9999,
        created_at: "2024-01-15T10:00:00Z",
        currency: "USD",
        total_price: "100.00",
        total_discounts: "0.00",
        fulfillment_status: "fulfilled",
        financial_status: "paid",
        customer: {
            id: 888888888,
            email: "manual.test@example.com",
            first_name: "Manual",
            last_name: "Test"
        },
        billing_address: {
            'address1: "123 Test St",
            city: "Test City",
            province: "CA",
            zip: "12345",
            country: "United States"
        },
        line_items: [
            {
                id: 777777777,
                title: "Test Product",
                quantity: 1,
                price: "100.00",
                sku: "TEST-SKU-001",
                tax_lines: []
            }
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };

    // Process the order
    io:println("Processing test order...");
    error? result = processOrder(testEvent);
    
    if result is error {
        io:println("Error: " + result.message());
    } else {
        io:println("Success! Check QuickBooks for the invoice.");
    }
}
```

Run with:
```bash
bal run manual_test.bal
```

## Test Scenarios to Cover

### ✅ Happy Path
- [ ] Fulfilled order creates invoice
- [ ] Paid order creates invoice
- [ ] Customer auto-creation works
- [ ] Product line items map correctly
- [ ] Shipping line item created
- [ ] Discount line item created (negative amount)
- [ ] Tax codes applied correctly
- [ ] Order reference in memo

### ✅ Validation & Filtering
- [ ] Order below minimum amount is skipped
- [ ] Order without line items is quarantined
- [ ] Order without customer email (based on config)
- [ ] Unfulfilled order is skipped (when trigger is FULFILLED)
- [ ] Unpaid order is skipped (when trigger is PAID)

### ✅ Error Handling
- [ ] Missing SKU mapping (should error or fallback to QB query)
- [ ] Customer not found (should auto-create or error)
- [ ] Duplicate order (should skip)
- [ ] Invalid QuickBooks credentials (should error)
- [ ] Network timeout (should error and quarantine)

### ✅ Edge Cases
- [ ] Order with multiple discount codes
- [ ] Order with no shipping
- [ ] Order with no discounts
- [ ] Order with special characters in description
- [ ] Order with very large amounts
- [ ] Order with zero-price items

## Monitoring Test Results

### Check Logs
Look for these log patterns:
- `[Shopify]` - Incoming webhooks
- `[Skip]` - Filtered orders
- `[QB]` - QuickBooks operations
- `[QUARANTINE]` - Failed orders
- `[Error]` - Errors with details

### Verify in QuickBooks
1. Go to Sales → Invoices
2. Find invoice by order number (in Private Note)
3. Verify:
   - Customer matches
   - Line items match
   - Amounts match
   - Tax applied correctly
   - Shipping/discount lines present

### Check for Duplicates
1. Process the same order twice
2. Second attempt should log: `[Skip] Order #XXX: already synced to QuickBooks (duplicate)`
3. Verify only one invoice exists in QuickBooks

## Troubleshooting

### "No QuickBooks item found for SKU"
- Add the SKU to productMappingJson
- Or create an item in QuickBooks with Name matching the SKU

### "QB customer not found"
- Enable `createCustomerIfNotFound = true`
- Or manually create the customer in QuickBooks

### "Webhook signature validation failed"
- Verify apiSecretKey matches Shopify settings
- Check X-Shopify-Hmac-Sha256 header is present

### "OAuth token expired"
- Refresh your QuickBooks OAuth token
- Update refreshToken in Config.toml

## Performance Testing

For high-volume testing:

1. **Load test with multiple orders**:
   - Send 100+ webhook requests
   - Monitor memory usage
   - Check for rate limiting

2. **Concurrent requests**:
   - Send multiple webhooks simultaneously
   - Verify all are processed correctly
   - Check for race conditions

3. **Large orders**:
   - Test with 50+ line items
   - Test with very long descriptions
   - Verify performance is acceptable

## Cleanup After Testing

1. **Delete test invoices** from QuickBooks sandbox
2. **Delete test customers** (optional)
3. **Clear logs**
4. **Remove test webhooks** from Shopify

---

**Remember**: Always test in sandbox/development environments before deploying to production!
