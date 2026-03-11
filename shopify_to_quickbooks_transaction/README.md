# Shopify to QuickBooks Transaction Sync

## Overview
This prebuilt integration automatically synchronizes Shopify orders to QuickBooks Online as transactions (e.g. Sales Receipts or Invoices). By listening for Shopify order webhooks, it enables real-time synchronization, mapping Shopify line items, shipping charges, and discounts accurately into QuickBooks to ensure consistent financial records.

## Features
- Real-time synchronization triggered by Shopify webhooks (`orders/fulfilled` or `orders/paid`).
- Mapping of Shopify products to QuickBooks Items.
- Lookup or creation of QuickBooks customers corresponding to Shopify customers.
- Management of multi-currency orders, shipping charges, discounts, and custom tax codes.
- Filter criteria to sync orders by status (`FULFILLED`, `PAID`, or `COMPLETED`).
- Robust quarantine mechanism to defer orders lacking configuration details or failing validation.

## Prerequisites
- A **Shopify** account and administrative access to create Webhooks.
- A **QuickBooks Online** account with API access (Developer Portal).
- Active API Credentials for both systems.

## Getting Started

### 1. Shopify Setup
1. Log in to your Shopify Admin Dashboard.
2. Go to **Settings > Notifications > Webhooks**.
3. Create a new webhook for `orders/fulfilled` or `orders/paid` in JSON format.
4. Set the Endpoint URL to the generated webhook URL of this integration.
5. Note down the **Webhook Signing Secret**.

### 2. QuickBooks Online Setup
1. Log in to the [Intuit Developer Portal](https://developer.intuit.com).
2. Create an App under the Dashboard and enable the **Accounting** scope (`com.intuit.quickbooks.accounting`).
3. Retrieve your **Client ID** and **Client Secret**.
4. Generate a **Refresh Token** via the OAuth API Playground or your custom auth implementation.
5. Note your **Company ID (Realm ID)**.

### 3. Setup and Configuration
Deploy this integration in your environment and provide the following required parameters during the setup wizard:
- `shopifyConfig.apiSecretKey`: Your Shopify webhook signing secret.
- `quickbooksConfig.clientId`: Your QuickBooks app Client ID.
- `quickbooksConfig.clientSecret`: Your QuickBooks app Client Secret.
- `quickbooksConfig.refreshToken`: Your QuickBooks app Refresh Token.
- `quickbooksConfig.companyId`: Your QuickBooks Realm ID.
- Account configurations (e.g. Product Sales Account ID, Shipping Account ID, Discount Account ID).

## Deployment Flow
This integration is developed as an Event-Driven Webhook Consumer using Ballerina. When a webhook arrives at the listener port (8090), it validates the HMAC signature, parses the order data, performs cross-reference lookups with QuickBooks, and pushes the final transformed sales receipt or invoice transaction securely to the Intuit API.
