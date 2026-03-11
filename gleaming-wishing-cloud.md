# Engineering Document: Shopify to QuickBooks Integration

## Context

This document provides a complete engineering specification for a Shopify → QuickBooks prebuilt integration on the Devant platform. The integration will automatically sync fulfilled or paid Shopify orders into QuickBooks as financial transactions (Sales Receipts, Invoices, or Payments), eliminating manual data entry and ensuring real-time financial accuracy.

This specification is based on comprehensive analysis of the existing Salesforce-to-Google Sheets integration in this repository, applying established Devant/Ballerina architectural patterns to the new requirements.

**Business Value:**
- Eliminates 2-4 hours of daily manual order entry
- Removes human transcription errors in financial records
- Provides real-time revenue visibility to finance teams
- Ensures consistent tax code application and audit trail
- Scales to handle high-volume sales periods without additional staffing

---

## 1. Integration Overview

**Integration Name:** Shopify Order to QuickBooks Transaction Sync
**Category:** E-Commerce & Finance
**Integration Type:** Event-Driven Webhook
**Priority:** High
**Complexity:** High

**What It Does:**
- Listens for Shopify order webhooks (orders/fulfilled, orders/paid, orders/updated)
- Validates webhook signature using HMAC-SHA256
- Filters orders based on configured status trigger (fulfilled/paid/completed)
- Looks up or creates QuickBooks customers from Shopify customer data
- Maps Shopify line items to QuickBooks products using configurable SKU mappings
- Creates QuickBooks transactions with proper tax codes and income account assignments
- Handles shipping charges, discounts, and multi-currency orders
- Quarantines orders with validation errors or missing mappings for manual review

---

## 2. Technical Architecture

### 2.1 Integration Pattern
- **Pattern:** Event-Driven Webhook Consumer
- **Protocol:** HTTPS POST (Shopify Webhook → Ballerina Listener)
- **Deployment Model:** Always-on service listening on port 8090
- **Technology:** Ballerina 2201.12.10+

### 2.2 Data Flow

```
Shopify Store (orders/fulfilled, orders/paid webhooks)
    ↓ HTTPS POST (HMAC-SHA256 signed)
Ballerina Shopify Webhook Listener (ballerinax/trigger.shopify)
    ↓ Validate signature, parse OrderEvent
Order Processing Logic
    ↓ Filter by status, validate fields
QuickBooks Customer Lookup/Creation
    ↓ Query by email, create if not found
Data Transformation & Mapping
    ↓ Map line items, taxes, shipping, discounts
QuickBooks Transaction Creation (ballerinax/quickbooks)
    ↓ POST /salesreceipt or /invoice
Response & Error Handling
    ↓ Log success or quarantine on failure
```

### 2.3 Ballerina Connectors

**Required Dependencies (Ballerina.toml):**
- `ballerinax/trigger.shopify` - Webhook listener with signature validation
- `ballerinax/quickbooks` - QuickBooks Online REST API client
- `ballerina/http` - HTTP service framework
- `ballerina/log` - Logging utilities
- `ballerina/time` - Date/time formatting

### 2.4 File Structure

Following Devant conventions:

```
shopify-to-quickbooks/
├── Ballerina.toml              # Package metadata & dependencies
├── config.bal                  # Configurable inputs (auth, mappings, settings)
├── connections.bal             # Shopify listener + QuickBooks client initialization
├── types.bal                   # Type definitions (ShopifyOrderEvent, QB records)
├── data_mappings.bal           # Transformation functions (Order → QB transaction)
├── main.bal                    # Webhook service handlers (onOrdersFulfilled, etc.)
├── functions.bal               # Utilities (customer lookup, validation, quarantine)
├── README.md                   # Setup, configuration, deployment documentation
└── .choreo/
    └── config-schema.json      # Devant UI schema for configuration fields
```

---

## 3. Authentication Requirements

### 3.1 Shopify Authentication

**Method:** HMAC-SHA256 webhook signature validation

**Required Credential:**
- `apiSecretKey` - Shopify webhook signing secret

**Setup Steps:**
1. Log in to Shopify Admin
2. Navigate to **Settings → Notifications → Webhooks**
3. Copy the webhook signing key shown under "Your webhooks will be signed with..."
4. Create webhook subscriptions:
   - Event: `orders/fulfilled` (for fulfillment-based sync)
   - Event: `orders/paid` (for payment-based sync)
   - Format: JSON
   - URL: `https://<devant-endpoint>/` (provided after deployment)

**Configuration (config.bal):**
```ballerina
configurable record {
    string apiSecretKey;
} shopifyConfig = ?;
```

### 3.2 QuickBooks Authentication

**Method:** OAuth2 Refresh Token Flow

**Required Credentials:**
- `clientId` - QuickBooks OAuth2 app client ID
- `clientSecret` - QuickBooks OAuth2 app client secret
- `refreshToken` - Long-lived refresh token
- `companyId` - QuickBooks Realm ID (company identifier)

**Setup Steps:**
1. Create QuickBooks app at [developer.intuit.com](https://developer.intuit.com)
2. Enable **Accounting** scope (`com.intuit.quickbooks.accounting`)
3. Navigate to **Keys & credentials** tab and copy Client ID/Secret
4. Use OAuth2 authorization flow to obtain initial refresh token
5. Retrieve **Company ID** from QuickBooks Online URL after login

**Configuration (config.bal):**
```ballerina
configurable record {
    string clientId;
    string clientSecret;
    string refreshToken;
    string companyId;
} quickbooksConfig = ?;
```

**Connector Initialization (connections.bal):**
```ballerina
final quickbooks:Client quickbooksClient = check new ({
    auth: {
        clientId: quickbooksConfig.clientId,
        clientSecret: quickbooksConfig.clientSecret,
        refreshToken: quickbooksConfig.refreshToken
    },
    companyId: quickbooksConfig.companyId
});

listener shopify:Listener shopifyListener = new ({
    apiSecretKey: shopifyConfig.apiSecretKey,
    port: 8090
});
```

---

## 4. Configurable Inputs Specification

### 4.1 Configuration Schema (config.bal)

```ballerina
// Transaction type selection
enum QBTransactionType {
    SALES_RECEIPT = "SALES_RECEIPT",
    INVOICE = "INVOICE",
    PAYMENT = "PAYMENT"
}
configurable QBTransactionType transactionType = "SALES_RECEIPT";

// Order status trigger filter
enum OrderStatusTrigger {
    COMPLETED = "COMPLETED",
    PAID = "PAID",
    FULFILLED = "FULFILLED"
}
configurable OrderStatusTrigger orderStatusTrigger = "FULFILLED";

// Customer creation behavior
configurable boolean createCustomerIfNotFound = true;

// Product to QuickBooks Item mapping (JSON string)
configurable string productMappingJson = "{}";
// Example: {"shopify-sku-123": "QB-ITEM-ID-456"}

// Tax handling configuration
configurable record {
    string defaultTaxCode;
    string taxMappingJson;
} taxConfig = {
    defaultTaxCode: "TAX",
    taxMappingJson: "{}"
};

// Income account assignments
configurable record {
    string productSalesAccountId;
    string shippingAccountId;
    string discountAccountId;
} accountConfig = ?;

// Shipping mapping
configurable boolean mapShippingAsSeparateLine = true;
configurable string shippingItemName = "Shipping";

// Discount handling
configurable boolean includeDiscountLineItems = true;

// Order reference in QB memo
configurable boolean addOrderReferenceToMemo = true;
configurable string memoTemplate = "Shopify Order: {orderId} | {orderNumber}";

// Validation rules
configurable record {
    boolean requireCustomerEmail;
    boolean requireLineItems;
    decimal minimumOrderAmount;
} validationRules = {
    requireCustomerEmail: true,
    requireLineItems: true,
    minimumOrderAmount: 0.0
};
```

### 4.2 Configuration Data Types & Defaults

| Configuration | Type | Required | Default | Description |
|--------------|------|----------|---------|-------------|
| `transactionType` | QBTransactionType | No | SALES_RECEIPT | Type of QB transaction (SALES_RECEIPT/INVOICE/PAYMENT) |
| `orderStatusTrigger` | OrderStatusTrigger | No | FULFILLED | Order status to sync on (FULFILLED/PAID/COMPLETED) |
| `createCustomerIfNotFound` | boolean | No | true | Auto-create QB customers if not found |
| `productMappingJson` | string (JSON) | No | "{}" | Shopify SKU → QB Item ID mapping |
| `taxConfig.defaultTaxCode` | string | No | "TAX" | Default QB tax code |
| `taxConfig.taxMappingJson` | string (JSON) | No | "{}" | Shopify tax name → QB tax code mapping |
| `accountConfig.productSalesAccountId` | string | Yes | - | QB income account for product sales |
| `accountConfig.shippingAccountId` | string | Yes | - | QB income account for shipping |
| `accountConfig.discountAccountId` | string | Yes | - | QB account for discounts |
| `mapShippingAsSeparateLine` | boolean | No | true | Create separate line for shipping |
| `includeDiscountLineItems` | boolean | No | true | Include discount line items |
| `addOrderReferenceToMemo` | boolean | No | true | Add Shopify order ref to QB memo |
| `validationRules.minimumOrderAmount` | decimal | No | 0.0 | Minimum order amount to process |

---

## 5. Data Mapping Requirements

### 5.1 Core Type Definitions (types.bal)

```ballerina
// Shopify order event structure
type ShopifyOrderEvent record {
    int id;
    string? email;
    string? order_number;
    decimal? total_price;
    decimal? subtotal_price;
    decimal? total_tax;
    decimal? total_discounts;
    string? financial_status;
    string? fulfillment_status;
    string? currency;
    string? created_at;
    ShopifyCustomer? customer;
    ShopifyLineItem[] line_items;
    ShopifyShippingLine[] shipping_lines;
    ShopifyTaxLine[] tax_lines;
    ShopifyDiscountApplication[] discount_applications;
    ShopifyBillingAddress? billing_address;
};

// QuickBooks Sales Receipt structure
type QBSalesReceipt record {
    string? Id;
    string CustomerRef_value;
    string? TxnDate;
    QBLine[] Line;
    string? PrivateNote;
    decimal? TotalAmt;
    string? CurrencyRef_value;
};

type QBLine record {
    string DetailType;
    decimal? Amount;
    string? Description;
    QBSalesItemLineDetail? SalesItemLineDetail;
};

type QBSalesItemLineDetail record {
    string ItemRef_value;
    decimal? UnitPrice;
    int? Qty;
    string? TaxCodeRef_value;
    string? IncomeAccountRef_value;
};
```

### 5.2 Field Mapping Specifications

#### Customer Mapping (Shopify → QuickBooks Customer)

| Shopify Field | QuickBooks Field | Transformation | Required |
|--------------|------------------|----------------|----------|
| `customer.email` | `PrimaryEmailAddr.Address` | Direct | Yes |
| `customer.first_name + last_name` | `DisplayName` | Concatenate, fallback to email | Yes |
| `customer.first_name` | `GivenName` | Direct | No |
| `customer.last_name` | `FamilyName` | Direct | No |
| `billing_address.address1` | `BillAddr.Line1` | Direct | No |
| `billing_address.city` | `BillAddr.City` | Direct | No |
| `billing_address.province` | `BillAddr.CountrySubDivisionCode` | Direct | No |
| `billing_address.zip` | `BillAddr.PostalCode` | Direct | No |

#### Transaction Header Mapping

| Shopify Field | QuickBooks Field | Transformation |
|--------------|------------------|----------------|
| `created_at` | `TxnDate` | Convert to YYYY-MM-DD |
| `order_number` + `id` | `PrivateNote` | Use memoTemplate config |
| `currency` | `CurrencyRef.value` | Direct (default "USD") |
| `total_price` | `TotalAmt` | Direct |

#### Product Line Item Mapping

| Shopify Field | QuickBooks Field | Transformation |
|--------------|------------------|----------------|
| `line_items[].sku` | `SalesItemLineDetail.ItemRef.value` | Lookup in productMappingJson |
| `line_items[].title` | `Description` | Direct |
| `line_items[].quantity` | `SalesItemLineDetail.Qty` | Direct |
| `line_items[].price` | `SalesItemLineDetail.UnitPrice` | Direct |
| `line_items[].quantity * price` | `Amount` | Calculate |
| `accountConfig.productSalesAccountId` | `IncomeAccountRef.value` | From config |
| `line_items[].tax_lines[0].title` | `TaxCodeRef.value` | Lookup in taxMappingJson |

#### Shipping Line Mapping (if mapShippingAsSeparateLine = true)

| Shopify Field | QuickBooks Field | Value |
|--------------|------------------|-------|
| `shippingItemName` config | `ItemRef.value` | "Shipping" (or config value) |
| `shipping_lines[].title` | `Description` | Shipping method name |
| `shipping_lines[].price` | `Amount` | Sum all shipping lines |
| `accountConfig.shippingAccountId` | `IncomeAccountRef.value` | From config |

#### Discount Line Mapping (if includeDiscountLineItems = true)

| Shopify Field | QuickBooks Field | Value |
|--------------|------------------|-------|
| `discount_applications[].title` | `Description` | Discount code/name |
| `discount_applications[].value` | `Amount` | Negated (negative value) |
| `accountConfig.discountAccountId` | `IncomeAccountRef.value` | From config |

### 5.3 Customer Lookup and Creation Logic (functions.bal)

```ballerina
function getOrCreateQuickBooksCustomer(
    ShopifyCustomer? shopifyCustomer,
    ShopifyBillingAddress? billingAddress
) returns string|error {

    // Step 1: Validate customer email
    if shopifyCustomer is () || shopifyCustomer.email is () {
        if validationRules.requireCustomerEmail {
            return error("Customer email is required");
        }
        return "DEFAULT_CUSTOMER_ID";
    }

    string customerEmail = shopifyCustomer.email ?: "";

    // Step 2: Query QuickBooks for existing customer by email
    string query = string `SELECT * FROM Customer WHERE PrimaryEmailAddr = '${customerEmail}'`;
    QBQueryResponse|error queryResponse = quickbooksClient->query(query);

    // Step 3: Return QB ID if customer exists
    if queryResponse is QBQueryResponse {
        if queryResponse.QueryResponse?.Customer is QBCustomer[] {
            QBCustomer[] customers = <QBCustomer[]>queryResponse.QueryResponse?.Customer;
            if customers.length() > 0 {
                return customers[0].Id ?: error("Customer ID not found");
            }
        }
    }

    // Step 4: Check if auto-creation enabled
    if !createCustomerIfNotFound {
        return error(string `Customer not found: ${customerEmail}. Auto-creation disabled.`);
    }

    // Step 5: Create new QuickBooks customer
    QBCustomer newCustomer = {
        DisplayName: constructDisplayName(shopifyCustomer, customerEmail),
        GivenName: shopifyCustomer.first_name,
        FamilyName: shopifyCustomer.last_name,
        PrimaryEmailAddr_Address: customerEmail,
        BillAddr: mapBillingAddress(billingAddress)
    };

    QBCustomer|error createdCustomer = quickbooksClient->/customer.post(newCustomer);

    if createdCustomer is error {
        return error(string `Failed to create QB customer: ${createdCustomer.message()}`);
    }

    return createdCustomer.Id ?: error("Created customer ID not returned");
}
```

### 5.4 Product SKU Mapping (functions.bal)

```ballerina
// Parse JSON mapping once at startup
json productMappingParsed = check value:fromJsonString(productMappingJson);
map<string> productMap = <map<string>>productMappingParsed;

function lookupQuickBooksItemId(string? shopifySku) returns string|error {
    if shopifySku is () {
        return error("Product SKU is null");
    }

    // Check explicit mapping first
    if productMap.hasKey(shopifySku) {
        return productMap.get(shopifySku);
    }

    // Fallback: Query QB for item by SKU
    string? itemId = check queryQuickBooksItemBySku(shopifySku);

    if itemId is () {
        return error(string `No QuickBooks item found for SKU: ${shopifySku}`);
    }

    return itemId;
}

function queryQuickBooksItemBySku(string sku) returns string?|error {
    string query = string `SELECT Id FROM Item WHERE Sku = '${sku}' OR Name = '${sku}'`;
    QBQueryResponse|error response = quickbooksClient->query(query);

    if response is error {
        return response;
    }

    // Extract Item ID from response
    // (Implementation detail)

    return ();
}
```

---

## 6. Error Handling & Edge Cases

### 6.1 Error Classification

| Error Type | Cause | Handling Strategy |
|-----------|-------|-------------------|
| **Validation Error** | Missing required fields | Quarantine order, log warning |
| **Customer Not Found** | QB customer missing, auto-create disabled | Quarantine order |
| **Product Mapping Missing** | Shopify SKU not in mapping | Quarantine order |
| **QB Authentication** | Expired refresh token | Retry 3x with backoff, then quarantine |
| **QB Rate Limit** | 500 req/min exceeded | Retry after 60s delay |
| **Duplicate Transaction** | Order already synced | Check QB by memo, skip if found |
| **Tax Mismatch** | QB tax ≠ Shopify tax | Log warning, use Shopify amount |
| **Network Timeout** | QB API unresponsive | Retry 3x with 5s delay |

### 6.2 Quarantine Pattern (types.bal + functions.bal)

```ballerina
type QuarantinedOrder record {
    string orderId;
    string orderNumber;
    string quarantineReason;
    string errorType;
    string timestamp;
    json rawPayload;
    int retryCount;
    boolean retryEligible;
};

function quarantineOrder(
    shopify:OrderEvent event,
    string reason,
    string errorType
) returns error? {
    QuarantinedOrder quarantined = {
        orderId: event.id.toString(),
        orderNumber: event.order_number ?: "N/A",
        quarantineReason: reason,
        errorType: errorType,
        timestamp: time:utcNow().toString(),
        rawPayload: event.toJson(),
        retryCount: 0,
        retryEligible: errorType != "VALIDATION"
    };

    log:printWarn(string `Order quarantined: ${quarantined.orderNumber} - ${reason}`);

    // Write to quarantine storage (DB/file/notification)
    // Optional: Send Slack/email notification to finance team

    return;
}
```

### 6.3 Edge Case Handling

**Order Status Filtering:**
```ballerina
remote function onOrdersFulfilled(shopify:OrderEvent event) returns error? {
    match orderStatusTrigger {
        FULFILLED => {
            if event.fulfillment_status != "fulfilled" {
                log:printInfo(string `Skipping order ${event.order_number}: not fulfilled`);
                return;
            }
        }
        PAID => {
            if event.financial_status != "paid" {
                return;
            }
        }
        COMPLETED => {
            if event.fulfillment_status != "fulfilled" || event.financial_status != "paid" {
                return;
            }
        }
    }

    check processOrder(event);
}
```

**Duplicate Prevention (Idempotency):**
```ballerina
function isDuplicateTransaction(string orderNumber) returns boolean|error {
    string memoSearch = string `Shopify Order: ${orderNumber}`;
    string query = string `SELECT * FROM SalesReceipt WHERE PrivateNote LIKE '%${memoSearch}%'`;

    QBQueryResponse|error response = quickbooksClient->query(query);

    if response is error {
        return false;  // Assume not duplicate if check fails
    }

    return (response.QueryResponse?.SalesReceipt is QBSalesReceipt[]
            && (<QBSalesReceipt[]>response.QueryResponse?.SalesReceipt).length() > 0);
}
```

**Minimum Order Amount:**
```ballerina
if event.total_price < validationRules.minimumOrderAmount {
    log:printInfo(string `Skipping order ${event.order_number}: below minimum`);
    return;
}
```

---

## 7. Implementation Considerations

### 7.1 Transaction Type Logic

**Sales Receipt Mode (Default):**
Use for orders paid in full at purchase (credit card, PayPal).

```ballerina
function mapOrderToSalesReceipt(
    shopify:OrderEvent event,
    string customerId
) returns QBSalesReceipt|error {
    QBLine[] lines = [];

    // Add product line items
    foreach var item in event.line_items {
        QBLine line = {
            DetailType: "SalesItemLineDetail",
            Amount: <decimal>item.quantity * (item.price ?: 0.0),
            Description: item.title,
            SalesItemLineDetail: {
                ItemRef_value: check lookupQuickBooksItemId(item.sku),
                UnitPrice: item.price,
                Qty: item.quantity,
                TaxCodeRef_value: mapTaxCode(item.tax_lines),
                IncomeAccountRef_value: accountConfig.productSalesAccountId
            }
        };
        lines.push(line);
    }

    // Add shipping line if configured
    if mapShippingAsSeparateLine && event.shipping_lines.length() > 0 {
        decimal totalShipping = event.shipping_lines.reduce(
            function (decimal sum, ShopifyShippingLine line)
                returns decimal => sum + (line.price ?: 0.0),
            0.0
        );

        QBLine shippingLine = {
            DetailType: "SalesItemLineDetail",
            Amount: totalShipping,
            Description: string:'join(", ", ...event.shipping_lines.map(sl => sl.title ?: "Shipping")),
            SalesItemLineDetail: {
                ItemRef_value: shippingItemName,
                Qty: 1,
                IncomeAccountRef_value: accountConfig.shippingAccountId
            }
        };
        lines.push(shippingLine);
    }

    // Add discount lines if configured
    if includeDiscountLineItems && event.total_discounts > 0.0 {
        QBLine discountLine = {
            DetailType: "SalesItemLineDetail",
            Amount: -(event.total_discounts ?: 0.0),
            Description: "Discount: " + string:'join(", ", ...event.discount_applications.map(da => da.title ?: "")),
            SalesItemLineDetail: {
                ItemRef_value: "Discount",
                Qty: 1,
                IncomeAccountRef_value: accountConfig.discountAccountId
            }
        };
        lines.push(discountLine);
    }

    return {
        CustomerRef_value: customerId,
        TxnDate: formatDate(event.created_at),
        Line: lines,
        PrivateNote: constructMemo(event),
        CurrencyRef_value: event.currency ?: "USD",
        TotalAmt: event.total_price
    };
}
```

**Invoice Mode:**
Use for B2B orders with NET-30 payment terms.

```ballerina
function mapOrderToInvoice(
    shopify:OrderEvent event,
    string customerId
) returns QBInvoice|error {
    QBLine[] lines = check buildLineItems(event);
    string dueDate = calculateDueDate(event.created_at, 30);

    return {
        CustomerRef_value: customerId,
        TxnDate: formatDate(event.created_at),
        DueDate: dueDate,
        Line: lines,
        PrivateNote: constructMemo(event),
        TotalAmt: event.total_price,
        Balance: event.total_price
    };
}
```

### 7.2 Main Webhook Service (main.bal)

```ballerina
service shopify:OrdersService on shopifyListener {

    remote function onOrdersFulfilled(shopify:OrderEvent event) returns error? {
        log:printInfo(string `Received order fulfilled: ${event.order_number}`);
        return processOrder(event);
    }

    remote function onOrdersPaid(shopify:OrderEvent event) returns error? {
        log:printInfo(string `Received order paid: ${event.order_number}`);
        return processOrder(event);
    }
}

function processOrder(shopify:OrderEvent event) returns error? {
    do {
        // Validate order status
        if !shouldProcessOrder(event) {
            return;
        }

        // Check minimum amount
        if (event.total_price ?: 0.0) < validationRules.minimumOrderAmount {
            return;
        }

        // Check for duplicate
        if check isDuplicateTransaction(event.order_number ?: "") {
            log:printInfo(string `Skipping duplicate: ${event.order_number}`);
            return;
        }

        // Validate required fields
        check validateOrder(event);

        // Get/create customer
        string customerId = check getOrCreateQuickBooksCustomer(
            event.customer,
            event.billing_address
        );

        // Create transaction
        match transactionType {
            SALES_RECEIPT => {
                QBSalesReceipt receipt = check mapOrderToSalesReceipt(event, customerId);
                QBSalesReceipt|error result = quickbooksClient->/salesreceipt.post(receipt);

                if result is error {
                    check quarantineOrder(event, result.message(), "API_ERROR");
                    return result;
                }

                log:printInfo(string `Sales Receipt created: ${result.Id} for ${event.order_number}`);
            }
            INVOICE => {
                QBInvoice invoice = check mapOrderToInvoice(event, customerId);
                QBInvoice|error result = quickbooksClient->/invoice.post(invoice);

                if result is error {
                    check quarantineOrder(event, result.message(), "API_ERROR");
                    return result;
                }

                log:printInfo(string `Invoice created: ${result.Id} for ${event.order_number}`);
            }
        }

    } on fail error e {
        log:printError(string `Failed to process ${event.order_number}`, 'error = e);
        check quarantineOrder(event, e.message(), "UNKNOWN_ERROR");
        return e;
    }
}
```

---

## 8. Suggested Improvements Analysis

### 8.1 Discount and Refund Line Items

**Discounts:** ✅ **Included in initial implementation**
- Map `discount_applications[]` to negative line items
- Use dedicated `discountAccountId`
- Controlled by `includeDiscountLineItems` config

**Refunds:** 📋 **Recommended for Phase 2**
- Requires separate webhook subscription (`orders/refunded`)
- Create QuickBooks Credit Memos linked to original transactions
- Implementation strategy:
  1. Subscribe to `orders/refunded` webhook
  2. Add `onOrdersRefunded()` handler
  3. Query QB to find original Sales Receipt/Invoice
  4. Create Credit Memo with refund details
  5. Handle partial vs. full refunds

**Complexity:** Medium (requires transaction lookup logic)

### 8.2 Shipping Charges to Separate Account

✅ **Already included in initial implementation**
- Configuration: `accountConfig.shippingAccountId`
- Toggle: `mapShippingAsSeparateLine`
- Shipping line items use dedicated income account
- Benefits: P&L breakout, tax reporting simplification

### 8.3 Order Reference in QB Memo

✅ **Already included in initial implementation**
- Configuration: `addOrderReferenceToMemo` toggle, `memoTemplate` string
- Default template: `"Shopify Order: {orderId} | {orderNumber}"`
- Mapped to `PrivateNote` field (internal memo)
- Used for duplicate detection and customer service lookups

---

## 9. Testing Requirements

### 9.1 Unit Testing Scenarios

**Data Mapping Functions:**
- `mapOrderToSalesReceipt()` with 2 products → verify 2 line items, correct total
- Order with shipping → verify 3 lines (2 products + shipping), correct account
- Order with discount → verify negative discount line item
- `lookupQuickBooksItemId()` with valid SKU → correct QB Item ID
- `lookupQuickBooksItemId()` with unknown SKU → error

**Validation Functions:**
- `validateOrder()` without email, `requireCustomerEmail = true` → error
- `shouldProcessOrder()` with fulfilled order, trigger = FULFILLED → true
- `isDuplicateTransaction()` with existing order → true

### 9.2 Integration Testing Scenarios

| Scenario | Expected Outcome |
|----------|------------------|
| **Happy Path** | New order → QB Sales Receipt created with customer, line items, shipping, tax |
| **Customer Creation** | Unknown customer + auto-create enabled → New QB Customer + Sales Receipt |
| **Customer Not Found** | Unknown customer + auto-create disabled → Order quarantined |
| **Product Mapping Failure** | Unknown SKU → Order quarantined with "No QB item found" |
| **Duplicate Prevention** | Same webhook sent twice → First creates transaction, second skips |
| **Order Status Filtering** | Unfulfilled order + trigger = FULFILLED → Order skipped |
| **Minimum Amount** | $5 order + minimum = $10 → Order skipped |
| **Invoice Mode** | Transaction type = INVOICE → QB Invoice created (not Sales Receipt) |
| **Multi-Currency** | EUR order → Sales Receipt with CurrencyRef = "EUR" |

### 9.3 Performance Testing

| Scenario | Load | Success Criteria |
|----------|------|------------------|
| **Normal Load** | 10 orders/min | < 2 sec avg response time |
| **Peak Load** | 100 orders/min | < 10 sec p95 latency, no dropped webhooks |
| **QB Rate Limit** | 600 req/min | Retry logic activates, all orders eventually processed |
| **Large Order** | 100 line items | < 5 sec processing time |

### 9.4 Error Recovery Testing

- QB API timeout → Retry 3x with 5s delay, then quarantine
- Expired OAuth token → Connector auto-refreshes, request succeeds
- Network partition → Retry with exponential backoff
- Malformed webhook → Listener rejects with 400 Bad Request

---

## 10. Documentation Requirements

### 10.1 README.md Structure

Following Devant patterns:

**Sections:**
1. **Description** - What the integration does, list of capabilities
2. **Prerequisites** - Shopify setup (webhook configuration), QuickBooks setup (OAuth2 app, account preparation)
3. **Configuration** - All 20+ config fields documented with data types, defaults, examples
4. **Deploying on Devant** - Step-by-step deployment instructions
5. **Troubleshooting** - Common issues (order not syncing, customer not found, product mapping error)

**Example Configuration Documentation:**
```markdown
### Transaction Type
- `transactionType` - Type of QuickBooks transaction to create
  - `SALES_RECEIPT` (default): For orders paid in full
  - `INVOICE`: For B2B orders with payment terms
  - `PAYMENT`: For payment-only mode

### Product Mapping
- `productMappingJson` - JSON mapping of Shopify SKUs to QuickBooks Item IDs
  ```json
  {
    "shopify-sku-123": "QB-ITEM-ID-456",
    "shopify-sku-789": "QB-ITEM-ID-012"
  }
  ```
```

### 10.2 Config Schema for Devant UI

File: `.choreo/config-schema.json`

Provides structured UI in Devant for configuration:
- Groups: Shopify Config, QuickBooks Config, Transaction Settings, Mappings, Account Assignments
- Field types: string, enum, boolean, text (multi-line), secret
- Descriptions and help text for each field
- Required field validation

### 10.3 Inline Code Documentation

All functions include Ballerina doc comments:
```ballerina
# Looks up or creates a QuickBooks customer from Shopify customer data.
#
# + shopifyCustomer - Customer details from Shopify order event
# + billingAddress - Billing address from Shopify order event
# + return - QuickBooks customer ID, or error if lookup/creation fails
function getOrCreateQuickBooksCustomer(...) returns string|error {
    // Implementation
}
```

---

## Critical Files for Implementation

Based on Devant/Ballerina patterns:

1. **[Ballerina.toml](Ballerina.toml)** - Package metadata, dependencies (trigger.shopify, quickbooks)
2. **[config.bal](config.bal)** - All configurable variables with enums, records, defaults
3. **[connections.bal](connections.bal)** - Shopify listener and QuickBooks client initialization
4. **[types.bal](types.bal)** - ShopifyOrderEvent, QBSalesReceipt, QBInvoice, QBCustomer, QuarantinedOrder
5. **[data_mappings.bal](data_mappings.bal)** - mapOrderToSalesReceipt(), mapOrderToInvoice(), buildLineItems()
6. **[main.bal](main.bal)** - Webhook service with onOrdersFulfilled(), onOrdersPaid(), processOrder()
7. **[functions.bal](functions.bal)** - getOrCreateQuickBooksCustomer(), lookupQuickBooksItemId(), quarantineOrder()
8. **[README.md](README.md)** - Comprehensive setup and deployment documentation
9. **[.choreo/config-schema.json](.choreo/config-schema.json)** - Devant UI configuration schema

---

## Implementation Phases

**Phase 1 (MVP):**
- Core webhook listener with signature validation
- Customer lookup and creation
- Sales Receipt mode
- Basic product mapping (explicit productMappingJson only)
- Simple error handling with quarantine

**Phase 2 (Enhanced):**
- Invoice mode with due date calculation
- Advanced tax handling with tax code mapping
- Discount line items
- Duplicate prevention (idempotency)
- Shipping as separate line item

**Phase 3 (Advanced):**
- Refund handling with Credit Memos
- Payment mode with invoice linking
- Multi-currency support validation
- Advanced quarantine management (retry logic, notifications)

---

## Summary

This engineering document provides a complete technical specification for implementing the Shopify → QuickBooks integration on the Devant platform using Ballerina. The design follows established patterns from the existing Salesforce-to-Google Sheets integration, ensuring consistency with Devant's architecture.

**Key Highlights:**
- Event-driven webhook architecture with HMAC validation
- Flexible transaction type support (Sales Receipt/Invoice/Payment)
- Comprehensive data mapping with configurable SKU and tax code mappings
- Robust error handling with quarantine pattern
- Customer auto-creation with duplicate prevention
- Shipping and discount handling as separate line items
- Multi-currency support
- Production-ready with performance and testing requirements

The integration addresses all specified requirements and includes the suggested improvements (discounts, shipping account separation, order reference memo) in the initial implementation, with refunds recommended for Phase 2.
