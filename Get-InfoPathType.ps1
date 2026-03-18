[CmdletBinding()]
param(
    [string]$OutPath,
    [string[]]$ExcludedWebApps = $null
) 

if((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null){
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}

function Get-InfoPathType {
    param($list)

    if ($list.BaseTemplate -eq 115){
        return "FormLibrary"
    }

    if($list.ContentTypesEnabled -and $list.ContentTypes -ne $null -and $list.ContentTypes.Count -gt 0){
        foreach($ct in $list.ContentTypes){
            if($null -ne $ct.ResourceFolder -and $ct.ResourceFolder.Properties["_ipfs_infopathenabled"] -eq "True"){
                return "CustomizedListForm"
            }
        }
    }
    return $null
}



$webapplications = Get-SPWebApplication | Where-Object { -not $ExcludedWebApps -or $_.Name -notin $ExcludedWebApps }

foreach ($webapp in $webapplications)
{
    foreach ($site in $webapp.Sites)
    {
     try{         
        foreach ($web in $site.AllWebs)
        {
        try{
            foreach ($list in $web.Lists)
            {
            try{
                $detectionType = Get-InfoPathType -list $list
                if($detectionType){
                    Write-Host "$detectionType : $($list.Title) @ $($web.Url)"
                    [pscustomobject]@{
                        Site = $web.Url
                        List = $list.Title
                        ListId = $list.Id
                        ItemCount = $list.Items.Count+$list.Folders.Count
                        LastItemModified = $list.LastItemModifiedDate
                        DetectionType = $detectionType
                    } | Export-Csv -Path $OutPath -Append -NoTypeInformation -Delimiter "`t" -Encoding UTF8
                }
                }
                catch{Write-Host "Error processing list '$($list.Title)' in $($web.Url) : $_"}
            }
            }
        catch{Write-Host "Error processing web '$($web.Url)' : $_"}
        finally{$web.Dispose()}
        }
    }
    catch{Write-Host "Error processing site '$($site.Url)' : $_"}
    finally{$site.Dispose()}
    }
}

