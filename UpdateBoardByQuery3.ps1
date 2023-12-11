# Define variables
$organizationURL = "https://dev.azure.com/[OrgName]"
$projectName = "[ProjName]"
$pat = "[PATName]"
$savedQueryId = "[QueryName_ID]"  # Replace this with your saved query ID
$queryURL = "$organizationURL/$projectName/_apis/wit/wiql/$($savedQueryId)?api-version=6.0"

# Function to fetch work items using a saved query and add comments
function Fetch-WorkItemsAndAddMessage {
    try {
        # Make API request to execute the saved query
        $response = Invoke-RestMethod -Uri $queryURL -Method Get -Headers @{
            Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
            "Content-Type" = "application/json"
        }

        # Process the response and retrieve work item details
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
                    $updateText = "Please assign a user to this work Item @UserName"
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
            Write-Output "No work items found for the saved query or an error occurred while fetching data."
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}

# Execute the function
Fetch-WorkItemsAndAddMessage
