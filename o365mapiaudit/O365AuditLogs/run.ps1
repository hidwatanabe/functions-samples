using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Azure AD application settings
$ClientID = "{Azure AD Application (client) ID}"
$ClientSecret = "{Client secret}"
$loginURL = "https://login.microsoftonline.com/"
$tenantdomain = "{your tenant name}.onmicrosoft.com"
$TenantGuid = "{Directory (tenant) ID}"
$resource = "https://manage.office.com"
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"} 

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Time Setting
$currentUTCtime = (Get-Date).ToUniversalTime()
$endTime = $currentUTCtime.AddHours(-24) | Get-Date -Format yyyy-MM-ddThh:mm:ss
$startTime = $currentUTCtime.AddHours(-48) | Get-Date -Format yyyy-MM-ddThh:mm:ss

# Subscription and Record Type Setting
$contentTypes = "Audit.AzureActiveDirectory,Audit.Exchange,Audit.SharePoint,Audit.General"

# Obtain data for eatch ContentTypes
$contentTypes = $contentTypes.split(",")
    # Loop for each content Type like Audit.Exchange
    foreach($contentType in $contentTypes){
        $listAvailableContentUri = "https://manage.office.com/api/v1.0/$tenantGUID/activity/feed/subscriptions/content?contentType=$contentType&PublisherIdentifier=$publisher&startTime=$startTime&endTime=$endTime"
        do {
            # List Available Content
            $contentResult = Invoke-RestMethod -Method GET -Headers $headerParams -Uri $listAvailableContentUri
            $contentResult.Count

            # Loop for each Content
            foreach($obj in $contentResult){
                # Retrieve Content
                $data = Invoke-RestMethod -Method GET -Headers $headerParams -Uri ($obj.contentUri)
                $data.Count                 
            }

            # Handles Pagination
            $nextPageResult = Invoke-WebRequest -Method GET -Headers $headerParams -Uri $listAvailableContentUri
            If($null -ne ($nextPageResult.Headers.NextPageUrl)){
                $nextPage = $true
                $listAvailableContentUri = $nextPageResult.Headers.NextPageUrl
            }
            Else{$nextPage = $false}
        } until ($nextPage -eq $false)
    }

# Blob Output
Push-OutputBinding -Name OutputBlob -Value ([HttpResponseContext]@{    
    Body = $data
})

# Standard Output
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{    
    StatusCode = [HttpStatusCode]::OK
    Body = $data
})