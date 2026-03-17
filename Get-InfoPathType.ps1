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




$webapplications = Get-SPWebApplication | Where-Object { $_.Name -in ("Main","Legacy","Index") }

foreach ($webapp in $webapplications)
{
    foreach ($site in $webapp.Sites)
    {
        foreach ($web in $site.AllWebs)
        {
            foreach ($list in $web.Lists)
            {
                $detectionType = Get-InfoPathType -list $list

                if($detectionType){
                    Write-Host "$detectionType : $($list.Title) @ $($web.url)"
                    [pscustomobject]@{
                        Site = $web.url
                        List = $list.Title
                        ListId = $list.Id
                        ItemCount = $($list.Items.Count)+$($list.folders.count)
                        LastItemModified = $list.LastItemModifiedDate
                        DetectionType = $detectionType
                    } | Export-Csv -Path "C:\SiteEnumeration\resultsInfoPath_03_13.csv" -Append -NoTypeInformation -Delimiter "`t"
                }
            }
            $web.Dispose()
        }
        $site.Dispose()
    }
}