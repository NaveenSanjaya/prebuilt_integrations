import ballerinax/trigger.shopify;

// Mock Shopify order events for testing

function getMockFulfilledOrder() returns shopify:OrderEvent {
    return {
        id: 123456789,
        order_number: 1001,
        created_at: "2024-01-15T10:30:00Z",
        currency: "USD",
        total_price: "150.00",
        total_discounts: "10.00",
        fulfillment_status: "fulfilled",
        financial_status: "paid",
        customer: {
            id: 987654321,
            email: "test.customer@example.com",
            first_name: "John",
            last_name: "Doe"
        },
        billing_address: {
            'address1: "123 Main St",
            city: "San Francisco",
            province: "CA",
            zip: "94102",
            country: "United States"
        },
        line_items: <shopify:OrderLineItem[]>[
            {
                id: 111,
                title: "Test Product 1",
                quantity: 2,
                price: "50.00",
                sku: "TEST-SKU-001",
                tax_lines: <shopify:TaxLine[]>[
                    {
                        title: "Sales Tax",
                        rate: 0.0875,
                        price: "8.75"
                    }
                ]
            },
            {
                id: 222,
                title: "Test Product 2",
                quantity: 1,
                price: "40.00",
                sku: "TEST-SKU-002",
                tax_lines: <shopify:TaxLine[]>[]
            }
        ],
        shipping_lines: [
            {
                title: "Standard Shipping",
                price: "10.00"
            }
        ],
        discount_codes: [
            {
                code: "SAVE10",
                amount: "10.00",
                'type: "fixed_amount"
            }
        ],
        discount_applications: [
            {
                title: "SAVE10",
                description: "Save $10 discount",
                value: "10.00",
                value_type: "fixed_amount"
            }
        ]
    };
}

function getMockPaidOrder() returns shopify:OrderEvent {
    return {
        id: 123456790,
        order_number: 1002,
        created_at: "2024-01-15T11:00:00Z",
        currency: "USD",
        total_price: "75.00",
        total_discounts: "0.00",
        fulfillment_status: "unfulfilled",
        financial_status: "paid",
        customer: {
            id: 987654322,
            email: "jane.smith@example.com",
            first_name: "Jane",
            last_name: "Smith"
        },
        billing_address: {
            'address1: "456 Oak Ave",
            city: "Los Angeles",
            province: "CA",
            zip: "90001",
            country: "United States"
        },
        line_items: <shopify:OrderLineItem[]>[
            {
                id: 444,
                title: "Test Product 3",
                quantity: 1,
                price: "75.00",
                sku: "TEST-SKU-003",
                tax_lines: <shopify:TaxLine[]>[]
            }
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}

function getMockOrderWithoutEmail() returns shopify:OrderEvent {
    return {
        id: 123456791,
        order_number: 1003,
        created_at: "2024-01-15T12:00:00Z",
        currency: "USD",
        total_price: "50.00",
        total_discounts: "0.00",
        fulfillment_status: "fulfilled",
        financial_status: "paid",
        customer: {
            id: 987654323,
            email: (),
            first_name: "Anonymous",
            last_name: "Customer"
        },
        billing_address: (),
        line_items: <shopify:OrderLineItem[]>[
            {
                id: 555,
                title: "Test Product 4",
                quantity: 1,
                price: "50.00",
                sku: "TEST-SKU-004",
                tax_lines: <shopify:TaxLine[]>[]
            }
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}

function getMockOrderBelowMinimum() returns shopify:OrderEvent {
    return {
        id: 123456792,
        order_number: 1004,
        created_at: "2024-01-15T13:00:00Z",
        currency: "USD",
        total_price: "5.00",
        total_discounts: "0.00",
        fulfillment_status: "fulfilled",
        financial_status: "paid",
        customer: {
            id: 987654324,
            email: "small.order@example.com",
            first_name: "Small",
            last_name: "Order"
        },
        billing_address: (),
        line_items: <shopify:OrderLineItem[]>[
            {
                id: 666,
                title: "Cheap Item",
                quantity: 1,
                price: "5.00",
                sku: "TEST-SKU-005",
                tax_lines: <shopify:TaxLine[]>[]
            }
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}

function getMockOrderWithoutLineItems() returns shopify:OrderEvent {
    return {
        id: 123456793,
        order_number: 1005,
        created_at: "2024-01-15T14:00:00Z",
        currency: "USD",
        total_price: "0.00",
        total_discounts: "0.00",
        fulfillment_status: "fulfilled",
        financial_status: "paid",
        customer: {
            id: 987654325,
            email: "empty.order@example.com",
            first_name: "Empty",
            last_name: "Order"
        },
        billing_address: (),
        line_items: <shopify:OrderLineItem[]>[],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}

function getMockUnfulfilledOrder() returns shopify:OrderEvent {
    return {
        id: 123456794,
        order_number: 1006,
        created_at: "2024-01-15T15:00:00Z",
        currency: "USD",
        total_price: "100.00",
        total_discounts: "0.00",
        fulfillment_status: "unfulfilled",
        financial_status: "pending",
        customer: {
            id: 987654326,
            email: "pending.order@example.com",
            first_name: "Pending",
            last_name: "Order"
        },
        billing_address: (),
        line_items: <shopify:OrderLineItem[]>[
            {
                id: 777,
                title: "Test Product 5",
                quantity: 1,
                price: "100.00",
                sku: "TEST-SKU-006",
                tax_lines: <shopify:TaxLine[]>[]
            }
        ],
        shipping_lines: [],
        discount_codes: [],
        discount_applications: []
    };
}
