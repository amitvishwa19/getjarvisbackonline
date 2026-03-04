# Get Google OAuth 2.0 Refresh Token
# Usage: .\get-google-refresh-token.ps1 -ClientId "your-client-id" -ClientSecret "your-client-secret"

param(
    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

# Scopes for Google Workspace (Drive, Gmail, Calendar)
$scopes = @(
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/calendar"
) -join ' '

# Encode scopes for URL
$encodedScopes = [System.Web.HttpUtility]::UrlEncode($scopes)

# Build authorization URL
$authUrl = "https://accounts.google.com/o/oauth2/auth?client_id=$ClientId&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&scope=$encodedScopes&access_type=offline&prompt=consent"

Write-Host "`n=== Google OAuth: Get Refresh Token ===`n" -ForegroundColor Cyan
Write-Host "Opening browser for authorization..." -ForegroundColor Yellow
Start-Process $authUrl

Write-Host "`n1. Browser mein Google account se login karein." -ForegroundColor White
Write-Host "2. 'Allow' button dabayein (full access)." -ForegroundColor White
Write-Host "3. Page par 'Authorization code' dikhai dega (long string)." -ForegroundColor White
Write-Host "4. Us code ko copy karein.`n" -ForegroundColor White

$code = Read-Host "Paste the authorization code here"

if ([string]::IsNullOrWhiteSpace($code)) {
    Write-Error "No code provided."
    exit 1
}

Write-Host "`nExchanging code for tokens..." -ForegroundColor Yellow

# Exchange code for tokens
$tokenResponse = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" `
    -Method Post `
    -ContentType "application/x-www-form-urlencoded" `
    -Body "code=$code&client_id=$ClientId&client_secret=$ClientSecret&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code"

if ($tokenResponse.access_token) {
    $refreshToken = $tokenResponse.refresh_token
    if ([string]::IsNullOrWhiteSpace($refreshToken)) {
        Write-Warning "No refresh_token returned. Maybe already have a long-lived access token? Full response:"
        $tokenResponse | ConvertTo-Json -Depth 3 | Write-Host
        exit 1
    }

    Write-Host "`n✅ Refresh token obtained!" -ForegroundColor Green
    Write-Host "`nRefresh Token: $refreshToken`n" -ForegroundColor Cyan

    # Set environment variable (user-level)
    [System.Environment]::SetEnvironmentVariable("GOOGLE_REFRESH_TOKEN", $refreshToken, "User")
    Write-Host "✅ Set GOOGLE_REFRESH_TOKEN in user environment." -ForegroundColor Green

    # Also show other tokens for reference
    Write-Host "`nOther tokens (for reference):" -ForegroundColor Gray
    $tokenResponse | Select-Object access_token, expires_in, scope | ConvertTo-Json -Depth 3 | Write-Host

    Write-Host "`nDone! You can now use the google-workspace skill." -ForegroundColor Green
} else {
    Write-Error "Failed to get tokens. Response:"
    $tokenResponse | ConvertTo-Json -Depth 3 | Write-Host
    exit 1
}
