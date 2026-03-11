# Shopify to QuickBooks Connect Guide

Follow the steps below to configure your Shopify to QuickBooks integration.

## Obtain Shopify Credentials
1. In your Shopify admin panel, navigate to **Settings > Notifications > Webhooks**.
2. Create a webhook for `orders/fulfilled` or `orders/paid`. Let the webhook point to the endpoint provided after deployment.
3. Scroll down to the bottom of the Webhooks page and locate **"Your webhooks will be signed with..."**
4. Copy the signing secret. Provide this as the `apiSecretKey` when configuring the connection.

## Obtain QuickBooks Credentials
1. Go to the [QuickBooks Developer Portal](https://developer.intuit.com).
2. In your app dashboard under **Keys & credentials**, copy the **Client ID** and **Client Secret**.
3. Authenticate with QuickBooks via OAuth2 (using the `com.intuit.quickbooks.accounting` scope) to generate a **Refresh Token**.
4. Retrieve your **Company ID** (also known as the Realm ID) from the QuickBooks app dashboard or company URL.
5. Provide these tokens during setup to authorize the QuickBooks connection.

## Map QuickBooks Accounts
You must reference specific ID values for the QuickBooks accounts you wish to use when syncing transactions. 
- Provide the Income Account ID for standard Products/Services.
- Ensure that the Shipping Account ID and Discount Account ID are properly set.
