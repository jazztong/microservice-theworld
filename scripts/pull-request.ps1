param (
  [Parameter(Mandatory)] $_repoName, 
  [Parameter(Mandatory)]$_filePath,
  [Parameter(Mandatory)]$_fileContent
)
[string] $repoName = $_repoName
[string] $filePath = $_filePath
[string] $fileContent = $_fileContent
[string] $branchRef = 'heads/main'
[string] $apiVersion = '5.1'
[string] $commitComment = "Update Image Version"
[int] $debugRequest = $false
[string] $pullRequestTitle = "Auto pull request"
[string] $pullRequestDesc = "Merge to main to update version"

function DebugLog {
  param (
    [Parameter(Mandatory = $true)][string] $requestUrl,
    [Parameter(Mandatory = $false)][System.Object] $requestBody,
    [Parameter(Mandatory = $true)][System.Object] $response
  )
  if ($debugRequest -eq $true) {
    Write-Host "URL = $requestUrl" -ForegroundColor Blue
    Write-Host "Request Body = " -ForegroundColor Blue
    Write-Host $requestBody -ForegroundColor Blue
    Write-Host "Response - " -ForegroundColor Blue
    $response | ConvertTo-Json
  }
}
$SYSTEM_COLLECTIONURI = [System.Environment]::GetEnvironmentVariable("SYSTEM_COLLECTIONURI")
$SYSTEM_TEAMPROJECT = [System.Environment]::GetEnvironmentVariable("SYSTEM_TEAMPROJECT")
$SYSTEM_ACCESSTOKEN = [System.Environment]::GetEnvironmentVariable("SYSTEM_ACCESSTOKEN")
$global:debugRequest = $debugRequest

if ($null -eq $SYSTEM_COLLECTIONURI) { Write-Host "SYSTEM_COLLECTIONURI environment variable not found." ; return }
if ($null -eq $SYSTEM_TEAMPROJECT) { Write-Host "SYSTEM_TEAMPROJECT environment variable not found."; return }
if ($null -eq $SYSTEM_ACCESSTOKEN) { Write-Host "SYSTEM_ACCESSTOKEN environment variable not found."; return }

# Variable
$date = Get-Date
$encodeSystemTeamProject = [uri]::EscapeDataString($SYSTEM_TEAMPROJECT)
$invokeURI = "$SYSTEM_COLLECTIONURI$encodeSystemTeamProject"
$pullRequestBranch = "AutoBranch-" + $date.ToString("yyyyMMddHHmm")

if ($debugRequest -eq $true) {
  Write-Host "SYSTEM_COLLECTIONURI=$SYSTEM_COLLECTIONURI
  SYSTEM_TEAMPROJECT=$SYSTEM_TEAMPROJECT
  encodeSystemTeamProject=$encodeSystemTeamProject
  invokeURI=$invokeURI
  repoName=$repoName
  SYSTEM_ACCESSTOKEN=$env:SYSTEM_ACCESSTOKEN
  " -ForegroundColor Green
}

$headers = New-Object "System.Collections.Generic.Dictionary[[String], [String]]"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("user:$SYSTEM_ACCESSTOKEN"))
$headers.Add("Authorization", "Basic $encodedCreds")
$headers.Add("Content-Type", "application/json")
# Find repo ID
$url = "$invokeURI/_apis/git/repositories?api-version=$apiVersion"
Write-Host $url
$response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
DebugLog $url $null $response

$repoObj = $response.value | Where-Object { $_.name -eq $repoName }

if ($null -eq $repoObj) { Write-Host "Unable to find repo"; return }
$repoID = $repoObj.id
Write-Host "Repo Id = $repoID"
# Find main branch commit object
$url = "$invokeURI/_apis/git/repositories/$repoID/refs?filter=$branchRef&api-version=$apiVersion"
$response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
DebugLog $url $null $response

if ($response.count -eq 0) { Write-Host "Unable to find ref $branchRef"; return }
$objectId = $response.value[0].objectId
Write-Host "Branch Object Id = $objectId"

# Find if file exist
$changeType = "edit"
try {
  $url = "$invokeURI/_apis/git/repositories/$repoID/items?path=$filePath&api-version=$apiVersion"
  $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
  DebugLog $url $null $response
}
catch {
  # File not exist
  $changeType = "add"
}
Write-Host "File commit type = $changeType"
$body = @"
{
  "refUpdates": [
    {"name": "refs/heads/$PullRequestBranch","oldObjectId": "$objectId"}
  ],
  "commits": [
    {
      "comment": "$commitComment",
      "changes": [
        {
          "changeType": "$changeType",
          "item": {
            "path": "$filePath"
          },
          "newContent": {
            "content": "$fileContent",
            "contentType": "rawtext"
          }
        }
      ]
    }
  ]
}
"@
#Create Repo
$url = "$invokeURI/_apis/git/repositories/$repoID/pushes?api-version=$apiVersion"
$response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $body
DebugLog $url $body $response

if ($response.commits.Count -eq 0) { Write-Error "Create new branch fail"; return }

$body = @"
{
    "sourceRefName": "refs/heads/$PullRequestBranch",
    "targetRefName": "refs/$branchRef",
    "title": "$pullRequestTitle",
    "description": "$pullRequestDesc"
  }
"@
# Create Pull Request
$url = "$invokeURI/_apis/git/repositories/$repoID/pullrequests?api-version=$apiVersion"
$response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $body
DebugLog $url $body $response

if (-not($response.repository)) { Write-Error "Create pull request fail"; return }
Write-Host "New pull request create successful" -ForegroundColor Green