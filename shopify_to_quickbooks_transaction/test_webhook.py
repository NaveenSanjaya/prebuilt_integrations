"""
End-to-end test: send a mock Shopify orders/fulfilled webhook to the local service.

Usage:
    python test_webhook.py

Requirements:
    pip install requests   (only standard + requests needed)

Before running:
    1. Fill in SECRET and QB_ITEM_SKU below to match your Config.toml / QB sandbox items.
    2. Start the service: cd shopify_to_quickbooks_transaction && bal run
    3. Run this script in a second terminal.
"""

import hashlib
import hmac
import base64
import json
import sys
import requests  # pip install requests

# ── Configuration ───────────────────────────────────────────────────────────────
# Must match Config.toml shopifyConfig.apiSecretKey
SECRET = "4b80bf797ee31686771550fc705b55d89c1b9527258ed06133bc0a347cd6640f"

# The local service listens on port 8090
SERVICE_URL = "http://localhost:8090"

# Shopify topic — "orders/fulfilled" triggers onOrdersFulfilled
# Change to "orders/paid" to test onOrdersPaid (set financial_status="paid" in payload too)
TOPIC = "orders/fulfilled"

# SKU of a product that exists in your QuickBooks sandbox Items list.
# If productMappingJson is "{}", the integration falls back to querying QB by SKU/Name.
QB_ITEM_SKU = "TEST-SKU-001"
# ────────────────────────────────────────────────────────────────────────────────

# Minimal but realistic Shopify order payload
order_payload = {
    "id": 9988776655,
    "order_number": 1047,
    "email": "testcustomer@example.com",
    "created_at": "2026-03-10T12:00:00-05:00",
    "currency": "USD",
    "financial_status": "paid",
    "fulfillment_status": "fulfilled",
    "total_price": "109.95",
    "total_discounts": "10.00",
    "customer": {
        "id": 123456789,
        "email": "testcustomer@example.com",
        "first_name": "Test",
        "last_name": "Customer"
    },
    "billing_address": {
        "address1": "123 Main St",
        "city": "San Francisco",
        "province": "CA",
        "zip": "94105",
        "country": "US"
    },
    "line_items": [
        {
            "id": 111111111,
            "title": "Test Product",
            "sku": QB_ITEM_SKU,
            "quantity": 2,
            "price": "49.99",
            "tax_lines": []
        },
        {
            "id": 222222222,
            "title": "Another Product",
            "sku": QB_ITEM_SKU,   # reuse same SKU for simplicity
            "quantity": 1,
            "price": "9.97",
            "tax_lines": []
        }
    ],
    "shipping_lines": [
        {
            "id": 333333333,
            "title": "Standard Shipping",
            "price": "10.00"
        }
    ],
    "discount_codes": [
        {
            "code": "SAVE10",
            "amount": "10.00",
            "type": "fixed_amount"
        }
    ],
    "discount_applications": [
        {
            "type": "discount_code",
            "title": "SAVE10",
            "description": "10 off",
            "value": "10.00",
            "value_type": "fixed_amount"
        }
    ]
}


def compute_hmac(body: bytes, secret: str) -> str:
    """Compute Shopify-style HMAC-SHA256 signature (base64-encoded)."""
    digest = hmac.new(secret.encode("utf-8"), body, hashlib.sha256).digest()
    return base64.b64encode(digest).decode("utf-8")


def send_webhook(topic: str, payload: dict, secret: str) -> None:
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    signature = compute_hmac(body, secret)

    headers = {
        "Content-Type": "application/json",
        "X-Shopify-Topic": topic,
        "X-Shopify-Hmac-Sha256": signature,
        "X-Shopify-Shop-Domain": "test-store.myshopify.com",
        "X-Shopify-Api-Version": "2024-01",
    }

    print(f"Sending {topic} webhook to {SERVICE_URL} ...")
    print(f"  Payload order #: {payload.get('order_number')}")
    print(f"  HMAC signature : {signature[:20]}...")

    try:
        resp = requests.post(SERVICE_URL, headers=headers, data=body, timeout=30)
        print(f"\nResponse: HTTP {resp.status_code}")
        if resp.text:
            print(f"Body: {resp.text[:500]}")
    except requests.exceptions.ConnectionError:
        print("\nERROR: Could not connect to the service.")
        print("  Make sure the Ballerina service is running:")
        print("    cd shopify_to_quickbooks_transaction && bal run")
        sys.exit(1)
    except requests.exceptions.Timeout:
        print("\nERROR: Request timed out (QB API may be slow — check service logs).")
        sys.exit(1)


if __name__ == "__main__":
    print("=" * 60)
    print("Shopify → QuickBooks  End-to-End Webhook Test")
    print("=" * 60)

    if SECRET == "YOUR_SHOPIFY_WEBHOOK_SECRET":
        print("\nWARNING: SECRET is still the placeholder. Update it to match Config.toml.\n")

    send_webhook(TOPIC, order_payload, SECRET)

    print("\nDone. Check the service terminal for log output:")
    print("  [QB] Invoice created: Id=... for Order #1042")
    print("\nVerify in QuickBooks Sandbox:")
    print("  https://app.sandbox.qbo.intuit.com  > Sales > Invoices")
