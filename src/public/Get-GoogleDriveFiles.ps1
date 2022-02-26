<#
#>
function Get-GoogleDriveFiles 
{
    [CmdletBinding()]
    param(
        [ValidateSet("All","Files","Folders")]
        [string]$ResultType = "All",

        [string]$Title,

        [string]$ParentId
    )

    $q = @()

    # mimeType
    if ($ResultType -ne "All") {
        if ($ResultType -eq "Folders") {
            $q += "mimeType='application/vnd.google-apps.folder'"
        }
        else {
            $q += "mimeType!='application/vnd.google-apps.folder'"
        }
    }

    # title
    if (![string]::IsNullOrEmpty($Title)) {
        $q += "name='$Title'"
    }

    # parents
    if (![string]::IsNullOrEmpty($ParentId)) {
        $q += "'$ParentId' in parents"
    }

    $queryArgs = @{
        q = [System.Web.HttpUtility]::UrlEncode($q -join ' and ')
        pageSize=40
    }    

    do {

        $queryString = $queryArgs.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)"} | Join-String -Separator "&"    
        
        $uri = "https://www.googleapis.com/drive/v3/files?$queryString"
        
        Write-Verbose $uri

        $result = Invoke-GApi -uri $uri

        # stream results
        $result.files

        if ('nextPageToken' -in $result.PSObject.Properties.Name) {
            $queryArgs.pageToken = $result.nextPageToken
        } else {
            $queryArgs.pageToken = $null    
        }

        $result | Out-String | Write-Verbose

    } while($queryArgs.pageToken)

}