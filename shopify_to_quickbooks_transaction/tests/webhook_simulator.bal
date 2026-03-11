import ballerina/http;
import ballerina/io;

// Simple webhook simulator for local testing
// This sends a test order event directly to your running integration

configurable string integrationUrl = "http://localhost:8090";

public function runWebhookSimulator() returns error? {
    io:println("=== Shopify Webhook Simulator ===");
    io:println("This tool sends test order events to your running integration.");
    io:println("");

    // Get test order
    var testOrder = getMockFulfilledOrder();

    io:println("Test Order Details:");
    io:println("  Order Number: " + (testOrder?.order_number ?: 0).toString());
    io:println("  Customer: " + (testOrder?.customer?.email ?: "N/A"));
    io:println("  Total: $" + (testOrder?.total_price ?: "0"));
    io:println("  Status: " + (testOrder?.fulfillment_status ?: "unknown"));
    io:println("");

    // Create HTTP client
    http:Client httpClient = check new (integrationUrl);

    // Send webhook
    io:println("Sending webhook to: " + integrationUrl);

    json orderJson = testOrder.toJson();

    http:Response response = check httpClient->post("/", orderJson, headers = {
        "Content-Type": "application/json",
        "X-Shopify-Topic": "orders/fulfilled",
        "X-Shopify-Shop-Domain": "test-shop.myshopify.com"
        // Note: HMAC signature validation will fail unless you provide a valid signature
        // For local testing, you may need to temporarily disable signature validation
    });

    io:println("");
    io:println("Response Status: " + response.statusCode.toString());

    if response.statusCode == 200 || response.statusCode == 202 {
        io:println("✅ Webhook accepted! Check your integration logs for processing results.");
    } else {
        string payload = check response.getTextPayload();
        io:println("❌ Webhook rejected:");
        io:println(payload);
    }
}

// Helper function to convert order event to JSON
function toJson(any data) returns json {
    return <json>data;
}
