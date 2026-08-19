$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3ODY1MDk1MzMsIm5iZiI6MTc4NjUwOTUzMywiZXhwIjoxNzg5MTAxNTMzLCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.R7_4kHcFW6CnHbyrscNtcSG8KX3z110dKHfr66hLt68'

# Try to POST to Pinaka POS /orders endpoint with flag_type = parent_online_order
# This should create the order in the Pinaka custom table with order_type = Online Order
Write-Host "=== Testing Pinaka POS /orders endpoint with online order_type ==="

$body = @{
    flag_type       = "parent_online_order"
    restaurant_id   = 1
    created_via     = "online"
    order_type      = "Online Order"
    order_datetime  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.ffffff")
} | ConvertTo-Json

$resp = Invoke-RestMethod `
    -Uri 'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/orders' `
    -Method POST `
    -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
    -Body $body

$resp | ConvertTo-Json -Depth 5
