# 2-Item Online Order Webhook Test
# Order: Paneer Butter Masala + Chicken Tikka Masala = Rs.498.00

Invoke-RestMethod -Uri "http://localhost:3001/api/v1/connectors/doordash/webhook" `
  -Method POST `
  -Headers @{
    "Content-Type"     = "application/json"
    "x-correlation-id" = "pos-live-test-201"
  } `
  -Body '{
    "order_id": "DD-PINAKA-201",
    "store_id": "Pinaka_013",
    "total": 498.00,
    "items": [
      {
        "item_id": "ITEM-PAN-201",
        "name": "Paneer Butter Masala",
        "qty": 1,
        "price": 249.00
      },
      {
        "item_id": "ITEM-CHK-201",
        "name": "Chicken Tikka Masala",
        "qty": 1,
        "price": 249.00
      }
    ]
  }' | ConvertTo-Json -Depth 5
