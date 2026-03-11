# Testing Guide

This directory contains test files for the Shopify-to-QuickBooks integration.

## Test Files

- **`test_data.bal`** - Mock Shopify order events for testing
- **`unit_tests.bal`** - Unit tests for helper functions (no external API calls)
- **`integration_tests.bal`** - Integration tests (require valid credentials)
- **`manual_test_guide.md`** - Comprehensive manual testing guide

## Quick Start

### 1. Run Unit Tests (No Setup Required)

```bash
bal test --tests unit_tests.bal
```

Unit tests verify:
- Date formatting and calculations
- Order status filtering
- Discount description building
- Helper function logic

### 2. Run Integration Tests (Requires Setup)

**Prerequisites:**
- QuickBooks sandbox account with OAuth credentials
- Shopify development store with API secret key
- Test items created in QuickBooks

**Setup:**
1. Create `tests/Config.toml` with your test credentials:

```toml
[shopifyConfig]
apiSecretKey = "your-test-api-secret"

[quickbooksConfig]
clientId = "your-client-id"
clientSecret = "your-client-secret"
refreshToken = "your-refresh-token"
realmId = "your-realm-id"
serviceUrl = "https://sandbox-quickbooks.api.intuit.com"

transactionType = "SALES_RECEIPT"
orderStatusTrigger = "FULFILLED"
createCustomerIfNotFound = true

productMappingJson = """{"TEST-SKU-001": "1", "TEST-SKU-002": "2"}"""

[taxConfig]
defaultTaxCode = "TAX"
taxMappingJson = "{}"

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

2. Enable integration tests by editing `integration_tests.bal`:
   - Change `enable: false` to `enable: true` for tests you want to run

3. Run tests:
```bash
bal test --tests integration_tests.bal
```

### 3. Manual End-to-End Testing

See **`manual_test_guide.md`** for detailed instructions on:
- Testing with real Shopify webhooks
- Simulating webhooks with cURL
- Direct function testing
- Test scenarios to cover
- Troubleshooting common issues

## Test Data

The `test_data.bal` file provides mock order events:

- **`getMockFulfilledOrder()`** - Complete order with all fields
- **`getMockPaidOrder()`** - Paid but unfulfilled order
- **`getMockOrderWithoutEmail()`** - Order missing customer email
- **`getMockOrderBelowMinimum()`** - Order with small amount
- **`getMockOrderWithoutLineItems()`** - Empty order
- **`getMockUnfulfilledOrder()`** - Pending order

Use these in your own tests:

```ballerina
import ballerina/test;

@test:Config {}
function myCustomTest() returns error? {
    var order = getMockFulfilledOrder();
    // Your test logic here
}
```

## What Gets Tested

### Unit Tests ✅
- Order number string conversion
- Order status filtering (fulfilled/paid/completed)
- Date formatting (ISO to YYYY-MM-DD)
- Date arithmetic (adding days, leap years)
- Discount description building
- Memo/note generation
- Tax code resolution
- Address mapping

### Integration Tests 🔧
- Full order processing pipeline
- QuickBooks customer lookup/creation
- Invoice creation in QuickBooks
- Line item mapping
- Validation rules enforcement
- Quarantine system
- Duplicate detection

### Manual Tests 🧪
- Real webhook processing
- End-to-end Shopify → QuickBooks flow
- Error handling and recovery
- Performance under load
- Edge cases and special scenarios

## Running All Tests

```bash
# Run all tests
bal test

# Run specific test file
bal test --tests unit_tests.bal

# Run with coverage
bal test --code-coverage

# Run with verbose output
bal test --debug
```

## Continuous Integration

For CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Unit Tests
  run: bal test --tests unit_tests.bal

- name: Run Integration Tests
  run: bal test --tests integration_tests.bal
  env:
    SHOPIFY_API_SECRET: ${{ secrets.SHOPIFY_API_SECRET }}
    QB_CLIENT_ID: ${{ secrets.QB_CLIENT_ID }}
    QB_CLIENT_SECRET: ${{ secrets.QB_CLIENT_SECRET }}
```

## Troubleshooting Tests

### "Config.toml not found"
- Create `tests/Config.toml` with your test credentials
- Or set `enable: false` for integration tests

### "No QuickBooks item found"
- Create test items in your QuickBooks sandbox
- Update `productMappingJson` with correct item IDs

### "Customer not found"
- Set `createCustomerIfNotFound = true`
- Or create test customers manually

### Tests timing out
- Check your network connection
- Verify QuickBooks sandbox is accessible
- Increase timeout in test configuration

## Best Practices

1. **Always test in sandbox** - Never use production credentials
2. **Clean up after tests** - Delete test data from QuickBooks
3. **Use meaningful test data** - Make it easy to identify test records
4. **Test error cases** - Don't just test happy paths
5. **Document test scenarios** - Help future developers understand coverage

## Need Help?

- Check `manual_test_guide.md` for detailed testing instructions
- Review logs for error messages
- Verify your test configuration matches QuickBooks setup
- Ensure all required items exist in QuickBooks sandbox

---

**Remember**: Testing in sandbox environments prevents accidental changes to production data!
