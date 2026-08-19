$ck = 'ck_74739e5d026eb9c45628548c65dfa35a057cf0bb'
$cs = 'cs_41bccfc9f218445664eca0ba008294959f14af49'
$auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ck}:${cs}"))

# Fetch a known Dine-in order and an Online order to compare meta_data keys
Write-Host "=== Fetching recent orders to compare meta_data ==="
$orders = Invoke-RestMethod -Uri "https://merchantrestaurant.alektasolutions.com/wp-json/wc/v3/orders?per_page=20&orderby=date&order=desc" -Headers @{ Authorization = $auth }

foreach ($o in $orders) {
    $meta = $o.meta_data
    $orderType = ($meta | Where-Object { $_.key -eq '_order_type' -or $_.key -eq 'order_type' } | Select-Object -First 1).value
    $createdVia = $o.created_via
    $posType = ($meta | Where-Object { $_.key -match 'pos|type|channel|kot' } | ForEach-Object { "$($_.key)=$($_.value)" }) -join ', '
    Write-Host "ID=$($o.id) | status=$($o.status) | created_via=$createdVia | _order_type=$orderType | pos_meta=[$posType]"
}
