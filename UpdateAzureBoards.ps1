# Define variables
$organizationURL = "https://dev.azure.com/{ORG}"
$projectName = "{PRJ}"
$pat = "{PAT}"
$queryURL = "$organizationURL/$projectName/_apis/wit/wiql?api-version=6.0"

# Define the Wiql query
$sprintQuery = @{
    query = "Select [System.Id], [System.Title], [System.State], [System.ChangedDate] From WorkItems Where [System.IterationPath] Under '$projectName\\{QueryName}' Order By [System.ChangedDate] Desc"
}

# Function to fetch work items
function Fetch-WorkItemsAndAddMessage {
    try {
        # Make API request to fetch work items
        $response = Invoke-RestMethod -Uri $queryURL -Method Post -Headers @{
            Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
            "Content-Type" = "application/json"
        } -Body ($sprintQuery | ConvertTo-Json -Depth 10)

        # Process response
        if ($response.workItems -and $response.workItems.Length -gt 0) {
            foreach ($workItem in $response.workItems) {
                $workItemID = $workItem.id
                $workItemURL = $workItem.url

                # Fetch individual work item details
                $workItemDetails = Invoke-RestMethod -Uri $workItemURL -Headers @{
                    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
                    "Content-Type" = "application/json"
                }

                Write-Output "Work Item Number: $workItemID - URL: $workItemURL"
                Write-Output ($workItemDetails | ConvertTo-Json)  # Output work item details

                # Update message to be added
                if (-not [string]::IsNullOrWhiteSpace($assignedUser)) {
                    $updateText = "Please Update the board @$assignedUser"
                } else {
                    $updateText = "Please assign a user to this work Item @km.developer.all@gmail.com"
                }



                # Update message to be added
              

                # Add the message to the discussion of the work item
                $messagePayload = @{
                    text = $updateText
                }

                # Add message to the work item comments
                $addMessageResponse = Invoke-RestMethod -Uri "$workItemURL/comments?api-version=6.0-preview.3" -Method Post -Headers @{
                    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
                    "Content-Type" = "application/json"
                } -Body ($messagePayload | ConvertTo-Json -Depth 10)
                
                Write-Output "Response after adding message: $($addMessageResponse | ConvertTo-Json)"
            }
        } else {
            Write-Output "No work items found or an error occurred while fetching data."
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}

# Execute the function
Fetch-WorkItemsAndAddMessage
