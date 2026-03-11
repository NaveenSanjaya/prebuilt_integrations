# Manual Test Instructions

## How to Run the Manual Tests

The manual test suite is located in `manual_test.bal` and contains 21 comprehensive tests covering all scenarios.

### Steps to Run:

1. **Temporarily disable the service** in `main.bal`:
   - Open `shopify_to_quickbooks_transaction/main.bal`
   - Comment out the entire `service shopify:OrdersService on shopifyListener { ... }` block
   - You can do this by adding `//` at the start of each line in the service block

2. **Make sure your Config.toml is configured** with:
   - Valid QuickBooks sandbox credentials
   - Product mappings (e.g., `productMappingJson = "{\"TEST-SKU-001\": \"1\", \"TEST-SKU-002\": \"2\"}"`)
   - Shipping item name (e.g., `shippingItemName = "Shipping"`)
   - Discount item name (e.g., `discountItemName = "Discount"`)

3. **Run the tests**:
   ```bash
   bal run
   ```

4. **Review the output**:
   - Each test will show ✅ PASSED or ❌ FAILED
   - A summary will be displayed at the end
   - Check your QuickBooks sandbox to verify invoices were created

5. **After testing, re-enable the service**:
   - Uncomment the service block in `main.bal`
   - Run `bal run` to start the webhook listener

## Test Coverage

### Happy Path (8 tests)
- ✅ Fulfilled order creates invoice
- ✅ Paid order creates invoice
- ✅ Customer auto-creation works
- ✅ Product line items map correctly
- ✅ Shipping line item created
- ✅ Discount line item created (negative amount)
- ✅ Tax codes applied correctly
- ✅ Order reference in memo

### Validation & Filtering (5 tests)
- ✅ Order below minimum amount is skipped
- ✅ Order without line items is quarantined
- ✅ Order without customer email validation
- ✅ Unfulfilled order is skipped
- ✅ Unpaid order is skipped

### Error Handling (2 tests)
- ✅ Missing SKU mapping (expects error)
- ✅ Duplicate order is skipped

### Edge Cases (6 tests)
- ✅ Order with multiple discount codes
- ✅ Order with no shipping
- ✅ Order with no discounts
- ✅ Order with special characters in description
- ✅ Order with very large amounts
- ✅ Order with zero-price items

## Verification

After running the tests, log into your QuickBooks sandbox and verify:
1. Invoices were created with correct order numbers (1001-1021)
2. Customer details match the test data
3. Line items, shipping, and discounts are correct
4. Amounts are accurate
5. Private notes contain the Shopify order reference

## Troubleshooting

**Error: "No QuickBooks item found for SKU"**
- Add the SKU to `productMappingJson` in Config.toml
- Or create an item in QuickBooks with Name matching the SKU

**Error: "QB customer not found"**
- Enable `createCustomerIfNotFound = true` in Config.toml
- Or manually create the customer in QuickBooks

**Error: "OAuth token expired"**
- Refresh your QuickBooks OAuth token
- Update `refreshToken` in Config.toml
