$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3ODY1MDk1MzMsIm5iZiI6MTc4NjUwOTUzMywiZXhwIjoxNzg5MTAxNTMzLCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.R7_4kHcFW6CnHbyrscNtcSG8KX3z110dKHfr66hLt68'

$resp = Invoke-RestMethod `
    -Uri 'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/kot/get-all-orders?restaurant_id=1' `
    -Headers @{ Authorization = "Bearer $token" }

# Unwrap nested orders array
$orders = $resp.orders

Write-Host "Total orders in response: $($orders.Count)"
Write-Host "`n=== FIRST 5 ORDERS - ALL FIELDS ==="

$orders | Select-Object -First 5 | ForEach-Object {
    Write-Host "`n-------------------------------"
    Write-Host "order_id   : $($_.order_id)"
    Write-Host "order_type : $($_.order_type)"
    Write-Host "created_via: $($_.created_via)"
    Write-Host "flag_type  : $($_.flag_type)"
    Write-Host "is_parent  : $($_.is_parent)"
    Write-Host "status     : $($_.status)"
    Write-Host "ALL KEYS   : $($_.PSObject.Properties.Name -join ' | ')"
}
