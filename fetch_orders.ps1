$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczpcL1wvbWVyY2hhbnRyZXN0YXVyYW50LmFsZWt0YXNvbHV0aW9ucy5jb20iLCJpYXQiOjE3ODY1MDk1MzMsIm5iZiI6MTc4NjUwOTUzMywiZXhwIjoxNzg5MTAxNTMzLCJkYXRhIjp7InVzZXIiOnsiaWQiOjUsImRldmljZSI6IiIsInBhc3MiOiIyYjhlMjJlOTM2ZTY0N2JhNDRmOWJhMmY3Y2Q1ZmFjNiJ9fX0.R7_4kHcFW6CnHbyrscNtcSG8KX3z110dKHfr66hLt68'
$headers = @{ Authorization = "Bearer $token" }
$resp = Invoke-WebRequest -Uri 'https://merchantrestaurant.alektasolutions.com/wp-json/pinaka-restaurant-pos/v1/kot/get-all-orders?restaurant_id=1' -Headers $headers
$resp.Content | Out-File 'c:\Projects\pinaka_restaurant_pos\orders_raw.json' -Encoding utf8
Write-Host "Saved. Size: $($resp.Content.Length)"
